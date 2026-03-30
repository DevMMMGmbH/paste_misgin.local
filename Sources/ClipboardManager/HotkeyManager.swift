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

    /// Registers ⇧⌘V as the global panel toggle.
    func register() {
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

        let hotKeyID = EventHotKeyID(signature: 0x434C_504D, id: 1) // 'CLPM'
        RegisterEventHotKey(
            UInt32(kVK_ANSI_V),           // V
            UInt32(shiftKey | cmdKey),     // ⇧⌘
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func unregister() {
        if let ref = hotKeyRef { UnregisterEventHotKey(ref) }
        if let ref = eventHandlerRef { RemoveEventHandler(ref) }
    }
}
