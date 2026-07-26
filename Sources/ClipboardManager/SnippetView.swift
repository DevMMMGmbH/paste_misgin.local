import SwiftUI
import AppKit

struct SnippetView: View {
    @ObservedObject private var store = SnippetStore.shared
    var onPaste: (String) -> Void

    @State private var searchText = ""
    @State private var showAdd = false
    @State private var editingSnippet: Snippet? = nil

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            Divider()
            if store.filtered(by: searchText).isEmpty {
                emptyState
            } else {
                snippetList
            }
        }
        .overlay {
            if showAdd {
                AddSnippetOverlay(isPresented: $showAdd, existing: nil) { snippet in
                    store.add(snippet)
                }
            } else if let snippet = editingSnippet {
                AddSnippetOverlay(isPresented: Binding(
                    get: { editingSnippet != nil },
                    set: { if !$0 { editingSnippet = nil } }
                ), existing: snippet) { updated in
                    store.update(updated)
                    editingSnippet = nil
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
            TextField("Suchen…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            Button { showAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.07), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Snippet hinzufügen")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - List

    private var snippetList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(store.filtered(by: searchText)) { snippet in
                    SnippetRow(snippet: snippet) {
                        onPaste(snippet.content)
                    } onEdit: {
                        editingSnippet = snippet
                    } onDelete: {
                        store.remove(id: snippet.id)
                    }
                    Divider().padding(.leading, 40)
                }
            }
        }
        .frame(maxHeight: 400)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bookmark")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Keine Snippets")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button { showAdd = true } label: {
                Label("Snippet hinzufügen", systemImage: "plus")
                    .font(.system(size: 13))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Snippet Row

struct SnippetRow: View {
    let snippet: Snippet
    let onPaste: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "bookmark.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color.accentColor.opacity(0.7))
                .frame(width: 16, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(snippet.title)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    if !snippet.project.isEmpty {
                        Text(snippet.project)
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.8), in: Capsule())
                    }
                }
                Text(snippet.content)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if !snippet.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(snippet.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isHovered {
                HStack(spacing: 4) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Bearbeiten")

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                            .foregroundStyle(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Löschen")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(isHovered ? Color.accentColor.opacity(0.08) : Color.clear)
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture { onPaste() }
    }
}

// MARK: - Add / Edit Overlay

struct AddSnippetOverlay: View {
    @Binding var isPresented: Bool
    var existing: Snippet?
    var prefillContent: String? = nil
    var onSave: (Snippet) -> Void

    @State private var title = ""
    @State private var content = ""
    @State private var tags = ""
    @State private var project = ""
    @FocusState private var titleFocused: Bool

    var isEditing: Bool { existing != nil }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text(isEditing ? "Snippet bearbeiten" : "Snippet hinzufügen")
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    field(label: "Titel", placeholder: "z.B. SSH Produktiv-Server") {
                        TextField("", text: $title)
                            .focused($titleFocused)
                    }
                    field(label: "Inhalt", placeholder: "ssh user@1.2.3.4 -p 22") {
                        TextEditor(text: $content)
                            .font(.system(size: 13, design: .monospaced))
                            .frame(minHeight: 60, maxHeight: 120)
                            .scrollContentBackground(.hidden)
                    }
                    field(label: "Projekt", placeholder: "z.B. misgin.local") {
                        TextField("", text: $project)
                    }
                    field(label: "Tags", placeholder: "ssh, server, prod  (kommagetrennt)") {
                        TextField("", text: $tags)
                    }
                }
                .padding(16)

                Divider()

                HStack {
                    Spacer()
                    Button("Abbrechen") { isPresented = false }
                    Button(isEditing ? "Speichern" : "Hinzufügen") { save() }
                        .buttonStyle(.borderedProminent)
                        .disabled(title.isEmpty || content.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.25), radius: 16, y: 4)
            .padding(24)
            .onAppear {
                if let s = existing {
                    title   = s.title
                    content = s.content
                    project = s.project
                    tags    = s.tagString
                } else {
                    if let pre = prefillContent { content = pre }
                    titleFocused = true
                }
            }
        }
    }

    @ViewBuilder
    private func field<F: View>(label: String, placeholder: String, @ViewBuilder field: () -> F) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            ZStack(alignment: .topLeading) {
                if content.isEmpty && label == "Inhalt" {
                    Text(placeholder)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(8)
                        .allowsHitTesting(false)
                }
                field()
                    .padding(label == "Inhalt" ? 4 : 7)
            }
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primary.opacity(0.1), lineWidth: 1))
        }
    }

    private func save() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if var updated = existing {
            updated.title   = title
            updated.content = content
            updated.tags    = parsedTags
            updated.project = project
            onSave(updated)
        } else {
            onSave(Snippet(title: title, content: content, tags: parsedTags, project: project))
        }
        isPresented = false
    }
}
