import XCTest

@testable import RadarCore

final class FormatTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func countdown(after seconds: TimeInterval) -> String {
        Format.countdown(to: now.addingTimeInterval(seconds), from: now)
    }

    func testPastAndNowAreDue() {
        XCTAssertEqual(countdown(after: -3600), "due")
        XCTAssertEqual(countdown(after: -1), "due")
        XCTAssertEqual(countdown(after: 0), "due")
    }

    func testUnderAMinuteRoundsUpToOneMinute() {
        XCTAssertEqual(countdown(after: 1), "1m")
        XCTAssertEqual(countdown(after: 59), "1m")
        XCTAssertEqual(countdown(after: 60), "1m")
        XCTAssertEqual(countdown(after: 119), "1m")
        XCTAssertEqual(countdown(after: 120), "2m")
    }

    func testMinutesUpToTheHour() {
        XCTAssertEqual(countdown(after: 45 * 60), "45m")
        XCTAssertEqual(countdown(after: 59 * 60 + 59), "59m")
    }

    func testHoursAndMinutesUnderTwoHours() {
        XCTAssertEqual(countdown(after: 60 * 60), "1h 0m")
        XCTAssertEqual(countdown(after: 60 * 60 + 59), "1h 0m")
        XCTAssertEqual(countdown(after: 61 * 60), "1h 1m")
        XCTAssertEqual(countdown(after: 90 * 60), "1h 30m")
        XCTAssertEqual(countdown(after: 2 * 3600 - 1), "1h 59m")
    }

    func testHoursUpToFortyEight() {
        XCTAssertEqual(countdown(after: 2 * 3600), "2h")
        XCTAssertEqual(countdown(after: 9 * 3600 + 30 * 60), "9h")
        XCTAssertEqual(countdown(after: 48 * 3600 - 1), "47h")
        XCTAssertEqual(countdown(after: 48 * 3600), "2d")
    }

    func testSpokenCountdown() {
        func spoken(_ seconds: TimeInterval) -> String {
            Format.spokenCountdown(to: now.addingTimeInterval(seconds), from: now)
        }
        XCTAssertEqual(spoken(0), "due")
        XCTAssertEqual(spoken(45 * 60), "45 minutes")
        XCTAssertEqual(spoken(60), "1 minute")
        XCTAssertEqual(spoken(3600), "1 hour")
        XCTAssertEqual(spoken(3600 + 59 * 60), "1 hour 59 minutes")
        XCTAssertEqual(spoken(9 * 3600), "9 hours")
        XCTAssertEqual(spoken(72 * 3600), "3 days")
    }

    func testDaysFromFortyEightHours() {
        XCTAssertEqual(countdown(after: 72 * 3600 - 1), "2d")
        XCTAssertEqual(countdown(after: 72 * 3600), "3d")
        XCTAssertEqual(countdown(after: 10 * 24 * 3600), "10d")
    }
}
