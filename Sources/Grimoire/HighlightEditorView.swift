import SwiftUI
import GrimoireKit

/// Second window for managing custom highlights. Left: list of rules with
/// an enable toggle. Right: detail editor with live preview against a
/// canned sample paragraph so the user can see the result instantly.
struct HighlightEditorView: View {
    @EnvironmentObject var store: HighlightStore
    @State private var selectedId: UUID?
    @State private var importing: Bool = false
    @State private var importError: String?
    @State private var listKind: HighlightKind = .text

    private var visibleHighlights: [Highlight] {
        store.highlights.filter { $0.kind == listKind }
    }

    var body: some View {
        HSplitView {
            list
                .frame(minWidth: 240)
            detail
                .frame(minWidth: 420)
        }
        .frame(minWidth: 760, minHeight: 520)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.xml, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .onAppear {
            if selectedId == nil { selectedId = visibleHighlights.first?.id }
        }
        .onChange(of: listKind) { _, _ in
            selectedId = visibleHighlights.first?.id
        }
    }

    // MARK: - List

    private var list: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Highlights").font(.headline)
                Spacer()
                Text("\(visibleHighlights.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button {
                    let placeholder = listKind == .name ? "new name" : "new highlight"
                    let fresh = store.add(
                        Highlight(text: placeholder, fgColor: "#FFCC66", kind: listKind)
                    )
                    selectedId = fresh.id
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add a new \(listKind == .name ? "name" : "highlight")")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Picker("", selection: $listKind) {
                Text("Text").tag(HighlightKind.text)
                Text("Names").tag(HighlightKind.name)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            Divider()

            List(selection: $selectedId) {
                ForEach(visibleHighlights) { rule in
                    HStack(spacing: 8) {
                        Toggle("", isOn: bindingForEnabled(rule.id))
                            .toggleStyle(.checkbox)
                            .labelsHidden()
                        VStack(alignment: .leading, spacing: 2) {
                            inlineSample(rule)
                            metaBadges(rule)
                        }
                    }
                    .tag(rule.id)
                    .contentShape(Rectangle())
                }
            }
            .listStyle(.inset)

            Divider()
            HStack {
                Button("Import from XML…") { importing = true }
                Spacer()
                if let importError {
                    Text(importError)
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(8)
        }
    }

    /// Renders the rule's own match text styled with its fg / bg colors so the
    /// list row previews exactly what the user will see in the game feed.
    /// Falls back to a placeholder when the text is still empty.
    private func inlineSample(_ rule: Highlight) -> some View {
        let display = rule.text.isEmpty ? "(no text)" : rule.text
        let fg = rule.fgColor.flatMap { Color(hex: $0) }
        let bg = rule.bgColor.flatMap { Color(hex: $0) } ?? .clear
        return Text(display)
            .font(.system(size: 12, design: .monospaced))
            .foregroundStyle(fg ?? .primary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(bg)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder
    private func metaBadges(_ rule: Highlight) -> some View {
        HStack(spacing: 4) {
            if rule.entireLine    { badge("LINE") }
            if rule.caseSensitive { badge("CASE") }
            if rule.wholeWord     { badge("WORD") }
        }
    }

    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .foregroundStyle(.secondary)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        if let id = selectedId, let rule = store.highlights.first(where: { $0.id == id }) {
            HighlightDetail(rule: rule, store: store, onDelete: {
                store.remove(id: id)
                selectedId = store.highlights.first?.id
            })
            .id(id)  // reset form state when switching rows
            .padding(16)
        } else {
            VStack {
                Spacer()
                Text("Select a highlight, or press + to add one.")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Bindings

    private func bindingForEnabled(_ id: UUID) -> Binding<Bool> {
        Binding(
            get: { store.highlights.first(where: { $0.id == id })?.enabled ?? false },
            set: { newValue in
                if var r = store.highlights.first(where: { $0.id == id }) {
                    r.enabled = newValue
                    store.update(r)
                }
            }
        )
    }

    // MARK: - Import

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            // SwiftUI file importer hands back a security-scoped URL on real
            // sandboxed builds; ad-hoc dev signing means this is a no-op, but
            // wrapping keeps us correct under either.
            let didScope = url.startAccessingSecurityScopedResource()
            defer { if didScope { url.stopAccessingSecurityScopedResource() } }
            let parsed = try HighlightParser.parse(file: url)
            store.replaceAll(with: parsed)
            selectedId = parsed.first(where: { $0.kind == listKind })?.id
                ?? parsed.first?.id
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
    }
}

// MARK: - Detail form + live preview

private struct HighlightDetail: View {
    let rule: Highlight
    let store: HighlightStore
    let onDelete: () -> Void

    @State private var text: String
    @State private var fgColor: Color
    @State private var bgColor: Color
    @State private var fgEnabled: Bool
    @State private var bgEnabled: Bool
    @State private var entireLine: Bool
    @State private var caseSensitive: Bool
    @State private var wholeWord: Bool
    @State private var enabled: Bool

    init(rule: Highlight, store: HighlightStore, onDelete: @escaping () -> Void) {
        self.rule = rule
        self.store = store
        self.onDelete = onDelete
        _text          = State(initialValue: rule.text)
        _fgColor       = State(initialValue: rule.fgColor.flatMap { Color(hex: $0) } ?? .yellow)
        _bgColor       = State(initialValue: rule.bgColor.flatMap { Color(hex: $0) } ?? .black)
        _fgEnabled     = State(initialValue: rule.fgColor != nil)
        _bgEnabled     = State(initialValue: rule.bgColor != nil)
        _entireLine    = State(initialValue: rule.entireLine)
        _caseSensitive = State(initialValue: rule.caseSensitive)
        _wholeWord     = State(initialValue: rule.wholeWord)
        _enabled       = State(initialValue: rule.enabled)
    }

    /// Reflects the form state without going through `store` — keeps the
    /// preview in sync with unsaved keystrokes.
    private var draftHighlight: Highlight {
        Highlight(
            id: rule.id,
            text: text,
            fgColor: fgEnabled ? fgColor.hexString : nil,
            bgColor: bgEnabled ? bgColor.hexString : nil,
            entireLine: entireLine,
            caseSensitive: caseSensitive,
            wholeWord: wholeWord,
            enabled: enabled,
            kind: rule.kind
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle("Enabled", isOn: $enabled)
                Spacer()
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Match text").font(.subheadline.bold())
                TextField("e.g. greedy gremlins", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            HStack(spacing: 24) {
                colorRow(title: "Text color",       isOn: $fgEnabled, color: $fgColor)
                colorRow(title: "Background color", isOn: $bgEnabled, color: $bgColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Highlight entire line", isOn: $entireLine)
                Toggle("Case sensitive",        isOn: $caseSensitive)
                Toggle("Whole word only",       isOn: $wholeWord)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Preview").font(.subheadline.bold())
                previewBlock
            }

            Spacer()
        }
        .onChange(of: draftHighlight) { _, new in
            store.update(new)
        }
    }

    private func colorRow(title: String, isOn: Binding<Bool>, color: Binding<Color>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: isOn)
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
        }
    }

    /// Renders a canned sample paragraph through the very same NSTextView
    /// pipeline the live game feed uses, with this draft rule pinned in.
    /// Using the real renderer means the preview is byte-identical to what
    /// the user sees in-game — no parallel rendering path to keep in sync.
    private var previewBlock: some View {
        let sampleLines = HighlightPreviewSamples.lines(featuring: text)
        // `revision` only needs to change when sampleLines change; any
        // draftHighlight change (color, flags) is picked up by
        // StoryTextView's separate `highlightHash` and forces a rebuild.
        return StoryTextView(
            lines: sampleLines,
            revision: sampleLines.count,
            highlights: [draftHighlight],
            onLinkClick: { _ in }
        )
        .frame(height: 140)
        .background(GameTheme.background)
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .environment(\.fontSize, 13)
        .environment(\.colorScheme, .dark)
    }
}

/// Canned sample lines used by the editor's preview. Includes the user's
/// current match text so they can see their rule fire even before typing it
/// into the game.
private enum HighlightPreviewSamples {
    static func lines(featuring search: String) -> [RenderedLine] {
        var base: [String] = [
            "Burghal Gnome arrives, leading a yierka-spider.",
            "You hear the soft chime of distant temple bells.",
            "A dark figure slinks into the shadows; you catch a glimpse of a runestaff.",
            "[Private]-GSIV:Someone says, \"meet at the north gate in five.\"",
            "Your veins pulsate slightly as your concentration deepens.",
            "The greedy gremlins scatter, snatching coins as they flee."
        ]
        if !search.isEmpty, !base.contains(where: { $0.localizedCaseInsensitiveContains(search) }) {
            base.append("(Match preview) Sample line containing \(search) for visualization.")
        }
        return base.map { line in
            RenderedLine(runs: [RenderedRun(text: line, style: RunStyle())])
        }
    }
}
