import SwiftUI
import AppKit

struct PanelView: View {
    @ObservedObject var state: PanelState
    var onPaste: ([ClipboardItem]) -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if state.filteredItems.isEmpty {
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
                    ForEach(Array(state.filteredItems.enumerated()), id: \.element.id) { index, item in
                        ItemRow(
                            item: item,
                            isHighlighted: index == state.highlightedIndex,
                            isSelected: state.selectedIDs.contains(item.id)
                        )
                        .id(item.id)
                        .contentShape(Rectangle())
                        .onTapGesture { handleTap(item: item) }

                        if index < state.filteredItems.count - 1 {
                            Divider().padding(.leading, 40)
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
            .onChange(of: state.highlightedIndex) { _, newIndex in
                if let item = state.filteredItems[safe: newIndex] {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(item.id, anchor: .center)
                    }
                }
            }
        }
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
                onPaste(state.selectedItems())
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Tap Handling

    private func handleTap(item: ClipboardItem) {
        if NSEvent.modifierFlags.contains(.command) {
            if state.selectedIDs.contains(item.id) { state.selectedIDs.remove(item.id) }
            else                                   { state.selectedIDs.insert(item.id) }
        } else {
            onPaste([item])
        }
    }
}

// MARK: - Item Row

struct ItemRow: View {
    let item: ClipboardItem
    let isHighlighted: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Thumbnail or text icon
            if item.isImage, let data = item.imageData, let nsImg = NSImage(data: data) {
                Image(nsImage: nsImg)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 36)
                    .cornerRadius(4)
                    .clipped()
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 16, alignment: .center)
            }

            Text(item.preview)
                .font(.system(size: 13))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

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
        .background(isHighlighted ? Color.accentColor.opacity(0.15) : Color.clear)
        .overlay(
            isSelected
                ? Rectangle().stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                : nil
        )
    }
}

// MARK: - Safe Array Subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
