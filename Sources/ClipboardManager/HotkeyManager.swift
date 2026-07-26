import Carbon.HIToolbox
import Foundation

extension Notification.Name {
    static let toggleClipboardPanel = Notification.Name("toggleClipboardPanel")
}

// Global C-compatible callback for Carbon hotkey events
private func hotkeyEventHandler(
    _ nextHandler: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    NotificationCenter.default.post(name: .toggleClipboardPanel, object: nil)
    return noErr
}

final class HotkeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    /// Registriert den Hotkey aus den Settings (Standard: ⌃⌘V).
    func register() {
        let keyCode  = Settings.shared.hotkeyKeyCode
        let modifiers = Settings.shared.hotkeyModifiers
        register(keyCode: keyCode, modifiers: modifiers)
    }

    /// Registriert einen beliebigen Hotkey (keyCode = kVK_*, modifiers = Carbon-Flags).
    func register(keyCode: Int, modifiers: Int) {
        // Alten Hotkey abmelden, Handler aber nur einmal installieren
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        if eventHandlerRef == nil {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            InstallEventHandler(
                GetApplicationEventTarget(),
                hotkeyEventHandler,
                1,
                &eventType,
                nil,
                &eventHandlerRef
            )
        }

        let hotKeyID = EventHotKeyID(signature: 0x434C_504D, id: 1) // 'CLPM'
        RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef   { UnregisterEventHotKey(ref); hotKeyRef = nil }
        if let ref = eventHandlerRef { RemoveEventHandler(ref); eventHandlerRef = nil }
    }
}
