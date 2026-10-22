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
        // Text interpolation drops an NSImage-backed glyph in the menu bar, so the countdown sits beside it.
        HStack(spacing: 4) {
            Self.radarImage
            if let when = model.pending?.scheduledFor {
                Text(Format.countdown(to: when, from: model.now))
            }
        }
    }

    // The template glyph only exists inside the built .app; `swift run` falls back to the SF Symbol.
    private static let radarImage: Image = {
        guard let image = Bundle.main.image(forResource: "RadarMenuBarTemplate") else {
            return Image(systemName: "dot.radiowaves.left.and.right")
        }
        image.isTemplate = true
        return Image(nsImage: image)
    }()
}
