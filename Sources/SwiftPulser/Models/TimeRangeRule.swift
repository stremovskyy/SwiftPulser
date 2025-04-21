import Foundation

public struct TimeRangeRule: Codable {
    public let minSeconds: Double?
    public let maxSeconds: Double?
    public let label: String
    
    public init(minSeconds: Double? = nil, maxSeconds: Double? = nil, label: String) {
        self.minSeconds = minSeconds
        self.maxSeconds = maxSeconds
        self.label = label
    }
    
    public func matches(_ seconds: Double) -> Bool {
        if let min = minSeconds, seconds < min {
            return false
        }
        if let max = maxSeconds, seconds >= max {
            return false
        }
        return true
    }
}

public struct TimeRangeRules: Codable {
    public let rules: [TimeRangeRule]
    public let useRawValue: Bool
    
    public init(rules: [TimeRangeRule] = [], useRawValue: Bool = true) {
        self.rules = rules
        self.useRawValue = useRawValue
    }
    
    public func getLabel(for seconds: Double) -> String {
        if useRawValue {
            return "\(Int(seconds))s"
        }
        
        for rule in rules {
            if rule.matches(seconds) {
                return rule.label
            }
        }
        
        // If no rule matches, return raw value
        return "\(Int(seconds))s"
    }
} 