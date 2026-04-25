import Foundation
import Combine
import Carbon.HIToolbox

final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Key {
        static let maxItems        = "maxItems"
        static let saveImages      = "saveImages"
        static let ignoreDupes     = "ignoreDupes"
        static let hotkeyKeyCode   = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
    }

    // MARK: - Published Properties

    @Published var maxItems: Int {
        didSet {
            defaults.set(maxItems, forKey: Key.maxItems)
            ClipboardStore.shared.applyLimit(maxItems)
        }
    }

    @Published var saveImages: Bool {
        didSet { defaults.set(saveImages, forKey: Key.saveImages) }
    }

    @Published var ignoreDupes: Bool {
        didSet { defaults.set(ignoreDupes, forKey: Key.ignoreDupes) }
    }

    /// Virtueller Key-Code (kVK_*), z.B. 0x09 für V
    @Published var hotkeyKeyCode: Int {
        didSet { defaults.set(hotkeyKeyCode, forKey: Key.hotkeyKeyCode) }
    }

    /// Carbon-Modifier-Flags (cmdKey | controlKey | …)
    @Published var hotkeyModifiers: Int {
        didSet { defaults.set(hotkeyModifiers, forKey: Key.hotkeyModifiers) }
    }

    // MARK: - Preset Options

    static let maxItemsOptions = [50, 100, 200, 500, 1000, 2000]

    // MARK: - Defaults

    /// Standard: ⌃⌘V
    static let defaultKeyCode:   Int = 0x09
    static let defaultModifiers: Int = Int(controlKey) | Int(cmdKey)

    private init() {
        defaults.register(defaults: [
            Key.maxItems:        500,
            Key.saveImages:      true,
            Key.ignoreDupes:     true,
            Key.hotkeyKeyCode:   Settings.defaultKeyCode,
            Key.hotkeyModifiers: Settings.defaultModifiers,
        ])
        maxItems        = defaults.integer(forKey: Key.maxItems)
        saveImages      = defaults.bool(forKey: Key.saveImages)
        ignoreDupes     = defaults.bool(forKey: Key.ignoreDupes)
        hotkeyKeyCode   = defaults.integer(forKey: Key.hotkeyKeyCode)
        hotkeyModifiers = defaults.integer(forKey: Key.hotkeyModifiers)
    }
}
