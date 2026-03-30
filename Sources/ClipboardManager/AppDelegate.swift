import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ClipboardMonitor.shared
    private let store = ClipboardStore.shared
    private let hotkey = HotkeyManager()
    private let panel = PanelController()
    private let statusBar = StatusBarController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermissions()

        statusBar.setup()
        statusBar.onToggle = { [weak self] in self?.panel.toggle() }
        statusBar.onClear  = { ClipboardStore.shared.clear() }
        statusBar.onQuit   = { NSApp.terminate(nil) }

        hotkey.register()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggle),
            name: .toggleClipboardPanel,
            object: nil
        )

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
        hotkey.unregister()
    }

    @objc private func handleToggle() {
        panel.toggle()
    }

    private func checkAccessibilityPermissions() {
        let options: [String: Any] = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !trusted {
            print("⚠️  Bitte Zugriffsrechte in Systemeinstellungen → Datenschutz → Bedienungshilfen gewähren.")
        }
    }
}
