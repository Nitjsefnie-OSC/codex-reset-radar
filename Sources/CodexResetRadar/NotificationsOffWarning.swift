import SwiftUI

/// Tells the user that notifications are off, with a way to fix it. Draws nothing otherwise.
struct NotificationsOffWarning: View {
    @ObservedObject var access: NotificationAccessMonitor

    var body: some View {
        if access.isOff {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Notifications are off", systemImage: "bell.slash.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                    Text("You won't hear when a reset is announced or lands.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Open Notification Settings") { access.openSettings() }
                }
                Divider()
            }
        }
    }
}
