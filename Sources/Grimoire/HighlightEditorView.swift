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
    /// When a new rule or group is created, the parent sets this to
    /// the freshly-added id. The matching detail view consumes it on
    /// `.onAppear` to immediately focus its primary text field, so
    /// the user can just start typing the name / match text without
    /// clicking into the field first.
    @State private var pendingFocusForId: UUID? = nil

    /// Rules that match the active kind tab + current filter, sorted by
    /// the current sort order. Group affiliation is preserved on the
    /// rule itself -- the list layout consults `rule.groupId` to nest
    /// each rule under its group.
    ///
    /// Filter syntax:
    /// - Plain text: case-insensitive substring against the match text.
    /// - `tag:regex|line|case|word|bold|italic`: flag filter. Bold and
    ///   italic honor group inheritance so a rule that gets bold from
    ///   its parent group still matches `tag:bold`.
    /// - Multiple space-separated terms AND together, so
    ///   `tag:regex death` finds regex rules whose text contains
    ///   "death".
    private var filteredRules: [Highlight] {
        var rules = store.highlights.filter { $0.kind == listKind }
        if !filterText.isEmpty {
            let groupsById = Dictionary(uniqueKeysWithValues: store.groups.map { ($0.id, $0) })
            let terms = filterText
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            for term in terms {
                rules = rules.filter { ruleMatches($0, term: term, groups: groupsById) }
            }
        }
        return sortOrder.apply(to: rules)
    }

    private func ruleMatches(_ rule: Highlight, term: String, groups: [UUID: HighlightGroup]) -> Bool {
        let lower = term.lowercased()
        if lower.hasPrefix("tag:") {
            let tag = String(lower.dropFirst(4))
            // All tags now check the rule's OWN field. Inherited
            // values are intentionally NOT included, because the
            // primary use case for these tags is finding explicit
            // overrides ("which rules in this group have their own
            // text color set when they should be inheriting?").
            // For "is this rule effectively bold/italic/etc?" the
            // visual badges in the sidebar (which DO show resolved
            // state) are the better signal.
            switch tag {
            case "regex":     return rule.usesPattern
            case "line":      return rule.entireLine
            case "case":      return rule.caseSensitive
            case "word":      return rule.wholeWord
            case "bold":      return rule.bold
            case "italic":    return rule.italic
            case "fg":        return rule.fgColor != nil
            case "bg":        return rule.bgColor != nil
            case "enabled":   return rule.enabled
            case "disabled":  return !rule.enabled
            case "grouped":   return rule.groupId != nil
            case "ungrouped": return rule.groupId == nil
            default:          return false  // unknown tag matches nothing (strict)
            }
        }
        return rule.text.localizedCaseInsensitiveContains(term)
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
            TextField("Filter (try tag:fg, tag:grouped, ...)", text: $filterText)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .help("""
                Plain text matches the rule's text. Prefix a term with tag: \
                to filter by a rule's own setting (NOT inherited values). \
                Tags: regex, line, case, word, bold, italic, fg (text color \
                set), bg (bg color set), enabled, disabled, grouped, \
                ungrouped. Multiple terms AND together — e.g. tag:fg \
                tag:grouped finds rules in a group that have their own \
                text color override.
                """)
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
        // Start with empty text so the user can just type the rule's
        // text without first deleting boilerplate. The list row's
        // "(no text)" placeholder + the TextField's prompt cover the
        // visual gap until they type something.
        let fresh = store.add(
            Highlight(text: "", fgColor: "#FFCC66", kind: listKind, groupId: groupId)
        )
        if let gid = groupId { collapsedGroups.remove(gid) }
        selection = .rule(fresh.id)
        pendingFocusForId = fresh.id
    }

    private func addGroup() {
        let fresh = store.addGroup(HighlightGroup(name: ""))
        collapsedGroups.remove(fresh.id)
        selection = .group(fresh.id)
        pendingFocusForId = fresh.id
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
                HighlightDetail(
                    rule: rule,
                    store: store,
                    pendingFocusForId: $pendingFocusForId,
                    onDelete: {
                        store.remove(id: id)
                        selection = store.highlights.first.map { .rule($0.id) }
                    }
                )
                .id(id)
                .padding(16)
            } else {
                emptyDetail
            }
        case .group(let id):
            if let group = store.groups.first(where: { $0.id == id }) {
                HighlightGroupDetail(
                    group: group,
                    store: store,
                    pendingFocusForId: $pendingFocusForId,
                    onDelete: {
                        store.removeGroup(id: id)
                        selection = nil
                    }
                )
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
            // REGEX is rule-only (groups don't have it).
            if rule.usesPattern { badge("REGEX") }
            // The matching/display flags reflect group inheritance so
            // a member of an "all lines" group shows LINE in the row,
            // matching what'll actually fire at render time.
            if r.entireLine    { badge("LINE") }
            if r.caseSensitive { badge("CASE") }
            if r.wholeWord     { badge("WORD") }
            if r.bold          { badge("bold") }
            if r.italic        { badge("italic") }
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
    @Binding var pendingFocusForId: UUID?
    let onDelete: () -> Void

    @FocusState private var matchTextFocused: Bool
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
    @State private var notify: Bool
    /// Stash for the user's last-chosen fg / bg colors. Persisted on
    /// the Highlight as `stashedFgColor` / `stashedBgColor` so toggling
    /// "Text color" off doesn't destroy the user's previous pick.
    @State private var stashedFgHex: String?
    @State private var stashedBgHex: String?
    /// True when the row was deleted via the trash button. Suppresses
    /// the `.onDisappear` flush so we don't immediately resurrect the
    /// deleted rule by pushing the local draft back into the store.
    @State private var didDelete: Bool = false
    /// Scratch input for the "Test against your own text" panel. Not
    /// persisted; gone when the user navigates away from the row.
    @State private var testInput: String = ""

    init(rule: Highlight, store: HighlightStore, pendingFocusForId: Binding<UUID?>, onDelete: @escaping () -> Void) {
        self.rule = rule
        self.store = store
        self._pendingFocusForId = pendingFocusForId
        self.onDelete = onDelete
        _text          = State(initialValue: rule.text)
        // The color picker's @State always reflects the user's last
        // intended pick: prefer the active fg, then the stashed value,
        // then a sensible default. So a rule with no active color but
        // a stashed red comes up as red in the picker -- the toggle is
        // off, but flipping it on restores the red instantly.
        let initialFgHex = rule.fgColor ?? rule.stashedFgColor
        let initialBgHex = rule.bgColor ?? rule.stashedBgColor
        _fgColor       = State(initialValue: initialFgHex.flatMap { Color(hex: $0) } ?? .yellow)
        _bgColor       = State(initialValue: initialBgHex.flatMap { Color(hex: $0) } ?? .black)
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
        _notify        = State(initialValue: rule.notify)
        _stashedFgHex  = State(initialValue: rule.stashedFgColor ?? rule.fgColor)
        _stashedBgHex  = State(initialValue: rule.stashedBgColor ?? rule.bgColor)
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
            groupId: groupId,
            stashedFgColor: stashedFgHex,
            stashedBgColor: stashedBgHex,
            notify: notify
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
                    .focused($matchTextFocused)
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
                colorRow(
                    title: "Text color",
                    isOn: $fgEnabled,
                    color: $fgColor,
                    stash: $stashedFgHex
                )
                colorRow(
                    title: "Background color",
                    isOn: $bgEnabled,
                    color: $bgColor,
                    stash: $stashedBgHex
                )
            }

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    inheritedToggle("Highlight entire line", isOn: $entireLine, inheritedKey: \.entireLine)
                    inheritedToggle("Case sensitive",        isOn: $caseSensitive, inheritedKey: \.caseSensitive)
                    inheritedToggle("Whole word only",       isOn: $wholeWord, inheritedKey: \.wholeWord)
                    Toggle("Regex pattern", isOn: $usesPattern)
                }
                VStack(alignment: .leading, spacing: 4) {
                    inheritedToggle("Bold",   isOn: $bold,   inheritedKey: \.bold)
                    inheritedToggle("Italic", isOn: $italic, inheritedKey: \.italic)
                    inheritedToggle("Notify on match", isOn: $notify, inheritedKey: \.notify)
                        .help("Posts a macOS notification with the matched game line when this rule fires. Per-rule throttle prevents flooding.")
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
        .onAppear {
            // When this rule was just created via "+ New highlight",
            // jump straight to typing the match text. Dispatched so
            // the field has finished mounting before we try to focus.
            if pendingFocusForId == rule.id {
                pendingFocusForId = nil
                DispatchQueue.main.async {
                    matchTextFocused = true
                }
            }
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

    /// Toggle that respects group inheritance: when the assigned
    /// group provides the same flag, the toggle is disabled and
    /// shown ON (so the user sees the effective state) with a
    /// tooltip explaining where it comes from. The rule's own
    /// underlying `@State` is preserved -- if the rule is later
    /// moved out of the group, its original setting comes back.
    private func inheritedToggle(
        _ title: String,
        isOn: Binding<Bool>,
        inheritedKey: KeyPath<HighlightGroup, Bool>
    ) -> some View {
        let inherited = parentGroup?[keyPath: inheritedKey] ?? false
        let display = Binding<Bool>(
            get: { isOn.wrappedValue || inherited },
            set: { newValue in
                // Only writes through when NOT inherited -- when the
                // group already provides this, the toggle is disabled
                // and any set is a no-op anyway, but keep it
                // defensive in case AppKit fires set() on a disabled
                // control during some state transition.
                if !inherited { isOn.wrappedValue = newValue }
            }
        )
        return Toggle(title, isOn: display)
            .disabled(inherited)
            .help(inherited
                  ? "Inherited from group \"\(parentGroup?.name ?? "")\". Move the rule out of the group to change."
                  : "")
    }

    /// Stash-aware color row. Toggling OFF moves the current color
    /// into the stash before clearing the active field; toggling ON
    /// restores from the stash (falling back to the picker's current
    /// `Color` when no stash exists). Dragging the picker keeps the
    /// stash in sync so the user's most recent pick is always what
    /// comes back on the next toggle-on. The stash is persisted on
    /// the Highlight (`stashedFgColor` / `stashedBgColor`), so this
    /// works across app restarts.
    private func colorRow(
        title: String,
        isOn: Binding<Bool>,
        color: Binding<Color>,
        stash: Binding<String?>
    ) -> some View {
        let wrappedToggle = Binding<Bool>(
            get: { isOn.wrappedValue },
            set: { newValue in
                if newValue {
                    if let s = stash.wrappedValue, let c = Color(hex: s) {
                        color.wrappedValue = c
                    }
                } else {
                    stash.wrappedValue = color.wrappedValue.hexString
                }
                isOn.wrappedValue = newValue
            }
        )
        let wrappedColor = Binding<Color>(
            get: { color.wrappedValue },
            set: { newValue in
                color.wrappedValue = newValue
                stash.wrappedValue = newValue.hexString
            }
        )
        return VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: wrappedToggle)
            ColorPicker("", selection: wrappedColor, supportsOpacity: false)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
                .opacity(isOn.wrappedValue ? 1 : 0.45)
        }
    }

    /// Test-panel renderer. Builds an AttributedString directly from
    /// the processor's output -- we deliberately avoid StoryTextView
    /// here because its reconcile path is optimized for the append-only
    /// game feed (revision-counter based) and silently drops updates
    /// when an existing line's text content mutates without the line
    /// count changing.
    private var testResultBlock: some View {
        Text(testResultAttributed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(GameTheme.background)
            .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            .environment(\.colorScheme, .dark)
            .textSelection(.enabled)
    }

    /// Draft rule with group-level styling merged in. The test pane
    /// has to honor inheritance just like the live renderer does --
    /// without this, a rule that inherits its color from a group
    /// (own fg unset) would render as plain text in the test pane and
    /// the counter would report "no match" because there'd be nothing
    /// styled to count, even when the regex genuinely matched.
    private var resolvedTestRule: Highlight {
        guard let g = parentGroup else { return draftHighlight }
        return HighlightResolver.resolve([draftHighlight], groups: [g]).first ?? draftHighlight
    }

    /// Runs the resolved draft rule over `testInput` and returns an
    /// AttributedString with highlight colors / bold / italic applied
    /// run-by-run. Multi-line input keeps its line breaks.
    private var testResultAttributed: AttributedString {
        var out = AttributedString()
        let rule = resolvedTestRule
        let inputLines = testInput.split(separator: "\n", omittingEmptySubsequences: false)
        for (i, raw) in inputLines.enumerated() {
            let inLine = RenderedLine(runs: [RenderedRun(text: String(raw), style: RunStyle())])
            let processed = HighlightProcessor.apply([rule], to: inLine)
            for run in processed.runs {
                var seg = AttributedString(run.text)
                var font: Font = .system(.body, design: .monospaced)
                if run.style.highlightBold { font = font.bold() }
                if run.style.italic        { font = font.italic() }
                seg.font = font
                if let hex = run.style.highlightFg, let c = Color(hex: hex) {
                    seg.foregroundColor = c
                } else {
                    seg.foregroundColor = GameTheme.foreground
                }
                if let hex = run.style.highlightBg, let c = Color(hex: hex) {
                    seg.backgroundColor = c
                }
                out += seg
            }
            if i < inputLines.count - 1 {
                out += AttributedString("\n")
            }
        }
        return out
    }

    /// Counts contiguous highlighted regions in `testInput` after the
    /// resolved draft rule is applied. Uses the real `HighlightProcessor`
    /// so the count is byte-identical to what would fire in the live
    /// game feed (including regex compile failures returning zero).
    ///
    /// Two important details:
    /// - Group inheritance is applied (via `resolvedTestRule`) before
    ///   counting, so a rule that gets its color from a group still
    ///   registers matches.
    /// - When the resolved rule has no visible styling at all (nothing
    ///   to mark a match with), a sentinel fg color is force-applied
    ///   just for the counter so the answer to "did my regex match?"
    ///   doesn't depend on whether the user has any styling configured.
    ///   The sentinel doesn't reach the visual render -- that uses
    ///   `resolvedTestRule` directly.
    private var testMatchCount: Int {
        guard !testInput.isEmpty else { return 0 }
        var ruleForCounting = resolvedTestRule
        if ruleForCounting.fgColor == nil
            && ruleForCounting.bgColor == nil
            && !ruleForCounting.bold
            && !ruleForCounting.italic {
            ruleForCounting.fgColor = "#000001"
        }
        var count = 0
        for rawLine in testInput.split(separator: "\n", omittingEmptySubsequences: false) {
            let input = RenderedLine(runs: [RenderedRun(text: String(rawLine), style: RunStyle())])
            let processed = HighlightProcessor.apply([ruleForCounting], to: input)
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
    @Binding var pendingFocusForId: UUID?
    let onDelete: () -> Void

    @FocusState private var nameFocused: Bool
    @State private var name: String
    @State private var fgColor: Color
    @State private var bgColor: Color
    @State private var fgEnabled: Bool
    @State private var bgEnabled: Bool
    @State private var bold: Bool
    @State private var italic: Bool
    @State private var entireLine: Bool
    @State private var caseSensitive: Bool
    @State private var wholeWord: Bool
    @State private var enabled: Bool
    @State private var notify: Bool
    @State private var didDelete: Bool = false
    @State private var stashedFgHex: String?
    @State private var stashedBgHex: String?

    init(group: HighlightGroup, store: HighlightStore, pendingFocusForId: Binding<UUID?>, onDelete: @escaping () -> Void) {
        self.group = group
        self.store = store
        self._pendingFocusForId = pendingFocusForId
        self.onDelete = onDelete
        _name      = State(initialValue: group.name)
        // Prefer active color, then stash, then default. Lets the
        // picker show the user's intended pick even when the toggle
        // is off, so toggling on restores it instantly.
        let initialFgHex = group.fgColor ?? group.stashedFgColor
        let initialBgHex = group.bgColor ?? group.stashedBgColor
        _fgColor   = State(initialValue: initialFgHex.flatMap { Color(hex: $0) } ?? .yellow)
        _bgColor   = State(initialValue: initialBgHex.flatMap { Color(hex: $0) } ?? .black)
        _fgEnabled = State(initialValue: group.fgColor != nil)
        _bgEnabled = State(initialValue: group.bgColor != nil)
        _bold          = State(initialValue: group.bold)
        _italic        = State(initialValue: group.italic)
        _entireLine    = State(initialValue: group.entireLine)
        _caseSensitive = State(initialValue: group.caseSensitive)
        _wholeWord     = State(initialValue: group.wholeWord)
        _enabled   = State(initialValue: group.enabled)
        _notify    = State(initialValue: group.notify)
        _stashedFgHex = State(initialValue: group.stashedFgColor ?? group.fgColor)
        _stashedBgHex = State(initialValue: group.stashedBgColor ?? group.bgColor)
    }

    private var draft: HighlightGroup {
        HighlightGroup(
            id: group.id,
            name: name,
            fgColor: fgEnabled ? fgColor.hexString : nil,
            bgColor: bgEnabled ? bgColor.hexString : nil,
            bold: bold,
            italic: italic,
            entireLine: entireLine,
            caseSensitive: caseSensitive,
            wholeWord: wholeWord,
            enabled: enabled,
            notify: notify,
            stashedFgColor: stashedFgHex,
            stashedBgColor: stashedBgHex
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
                    .focused($nameFocused)
            }

            HStack(spacing: 24) {
                colorRow(title: "Default text color", isOn: $fgEnabled, color: $fgColor, stash: $stashedFgHex)
                colorRow(title: "Default background", isOn: $bgEnabled, color: $bgColor, stash: $stashedBgHex)
            }
            Text("Member rules inherit these when their own color is unset.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Highlight entire line", isOn: $entireLine)
                    Toggle("Case sensitive",        isOn: $caseSensitive)
                    Toggle("Whole word only",       isOn: $wholeWord)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Bold",   isOn: $bold)
                    Toggle("Italic", isOn: $italic)
                }
            }
            Text("Members inherit these as defaults; a rule's own toggle adds to (but can't remove) what the group provides.")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Toggle("Notify on match", isOn: $notify)
                .help("Posts a macOS notification with the matched game line when any rule in this group fires. (Hooked up in a separate commit.)")

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
        .onAppear {
            // Auto-focus the Name field when this group was just
            // created via "+ New group". Dispatched so the field is
            // mounted before we try to focus.
            if pendingFocusForId == group.id {
                pendingFocusForId = nil
                DispatchQueue.main.async {
                    nameFocused = true
                }
            }
        }
    }

    /// Same stash-aware color row pattern as the rule detail uses;
    /// see the equivalent in `HighlightDetail` for the rationale.
    private func colorRow(
        title: String,
        isOn: Binding<Bool>,
        color: Binding<Color>,
        stash: Binding<String?>
    ) -> some View {
        let wrappedToggle = Binding<Bool>(
            get: { isOn.wrappedValue },
            set: { newValue in
                if newValue {
                    if let s = stash.wrappedValue, let c = Color(hex: s) {
                        color.wrappedValue = c
                    }
                } else {
                    stash.wrappedValue = color.wrappedValue.hexString
                }
                isOn.wrappedValue = newValue
            }
        )
        let wrappedColor = Binding<Color>(
            get: { color.wrappedValue },
            set: { newValue in
                color.wrappedValue = newValue
                stash.wrappedValue = newValue.hexString
            }
        )
        return VStack(alignment: .leading, spacing: 4) {
            Toggle(title, isOn: wrappedToggle)
            ColorPicker("", selection: wrappedColor, supportsOpacity: false)
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

