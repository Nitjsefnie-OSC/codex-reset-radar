import SwiftUI

@main
struct CodexResetRadarApp: App {
    @StateObject private var model = RadarModel()

    var body: some Scene {
        MenuBarExtra {
            RadarPanel()
                .environmentObject(model)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @ObservedObject var model: RadarModel

    var body: some View {
        if let when = model.pending?.scheduledFor {
            Text("\(Image(systemName: "dot.radiowaves.left.and.right")) \(Format.countdown(to: when, from: model.now))")
        } else {
            Image(systemName: "dot.radiowaves.left.and.right")
        }
    }
}
