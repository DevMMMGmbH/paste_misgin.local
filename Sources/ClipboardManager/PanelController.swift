import AppKit
import SwiftUI

final class PanelController {
    private var panel: ClipboardPanel?
    private let state = PanelState()
    private var previousApp: NSRunningApplication?

    func toggle() {
        if panel?.isVisible == true {
            close()
        } else {
            open()
        }
    }

    func open() {
        previousApp = NSWorkspace.shared.frontmostApplication

        state.searchText = ""
        state.selectedIDs = []
        state.highlightedIndex = 0

        if panel == nil { buildPanel() }

        centerOnScreen()
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        panel?.orderOut(nil)
    }

    // MARK: - Private

    private func buildPanel() {
        let rootView = PanelView(
            state: state,
            onPaste: { [weak self] items in self?.paste(items: items) },
            onClose: { [weak self] in self?.close() }
        )

        let hosting = NSHostingController(rootView: rootView)

        let p = ClipboardPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.onEscape = { [weak self] in self?.close() }
        p.backgroundColor = .clear
        p.isOpaque = false
        p.hasShadow = true
        p.level = .floating
        p.isMovableByWindowBackground = true
        p.isReleasedWhenClosed = false
        p.contentViewController = hosting

        self.panel = p
    }

    private func centerOnScreen() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let pw: CGFloat = 520
        let ph: CGFloat = 480
        let sx = screen.visibleFrame
        let x = sx.minX + (sx.width - pw) / 2
        let y = sx.minY + (sx.height - ph) / 2 + 60 // slightly above center
        panel?.setFrame(NSRect(x: x, y: y, width: pw, height: ph), display: false)
    }

    private func paste(items: [ClipboardItem]) {
        let pb = NSPasteboard.general
        pb.clearContents()

        let texts = items.compactMap(\.text)
        if !texts.isEmpty {
            ClipboardMonitor.shared.ignoreNext()
            pb.setString(texts.joined(separator: "\n"), forType: .string)
        } else if let imgData = items.first?.imageData {
            ClipboardMonitor.shared.ignoreNext()
            pb.setData(imgData, forType: .tiff)
        }

        close()

        // Restore previous app, then send ⌘V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.previousApp?.activate()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                Self.simulateCmdV()
            }
        }
    }

    private static func simulateCmdV() {
        let src = CGEventSource(stateID: .hidSystemState)
        let vKey = CGKeyCode(0x09)
        let dn = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false)
        dn?.flags = .maskCommand
        up?.flags = .maskCommand
        dn?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }
}

// MARK: - Custom NSPanel

final class ClipboardPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}
