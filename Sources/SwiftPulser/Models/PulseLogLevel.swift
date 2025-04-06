public enum PulseLogLevel: Int, Comparable {
    case none = 0
    case error = 1
    case warning = 2
    case info = 3
    case debug = 4
    case verbose = 5
    
    public static func < (lhs: PulseLogLevel, rhs: PulseLogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
} 