import SwiftUI
import AppKit

struct PanelView: View {
    @ObservedObject var store = ClipboardStore.shared
    @ObservedObject var state: PanelState
    var onPaste: ([ClipboardItem]) -> Void
    var onClose: () -> Void

    @FocusState private var searchFocused: Bool

    var filtered: [ClipboardItem] {
        guard !state.searchText.isEmpty else { return store.items }
        return store.items.filter {
            $0.preview.localizedCaseInsensitiveContains(state.searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if filtered.isEmpty {
                emptyState
            } else {
                itemList
            }
            if !state.selectedIDs.isEmpty {
                Divider()
                footer
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { searchFocused = true }
        .onChange(of: state.searchText) { _, _ in
            state.highlightedIndex = 0
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
            TextField("Suchen…", text: $state.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)
            if !state.searchText.isEmpty {
                Button {
                    state.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Item List

    private var itemList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, item in
                        ItemRow(
                            item: item,
                            isHighlighted: index == state.highlightedIndex,
                            isSelected: state.selectedIDs.contains(item.id)
                        )
                        .id(item.id)
                        .contentShape(Rectangle())
                        .onTapGesture { handleTap(item: item) }

                        if index < filtered.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
            .onChange(of: state.highlightedIndex) { _, newIndex in
                if let item = filtered[safe: newIndex] {
                    withAnimation { proxy.scrollTo(item.id, anchor: .center) }
                }
            }
        }
        .onKeyPress(keys: [.upArrow, .downArrow, .return, .escape, .space]) { press in
            handleKey(press)
        }
        .focusable()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Keine Einträge")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Text("\(state.selectedIDs.count) ausgewählt")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Einfügen (\(state.selectedIDs.count))") {
                pasteSelected()
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func handleTap(item: ClipboardItem) {
        let cmdHeld = NSEvent.modifierFlags.contains(.command)
        if cmdHeld {
            if state.selectedIDs.contains(item.id) {
                state.selectedIDs.remove(item.id)
            } else {
                state.selectedIDs.insert(item.id)
            }
        } else {
            onPaste([item])
        }
    }

    private func handleKey(_ press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .upArrow:
            if state.highlightedIndex > 0 { state.highlightedIndex -= 1 }
            return .handled
        case .downArrow:
            if state.highlightedIndex < filtered.count - 1 { state.highlightedIndex += 1 }
            return .handled
        case .return:
            pasteHighlightedOrSelected()
            return .handled
        case .escape:
            onClose()
            return .handled
        case .space:
            if let item = filtered[safe: state.highlightedIndex] {
                if state.selectedIDs.contains(item.id) {
                    state.selectedIDs.remove(item.id)
                } else {
                    state.selectedIDs.insert(item.id)
                }
            }
            return .handled
        default:
            return .ignored
        }
    }

    private func pasteHighlightedOrSelected() {
        if !state.selectedIDs.isEmpty {
            pasteSelected()
        } else if let item = filtered[safe: state.highlightedIndex] {
            onPaste([item])
        }
    }

    private func pasteSelected() {
        // Preserve insertion order (order of appearance in filtered list)
        let items = filtered.filter { state.selectedIDs.contains($0.id) }
        onPaste(items)
    }
}

// MARK: - Item Row

struct ItemRow: View {
    let item: ClipboardItem
    let isHighlighted: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isImage ? "photo" : "doc.text")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.preview)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(item.timeLabel)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 13))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            isHighlighted
                ? Color.accentColor.opacity(0.15)
                : Color.clear
        )
        .overlay(
            isSelected
                ? RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                : nil
        )
    }
}

// MARK: - Helpers

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
