import AppKit
import RadarCore
import UserNotifications

/// Keeps the notified pairs in `UserDefaults`.
private struct UserDefaultsNotifiedStore: NotifiedStore {
    private let defaults = UserDefaults.standard
    private let key = "notifiedAnnouncements"

    func load() -> [String: Double] {
        defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
    }

    func save(_ notified: [String: Double]) {
        defaults.set(notified, forKey: key)
    }
}

/// Sends one notification per announced reset time, and opens the source post on click.
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let tracker = AnnouncementTracker(store: UserDefaultsNotifiedStore())

    override init() {
        super.init()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func announceIfNew(_ reset: ScheduledReset?) {
        guard let announcement = tracker.announcementIfNew(reset) else { return }
        let reset = announcement.reset
        let when = announcement.scheduledFor

        let content = UNMutableNotificationContent()
        content.title = announcement.kind == .announced
            ? "Codex \(reset.typeLabel.lowercased()) announced"
            : "Codex \(reset.typeLabel.lowercased()) rescheduled"
        content.subtitle = "\(Format.when(when)) · \(Format.relative(when))"
        content.body = reset.text
        content.sound = .default
        if let url = reset.source.url {
            content.userInfo = ["url": url.absoluteString]
        }
        let stamp = Int(when.timeIntervalSince1970)
        center.add(UNNotificationRequest(identifier: "reset-\(reset.id)-\(stamp)", content: content, trigger: nil))
    }

    // The center calls its delegate on a background queue, so these hop to the main actor where needed.

    // Menu bar apps count as frontmost while the panel is open; show the banner anyway.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let string = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: string) {
            Task { @MainActor in NSWorkspace.shared.open(url) }
        }
        completionHandler()
    }
}
