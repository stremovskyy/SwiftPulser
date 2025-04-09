import Foundation
import UIKit

public class PulseMetricsManager {
    // MARK: - Properties
    
    public static let shared = PulseMetricsManager()
    public  var config: PulseMetricsConfig?
    public var session: URLSession!
    public var serviceToken: String?
    public var refreshToken: String?
    public private(set) var logLevel: PulseLogLevel = .error
    public private(set) var isEnabled = true
    public var defaultUserId: String?
    public var defaultMetadata: [String: Any] = [:]

    private let queue = DispatchQueue(label: "com.pulse.metrics", qos: .utility)
    private var timer: Timer?
    private var metricsBuffer: [PulseMetric] = []
    private var retryCounters: [UUID: Int] = [:]
    private var storageURL: URL?
    private var tokenStorageURL: URL?
    
    private lazy var deviceInfo: [String: Any] = {
        var info: [String: Any] = [:]
        
#if os(iOS) || os(tvOS) || os(watchOS)
        info["device_model"] = UIDevice.current.model
        info["system_name"] = UIDevice.current.systemName
        info["system_version"] = UIDevice.current.systemVersion
#elseif os(macOS)
        info["system_name"] = "macOS"
        let processInfo = ProcessInfo.processInfo
        info["system_version"] = processInfo.operatingSystemVersionString
#endif
        return info
    }()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    public func configure(with config: PulseMetricsConfig) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.timer?.invalidate()
            self.config = config
            self.session = URLSession(configuration: config.sessionConfiguration)
            if config.persistMetrics {
                self.setupStorage()
                self.loadPersistedMetrics()
            }
            
            self.startBatchTimer()
            
