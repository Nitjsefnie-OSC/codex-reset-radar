import XCTest

@testable import RadarCore

final class FailureCounterTests: XCTestCase {
    func testStartsOnline() {
        XCTAssertFalse(FailureCounter().isOffline)
    }

    func testOneFailureIsABlip() {
        var counter = FailureCounter()
        counter.recordFailure()
        XCTAssertFalse(counter.isOffline)
    }

    func testTwoConsecutiveFailuresFlipToOffline() {
        var counter = FailureCounter()
        counter.recordFailure()
        counter.recordFailure()
        XCTAssertTrue(counter.isOffline)
        counter.recordFailure()
        XCTAssertTrue(counter.isOffline)
    }

    func testSuccessResets() {
        var counter = FailureCounter()
        counter.recordFailure()
        counter.recordFailure()
        counter.recordSuccess()
        XCTAssertFalse(counter.isOffline)
        XCTAssertEqual(counter.count, 0)
    }

    func testFailuresMustBeConsecutive() {
        var counter = FailureCounter()
        counter.recordFailure()
        counter.recordSuccess()
        counter.recordFailure()
        XCTAssertFalse(counter.isOffline)
    }
}
