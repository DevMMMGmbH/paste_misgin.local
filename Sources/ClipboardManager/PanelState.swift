import Foundation

final class PanelState: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedIDs: Set<UUID> = []
    @Published var highlightedIndex: Int = 0
}
