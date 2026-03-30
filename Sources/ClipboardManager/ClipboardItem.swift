import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let text: String?
    let imageData: Data?
    let timestamp: Date
    var isPinned: Bool

    init(text: String?, imageData: Data?, timestamp: Date = Date(), isPinned: Bool = false) {
        self.id = UUID()
        self.text = text
        self.imageData = imageData
        self.timestamp = timestamp
        self.isPinned = isPinned
    }

    var preview: String {
        if let text {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return String(trimmed.prefix(400))
        }
        if imageData != nil { return "[Bild]" }
        return "[Unbekannt]"
    }

    var isImage: Bool { imageData != nil }
    var isText: Bool { text != nil }

    var timeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}
