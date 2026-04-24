import SwiftUI
import AppKit

struct PanelView: View {
    @ObservedObject var state: PanelState
    var onPaste: ([ClipboardItem]) -> Void
    var onClose: () -> Void
    var onCollapse: ((Bool) -> Void)?

    @State private var isCollapsed: Bool = false
    @State private var showHelp: Bool = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            titleBar
            if !isCollapsed {
                if showHelp {
                    helpOverlay
                } else {
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
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear { searchFocused = true }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 0) {
            // Drag-Anfasser
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 11))
                .foregroundStyle(.quaternary)
                .padding(.leading, 14)
                .frame(width: 36)
                .help("Fenster verschieben")

            Spacer()

            Text("ClipFlow")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Spacer()

            // Hilfe-Button
            titleBarButton(
                icon: showHelp ? "questionmark.circle.fill" : "questionmark",
                help: showHelp ? "Hilfe schließen" : "Tastaturkürzel"
            ) {
                if isCollapsed {
                    isCollapsed = false
                    onCollapse?(false)
                }
                showHelp.toggle()
            }

            // Einklapp-Button
            titleBarButton(
                icon: isCollapsed ? "chevron.down" : "chevron.up",
                help: isCollapsed ? "Aufklappen" : "Einklappen"
            ) {
                let next = !isCollapsed
                isCollapsed = next
                if next { showHelp = false }
                onCollapse?(next)
            }

            // Schließen-Button
            titleBarButton(icon: "xmark", help: "Schließen") {
                onClose()
            }
            .padding(.trailing, 8)
        }
        .frame(height: 36)
    }

    @ViewBuilder
    private func titleBarButton(
        icon: String,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: 22, height: 22)
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(width: 30, height: 36)
        .contentShape(Rectangle())
        .help(help)
    }

    // MARK: - Hilfe-Overlay

    private var helpOverlay: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "keyboard")
                    .foregroundStyle(Color.accentColor)
                Text("Tastaturkürzel & Hilfe")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 14)

            Divider()

            // Shortcuts
            VStack(spacing: 0) {
                shortcutSection(header: "Panel") {
                    shortcutRow("⇧⌘V",        "Panel öffnen / schließen")
                    shortcutRow("Esc",         "Panel schließen")
                }

                Divider().padding(.horizontal, 20).padding(.vertical, 6)

                shortcutSection(header: "Navigation") {
                    shortcutRow("↑  ↓",        "Eintrag navigieren")
                    shortcutRow("↩ Return",    "Markierten Eintrag einfügen")
                    shortcutRow("Tippen",      "Einträge filtern / suchen")
                }

                Divider().padding(.horizontal, 20).padding(.vertical, 6)

                shortcutSection(header: "Mehrfachauswahl") {
                    shortcutRow("Leertaste",   "Eintrag markieren / entmarkieren")
                    shortcutRow("⌘ + Klick",   "Zusätzlichen Eintrag wählen")
                    shortcutRow("↩ Return",    "Alle markierten Einträge einfügen")
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            Divider().padding(.top, 14)

            // Fußzeile
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(.tertiary)
                    .font(.caption)
                Text("Einstellungen über das Menüleisten-Icon → ⚙ Einstellungen")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortcutSection<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(header.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 2)
            content()
        }
        .padding(.bottom, 4)
    }

    private func shortcutRow(_ key: String, _ desc: String) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
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
