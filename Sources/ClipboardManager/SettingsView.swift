import SwiftUI
import Carbon.HIToolbox

// MARK: - Haupt-SettingsView mit Tabs

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralTab()
                .tabItem { Label("Allgemein", systemImage: "gearshape") }

            AboutTab()
                .tabItem { Label("Über", systemImage: "info.circle") }
        }
        .frame(width: 440, height: 440)
        .padding(.vertical, 8)
    }
}

// MARK: - Tab: Allgemein

private struct GeneralTab: View {
    @ObservedObject private var settings = Settings.shared
    @ObservedObject private var store    = ClipboardStore.shared

    var body: some View {
        Form {
            // --- Tastenkürzel ---
            Section {
                HStack {
                    Text("Panel-Tastenkürzel")
                    Spacer()
                    ShortcutRecorderView()
                }
            } header: {
                Text("Tastenkürzel")
            }

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

// MARK: - Shortcut Recorder

private struct ShortcutRecorderView: View {
    @ObservedObject private var settings = Settings.shared
    @State private var isRecording = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 8) {
            // Aktuelle Kombination anzeigen
            Text(isRecording ? "Drücke Tastenkombination…" : Shortcut.display(settings.hotkeyKeyCode, settings.hotkeyModifiers))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(isRecording ? .secondary : .primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isRecording ? Color.accentColor.opacity(0.1) : Color.primary.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isRecording ? Color.accentColor.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                )
                .frame(minWidth: 90)

            if isRecording {
                Button("Abbrechen") { stopRecording() }
                    .controlSize(.small)
            } else {
                Button("Ändern") { startRecording() }
                    .controlSize(.small)

                Button {
                    settings.hotkeyKeyCode   = Settings.defaultKeyCode
                    settings.hotkeyModifiers = Settings.defaultModifiers
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Auf Standard zurücksetzen (⌃⌘V)")
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])

            // Esc bricht ab
            if event.keyCode == 53 {
                self.stopRecording()
                return nil
            }

            // Mindestens ein Modifier erforderlich
            guard !flags.isEmpty else { return event }

            self.settings.hotkeyKeyCode   = Int(event.keyCode)
            self.settings.hotkeyModifiers = Shortcut.carbonModifiers(from: flags)
            self.stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let m = monitor { NSEvent.removeMonitor(m); monitor = nil }
    }
}

// MARK: - Shortcut-Hilfsfunktionen

enum Shortcut {
    /// Carbon-Modifier-Flags aus NSEvent.ModifierFlags erzeugen
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var c = 0
        if flags.contains(.command) { c |= Int(cmdKey) }
        if flags.contains(.control) { c |= Int(controlKey) }
        if flags.contains(.option)  { c |= Int(optionKey) }
        if flags.contains(.shift)   { c |= Int(shiftKey) }
        return c
    }

    /// Lesbare Anzeige: z.B. "⌃⌘V"
    static func display(_ keyCode: Int, _ carbonMods: Int) -> String {
        modifierSymbols(carbonMods) + keySymbol(keyCode)
    }

    private static func modifierSymbols(_ mods: Int) -> String {
        var s = ""
        if mods & Int(controlKey) != 0 { s += "⌃" }
        if mods & Int(optionKey)  != 0 { s += "⌥" }
        if mods & Int(shiftKey)   != 0 { s += "⇧" }
        if mods & Int(cmdKey)     != 0 { s += "⌘" }
        return s
    }

    private static func keySymbol(_ keyCode: Int) -> String {
        let map: [Int: String] = [
            0x00: "A",  0x01: "S",  0x02: "D",  0x03: "F",
            0x04: "H",  0x05: "G",  0x06: "Z",  0x07: "X",
            0x08: "C",  0x09: "V",  0x0B: "B",  0x0C: "Q",
            0x0D: "W",  0x0E: "E",  0x0F: "R",  0x10: "Y",
            0x11: "T",  0x12: "1",  0x13: "2",  0x14: "3",
            0x15: "4",  0x16: "6",  0x17: "5",  0x18: "=",
            0x19: "9",  0x1A: "7",  0x1B: "-",  0x1C: "8",
            0x1D: "0",  0x1F: "O",  0x20: "U",  0x22: "I",
            0x23: "P",  0x25: "L",  0x26: "J",  0x28: "K",
            0x2D: "N",  0x2E: "M",
            0x24: "↩",  0x30: "⇥",  0x31: "Space", 0x33: "⌫",
            0x35: "⎋",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
            0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12",
            0x7B: "←",  0x7C: "→",  0x7D: "↓",  0x7E: "↑",
        ]
        return map[keyCode] ?? "?"
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
