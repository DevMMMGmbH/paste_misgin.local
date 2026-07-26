import Foundation
import Combine

final class ClipboardStore: ObservableObject {
    static let shared = ClipboardStore()

    @Published private(set) var items: [ClipboardItem] = []
    private let saveURL: URL

    private var maxItems: Int { Settings.shared.maxItems }

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let oldDir = appSupport.appendingPathComponent("ClipboardManager")
        let dir = appSupport.appendingPathComponent("ClipFlow")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        // Migrate history from old name if present
        let oldSave = oldDir.appendingPathComponent("history.json")
        let newSave = dir.appendingPathComponent("history.json")
        if FileManager.default.fileExists(atPath: oldSave.path),
           !FileManager.default.fileExists(atPath: newSave.path) {
            try? FileManager.default.copyItem(at: oldSave, to: newSave)
        }
        saveURL = newSave
        load()
    }

    func add(_ item: ClipboardItem) {
        if Settings.shared.ignoreDupes,
           let first = items.first,
           first.text == item.text,
           item.text != nil { return }

        items.insert(item, at: 0)
        trim()
        save()
    }

    func moveToTop(id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }), idx != 0 else { return }
        let item = items.remove(at: idx)
        items.insert(item, at: 0)
        save()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func clear() {
        items.removeAll { !$0.isPinned }
        save()
    }

    /// Called when the user changes the limit in Settings.
    func applyLimit(_ limit: Int) {
        guard items.count > limit else { return }
        items = Array(items.prefix(limit))
        save()
    }

    // MARK: - Private

    private func trim() {
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
    }

    private func save() {
        let snapshot = items
        let url = saveURL
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let loaded = try? JSONDecoder().decode([ClipboardItem].self, from: data)
        else { return }
        items = loaded
        trim() // apply current limit in case it changed since last run
    }
}
