import Foundation

public class PerformanceTracker {
    private let name: String
    private let category: String
    private let startTime: CFAbsoluteTime
    private var additionalMetadata: [String: Any]?
    private var userId: String?
    
    public init(name: String,
                category: String,
                userId: String? = nil,
                additionalMetadata: [String: Any]? = nil) {
        self.name = name
        self.category = category
        self.startTime = CFAbsoluteTimeGetCurrent()
        self.userId = userId
        self.additionalMetadata = additionalMetadata
    }
    
    public func stop(extraMetadata: [String: Any]? = nil) {
        let endTime = CFAbsoluteTimeGetCurrent()
        let duration = (endTime - startTime) * 1000 // Convert to milliseconds
        
        var metadata = additionalMetadata ?? [:]
        
        if let extraMetadata = extraMetadata {
            for (key, value) in extraMetadata {
                metadata[key] = value
            }
        }
        
        PulseMetricsManager.shared.trackPerformance(
            name: name,
            category: category,
            value: duration,
            userId: userId,
            additionalMetadata: metadata
        )
    }
} 