import XCTest

@testable import RadarCore

final class VoiceOverLabelTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func reset(in seconds: TimeInterval?) -> ScheduledReset {
        ScheduledReset(
            id: "a",
            resetType: "regular",
            announcedAt: now,
            scheduledFor: seconds.map { now.addingTimeInterval($0) },
            text: "Soon.",
            source: Source(url: nil)
        )
    }

    private func label(pending: ScheduledReset? = nil, loaded: Bool = true, offline: Bool = false) -> String {
        VoiceOverLabel.menuBar(loaded: loaded, pending: pending, isOffline: offline, now: now)
    }

    func testNoResetAnnounced() {
        XCTAssertEqual(label(), "Codex Reset Radar, no reset announced")
    }

    func testBeforeTheFirstStatus() {
        XCTAssertEqual(label(loaded: false), "Codex Reset Radar, checking for resets")
    }

    func testCountdownIsSpokenOut() {
        XCTAssertEqual(label(pending: reset(in: 9 * 3600 + 600)), "Codex Reset Radar, reset in 9 hours")
        XCTAssertEqual(label(pending: reset(in: 45 * 60)), "Codex Reset Radar, reset in 45 minutes")
        XCTAssertEqual(label(pending: reset(in: 3600 + 59 * 60)), "Codex Reset Radar, reset in 1 hour 59 minutes")
        XCTAssertEqual(label(pending: reset(in: 3 * 24 * 3600)), "Codex Reset Radar, reset in 3 days")
    }

    func testSingularUnits() {
        XCTAssertEqual(label(pending: reset(in: 30)), "Codex Reset Radar, reset in 1 minute")
        XCTAssertEqual(label(pending: reset(in: 3600)), "Codex Reset Radar, reset in 1 hour")
        XCTAssertEqual(label(pending: reset(in: 3600 + 60)), "Codex Reset Radar, reset in 1 hour 1 minute")
        XCTAssertEqual(label(pending: reset(in: 2 * 3600)), "Codex Reset Radar, reset in 2 hours")
        XCTAssertEqual(label(pending: reset(in: 48 * 3600)), "Codex Reset Radar, reset in 2 days")
    }

    func testDue() {
        XCTAssertEqual(label(pending: reset(in: -60)), "Codex Reset Radar, reset due")
        XCTAssertEqual(label(pending: reset(in: 0)), "Codex Reset Radar, reset due")
    }

    func testPendingWithoutADate() {
        XCTAssertEqual(
            label(pending: reset(in: nil)), "Codex Reset Radar, reset announced, time not given yet")
    }

    func testOffline() {
        XCTAssertEqual(label(offline: true), "Codex Reset Radar, offline")
        XCTAssertEqual(label(loaded: false, offline: true), "Codex Reset Radar, offline")
    }

    func testOfflineKeepsSpeakingTheCountdown() {
        XCTAssertEqual(
            label(pending: reset(in: 9 * 3600), offline: true), "Codex Reset Radar, offline, reset in 9 hours")
        XCTAssertEqual(
            label(pending: reset(in: -60), offline: true), "Codex Reset Radar, offline, reset due")
    }
}
