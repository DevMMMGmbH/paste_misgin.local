import Foundation
import Combine

final class Settings: ObservableObject {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys
    private enum Key {
        static let maxItems       = "maxItems"
        static let saveImages     = "saveImages"
        static let ignoreDupes    = "ignoreDupes"
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

    // MARK: - Preset Options

    static let maxItemsOptions = [50, 100, 200, 500, 1000, 2000]

    private init() {
        // Register defaults
        defaults.register(defaults: [
            Key.maxItems:    500,
            Key.saveImages:  true,
            Key.ignoreDupes: true,
        ])
        maxItems    = defaults.integer(forKey: Key.maxItems)
        saveImages  = defaults.bool(forKey: Key.saveImages)
        ignoreDupes = defaults.bool(forKey: Key.ignoreDupes)
    }
}
