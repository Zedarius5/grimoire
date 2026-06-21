import SwiftUI
import GrimoireKit

/// Second window for managing custom highlights. Left: list of rules with
/// an enable toggle. Right: detail editor with live preview against a
/// canned sample paragraph.
/// Editor list selection. Either a rule or a group; the detail pane swaps
/// between the two editors accordingly.
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
    /// Collapsed group ids (tracking the negative since groups default to expanded).
    @State private var collapsedGroups: Set<UUID> = []
    /// Id of a freshly-created rule/group; the matching detail view consumes it
    /// on `.onAppear` to auto-focus its primary text field.
    @State private var pendingFocusForId: UUID? = nil

    /// One render's worth of list data, computed in a single pass so the
    /// filter + sort over all (~900) rules runs once per render rather than
    /// once per subview that needs a slice of it.
    ///
    /// `ordered` is the flat kind-filtered + searched + sorted list;
    /// `membersByGroup` and `ungrouped` are that same list partitioned
    /// by group affiliation. `matchCount`/`total` drive the count pill.
    private struct EditorLayout {
        var ordered: [Highlight] = []
        var membersByGroup: [UUID: [Highlight]] = [:]
        var ungrouped: [Highlight] = []
        var matchCount: Int = 0
        var total: Int = 0
    }

    /// Filter syntax:
    /// - Plain text: case-insensitive substring against the match text.
    /// - `tag:regex|line|case|word|bold|italic|fg|bg|enabled|disabled|`
    ///   `grouped|ungrouped|notify`: flag filter against the rule's own
    ///   setting -- except `notify`, which honors group inheritance
    ///   (see `ruleMatches` for the rationale).
    /// - Multiple space-separated terms AND together, so
    ///   `tag:regex death` finds regex rules whose text contains
    ///   "death".
    private func makeLayout() -> EditorLayout {
        let started = CFAbsoluteTimeGetCurrent()
        let kindFiltered = store.highlights.filter { $0.kind == listKind }
        var searched = kindFiltered
        if !filterText.isEmpty {
            let groupsById = Dictionary(uniqueKeysWithValues: store.groups.map { ($0.id, $0) })
            let terms = filterText
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            searched = kindFiltered.filter { rule in
                terms.allSatisfy { ruleMatches(rule, term: $0, groups: groupsById) }
            }
        }
        let ordered = sortOrder.apply(to: searched)

        var layout = EditorLayout(
            ordered: ordered,
            matchCount: ordered.count,
            total: kindFiltered.count
        )
        for rule in ordered {
            if let gid = rule.groupId {
                layout.membersByGroup[gid, default: []].append(rule)
            } else {
                layout.ungrouped.append(rule)
            }
        }

        // This must stay cheap (one pass per render); log if it ever creeps up.
        let ms = (CFAbsoluteTimeGetCurrent() - started) * 1000
        if ms > 3 {
            appLog("HighlightEditor",
                   "makeLayout \(String(format: "%.1f", ms))ms"
                   + " (\(layout.total) rules, filter=\(!filterText.isEmpty))",
                   level: .info)
        }
        return layout
    }

    private func ruleMatches(_ rule: Highlight, term: String, groups: [UUID: HighlightGroup]) -> Bool {
        let lower = term.lowercased()
        if lower.hasPrefix("tag:") {
            let tag = String(lower.dropFirst(4))
            // Tags check the rule's OWN field, not inherited values, so they
            // surface explicit overrides (the sidebar badges show resolved
            // state). Exception: `notify` honors group inheritance, since it
            // answers "which rules will actually fire a notification?".
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
            case "notify":
                return rule.notify
                    || (rule.groupId.flatMap { groups[$0] }?.notify ?? false)
            default:          return false  // unknown tag matches nothing (strict)
            }
        }
        return rule.text.localizedCaseInsensitiveContains(term)
    }

    private var visibleGroups: [HighlightGroup] {
        store.groups
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
            // Start collapsed so a large grouped rule set opens as a compact
            // list of group headers rather than a wall of nested rules.
            collapsedGroups = Set(store.groups.map(\.id))
            if selection == nil, let first = makeLayout().ordered.first {
                selection = .rule(first.id)
            }
        }
        .onChange(of: listKind) { _, _ in
            selection = makeLayout().ordered.first.map { .rule($0.id) }
        }
    }

    // MARK: - List

    private var list: some View {
        // Single pass per render; subviews read from this. See `makeLayout()`.
        let layout = makeLayout()
        return VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text("Highlights").font(.headline)
                Spacer()
                Text(countLabel(layout))
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
                    let members = layout.membersByGroup[group.id] ?? []
                    groupHeaderRow(group, memberCount: members.count)
                        .tag(HighlightSelection.group(group.id))
                    if !collapsedGroups.contains(group.id) {
                        ForEach(members) { rule in
                            ruleRow(rule, indented: true)
                                .tag(HighlightSelection.rule(rule.id))
                        }
                    }
                }
                if !layout.ungrouped.isEmpty {
                    if !visibleGroups.isEmpty {
                        // Divider between the grouped section and loose rules.
                        Text("Ungrouped")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                    ForEach(layout.ungrouped) { rule in
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

    /// Plain TextField rather than `.searchable`: the editor lives in an
    /// HSplitView (not a NavigationStack), where `.searchable` doesn't anchor
    /// cleanly to the left list pane.
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
                ungrouped, notify. Multiple terms AND together — e.g. tag:fg \
                tag:grouped finds rules in a group that have their own \
                text color override. tag:notify is the exception to the \
                own-setting rule: it matches every rule that will fire a \
                notification, including ones inheriting it from their group.
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

    /// Group header row: selectable like a rule, with a chevron to toggle
    /// expansion and a context menu for add/delete.
    @ViewBuilder
    private func groupHeaderRow(_ group: HighlightGroup, memberCount: Int) -> some View {
        let isExpanded = !collapsedGroups.contains(group.id)
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

    /// Optional left-indent when shown nested under a group header. Group
    /// reassignment is done via the dropdown in `HighlightDetail`, not here.
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

    /// `groupId` of the selected item; a freshly-added rule joins that group
    /// (or lands ungrouped when nothing relevant is selected).
    private var selectedGroupId: UUID? {
        switch selection {
        case .group(let id): return id
        case .rule(let id):  return store.highlights.first(where: { $0.id == id })?.groupId
        case .none:          return nil
        }
    }

    /// Small uppercase pill for the group header. Mirrors `HighlightRow.badge`.
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
        // Start with empty text (the "(no text)" placeholder + field prompt
        // cover the gap) so the user can type immediately.
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

    /// Count display in the list header: total, or `matches / total` while a
    /// filter is active.
    private func countLabel(_ layout: EditorLayout) -> String {
        if filterText.isEmpty { return "\(layout.total)" }
        return "\(layout.matchCount)/\(layout.total)"
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
            // The file importer hands back a security-scoped URL on sandboxed
            // builds (a no-op under ad-hoc dev signing); wrapping is correct either way.
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

/// Order options for the highlight list. `.insertion` is the save order, which
/// is also the render-time match priority ("later rules win on overlap"); keep
/// it the default so that mental model holds when not actively sorting.
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
            // Group same-colored rules together; rules with no fg color sink
            // to the end. Within a color, text order keeps the result stable.
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
/// `Highlight` hasn't changed; keeping it out of the parent's closure avoids
/// O(rules²) lookups per re-render that stall the editor at large rule counts.
///
/// `parentGroup` is the row's group (when nested) so the inline sample renders
/// with group inheritance applied, matching what the game feed will display.
private struct HighlightRow: View {
    let rule: Highlight
    let parentGroup: HighlightGroup?
    let onToggleEnabled: (Bool) -> Void

    /// Rule with group inheritance applied. Inline sample + B/I badges read
    /// from this; CASE/WORD/REGEX/LINE badges read the rule's own config.
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
            // Matching/display flags reflect group inheritance, matching what
            // fires at render time.
            if r.entireLine    { badge("LINE") }
            if r.caseSensitive { badge("CASE") }
            if r.wholeWord     { badge("WORD") }
            if r.bold          { badge("bold") }
            if r.italic        { badge("italic") }
            if r.notify        { badge("NOTIFY") }
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
    /// Last-chosen fg / bg, persisted on the Highlight so toggling a color off
    /// doesn't destroy the previous pick.
    @State private var stashedFgHex: String?
    @State private var stashedBgHex: String?
    /// Set when deleted via the trash button. Suppresses the `.onDisappear`
    /// flush so the local draft doesn't resurrect the deleted rule.
    @State private var didDelete: Bool = false
    /// Scratch input for the test panel. Not persisted.
    @State private var testInput: String = ""

    init(rule: Highlight, store: HighlightStore, pendingFocusForId: Binding<UUID?>, onDelete: @escaping () -> Void) {
        self.rule = rule
        self.store = store
        self._pendingFocusForId = pendingFocusForId
        self.onDelete = onDelete
        _text          = State(initialValue: rule.text)
        // Picker reflects the last intended pick: active fg, then stash, then
        // default -- so flipping a disabled color toggle on restores it instantly.
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

    /// Form state as a Highlight, without going through `store` — keeps the
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
            // Group reassignment commits live: a single discrete action with
            // no per-keystroke cascade, so the sidebar reflects the move at once.
            store.update(draftHighlight)
        }
        .onAppear {
            // Auto-focus the match field for a just-created rule. Dispatched so
            // the field has mounted before we focus.
            if pendingFocusForId == rule.id {
                pendingFocusForId = nil
                DispatchQueue.main.async {
                    matchTextFocused = true
                }
            }
        }
        .onDisappear {
            // Modal commit: edits stay local @State and only propagate to the
            // store when this view leaves the hierarchy, which avoids a
            // per-keystroke @Published cascade through the engine.
            // Skip the flush after a delete, or the draft would resurrect the row.
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

    /// Live-validates the current pattern. True for non-regex and empty-text
    /// regex rules; only flags actual ICU compile failures.
    private var patternIsValid: Bool {
        guard usesPattern, !text.isEmpty else { return true }
        return (try? NSRegularExpression(pattern: text)) != nil
    }

    /// Toggle that respects group inheritance: when the group provides the
    /// flag, the toggle is disabled and shown ON (the effective state), while
    /// the rule's own @State is preserved for if it later leaves the group.
    private func inheritedToggle(
        _ title: String,
        isOn: Binding<Bool>,
        inheritedKey: KeyPath<HighlightGroup, Bool>
    ) -> some View {
        let inherited = parentGroup?[keyPath: inheritedKey] ?? false
        let display = Binding<Bool>(
            get: { isOn.wrappedValue || inherited },
            set: { newValue in
                // Write through only when not inherited; defensive against
                // AppKit firing set() on the disabled control.
                if !inherited { isOn.wrappedValue = newValue }
            }
        )
        return Toggle(title, isOn: display)
            .disabled(inherited)
            .help(inherited
                  ? "Inherited from group \"\(parentGroup?.name ?? "")\". Move the rule out of the group to change."
                  : "")
    }

    /// Stash-aware color row. Toggling OFF stashes the current color before
    /// clearing the active field; toggling ON restores it. Dragging the picker
    /// keeps the stash in sync. The stash persists on the Highlight, so this
    /// survives app restarts.
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

    /// Test-panel renderer. Builds an AttributedString directly rather than
    /// using StoryTextView, whose revision-counter reconcile is tuned for the
    /// append-only feed and drops updates when a line's text mutates without
    /// the line count changing.
    private var testResultBlock: some View {
        Text(testResultAttributed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(GameTheme.background)
            .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            .environment(\.colorScheme, .dark)
            .textSelection(.enabled)
    }

    /// Draft rule with group-level styling merged in. The test pane must honor
    /// inheritance like the live renderer; otherwise a rule inheriting its
    /// color from a group renders plain and the counter falsely reports "no match".
    private var resolvedTestRule: Highlight {
        guard let g = parentGroup else { return draftHighlight }
        return HighlightResolver.resolve([draftHighlight], groups: [g]).first ?? draftHighlight
    }

    /// Runs the resolved draft rule over `testInput`, returning an
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

    /// Counts contiguous highlighted regions in `testInput`, using the real
    /// `HighlightProcessor` so the count matches the live feed (including
    /// regex compile failures counting as zero).
    ///
    /// Group inheritance is applied via `resolvedTestRule` so a rule colored
    /// by its group still registers. When the resolved rule has no visible
    /// styling, a sentinel fg is force-applied for counting only (not the
    /// visual render) so "did my regex match?" doesn't depend on configured styling.
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

    /// Renders a canned sample through the same NSTextView pipeline the live
    /// feed uses, with this draft rule pinned in, so the preview is
    /// byte-identical to in-game with no parallel rendering path to keep in sync.
    /// Reads `draftHighlight` directly; the per-keystroke reconcile stays local
    /// to this view and is sub-ms for a handful of sample lines.
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

/// Edits a `HighlightGroup`'s name, default colors, trait additions, and
/// enabled/notify toggles. Modal-commit on disappear (like `HighlightDetail`)
/// so typing doesn't cascade through the engine.
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
        // Active color, then stash, then default -- so flipping a disabled
        // toggle on restores the intended pick.
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
            // Auto-focus the Name field for a just-created group. Dispatched so
            // the field has mounted before we focus.
            if pendingFocusForId == group.id {
                pendingFocusForId = nil
                DispatchQueue.main.async {
                    nameFocused = true
                }
            }
        }
    }

    /// Stash-aware color row; see `HighlightDetail.colorRow` for the rationale.
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

/// Canned sample lines for the editor's preview. Appends the current match
/// text so the rule visibly fires before it's typed into the game.
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

