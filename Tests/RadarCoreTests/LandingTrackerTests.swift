import XCTest

@testable import RadarCore

private final class InMemoryLandedStore: LandedStore {
    var id: String?

    func load() -> String? { id }
    func save(_ id: String) { self.id = id }
}

final class LandingTrackerTests: XCTestCase {
    private let store = InMemoryLandedStore()

    private var tracker: LandingTracker { LandingTracker(store: store) }

    private func latest(_ id: String, type: String = "regular") -> Reset {
        Reset(id: id, resetType: type, announcedAt: Date(timeIntervalSince1970: 1_800_000_000))
    }

    func testFirstRunRecordsWithoutReporting() {
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertEqual(store.id, "a")
    }

    func testNewIdLandsOnce() throws {
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        let landed = try XCTUnwrap(tracker.landedIfNew(latest("b", type: "banked")))
        XCTAssertEqual(landed.id, "b")
        XCTAssertEqual(landed.typeLabel, "Banked reset")
        XCTAssertNil(tracker.landedIfNew(latest("b")))
        XCTAssertEqual(store.id, "b")
    }

    func testSameIdNeverLandsAgain() {
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertNil(tracker.landedIfNew(latest("a")))
    }

    func testSurpriseResetLandsWithoutAnyAnnouncement() {
        // The tracker only looks at the latest reset, so it does not matter that nothing was pending.
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertEqual(tracker.landedIfNew(latest("b"))?.id, "b")
    }

    func testCalledOffResetIsSilent() {
        // A call-off clears the pending reset while the latest reset stays the same.
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertEqual(store.id, "a")
    }

    func testMissingLatestResetChangesNothing() {
        XCTAssertNil(tracker.landedIfNew(nil))
        XCTAssertNil(store.id)
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        XCTAssertNil(tracker.landedIfNew(nil))
        XCTAssertEqual(store.id, "a")
    }

    func testPersistedIdSurvivesANewTracker() {
        XCTAssertNil(tracker.landedIfNew(latest("a")))
        // A relaunch builds a new tracker over the same stored id.
        XCTAssertNil(LandingTracker(store: store).landedIfNew(latest("a")))
        XCTAssertEqual(LandingTracker(store: store).landedIfNew(latest("b"))?.id, "b")
    }
}