            self.log(.info, message: "PulseMetricsManager configured successfully")
        }
    }
    
    public func setLogLevel(_ level: PulseLogLevel) {
        logLevel = level
    }
    
    public func setEnabled(_ enabled: Bool) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.isEnabled = enabled
            self.log(.info, message: "Metrics collection \(enabled ? "enabled" : "disabled")")
        }
    }
    
    public func track(metric: PulseMetric) {
        queue.async { [weak self] in
            guard let self = self, let config = self.config, self.isEnabled else { return }
            
            self.metricsBuffer.append(metric)
            self.log(.debug, message: "Tracked metric: \(metric.eventType)")
            
            if self.metricsBuffer.count >= config.batchSize {
                self.sendBatch()
            }
        }
    }
    
    public func track(eventType: String,
                      eventSubType: String? = nil,
                      serviceCode: String? = nil,
                      userId: String? = nil,
                      metadata: [String: Any]? = nil) {
        guard let config = self.config else {
            log(.error, message: "Cannot track metrics: Manager not configured")
            return
        }
        
        var combinedMetadata = defaultMetadata
        
        if let metadata = metadata {
            for (key, value) in metadata {
                combinedMetadata[key] = value
            }
        }
        
        if config.includeDeviceInfo {
            combinedMetadata.merge(self.deviceInfo) { (_, new) in new }
        }
        
        let metric = PulseMetric(
            serviceCode: serviceCode ?? config.defaultServiceCode ?? "unknown",
            eventType: eventType,
            eventSubType: eventSubType,
            userId: userId ?? defaultUserId,
            timestamp: Date(),
            metadata: combinedMetadata
        )
        
        track(metric: metric)
    }
    
    public func flush(completion: (() -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else {
                completion?()
                return
            }
            
            self.sendBatch()
            completion?()
        }
    }
    
    public func clearMetrics() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.metricsBuffer.removeAll()
            self.log(.info, message: "Metrics buffer cleared")
        }
    }
    
    // MARK: - Private Methods
    
    private func startBatchTimer() {
        guard let config = config else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.timer = Timer.scheduledTimer(withTimeInterval: config.batchInterval, repeats: true) { [weak self] _ in
                self?.sendBatch()
            }
        }
    }
    
    private func sendBatch() {
        guard let config = config, !metricsBuffer.isEmpty else { return }
        
        let batchId = UUID()
        let batch = metricsBuffer
        metricsBuffer.removeAll()
        
        log(.info, message: "Sending batch of \(batch.count) metrics")
        
        sendMetricsBatch(batch, batchId: batchId, retryCount: 0)
    }
    
    
 private func sendMetricsBatch(_ batch: [PulseMetric], batchId: UUID, retryCount: Int) {
    guard let config = self.config else { 
        log(.error, message: "[Batch \(batchId)] Cannot send metrics - configuration is nil")
        return 
    }
    
    // Add debug info about the batch
    log(.debug, message: "[Batch \(batchId)] Preparing to send \(batch.count) metrics (retry: \(retryCount))")
    
    // Fetch token if not available
    guard let serviceToken = serviceToken else {
        log(.info, message: "[Batch \(batchId)] No service token available, fetching new token")
        fetchServiceToken { [weak self] result in
            switch result {
            case .success(let token):
                    self?.log(.debug, message: "[Batch \(batchId)] Successfully fetched new token")
                self?.sendMetricsBatch(batch, batchId: batchId, retryCount: retryCount)
            case .failure(let error):
                self?.log(.error, message: "[Batch \(batchId)] Failed to fetch service token: \(error.localizedDescription)")
                self?.handleSendFailure(batch: batch, batchId: batchId, retryCount: retryCount)
            }
        }
        return
    }
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    do {
        let jsonData = try encoder.encode(batch)
        let endpoint = "pulse/api/v1/customer/track"
        let url = config.baseURL.appendingPathComponent(endpoint)
        
        log(.debug, message: "[Batch \(batchId)] Sending request to \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(serviceToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let payloadSize = jsonData.count
        log(.debug, message: "[Batch \(batchId)] Request payload size: \(payloadSize) bytes")
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.log(.error, message: "[Batch \(batchId)] Network error: \(error.localizedDescription)")
                self.handleSendFailure(batch: batch, batchId: batchId, retryCount: retryCount)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.log(.error, message: "[Batch \(batchId)] Invalid response type")
                self.handleSendFailure(batch: batch, batchId: batchId, retryCount: retryCount)
                return
            }
            

            if let responseHeaders = httpResponse.allHeaderFields as? [String: String] {
                let headersDebug = responseHeaders.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
                self.log(.debug, message: "[Batch \(batchId)] Response headers: \(headersDebug)")
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                self.log(.debug, message: "[Batch \(batchId)] Response body: \(responseString)")
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                self.log(.info, message: "[Batch \(batchId)] Successfully sent \(batch.count) metrics (HTTP \(httpResponse.statusCode))")
            } else {
                if httpResponse.statusCode == 401 {
                    self.serviceToken = nil // Invalidate expired token
                    self.log(.warning, message: "[Batch \(batchId)] Token expired (HTTP 401), will retry with new token")
                } else {
                    self.log(.error, message: "[Batch \(batchId)] Server error: HTTP \(httpResponse.statusCode)")
                }
                self.handleSendFailure(batch: batch, batchId: batchId, retryCount: retryCount)
            }
        }
        
        task.resume()
        log(.debug, message: "[Batch \(batchId)] Request started")
        
    } catch {
        log(.error, message: "[Batch \(batchId)] JSON encoding error: \(error.localizedDescription)")
        handleSendFailure(batch: batch, batchId: batchId, retryCount: retryCount)
    }
}

    private func handleSendFailure(batch: [PulseMetric], batchId: UUID, retryCount: Int) {
        guard let config = config else {
            queue.async { [weak self] in
                self?.metricsBuffer.insert(contentsOf: batch, at: 0)
            }
            return
        }
        
        if retryCount < config.maxRetries {
            let nextRetryCount = retryCount + 1
            let delay = config.baseRetryDelay * pow(2.0, Double(retryCount)) 
            
            log(.info, message: "Scheduling retry \(nextRetryCount)/\(config.maxRetries) for batch in \(delay) seconds")
            
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.sendMetricsBatch(batch, batchId: batchId, retryCount: nextRetryCount)
            }
        } else {
            log(.warning, message: "Exceeded max retries for batch, storing for later")
            
            if config.persistMetrics {
                persistMetricsBatch(batch)
            } else {
                queue.async { [weak self] in
                    self?.metricsBuffer.insert(contentsOf: batch, at: 0)
                }
            }
        }
    }
    
    private func log(_ level: PulseLogLevel, message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard level <= logLevel else { return }
        
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let prefix: String
        
        switch level {
            case .error: prefix = "❌ ERROR"
            case .warning: prefix = "⚠️ WARNING"
            case .info: prefix = "ℹ️ INFO"
            case .debug: prefix = "🔍 DEBUG"
            case .verbose: prefix = "📝 VERBOSE"
            case .none: return
        }
        
        print("[\(prefix)] [\(fileName):\(line)] \(function): \(message)")
    }
    
    // MARK: - Persistence Methods
    
    private func setupStorage() {
        guard let config = config else { return }
        
        let documentsURL = config.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let metricsStorageURL = documentsURL.appendingPathComponent("PulseMetrics", isDirectory: true)
        let tokenStorageURL = documentsURL.appendingPathComponent("PulseMetrics/Tokens", isDirectory: true)
        
        do {
            if !config.fileManager.fileExists(atPath: metricsStorageURL.path) {
                try config.fileManager.createDirectory(at: metricsStorageURL, withIntermediateDirectories: true)
            }
            
            if !config.fileManager.fileExists(atPath: tokenStorageURL.path) {
                try config.fileManager.createDirectory(at: tokenStorageURL, withIntermediateDirectories: true)
            }
            
            self.storageURL = metricsStorageURL
            self.tokenStorageURL = tokenStorageURL
            log(.debug, message: "Storage initialized at: \(metricsStorageURL.path)")
            log(.debug, message: "Token storage initialized at: \(tokenStorageURL.path)")
            
            loadPersistedTokens()
        } catch {
            log(.error, message: "Failed to setup storage: \(error.localizedDescription)")
        }
    }
    
    private func persistMetricsBatch(_ batch: [PulseMetric]) {
        guard let storageURL = storageURL, let config = config else { return }
        
        let batchURL = storageURL.appendingPathComponent("batch-\(UUID().uuidString).json")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let jsonData = try encoder.encode(batch)
            try jsonData.write(to: batchURL)
            log(.debug, message: "Persisted batch to: \(batchURL.lastPathComponent)")
            
            enforceStorageSizeLimit()
        } catch {
            log(.error, message: "Failed to persist metrics: \(error.localizedDescription)")
        }
    }
    
    private func loadPersistedMetrics() {
        guard let storageURL = storageURL, let config = config else { return }
        
        do {
            let fileURLs = try config.fileManager.contentsOfDirectory(
                at: storageURL,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "json" }
            
            log(.info, message: "Found \(fileURLs.count) persisted metric batches")
            
            for fileURL in fileURLs {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    
                    let batch = try decoder.decode([PulseMetric].self, from: data)
                    
                    metricsBuffer.append(contentsOf: batch)
                    
                    try config.fileManager.removeItem(at: fileURL)
                    
                    log(.debug, message: "Loaded and removed persisted batch: \(fileURL.lastPathComponent)")
                } catch {
                    log(.error, message: "Failed to load persisted batch \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
            
        } catch {
            log(.error, message: "Failed to access persisted metrics: \(error.localizedDescription)")
        }
    }
    
    func persistTokens() {
        guard let tokenStorageURL = tokenStorageURL,
              let config = config,
              let serviceToken = serviceToken,
              let refreshToken = refreshToken else { return }
        
        let tokenData: [String: String] = [
            "service_token": serviceToken,
            "refresh_token": refreshToken
        ]
        
        let tokenFileURL = tokenStorageURL.appendingPathComponent("tokens.json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: tokenData, options: .prettyPrinted)
            try jsonData.write(to: tokenFileURL)
            log(.debug, message: "Tokens persisted successfully")
        } catch {
            log(.error, message: "Failed to persist tokens: \(error.localizedDescription)")
        }
    }
    
    private func loadPersistedTokens() {
        guard let tokenStorageURL = tokenStorageURL,
              let config = config else { return }
        
        let tokenFileURL = tokenStorageURL.appendingPathComponent("tokens.json")
        
        do {
            let jsonData = try Data(contentsOf: tokenFileURL)
            let tokenData = try JSONSerialization.jsonObject(with: jsonData) as? [String: String]
            
            if let serviceToken = tokenData?["service_token"],
               let refreshToken = tokenData?["refresh_token"] {
                self.serviceToken = serviceToken
                self.refreshToken = refreshToken
                log(.info, message: "Loaded persisted tokens successfully")
            }
        } catch {
            log(.debug, message: "No persisted tokens found or error loading them: \(error.localizedDescription)")
        }
    }
    
    private func enforceStorageSizeLimit() {
        guard let storageURL = storageURL, let config = config else { return }
        
        do {
            let fileURLs = try config.fileManager.contentsOfDirectory(
                at: storageURL,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
            
            var filesWithSize: [(url: URL, size: Int64, date: Date)] = []
            
            for fileURL in fileURLs {
                do {
                    let attributes = try config.fileManager.attributesOfItem(atPath: fileURL.path)
                    let size = attributes[.size] as? Int64 ?? 0
                    let date = attributes[.creationDate] as? Date ?? Date.distantPast
                    
                    filesWithSize.append((fileURL, size, date))
                } catch {
                    log(.error, message: "Failed to get attributes for \(fileURL.lastPathComponent)")
                }
            }
            
            let totalSize = filesWithSize.reduce(0) { $0 + $1.size }
            
            if totalSize > Int64(config.maxStorageSize) {
                log(.warning, message: "Storage over limit (\(totalSize) > \(config.maxStorageSize)), cleaning up")
                
                let sortedFiles = filesWithSize.sorted { $0.date < $1.date }
                
                var currentSize = totalSize
                for file in sortedFiles {
                    if currentSize <= Int64(config.maxStorageSize) {
                        break
                    }
                    
                    do {
                        try config.fileManager.removeItem(at: file.url)
                        currentSize -= file.size
                        log(.debug, message: "Removed old batch: \(file.url.lastPathComponent)")
                    } catch {
                        log(.error, message: "Failed to remove file: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            log(.error, message: "Failed to check storage size: \(error.localizedDescription)")
        }
    }
    
    deinit {
        timer?.invalidate()
        flush()
    }
} 
