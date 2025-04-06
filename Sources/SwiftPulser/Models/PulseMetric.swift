import Foundation

public struct PulseMetric: Codable {
    public let serviceCode: String
    public let eventType: String
    public let eventSubType: String?
    public let userId: String?
    public let timestamp: Date
    public let metadata: [String: AnyCodable]?
    
    public init(serviceCode: String,
                eventType: String,
                eventSubType: String? = nil,
                userId: String? = nil,
                timestamp: Date = Date(),
                metadata: [String: Any]? = nil) {
        self.serviceCode = serviceCode
        self.eventType = eventType
        self.eventSubType = eventSubType
        self.userId = userId
        self.timestamp = timestamp
        self.metadata = metadata?.mapValues { AnyCodable($0) }
    }
    
    private enum CodingKeys: String, CodingKey {
        case serviceCode = "service_code"
        case eventType = "event_type"
        case eventSubType = "event_sub_type"
        case userId = "user_id"
        case timestamp
        case metadata
    }
} 