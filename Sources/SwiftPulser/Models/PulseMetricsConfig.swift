import Foundation

public struct PulseMetricsConfig {
    public let baseURL: URL
    public let oauthTokenURL: URL
    public let authToken: String
    public let batchSize: Int
    public let batchInterval: TimeInterval
    public let timeout: TimeInterval
    public let maxRetries: Int
    public let baseRetryDelay: TimeInterval
    public let persistMetrics: Bool
    public let maxStorageSize: Int
    public let fileManager: FileManager
    public let sessionConfiguration: URLSessionConfiguration
    public let defaultServiceCode: String?
    public let includeDeviceInfo: Bool
    
    public init(baseURL: URL,
                oauthTokenURL: URL,
                authToken: String,
                batchSize: Int = 100,
                batchInterval: TimeInterval = 60.0,
                timeout: TimeInterval = 30.0,
                maxRetries: Int = 3,
                baseRetryDelay: TimeInterval = 2.0,
                persistMetrics: Bool = true,
                maxStorageSize: Int = 10 * 1024 * 1024, // 10MB
                fileManager: FileManager = .default,
                sessionConfiguration: URLSessionConfiguration = .default,
                defaultServiceCode: String? = nil,
                includeDeviceInfo: Bool = true) {
        self.baseURL = baseURL
        self.oauthTokenURL = oauthTokenURL
        self.authToken = authToken
        self.batchSize = batchSize
        self.batchInterval = batchInterval
        self.timeout = timeout
        self.maxRetries = maxRetries
        self.baseRetryDelay = baseRetryDelay
        self.persistMetrics = persistMetrics
        self.maxStorageSize = maxStorageSize
        self.fileManager = fileManager
        self.sessionConfiguration = sessionConfiguration
        self.defaultServiceCode = defaultServiceCode
        self.includeDeviceInfo = includeDeviceInfo
        
        // Configure session timeout
        self.sessionConfiguration.timeoutIntervalForRequest = timeout
        self.sessionConfiguration.timeoutIntervalForResource = timeout * 2
    }
} 