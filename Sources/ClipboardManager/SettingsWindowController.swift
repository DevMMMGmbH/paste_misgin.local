import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hosting = NSHostingController(rootView: SettingsView())
        // SwiftUI soll die Fenstergröße selbst bestimmen
        hosting.sizingOptions = [.preferredContentSize]

        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        w.title = "ClipFlow – Einstellungen"
        w.contentViewController = hosting
        w.setContentSize(NSSize(width: 440, height: 440))
        w.center()
        w.isReleasedWhenClosed = false
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = w
    }
}
