import Foundation
import RadarCore

/// Checks GitHub for a newer release on launch and then once a day. Failures are silent:
/// telling people about updates isn't the app's main job.
@MainActor
final class UpdateChecker: ObservableObject {
    @Published private(set) var available: AvailableUpdate?

    private static let checkInterval: TimeInterval = 24 * 60 * 60

    private let client = ReleaseClient()
    private var timer: Timer?

    init() {
        check()
        let timer = Timer.scheduledTimer(withTimeInterval: Self.checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.check() }
        }
        timer.tolerance = 60 * 60
        self.timer = timer
    }

    private func check() {
        Task {
            guard let latest = try? await client.fetchLatest() else { return }
            available = UpdateCheck.available(latest: latest, currentVersion: Bundle.main.shortVersion)
        }
    }
}
