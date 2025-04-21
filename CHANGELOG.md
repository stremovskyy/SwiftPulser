# Changelog

All notable changes to SwiftPulser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.3] - 2025-04-17

### Added
- Time range round rules configuration
- Support for custom time range labels (e.g., "<5s", "5-10s", "10-30s", "30+s")
- Option to use raw seconds value when no rules are provided
- Duration labels in time range and session tracking metadata

## [1.1.1] - 2025-04-16

### Changed
- Optimized session and time range tracking implementation in PulseMetricsManager
- Improved code organization and maintainability

## [1.1.0] - 2025-04-16

### Added
- Enhanced session tracking with improved metadata handling
- Time range tracking with automatic duration calculation
- Token persistence and loading functionality
- Improved error handling and logging system

### Changed
- Refactored PulseMetricsManager for better session and time range tracking
- Enhanced documentation with new tracking features
- Improved error messages and logging for better debugging
- Updated repository links and documentation

## [1.0.0] - 2025-04-06

### Added
- Initial release of SwiftPulser
- Core metrics tracking functionality
- Support for various metric types (events, performance, errors, screen views)
- Automatic batching and retry mechanism
- Persistent storage with size limits
- OAuth token-based authentication
- Device information collection
- Comprehensive logging system
- Automatic token refresh
- Configurable batch size and intervals
- Performance tracking with timer
- Support for iOS, macOS, tvOS, and watchOS 