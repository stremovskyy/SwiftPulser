import Foundation

public extension PulseMetricsManager {
    func trackScreenView(screenName: String,
                         screenClass: String? = nil,
                         userId: String? = nil,
                         additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = ["screen_name": screenName]
        
        if let screenClass = screenClass {
            metadata["screen_class"] = screenClass
        }
        
        if let additionalMetadata = additionalMetadata {
            for (key, value) in additionalMetadata {
                metadata[key] = value
            }
        }
        
        track(eventType: "screen_view", userId: userId, metadata: metadata)
    }
    
    func trackUserAction(action: String,
                         category: String? = nil,
                         label: String? = nil,
                         value: Any? = nil,
                         userId: String? = nil,
                         additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = ["action": action]
        
        if let category = category {
            metadata["category"] = category
        }
        
        if let label = label {
            metadata["label"] = label
        }
        
        if let value = value {
            metadata["value"] = value
        }
        
        if let additionalMetadata = additionalMetadata {
            for (key, value) in additionalMetadata {
                metadata[key] = value
            }
        }
        
        track(eventType: "user_action", userId: userId, metadata: metadata)
    }
    
    func trackError(_ error: Error,
                    domain: String? = nil,
                    context: String? = nil,
                    userId: String? = nil,
                    additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = [
            "error_code": (error as NSError).code,
            "error_message": error.localizedDescription
        ]
        
        if let domain = domain {
            metadata["error_domain"] = domain
        } else {
            metadata["error_domain"] = (error as NSError).domain
        }
        
        if let context = context {
            metadata["context"] = context
        }
        
        if let additionalMetadata = additionalMetadata {
            for (key, value) in additionalMetadata {
                metadata[key] = value
            }
        }
        
        track(eventType: "error", userId: userId, metadata: metadata)
    }
    
    func trackPerformance(name: String,
                          category: String,
                          value: Double,
                          userId: String? = nil,
                          additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = [
            "metric_name": name,
            "category": category,
            "value": value
        ]
        
        if let additionalMetadata = additionalMetadata {
            for (key, value) in additionalMetadata {
                metadata[key] = value
            }
        }
        
        track(eventType: "performance", userId: userId, metadata: metadata)
    }
} 