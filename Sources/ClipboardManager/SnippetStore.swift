import Foundation
import Combine

final class SnippetStore: ObservableObject {
    static let shared = SnippetStore()

    @Published private(set) var snippets: [Snippet] = []
    private let saveURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("ClipFlow")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        saveURL = dir.appendingPathComponent("snippets.json")
        load()
    }

    func add(_ snippet: Snippet) {
        snippets.insert(snippet, at: 0)
        save()
    }

    func remove(id: UUID) {
        snippets.removeAll { $0.id == id }
        save()
    }

    func filtered(by query: String) -> [Snippet] {
        query.isEmpty ? snippets : snippets.filter { $0.matches(query) }
    }

    private func save() {
        let snapshot = snippets
        let url = saveURL
        DispatchQueue.global(qos: .utility).async {
            if let data = try? JSONEncoder().encode(snapshot) {
                try? data.write(to: url, options: .atomic)
            }
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: saveURL),
              let loaded = try? JSONDecoder().decode([Snippet].self, from: data)
        else { return }
        snippets = loaded
    }
}
