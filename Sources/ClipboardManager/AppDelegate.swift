import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor.shared
    private let store = ClipboardStore.shared
    private let settings = Settings.shared
    private let hotkey = HotkeyManager()
    private let panel = PanelController()
    private let statusBar = StatusBarController()
    private let settingsWindow = SettingsWindowController()
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar.setup()
        statusBar.onToggle    = { [weak self] in self?.panel.toggle() }
        statusBar.onSettings  = { [weak self] in self?.settingsWindow.show() }
        statusBar.onClear     = { ClipboardStore.shared.clear() }
        statusBar.onQuit      = { NSApp.terminate(nil) }

        hotkey.register()

        // Hotkey neu registrieren wenn der Nutzer ihn in den Einstellungen ändert
        settings.$hotkeyKeyCode
            .combineLatest(settings.$hotkeyModifiers)
            .dropFirst()
            .sink { [weak self] keyCode, modifiers in
                self?.hotkey.register(keyCode: keyCode, modifiers: modifiers)
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggle),
            name: .toggleClipboardPanel,
            object: nil
        )

        monitor.start()
        requestAccessibilityIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        hotkey.unregister()
    }

    @objc private func handleToggle() {
        panel.toggle()
    }

    private func requestAccessibilityIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
