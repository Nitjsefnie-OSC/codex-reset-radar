import RadarCore
import SwiftUI

/// Offers a newer release when there is one. Draws nothing otherwise.
struct UpdateAvailableRow: View {
    @ObservedObject var updates: UpdateChecker

    var body: some View {
        if let update = updates.available {
            HStack(spacing: 4) {
                Image(systemName: "arrow.down.circle.fill").foregroundStyle(.tint)
                Text("Version \(update.version.description) available —")
                Link("Download", destination: update.url)
            }
            .font(.callout)
        }
    }
}
