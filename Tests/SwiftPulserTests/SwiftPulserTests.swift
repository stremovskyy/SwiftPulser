import XCTest
@testable import SwiftPulser

final class SwiftPulserTests: XCTestCase {
    var manager: PulseMetricsManager!
    
    override func setUp() {
        super.setUp()
        manager = PulseMetricsManager.shared
    }
    
    override func tearDown() {
        manager = nil
        super.tearDown()
    }
    
    func testConfiguration() {
        let config = PulseMetricsConfig(
            baseURL: URL(string: "https://test.com")!,
            oauthTokenURL: URL(string: "https://test.com/token")!,
            authToken: "test-token"
        )
        
        manager.configure(with: config)
        XCTAssertNotNil(manager)
    }
    
    func testTrackEvent() {
        let config = PulseMetricsConfig(
            baseURL: URL(string: "https://test.com")!,
            oauthTokenURL: URL(string: "https://test.com/token")!,
            authToken: "test-token"
        )
        
        manager.configure(with: config)
        
        manager.track(eventType: "test_event")
        XCTAssertTrue(manager.isEnabled)
    }
    
    func testPerformanceTracking() {
        let tracker = PerformanceTracker(
            name: "test_operation",
            category: "test"
        )
        
        // Simulate some work
        Thread.sleep(forTimeInterval: 0.1)
        
        tracker.stop()
        XCTAssertNotNil(tracker)
    }
    
    func testLogLevel() {
        manager.setLogLevel(.debug)
        XCTAssertEqual(manager.logLevel, .debug)
    }
    
    func testEnableDisable() {
        manager.setEnabled(false)
        XCTAssertFalse(manager.isEnabled)
        
        manager.setEnabled(true)
        XCTAssertTrue(manager.isEnabled)
    }
} 