import Foundation

/// Persistence for the `id -> scheduled_for` (epoch seconds) pairs already notified.
public protocol NotifiedStore {
    func load() -> [String: Double]
    func save(_ notified: [String: Double])
}

/// A notification that should be sent.
public struct Announcement {
    public enum Kind {
        case announced
        case rescheduled
    }

    public let kind: Kind
    public let reset: ScheduledReset
    public let scheduledFor: Date
}

/// Decides which pending resets deserve a notification, one per announced reset time.
public struct AnnouncementTracker {
    private let store: NotifiedStore
    private let maxRemembered: Int

    public init(store: NotifiedStore, maxRemembered: Int = 50) {
        self.store = store
        self.maxRemembered = maxRemembered
    }

    /// Returns the announcement to send, if any, and remembers it so it is sent only once.
    public func announcementIfNew(_ reset: ScheduledReset?, now: Date = Date()) -> Announcement? {
        guard let reset, let when = reset.scheduledFor, when > now else { return nil }

        var notified = store.load()
        let stamp = when.timeIntervalSince1970
        let previous = notified[reset.id]
        guard previous != stamp else { return nil }

        notified[reset.id] = stamp
        if notified.count > maxRemembered {
            let oldest = notified.sorted { $0.value < $1.value }.prefix(notified.count - maxRemembered)
            for entry in oldest {
                notified.removeValue(forKey: entry.key)
            }
        }
        store.save(notified)

        return Announcement(kind: previous == nil ? .announced : .rescheduled, reset: reset, scheduledFor: when)
    }
}
