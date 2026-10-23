import Foundation

/// Re-syncs the last pending reset immediately when notification preferences change.
public final class ReminderScheduler {
    private var lastScheduledReset: ScheduledReset?
    private let schedule: (ScheduledReset?, Reminder?) -> Void

    public init(schedule: @escaping (ScheduledReset?, Reminder?) -> Void) {
        self.schedule = schedule
    }

    public func process(_ reset: ScheduledReset?, preferences: NotificationPreferences, now: Date = Date()) {
        lastScheduledReset = reset
        update(preferences, now: now)
    }

    public func update(_ preferences: NotificationPreferences, now: Date = Date()) {
        schedule(lastScheduledReset, preferences.plannedReminder(for: lastScheduledReset, now: now))
    }
}
