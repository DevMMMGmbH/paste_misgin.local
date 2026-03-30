import AppKit

final class StatusBarController {
    private var statusItem: NSStatusItem?
    var onToggle: (() -> Void)?
    var onClear: (() -> Void)?
    var onSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard Manager")
            button.image?.isTemplate = true
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func handleClick() {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showMenu()
        } else {
            onToggle?()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Panel öffnen  ⇧⌘V",
            action: #selector(openPanel),
            keyEquivalent: ""
        ).target = self

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Einstellungen…",
            action: #selector(openSettings),
            keyEquivalent: ","
        ).target = self

        menu.addItem(
            withTitle: "History löschen",
            action: #selector(clearHistory),
            keyEquivalent: ""
        ).target = self

        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Beenden",
            action: #selector(quit),
            keyEquivalent: ""
        ).target = self

        if let button = statusItem?.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 5), in: button)
        }
    }

    @objc private func openPanel() { onToggle?() }
    @objc private func openSettings() { onSettings?() }
    @objc private func clearHistory() { onClear?() }
    @objc private func quit() { onQuit?() }
}
