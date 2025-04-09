# SwiftPulser

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS-lightgrey.svg)](https://developer.apple.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

SwiftPulser is a powerful and flexible metrics tracking library for Swift applications. It provides a simple yet comprehensive way to track various types of events, performance metrics, and user actions in your iOS, macOS, tvOS, and watchOS applications.

## Features

- 📊 Track various types of metrics (events, performance, errors, screen views)
- 🔄 Automatic batching and retry mechanism
- 💾 Persistent storage with size limits
- 🔐 OAuth token-based authentication
- 📱 Device information collection
- 🚀 High performance with background processing
- 📝 Comprehensive logging system
- 🔄 Automatic token refresh
- 🛠️ Configurable batch size and intervals

## Requirements

- iOS 13.0+ / macOS 10.15+ / tvOS 13.0+ / watchOS 6.0+
- Swift 5.0+
- Xcode 12.0+

## Installation

### Swift Package Manager

Add SwiftPulser to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/stremovskyy/SwiftPulser.git", from: "1.0.0")
]
```

Or add it directly in Xcode:
1. File > Add Packages...
2. Enter the repository URL: `https://github.com/stremovskyy/SwiftPulser.git`
3. Select the version you want to use

## Usage

### Basic Setup

```swift
import SwiftPulser

// Configure the metrics manager
let config = PulseMetricsConfig(
    baseURL: URL(string: "https://your-api-endpoint.com")!,
    oauthTokenURL: URL(string: "https://your-oauth-endpoint.com")!,
    authToken: "your-auth-token"
)

PulseMetricsManager.shared.configure(with: config)
```

### Tracking Events

```swift
// Track a screen view
PulseMetricsManager.shared.trackScreenView(
    screenName: "HomeScreen",
    screenClass: "HomeViewController"
)

// Track a user action
PulseMetricsManager.shared.trackUserAction(
    action: "button_tap",
    category: "navigation",
    label: "settings_button"
)

// Track performance
PulseMetricsManager.shared.trackPerformance(
    name: "api_request",
    category: "network",
    value: 150.0
)

// Track errors
PulseMetricsManager.shared.trackError(
    error,
    domain: "network",
    context: "api_request"
)
```

### Performance Tracking with Timer

```swift
let tracker = PerformanceTracker(
    name: "complex_operation",
    category: "processing"
)

// Your code here...

tracker.stop()
```

## Configuration Options

```swift
let config = PulseMetricsConfig(
    baseURL: URL(string: "https://your-api-endpoint.com")!,
    oauthTokenURL: URL(string: "https://your-oauth-endpoint.com")!,
    authToken: "your-auth-token",
    batchSize: 100,                    // Number of metrics to batch
    batchInterval: 60.0,               // Time interval between batch sends
    timeout: 30.0,                     // Request timeout
    maxRetries: 3,                     // Maximum number of retries
    baseRetryDelay: 2.0,               // Base delay for retries
    persistMetrics: true,              // Enable persistence
    maxStorageSize: 10 * 1024 * 1024,  // Maximum storage size (10MB)
    defaultServiceCode: "app",         // Default service code
    includeDeviceInfo: true            // Include device information
)
```

## Advanced Usage

### Custom Logging Level

```swift
PulseMetricsManager.shared.setLogLevel(.debug)
```

### Disable/Enable Metrics Collection

```swift
PulseMetricsManager.shared.setEnabled(false) // Disable
PulseMetricsManager.shared.setEnabled(true)  // Enable
```

### Manual Flush

```swift
PulseMetricsManager.shared.flush {
    print("Metrics flushed successfully")
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

SwiftPulser is available under the MIT license. See the LICENSE file for more info. 