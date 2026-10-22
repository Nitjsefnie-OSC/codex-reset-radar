import AppKit
import Foundation

@MainActor
final class RadarModel: ObservableObject {
    @Published private(set) var status: StatusData?
    @Published private(set) var lastChecked: Date?
    @Published private(set) var lastError: String?
    @Published private(set) var isRefreshing = false
    /// Ticks every minute so countdowns stay current between polls.
    @Published private(set) var now = Date()

    private static let pollInterval: TimeInterval = 15 * 60

    private let client = StatusClient()
    private let notifier = Notifier()
    private var timers: [Timer] = []
    private var wakeObserver: NSObjectProtocol?

    init() {
        refresh()

        let poll = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        poll.tolerance = 60
        let tick = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
        tick.tolerance = 5
        timers = [poll, tick]

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    var pending: ScheduledReset? { status?.scheduledReset }

    func refresh() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            defer { isRefreshing = false }
            do {
                let status = try await client.fetch()
                self.status = status
                lastError = nil
                notifier.announceIfNew(status.scheduledReset)
            } catch {
                lastError = error.localizedDescription
            }
            lastChecked = Date()
            now = Date()
        }
    }
}

enum Format {
    static func when(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).hour().minute())
    }

    static func relative(_ date: Date, to now: Date = Date()) -> String {
        RelativeDateTimeFormatter().localizedString(for: date, relativeTo: now)
    }

    /// Compact countdown for the menu bar: 45m, 9h, 3d, or "due".
    static func countdown(to date: Date, from now: Date) -> String {
        let seconds = date.timeIntervalSince(now)
        guard seconds > 0 else { return "due" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(max(minutes, 1))m" }
        let hours = minutes / 60
        if hours < 48 { return "\(hours)h" }
        return "\(hours / 24)d"
    }
}
