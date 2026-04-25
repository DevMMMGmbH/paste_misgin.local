import SwiftUI

// MARK: - Haupt-SettingsView mit Tabs

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("Allgemein", systemImage: "gearshape") }

            AboutTab()
                .tabItem { Label("Über", systemImage: "info.circle") }
        }
        .frame(width: 440, height: 400)
        .padding(.vertical, 8)
    }
}

// MARK: - Tab: Allgemein

private struct GeneralTab: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store    = ClipboardStore.shared

    var body: some View {
        Form {
            // --- History ---
            Section {
                Picker("Einträge behalten", selection: $settings.maxItems) {
                    ForEach(Settings.maxItemsOptions, id: \.self) { n in
                        Text("\(n) Einträge").tag(n)
                    }
                }
                .pickerStyle(.menu)

                HStack {
                    Text("Aktuell gespeichert")
                    Spacer()
                    Text("\(store.items.count) Einträge")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("History")
            }

            // --- Verhalten ---
            Section {
                Toggle("Bilder speichern", isOn: $settings.saveImages)
                Toggle("Aufeinanderfolgende Duplikate ignorieren", isOn: $settings.ignoreDupes)
            } header: {
                Text("Verhalten")
            }

            // --- Daten ---
            Section {
                HStack {
                    Text("Gespeichert in")
                    Spacer()
                    Text("~/Library/Application Support/ClipFlow/")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }

                Button("History jetzt löschen…", role: .destructive) {
                    confirmClear()
                }
            } header: {
                Text("Daten")
            }
        }
        .formStyle(.grouped)
    }

    private func confirmClear() {
        let alert = NSAlert()
        alert.messageText = "History löschen?"
        alert.informativeText = "Alle \(store.items.count) Einträge werden unwiderruflich gelöscht."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Löschen")
        alert.addButton(withTitle: "Abbrechen")
        if alert.runModal() == .alertFirstButtonReturn {
            ClipboardStore.shared.clear()
        }
    }
}

// MARK: - Tab: Über

private struct AboutTab: View {
    var body: some View {
        VStack(spacing: 0) {
            // Icon + App-Name
            VStack(spacing: 10) {
                if let icnsURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
                   let image = NSImage(contentsOf: icnsURL) {
                    Image(nsImage: image)
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                } else {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Color.accentColor)
                }

                Text("ClipFlow")
                    .font(.system(size: 22, weight: .bold))

                Text("Version 1.1")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            Divider()

            // Author-Info
            VStack(spacing: 14) {
                infoRow(icon: "person.fill", label: "Entwickler", value: "Alexander Misgin")
                infoRow(icon: "envelope.fill", label: "E-Mail", value: "alex@misgin.com", isLink: true)
                infoRow(icon: "c.circle", label: "Copyright", value: "© 2026 Alexander Misgin")
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 40)

            Divider()

            // Systeminfo
            HStack(spacing: 16) {
                Text("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("Alle Rechte vorbehalten")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(
        icon: String,
        label: String,
        value: String,
        isLink: Bool = false
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)

            if isLink {
                Button(value) {
                    if let url = URL(string: "mailto:\(value)") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .font(.body)
            } else {
                Text(value)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
    }
}
