import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor.shared
    private let store = ClipboardStore.shared
    private let settings = Settings.shared
    private let hotkey = HotkeyManager()
    private let panel = PanelController()
    private let statusBar = StatusBarController()
    private let settingsWindow = SettingsWindowController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBar.setup()
        statusBar.onToggle    = { [weak self] in self?.panel.toggle() }
        statusBar.onSettings  = { [weak self] in self?.settingsWindow.show() }
        statusBar.onClear     = { ClipboardStore.shared.clear() }
        statusBar.onQuit      = { NSApp.terminate(nil) }

        hotkey.register()

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
        // Zeigt den System-Dialog der direkt in Bedienungshilfen führt.
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}
