import SwiftUI
import GrimoireKit

/// Second window for managing custom highlights. Left: list of rules with
/// an enable toggle. Right: detail editor with live preview against a
/// canned sample paragraph so the user can see the result instantly.
/// What's currently selected in the editor list. Polymorphic because
/// the user can now select either an individual rule or a group, and
/// the detail pane swaps between the two editors.
enum HighlightSelection: Hashable {
    case rule(UUID)
    case group(UUID)
}

struct HighlightEditorView: View {
    @EnvironmentObject var store: HighlightStore
    @State private var selection: HighlightSelection?
    @State private var importing: Bool = false
    @State private var importError: String?
    @State private var listKind: HighlightKind = .text
    @State private var filterText: String = ""
    @State private var sortOrder: HighlightSort = .insertion
    /// Group ids that are collapsed in the sidebar. Default is
    /// expanded; we track the negative because most users will leave
    /// groups expanded most of the time.
    @State private var collapsedGroups: Set<UUID> = []

    /// Rules that match the active kind tab + current filter, sorted by
    /// the current sort order. Group affiliation is preserved on the
    /// rule itself -- the list layout consults `rule.groupId` to nest
    /// each rule under its group.
    private var filteredRules: [Highlight] {
        var rules = store.highlights.filter { $0.kind == listKind }
        if !filterText.isEmpty {
            rules = rules.filter {
                $0.text.localizedCaseInsensitiveContains(filterText)
            }
        }
        return sortOrder.apply(to: rules)
    }

    private var visibleGroups: [HighlightGroup] {
        store.groups
    }

    private func members(of group: HighlightGroup) -> [Highlight] {
        filteredRules.filter { $0.groupId == group.id }
    }

