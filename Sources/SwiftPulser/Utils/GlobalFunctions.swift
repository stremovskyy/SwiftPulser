import Foundation

public func trackMetricEvent(eventType: String,
                             eventSubType: String? = nil,
                             serviceCode: String? = nil,
                             userId: String? = nil,
                             metadata: [String: Any]? = nil) {
    PulseMetricsManager.shared.track(eventType: eventType,
                                     eventSubType: eventSubType,
                                     serviceCode: serviceCode,
                                     userId: userId,
                                     metadata: metadata)
}

public func flushMetrics(completion: (() -> Void)? = nil) {
    PulseMetricsManager.shared.flush(completion: completion)
}

public func clearMetrics() {
    PulseMetricsManager.shared.clearMetrics()
} 