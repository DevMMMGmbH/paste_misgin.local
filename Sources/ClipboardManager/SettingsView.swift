import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store    = ClipboardStore.shared

    var body: some View {
        Form {
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

            Section {
                Toggle("Bilder speichern", isOn: $settings.saveImages)
                Toggle("Aufeinanderfolgende Duplikate ignorieren", isOn: $settings.ignoreDupes)
            } header: {
                Text("Verhalten")
            }

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
        .frame(width: 400)
        .padding(.vertical, 8)
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
