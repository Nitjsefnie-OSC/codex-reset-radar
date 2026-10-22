import AppKit
import UserNotifications

/// Sends one notification per announced reset time, and opens the source post on click.
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard
    private let notifiedKey = "notifiedAnnouncements"
    private let maxRemembered = 50

    override init() {
        super.init()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func announceIfNew(_ reset: ScheduledReset?) {
        guard let reset, let when = reset.scheduledFor, when > Date() else { return }

        // id -> scheduled_for (epoch seconds) of what we already notified.
        var notified = defaults.dictionary(forKey: notifiedKey) as? [String: Double] ?? [:]
        let stamp = when.timeIntervalSince1970
        let previous = notified[reset.id]
        guard previous != stamp else { return }

        notified[reset.id] = stamp
        if notified.count > maxRemembered {
            let oldest = notified.sorted { $0.value < $1.value }.prefix(notified.count - maxRemembered)
            oldest.forEach { notified.removeValue(forKey: $0.key) }
        }
        defaults.set(notified, forKey: notifiedKey)

        let content = UNMutableNotificationContent()
        content.title = previous == nil
            ? "Codex \(reset.typeLabel.lowercased()) announced"
            : "Codex \(reset.typeLabel.lowercased()) rescheduled"
        content.subtitle = "\(Format.when(when)) · \(Format.relative(when))"
        content.body = reset.text
        content.sound = .default
        if let url = reset.source.url {
            content.userInfo = ["url": url.absoluteString]
        }
        center.add(UNNotificationRequest(identifier: "reset-\(reset.id)-\(Int(stamp))", content: content, trigger: nil))
    }

    // Menu bar apps count as frontmost while the panel is open; show the banner anyway.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let string = response.notification.request.content.userInfo["url"] as? String,
           let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
        completionHandler()
    }
}
