import XCTest

@testable import RadarCore

final class ReminderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func reset(id: String = "a", in seconds: TimeInterval?) -> ScheduledReset {
        ScheduledReset(
            id: id,
            resetType: "regular",
            announcedAt: now,
            scheduledFor: seconds.map { now.addingTimeInterval($0) },
            text: "Soon.",
            source: Source(url: nil)
        )
    }

    func testDatedPendingResetIsArmedFifteenMinutesBefore() throws {
        let reminder = try XCTUnwrap(Reminder.planned(for: reset(in: 3600), now: now))
        XCTAssertEqual(reminder.resetID, "a")
        XCTAssertEqual(reminder.scheduledFor, now.addingTimeInterval(3600))
        XCTAssertEqual(reminder.fireDate, now.addingTimeInterval(45 * 60))
    }

    func testSavedThirtyMinuteLeadSchedulesThirtyMinutesBeforeReset() throws {
        let suite = "ReminderTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(30, forKey: "reminderLeadMinutes")
        let preferences = UserDefaultsNotificationPreferencesStore(defaults: defaults).load()

        let reminder = try XCTUnwrap(preferences.plannedReminder(for: reset(in: 3600), now: now))
        XCTAssertEqual(reminder.fireDate, now.addingTimeInterval(30 * 60))
    }

    func testSixtyMinuteLeadSchedulesSixtyMinutesBeforeReset() throws {
        let preferences = NotificationPreferences(reminderLeadTime: .sixtyMinutes)
        let reminder = try XCTUnwrap(preferences.plannedReminder(for: reset(in: 7200), now: now))
        XCTAssertEqual(reminder.fireDate, now.addingTimeInterval(60 * 60))
    }

    func testSavedLeadSkipsAnnouncementsInsideOrAtItsWindow() throws {
        let suite = "ReminderTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(30, forKey: "reminderLeadMinutes")
        let preferences = UserDefaultsNotificationPreferencesStore(defaults: defaults).load()

        XCTAssertNil(preferences.plannedReminder(for: reset(in: 20 * 60), now: now))
        XCTAssertNil(preferences.plannedReminder(for: reset(in: 30 * 60), now: now))
        XCTAssertNotNil(preferences.plannedReminder(for: reset(in: 30 * 60 + 1), now: now))
    }

    func testPlanningTheSameResetAgainGivesTheSameReminder() {
        XCTAssertEqual(
            Reminder.planned(for: reset(in: 3600), now: now),
            Reminder.planned(for: reset(in: 3600), now: now.addingTimeInterval(60))
        )
    }

    func testRescheduleMovesTheReminder() throws {
        let first = try XCTUnwrap(Reminder.planned(for: reset(in: 3600), now: now))
        let second = try XCTUnwrap(Reminder.planned(for: reset(in: 7200), now: now))
        XCTAssertNotEqual(first, second)
        XCTAssertEqual(second.fireDate, now.addingTimeInterval(105 * 60))
    }

    func testSkippedWhenAnnouncedLessThanFifteenMinutesAhead() {
        XCTAssertNil(Reminder.planned(for: reset(in: 14 * 60), now: now))
        XCTAssertNil(Reminder.planned(for: reset(in: 15 * 60), now: now))
        XCTAssertNotNil(Reminder.planned(for: reset(in: 15 * 60 + 1), now: now))
    }

    func testNothingLeftToArmOnceTheReminderIsDue() {
        XCTAssertNotNil(Reminder.planned(for: reset(in: 3600), now: now))
        XCTAssertNil(Reminder.planned(for: reset(in: 3600), now: now.addingTimeInterval(45 * 60)))
    }

    func testRescheduleToLessThanFifteenMinutesCancels() {
        XCTAssertNotNil(Reminder.planned(for: reset(in: 3600), now: now))
        XCTAssertNil(Reminder.planned(for: reset(in: 600), now: now))
    }

    func testNoReminderWithoutADate() {
        XCTAssertNil(Reminder.planned(for: reset(in: nil), now: now))
    }

    func testPastDueResetHasNoReminder() {
        XCTAssertNil(Reminder.planned(for: reset(in: -60), now: now))
    }

    func testLandedOrCalledOffResetCancels() {
        // Both clear `scheduled_reset`, so no reminder is planned and the armed one is removed.
        XCTAssertNotNil(Reminder.planned(for: reset(in: 3600), now: now))
        XCTAssertNil(Reminder.planned(for: nil, now: now))
    }
}
