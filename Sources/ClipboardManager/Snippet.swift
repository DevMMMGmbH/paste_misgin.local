import Foundation

struct Snippet: Identifiable, Codable {
    let id: UUID
    var title: String
    var content: String
    var tags: [String]
    var project: String
    var updatedAt: Date
    let createdAt: Date

    init(title: String, content: String, tags: [String] = [], project: String = "") {
        self.id = UUID()
        self.title = title
        self.content = content
        self.tags = tags
        self.project = project
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var tagString: String { tags.joined(separator: ", ") }

    func matches(_ query: String) -> Bool {
        let q = query.lowercased()
        return title.lowercased().contains(q)
            || content.lowercased().contains(q)
            || project.lowercased().contains(q)
            || tags.contains { $0.lowercased().contains(q) }
    }
}
