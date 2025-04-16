import Foundation

// MARK: - Time Range Tracking
public extension PulseMetricsManager {
    func startTimeRange(rangeId: String,
                       eventType: String,
                       eventSubType: String? = nil,
                       metadata: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            var combinedMetadata = self.defaultMetadata
            if let metadata = metadata {
                combinedMetadata.merge(metadata) { (_, new) in new }
            }
            
            self.activeTimeRanges[rangeId] = (Date(), combinedMetadata)
            self.log(.debug, message: "Started time range tracking for \(rangeId)")
        }
    }

    func endTimeRange(rangeId: String,
                     eventType: String,
                     eventSubType: String? = nil,
                     additionalMetadata: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let self = self,
                  let (startTime, metadata) = self.activeTimeRanges[rangeId] else {
                self?.log(.warning, message: "No active time range found for \(rangeId)")
                return
            }
            
            let duration = Date().timeIntervalSince(startTime)
            var combinedMetadata = metadata
            if let additionalMetadata = additionalMetadata {
                combinedMetadata.merge(additionalMetadata) { (_, new) in new }
            }
            combinedMetadata["duration_seconds"] = duration
            
            self.track(eventType: eventType,
                      eventSubType: eventSubType,
                      metadata: combinedMetadata)
            
            self.activeTimeRanges.removeValue(forKey: rangeId)
            self.log(.debug, message: "Ended time range tracking for \(rangeId) with duration \(duration) seconds")
        }
    }
}

// MARK: - Session Tracking
public extension PulseMetricsManager {    
    func startSession(sessionId: String, metadata: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            var combinedMetadata = self.defaultMetadata
            if let metadata = metadata {
                combinedMetadata.merge(metadata) { (_, new) in new }
            }
            
            self.activeSessions[sessionId] = (Date(), combinedMetadata)
            self.track(eventType: "session_start",
                      eventSubType: nil,
                      metadata: combinedMetadata)
            self.log(.debug, message: "Started session \(sessionId)")
        }
    }

    func endSession(sessionId: String, additionalMetadata: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let self = self,
                  let (startTime, metadata) = self.activeSessions[sessionId] else {
                self?.log(.warning, message: "No active session found for \(sessionId)")
                return
            }
            
            let duration = Date().timeIntervalSince(startTime)
            var combinedMetadata = metadata
            if let additionalMetadata = additionalMetadata {
                combinedMetadata.merge(additionalMetadata) { (_, new) in new }
            }
            combinedMetadata["duration_seconds"] = duration
            
            self.track(eventType: "session_end",
                      eventSubType: nil,
                      metadata: combinedMetadata)
            
            self.activeSessions.removeValue(forKey: sessionId)
            self.log(.debug, message: "Ended session \(sessionId) with duration \(duration) seconds")
        }
    }
}

// MARK: - Convenience Methods
public extension PulseMetricsManager {
    func trackUserAction(action: String,
                        screen: String,
                        userId: String? = nil,
                        additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = [
            "action": action,
            "screen": screen
        ]
        
        if let additionalMetadata = additionalMetadata {
            metadata.merge(additionalMetadata) { (_, new) in new }
        }
        
        track(eventType: "user_action",
              eventSubType: action,
              userId: userId,
              metadata: metadata)
    }

    func trackError(_ error: Error,
                   context: String,
                   userId: String? = nil,
                   additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "context": context
        ]
        
        if let additionalMetadata = additionalMetadata {
            metadata.merge(additionalMetadata) { (_, new) in new }
        }
        
        track(eventType: "error",
              eventSubType: context,
              userId: userId,
              metadata: metadata)
    }

    func trackPerformance(metricName: String,
                         value: Double,
                         unit: String,
                         userId: String? = nil,
                         additionalMetadata: [String: Any]? = nil) {
        var metadata: [String: Any] = [
            "metric_name": metricName,
            "value": value,
            "unit": unit
        ]
        
        if let additionalMetadata = additionalMetadata {
            metadata.merge(additionalMetadata) { (_, new) in new }
        }
        
        track(eventType: "performance",
              eventSubType: metricName,
              userId: userId,
              metadata: metadata)
    }
} 
