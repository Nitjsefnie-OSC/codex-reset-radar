import ServiceManagement
import SwiftUI

struct RadarPanel: View {
    @EnvironmentObject private var model: RadarModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Divider()
            announcement
            Divider()
            history
            Divider()
            footer
        }
        .padding(14)
        .frame(width: 320)
    }

    private var header: some View {
        HStack {
            Text("Codex Reset Radar").font(.headline)
            Spacer()
            Button {
                model.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(model.isRefreshing)
            .help("Check now")
        }
    }

    @ViewBuilder
    private var announcement: some View {
        if let reset = model.pending {
            VStack(alignment: .leading, spacing: 6) {
                Label("\(reset.typeLabel) announced", systemImage: "bell.badge.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                if let when = reset.scheduledFor {
                    Text(Format.when(when)).font(.title3.weight(.semibold))
                    Text(when > model.now
                         ? Format.relative(when, to: model.now)
                         : "Scheduled time passed, waiting for it to land")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Time not given yet").foregroundStyle(.secondary)
                }
                Text("“\(reset.text)”")
                    .italic()
                    .fixedSize(horizontal: false, vertical: true)
                if let url = reset.source.url {
                    Link("View post", destination: url).font(.callout)
                }
            }
        } else if model.status != nil {
            Label("No reset announced", systemImage: "moon.zzz")
                .foregroundStyle(.secondary)
        } else {
            Text(model.lastError == nil ? "Checking…" : "Couldn't reach codex-resets.com")
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var history: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let last = model.status?.latestReset {
                Text("Last reset \(Format.relative(last.announcedAt, to: model.now))")
            }
            if let avg = model.status?.stats.avgIntervalDays {
                Text("Every \(avg, specifier: "%.1f") days on average")
                    .foregroundStyle(.secondary)
            }
            if let checked = model.lastChecked {
                Text("Checked \(checked.formatted(date: .omitted, time: .shortened))")
                    .foregroundStyle(.secondary)
            }
            if let error = model.lastError {
                Text(error).foregroundStyle(.red)
            }
        }
        .font(.callout)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            LaunchAtLoginToggle()
            HStack {
                Link("Data from codex-resets.com", destination: URL(string: "https://codex-resets.com")!)
                    .font(.caption)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .keyboardShortcut("q")
            }
        }
    }
}

private struct LaunchAtLoginToggle: View {
    @State private var enabled = SMAppService.mainApp.status == .enabled

    var body: some View {
        Toggle("Launch at login", isOn: $enabled)
            .onChange(of: enabled) { wanted in
                do {
                    if wanted {
                        try SMAppService.mainApp.register()
                    } else {
                        try SMAppService.mainApp.unregister()
                    }
                } catch {
                    enabled = SMAppService.mainApp.status == .enabled
                }
            }
    }
}