    private var ungroupedRules: [Highlight] {
        filteredRules.filter { $0.groupId == nil }
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
            if selection == nil, let first = filteredRules.first {
                selection = .rule(first.id)
            }
        }
        .onChange(of: listKind) { _, _ in
            selection = filteredRules.first.map { .rule($0.id) }
        }
    }

    // MARK: - List

    private var list: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Highlights").font(.headline)
                Spacer()
                Text(countLabel)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Menu {
                    Button {
                        addRule(intoGroup: selectedGroupId)
                    } label: {
                        Label("New highlight", systemImage: "plus")
                    }
                    Button {
                        addGroup()
                    } label: {
                        Label("New group", systemImage: "folder.badge.plus")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Add a highlight or a group")
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

            HStack(spacing: 8) {
                filterBar
                sortMenu
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)

            Divider()

            List(selection: $selection) {
                ForEach(visibleGroups) { group in
                    groupHeaderRow(group)
                        .tag(HighlightSelection.group(group.id))
                    if !collapsedGroups.contains(group.id) {
                        ForEach(members(of: group)) { rule in
                            ruleRow(rule, indented: true)
                                .tag(HighlightSelection.rule(rule.id))
                        }
                    }
                }
                if !ungroupedRules.isEmpty {
                    if !visibleGroups.isEmpty {
                        // Soft divider between the grouped section and
                        // the loose rules so it's visually obvious
                        // where membership ends.
                        Text("Ungrouped")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                    ForEach(ungroupedRules) { rule in
                        ruleRow(rule, indented: false)
                            .tag(HighlightSelection.rule(rule.id))
                    }
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

    /// Magnifying-glass + text field + clear-X. Plain TextField rather
    /// than `.searchable` because the editor lives inside an HSplitView,
    /// not a NavigationStack -- `.searchable` doesn't anchor cleanly to
    /// the left list pane in that layout.
    private var filterBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.caption)
            TextField("Filter", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
            if !filterText.isEmpty {
                Button {
                    filterText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Clear filter")
            }
        }
    }

    /// Group header row. Selectable like a rule, plus a chevron that
    /// toggles expansion. Right-click offers rename/delete; rules can
    /// also be moved into / out of the group from their own context
    /// menu in `ruleRow`.
    @ViewBuilder
    private func groupHeaderRow(_ group: HighlightGroup) -> some View {
        let isExpanded = !collapsedGroups.contains(group.id)
        let memberCount = members(of: group).count
        HStack(spacing: 6) {
            Button {
                if isExpanded {
                    collapsedGroups.insert(group.id)
                } else {
                    collapsedGroups.remove(group.id)
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Circle()
                .fill(group.fgColor.flatMap(Color.init(hex:)) ?? .accentColor)
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 1) {
                Text(group.name.isEmpty ? "Unnamed group" : group.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(memberCount) \(memberCount == 1 ? "rule" : "rules")")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !group.enabled {
                badge("OFF")
            }
        }
        .contextMenu {
            Button("New highlight in group") {
                addRule(intoGroup: group.id)
            }
            Divider()
            Button("Delete group", role: .destructive) {
                store.removeGroup(id: group.id)
                if selection == .group(group.id) { selection = nil }
            }
        }
    }

    /// Optional left-indent when shown nested under a group header.
    /// Group reassignment is now done via the dropdown in
    /// `HighlightDetail` (matching the spell-preset editor's pattern),
    /// so no right-click menu is needed here.
    @ViewBuilder
    private func ruleRow(_ rule: Highlight, indented: Bool) -> some View {
        let parent = rule.groupId.flatMap { gid in
            store.groups.first(where: { $0.id == gid })
        }
        HStack(spacing: 0) {
            if indented {
                Color.clear.frame(width: 20, height: 1)
            }
            HighlightRow(
                rule: rule,
                parentGroup: parent,
                onToggleEnabled: { newValue in
                    var updated = rule
                    updated.enabled = newValue
                    store.update(updated)
                }
            )
        }
    }

    /// `groupId` of the currently-selected item, if any -- used to
    /// decide where a freshly-added rule should land. When the user
    /// has a group (or one of its members) selected, the new rule
    /// joins that group; otherwise it lands ungrouped.
    private var selectedGroupId: UUID? {
        switch selection {
        case .group(let id): return id
        case .rule(let id):  return store.highlights.first(where: { $0.id == id })?.groupId
        case .none:          return nil
        }
    }

    /// Small uppercase-text pill used in the group header to indicate
    /// disabled state. Mirrors the `badge` inside `HighlightRow`.
    private func badge(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .foregroundStyle(.secondary)
    }

    private func addRule(intoGroup groupId: UUID?) {
        filterText = ""
        let placeholder = listKind == .name ? "new name" : "new highlight"
        let fresh = store.add(
            Highlight(text: placeholder, fgColor: "#FFCC66", kind: listKind, groupId: groupId)
        )
        // Make sure the destination group is expanded so the user
        // sees the new row.
        if let gid = groupId { collapsedGroups.remove(gid) }
        selection = .rule(fresh.id)
    }

    private func addGroup() {
        let fresh = store.addGroup(HighlightGroup(name: "New Group"))
        collapsedGroups.remove(fresh.id)
        selection = .group(fresh.id)
    }

    private var sortMenu: some View {
        Menu {
            ForEach(HighlightSort.allCases) { option in
                Button {
                    sortOrder = option
                } label: {
                    Label(option.label, systemImage: sortOrder == option ? "checkmark" : "")
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Sort highlights")
    }

    /// Count display in the list header. Shows total-after-filtering or
    /// `matches / total` while a filter is active so the user can tell
    /// how much the search narrowed the set.
    private var countLabel: String {
        let total = store.highlights.filter { $0.kind == listKind }.count
        if filterText.isEmpty { return "\(total)" }
        return "\(filteredRules.count)/\(total)"
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .rule(let id):
            if let rule = store.highlights.first(where: { $0.id == id }) {
                HighlightDetail(rule: rule, store: store, onDelete: {
                    store.remove(id: id)
                    selection = store.highlights.first.map { .rule($0.id) }
                })
                .id(id)
                .padding(16)
            } else {
                emptyDetail
            }
        case .group(let id):
            if let group = store.groups.first(where: { $0.id == id }) {
                HighlightGroupDetail(group: group, store: store, onDelete: {
                    store.removeGroup(id: id)
                    selection = nil
                })
                .id(id)
                .padding(16)
            } else {
                emptyDetail
            }
        case .none:
            emptyDetail
        }
    }

    private var emptyDetail: some View {
        VStack {
            Spacer()
            Text("Select a highlight or group, or press + to add one.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
            selection = parsed.first(where: { $0.kind == listKind }).map { .rule($0.id) }
                ?? parsed.first.map { .rule($0.id) }
            importError = nil
        } catch {
            importError = error.localizedDescription
        }
    }
}

/// Order options for the highlight list. `.insertion` is the natural
/// save-order which also happens to be the match priority order at
/// render time -- keep it as the default so the user's mental model of
/// "later rules win on overlap" still holds when they're not actively
/// sorting.
enum HighlightSort: String, CaseIterable, Identifiable {
    case insertion
    case textAsc
    case textDesc
    case color

    var id: String { rawValue }

    var label: String {
        switch self {
        case .insertion: return "Insertion order"
        case .textAsc:   return "Match text (A-Z)"
        case .textDesc:  return "Match text (Z-A)"
        case .color:     return "Color"
        }
    }

    func apply(to rules: [Highlight]) -> [Highlight] {
        switch self {
        case .insertion:
            return rules
        case .textAsc:
            return rules.sorted { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending }
        case .textDesc:
            return rules.sorted { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedDescending }
        case .color:
            // Group same-colored rules together; rules without a fg
            // color sink to the end. Within a color, fall back to
            // case-insensitive text order so the result is stable.
            return rules.sorted { a, b in
                switch (a.fgColor, b.fgColor) {
                case (nil, nil): return a.text.localizedCaseInsensitiveCompare(b.text) == .orderedAscending
                case (nil, _):   return false
                case (_, nil):   return true
                case (let l?, let r?):
                    if l == r {
                        return a.text.localizedCaseInsensitiveCompare(b.text) == .orderedAscending
                    }
                    return l < r
                }
            }
        }
    }
}

// MARK: - List row

/// Standalone row so SwiftUI's value-type diff can skip rows whose
/// `Highlight` hasn't changed. Keeping this out of the parent's
/// closure (where the previous implementation called
/// `store.highlights.first(where:)` inside a Binding `get:`) gets rid
/// of the O(rules²) work per re-render that made toggling a single
/// rule visibly stall the editor at ~900 rules.
///
/// `parentGroup` is the row's group (when nested under one) so the
/// inline sample can render with group inheritance applied -- a rule
/// with no own fg color inside a red group shows red in the sidebar,
/// matching what the game feed will actually display.
private struct HighlightRow: View {
    let rule: Highlight
    let parentGroup: HighlightGroup?
    let onToggleEnabled: (Bool) -> Void

    /// Rule with group inheritance applied. Inline sample + B/I badges
    /// read from this; CASE/WORD/REGEX/LINE badges stay on the rule's
    /// own config since those are structural, not stylistic.
    private var resolved: Highlight {
        guard let g = parentGroup else { return rule }
        return HighlightResolver.resolve([rule], groups: [g]).first ?? rule
    }

    var body: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: { rule.enabled },
                set: { newValue in onToggleEnabled(newValue) }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()
            VStack(alignment: .leading, spacing: 2) {
                inlineSample
                metaBadges
            }
        }
        .contentShape(Rectangle())
    }

    private var inlineSample: some View {
        let r = resolved
        let display = r.text.isEmpty ? "(no text)" : r.text
        let fg = r.fgColor.flatMap { Color(hex: $0) }
        let bg = r.bgColor.flatMap { Color(hex: $0) } ?? .clear
        var t = Text(display)
            .font(.system(size: 12, design: .monospaced))
        if r.bold   { t = t.bold() }
        if r.italic { t = t.italic() }
        return t
            .foregroundStyle(fg ?? .primary)
            .padding(.horizontal, 4)
            .padding(.vertical, 1)
            .background(bg)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    @ViewBuilder
    private var metaBadges: some View {
        let r = resolved
        HStack(spacing: 4) {
            if rule.usesPattern   { badge("REGEX") }
            if rule.entireLine    { badge("LINE") }
            if rule.caseSensitive { badge("CASE") }
            if rule.wholeWord     { badge("WORD") }
            if r.bold             { badge("B") }
            if r.italic           { badge("I") }
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
    @State private var usesPattern: Bool
    @State private var bold: Bool
    @State private var italic: Bool
    @State private var groupId: UUID?
    /// True when the row was deleted via the trash button. Suppresses
    /// the `.onDisappear` flush so we don't immediately resurrect the
    /// deleted rule by pushing the local draft back into the store.
    @State private var didDelete: Bool = false
    /// Scratch input for the "Test against your own text" panel. Not
    /// persisted; gone when the user navigates away from the row.
    @State private var testInput: String = ""

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
        _usesPattern   = State(initialValue: rule.usesPattern)
        _bold          = State(initialValue: rule.bold)
        _italic        = State(initialValue: rule.italic)
        _groupId       = State(initialValue: rule.groupId)
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
            kind: rule.kind,
            usesPattern: usesPattern,
            bold: bold,
            italic: italic,
            groupId: groupId
        )
    }

    /// The group `groupId` currently points at, if any. Drives the
    /// "Inheriting from group X" hint.
    private var parentGroup: HighlightGroup? {
        guard let gid = groupId else { return nil }
        return store.groups.first(where: { $0.id == gid })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle("Enabled", isOn: $enabled)
                Spacer()
                Button(role: .destructive) {
                    didDelete = true
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Match text").font(.subheadline.bold())
                TextField(matchPlaceholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                if usesPattern {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Regex: `\\d` digit · `\\w` word char · `.` any · `?` optional · `+` 1+ · `*` 0+ · `[abc]` class · `(a|b)` alt. Escape `( ) . + ? * | [ ]` to match them literally.")
                        if !patternIsValid {
                            Text("Invalid regex — won't match anything.")
                                .foregroundStyle(.red)
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                colorRow(title: "Text color",       isOn: $fgEnabled, color: $fgColor)
                colorRow(title: "Background color", isOn: $bgEnabled, color: $bgColor)
            }

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Highlight entire line", isOn: $entireLine)
                    Toggle("Case sensitive",        isOn: $caseSensitive)
                    Toggle("Whole word only",       isOn: $wholeWord)
                    Toggle("Regex pattern",         isOn: $usesPattern)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Bold",   isOn: $bold)
                    Toggle("Italic", isOn: $italic)
                }
            }

            if !store.groups.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Group").font(.subheadline.bold())
                    Picker("", selection: $groupId) {
                        Text("(None)").tag(UUID?.none)
                        ForEach(store.groups) { g in
                            Text(g.name.isEmpty ? "Unnamed group" : g.name).tag(UUID?.some(g.id))
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    if let p = parentGroup {
                        Text("Inheriting unset fields from group \"\(p.name.isEmpty ? "Unnamed group" : p.name)\".")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Preview").font(.subheadline.bold())
                previewBlock
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Test against custom text").font(.subheadline.bold())
                    Spacer()
                    if !testInput.isEmpty {
                        Text(testMatchLabel)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(testMatchCount > 0 ? .green : .red)
                    }
                }
                TextField(
                    "Paste a game line to check whether this rule matches it…",
                    text: $testInput,
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1...4)
                if !testInput.isEmpty {
                    testResultBlock
                }
            }

            Spacer()
        }
        .onChange(of: groupId) { _, _ in
            // Group reassignment commits live (single discrete action,
            // no per-keystroke cascade concern). This makes the
            // sidebar reflect the move the instant the user picks a
            // new group from the dropdown, mirroring the spell-preset
            // editor's behavior.
            store.update(draftHighlight)
        }
        .onDisappear {
            // Modal commit for the rest of the form: the draft only
            // propagates into the store when this view leaves the
            // hierarchy (selection change, editor window close, app
            // quit). Until then every edit is local @State and the
            // rest of the app sees the prior committed value -- this
            // is what eliminates the per-keystroke @Published cascade.
            //
            // Skip the flush when the user just hit Delete; otherwise
            // the local draft would resurrect the row we just removed.
            guard !didDelete else { return }
            guard let current = store.highlights.first(where: { $0.id == rule.id }) else { return }
            if current != draftHighlight {
                store.update(draftHighlight)
            }
        }
    }

    private var matchPlaceholder: String {
        usesPattern
            ? #"e.g. \(\d+ hidden disks?\)"#
            : "e.g. greedy gremlins"
    }

    /// Live-validates the current pattern. Returns true for non-regex
    /// rules and for empty-text regex rules; only flags actual ICU
    /// compile failures so the user knows their pattern won't match.
    /// Sub-µs per call -- NSRegularExpression compile is fast and the
    /// HighlightProcessor cache catches repeated valid patterns anyway.
    private var patternIsValid: Bool {
        guard usesPattern, !text.isEmpty else { return true }
        return (try? NSRegularExpression(pattern: text)) != nil
    }

    private func colorRow(title: String, isOn: Binding<Bool>, color: Binding<Color>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: isOn)
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
                .opacity(isOn.wrappedValue ? 1 : 0.45)
        }
    }

    /// Mini StoryTextView showing just the user's pasted test text,
    /// styled with whatever the current draft rule would do to it.
    /// Multi-line input splits on `\n` so pasting a 3-line excerpt
    /// keeps the visual layout the user expects.
    private var testResultBlock: some View {
        let lines: [RenderedLine] = testInput
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { RenderedLine(runs: [RenderedRun(text: String($0), style: RunStyle())]) }
        return StoryTextView(
            lines: lines,
            revision: lines.count,
            highlights: [draftHighlight],
            onLinkClick: { _ in }
        )
        .frame(minHeight: 40, maxHeight: 120)
        .background(GameTheme.background)
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .environment(\.fontSize, 13)
        .environment(\.colorScheme, .dark)
    }

    /// Counts contiguous highlighted regions in `testInput` after the
    /// draft rule is applied. Uses the real `HighlightProcessor` so
    /// the count is byte-identical to what would fire in the live
    /// game feed (including regex compile failures returning zero).
    private var testMatchCount: Int {
        guard !testInput.isEmpty else { return 0 }
        var count = 0
        for rawLine in testInput.split(separator: "\n", omittingEmptySubsequences: false) {
            let input = RenderedLine(runs: [RenderedRun(text: String(rawLine), style: RunStyle())])
            let processed = HighlightProcessor.apply([draftHighlight], to: input)
            var inMatch = false
            for run in processed.runs {
                let isHit = run.style.highlightFg != nil
                    || run.style.highlightBg != nil
                    || run.style.highlightBold
                    || run.style.italic
                if isHit && !inMatch { count += 1; inMatch = true }
                else if !isHit { inMatch = false }
            }
        }
        return count
    }

    private var testMatchLabel: String {
        switch testMatchCount {
        case 0:  return "No match"
        case 1:  return "1 match"
        case let n: return "\(n) matches"
        }
    }

    /// Renders a canned sample paragraph through the very same NSTextView
    /// pipeline the live game feed uses, with this draft rule pinned in.
    /// Using the real renderer means the preview is byte-identical to what
    /// the user sees in-game — no parallel rendering path to keep in sync.
    ///
    /// Reads `draftHighlight` directly: with the modal-commit pattern the
    /// rest of the app no longer cascades on each keystroke, so paying
    /// for the StoryTextView reconcile per keystroke is fine -- it stays
    /// local to this view and the rebuild for ~6 sample lines plus one
    /// rule is sub-ms.
    private var previewBlock: some View {
        let draft = draftHighlight
        let sampleLines = HighlightPreviewSamples.lines(featuring: draft.text)
        return StoryTextView(
            lines: sampleLines,
            revision: sampleLines.count,
            highlights: [draft],
            onLinkClick: { _ in }
        )
        .frame(height: 140)
        .background(GameTheme.background)
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .environment(\.fontSize, 13)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Group detail

/// Edits a `HighlightGroup`'s name, default colors, trait additions,
/// enabled/notify toggles. Modal-commit on disappear, matching the
/// pattern in `HighlightDetail` so typing into the name doesn't
/// cascade through the engine.
private struct HighlightGroupDetail: View {
    let group: HighlightGroup
    let store: HighlightStore
    let onDelete: () -> Void

    @State private var name: String
    @State private var fgColor: Color
    @State private var bgColor: Color
    @State private var fgEnabled: Bool
    @State private var bgEnabled: Bool
    @State private var bold: Bool
    @State private var italic: Bool
    @State private var enabled: Bool
    @State private var notify: Bool
    @State private var didDelete: Bool = false

    init(group: HighlightGroup, store: HighlightStore, onDelete: @escaping () -> Void) {
        self.group = group
        self.store = store
        self.onDelete = onDelete
        _name      = State(initialValue: group.name)
        _fgColor   = State(initialValue: group.fgColor.flatMap { Color(hex: $0) } ?? .yellow)
        _bgColor   = State(initialValue: group.bgColor.flatMap { Color(hex: $0) } ?? .black)
        _fgEnabled = State(initialValue: group.fgColor != nil)
        _bgEnabled = State(initialValue: group.bgColor != nil)
        _bold      = State(initialValue: group.bold)
        _italic    = State(initialValue: group.italic)
        _enabled   = State(initialValue: group.enabled)
        _notify    = State(initialValue: group.notify)
    }

    private var draft: HighlightGroup {
        HighlightGroup(
            id: group.id,
            name: name,
            fgColor: fgEnabled ? fgColor.hexString : nil,
            bgColor: bgEnabled ? bgColor.hexString : nil,
            bold: bold,
            italic: italic,
            enabled: enabled,
            notify: notify
        )
    }

    private var memberCount: Int {
        store.highlights.filter { $0.groupId == group.id }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Toggle("Enabled", isOn: $enabled)
                Spacer()
                Button(role: .destructive) {
                    didDelete = true
                    onDelete()
                } label: {
                    Label("Delete group", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .help("Removes the group and detaches its rules (rules are kept).")
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Name").font(.subheadline.bold())
                TextField("e.g. Combat events", text: $name)
                    .textFieldStyle(.roundedBorder)
            }

            HStack(spacing: 24) {
                colorRow(title: "Default text color", isOn: $fgEnabled, color: $fgColor)
                colorRow(title: "Default background", isOn: $bgEnabled, color: $bgColor)
            }
            Text("Member rules inherit these when their own color is unset.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Bold (adds to member rules)",   isOn: $bold)
                Toggle("Italic (adds to member rules)", isOn: $italic)
                Toggle("Notify on match",               isOn: $notify)
                    .help("Posts a macOS notification with the matched game line when any rule in this group fires. (Hooked up in a separate commit.)")
            }

            Divider()

            HStack {
                Text("\(memberCount) member \(memberCount == 1 ? "rule" : "rules")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer()
        }
        .onDisappear {
            guard !didDelete else { return }
            if group != draft {
                store.updateGroup(draft)
            }
        }
    }

    private func colorRow(title: String, isOn: Binding<Bool>, color: Binding<Color>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: isOn)
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
                .opacity(isOn.wrappedValue ? 1 : 0.45)
        }
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

