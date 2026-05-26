import SwiftUI
import GrimoireKit

/// Window for managing per-spell visual overrides across the four
/// timer dialogs (Active Spells / Buffs / Cooldowns / Debuffs).
///
/// Each window is configured independently and holds three things:
/// a **default styling** that applies to every bar in that window, an
/// optional set of **groups** that bundle related spells under one
/// styling, and the **individual spell presets** that override the
/// other two. Resolution order at render time is spell → group →
/// default → hardcoded fallback.
struct SpellPresetEditorView: View {
    @EnvironmentObject var store: SpellPresetStore
    @EnvironmentObject var client: LichClient

    /// Currently-selected window tab. Drives both the list contents
    /// and the active-bars picker.
    @State private var currentWindow: DialogWindow = .buffs
    @State private var selected: SelectedItem = .defaultStyling
    @State private var showingActivePicker: Bool = false
    @State private var addByIdText: String = ""
    @State private var addingGroup: Bool = false
    @State private var newGroupName: String = ""
    @State private var importing: Bool = false
    @State private var importStatus: String? = nil
    @State private var pendingImport: PendingImport? = nil
    /// Group IDs the user has expanded. Collapsed by default — group
    /// rows show their member count, click the chevron to reveal.
    /// Per-session, not persisted.
    @State private var expandedGroups: Set<UUID> = []

    /// Cursor into the per-window list, distinguishing the default
    /// row, a group row, or a spell preset row. `SwiftUI.List` keys
    /// selection on `Hashable`, so this needs to be hashable.
    enum SelectedItem: Hashable {
        case defaultStyling
        case group(UUID)
        case preset(UUID)
    }

    private struct PendingImport: Identifiable {
        let id = UUID()
        let fileName: String
        let windows: [TimersProfileImporter.ParsedWindow]
    }

    private var windowConfig: WindowConfig {
        store.windowConfig(for: currentWindow)
    }

    var body: some View {
        VStack(spacing: 0) {
            windowPicker
            Divider()
            HSplitView {
                list
                    .frame(minWidth: 280)
                detail
                    .frame(minWidth: 500)
            }
        }
        .frame(minWidth: 820, minHeight: 560)
        .fileImporter(
            isPresented: $importing,
            allowedContentTypes: [.plainText, .text, .data],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .sheet(item: $pendingImport) { pending in
            ImportTargetSheet(
                fileName: pending.fileName,
                windows: pending.windows,
                onChoose: { source, target, replace in
                    let presets = source
                        .map { $0.presets }
                        ?? TimersProfileImporter.merge(pending.windows)
                    applyImport(
                        presets: presets,
                        fileName: pending.fileName,
                        sourceLabel: source?.name ?? "all windows merged",
                        target: target,
                        replaceExisting: replace
                    )
                    pendingImport = nil
                },
                onCancel: { pendingImport = nil }
            )
        }
    }

    // MARK: - Window picker

    private var windowPicker: some View {
        HStack(spacing: 12) {
            Picker("", selection: $currentWindow) {
                ForEach(DialogWindow.allCases) { w in
                    Text(w.displayName).tag(w)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 480)
            Spacer()
            if let status = importStatus {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .onChange(of: currentWindow) { _, _ in
            // Reset selection when switching tabs so the detail pane
            // doesn't hold onto a stale group/preset UUID from a
            // different window.
            selected = .defaultStyling
        }
    }

    // MARK: - List

    private var list: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Text(currentWindow.displayName).font(.headline)
                Spacer()
                Text("\(windowConfig.presets.count)")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                Button {
                    importing = true
                } label: { Image(systemName: "square.and.arrow.down") }
                    .buttonStyle(.borderless)
                    .help("Import a Lich `Timers Profile <name>.txt` file into the selected window.")
                Button {
                    addingGroup = true
                } label: { Image(systemName: "folder.badge.plus") }
                    .buttonStyle(.borderless)
                    .help("Add a new group — bundle related spells under one styling.")
                Button {
                    showingActivePicker = true
                } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .help("Add a preset from a currently-active bar, or by spell ID.")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(selection: $selected) {
                defaultRow.tag(SelectedItem.defaultStyling)

                // Each group renders its header, then its members
                // inline & indented when expanded. Keeps assigned
                // spells visually grouped under the group they belong
                // to, instead of getting lost in a flat list.
                ForEach(windowConfig.groups) { group in
                    groupHeaderRow(group).tag(SelectedItem.group(group.id))
                    if expandedGroups.contains(group.id) {
                        ForEach(membersOf(group)) { preset in
                            presetRow(preset, indented: true).tag(SelectedItem.preset(preset.id))
                        }
                    }
                }

                let ungrouped = windowConfig.presets.filter { $0.groupId == nil }
                if !ungrouped.isEmpty {
                    ForEach(ungrouped) { preset in
                        presetRow(preset).tag(SelectedItem.preset(preset.id))
                    }
                }
            }
            .listStyle(.inset)
        }
        .popover(isPresented: $showingActivePicker, arrowEdge: .bottom) { addPopover }
        .popover(isPresented: $addingGroup, arrowEdge: .bottom) { addGroupPopover }
    }

    @ViewBuilder
    private var defaultRow: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(windowConfig.defaultStyling.barColor.flatMap(Color.init(hex:)) ?? Color.blue)
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text("Window default")
                    .font(.system(size: 13))
                Text("Applies to all bars in \(currentWindow.displayName)")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func groupHeaderRow(_ group: SpellGroup) -> some View {
        let memberCount = membersOf(group).count
        let isExpanded = expandedGroups.contains(group.id)
        HStack(spacing: 6) {
            Button {
                toggleExpansion(group.id)
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, height: 14)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isExpanded ? "Collapse group" : "Expand group")

            Circle()
                .fill(group.styling.barColor.flatMap(Color.init(hex:)) ?? Color.purple)
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text(group.name.isEmpty ? "Unnamed group" : group.name)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Text("\(memberCount) \(memberCount == 1 ? "member" : "members")")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !group.enabled { badge("OFF") }
        }
    }

    @ViewBuilder
    private func presetRow(_ preset: SpellPreset, indented: Bool = false) -> some View {
        HStack(spacing: 8) {
            if indented {
                // Visual nesting under an expanded group. Sized to
                // line up with the group's text column (chevron + dot
                // + small gap).
                Color.clear.frame(width: 20, height: 1)
            }
            Circle()
                .fill(rowBarColor(for: preset))
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 1) {
                Text(rowLabel(for: preset))
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text("id: \(preset.spellId)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if preset.styling.hidden { badge("HIDE") }
            if !preset.enabled       { badge("OFF") }
        }
    }

    private func membersOf(_ group: SpellGroup) -> [SpellPreset] {
        windowConfig.presets.filter { $0.groupId == group.id }
    }

    private func toggleExpansion(_ id: UUID) {
        if expandedGroups.contains(id) {
            expandedGroups.remove(id)
        } else {
            expandedGroups.insert(id)
        }
    }

    /// Display label for a preset row. Priority:
    ///  1. User's display-name override (always wins — explicit intent).
    ///  2. Live in-game text from `client.dialogs` (covers active spells).
    ///  3. Lich's cached spell-name database — `~/Gemstone/data/effect-list.xml`,
    ///     populated by Lich the same way `Spell[id].name` resolves in
    ///     timers.lic. Means the editor shows real names even when
    ///     disconnected, for any spell Lich has ever seen.
    ///  4. "Spell #ID" — last resort, for cooldowns/ability ids that
    ///     don't appear in the spell database.
    private func rowLabel(for preset: SpellPreset) -> String {
        if let custom = preset.displayName, !custom.isEmpty { return custom }
        if let live = liveSpellName(spellId: preset.spellId), !live.isEmpty { return live }
        if let cached = store.spellNames.name(forId: preset.spellId), !cached.isEmpty { return cached }
        return "Spell #\(preset.spellId)"
    }

    /// Resolved bar-fill colour for the row's status dot. Pulls
    /// through the same spell → group → window-default fall-through
    /// the render path uses, so a preset assigned to a group with a
    /// red bar shows a red dot even when the preset itself sets no
    /// `barColor`.
    private func rowBarColor(for preset: SpellPreset) -> Color {
        let resolved = windowConfig.resolve(spellId: preset.spellId)
        return resolved.barColor.flatMap(Color.init(hex:)) ?? Color.blue
    }

    /// Searches every live dialog (not just the current window's) for
    /// a progressBar whose id matches. Returns its `text` so the
    /// editor can show real spell names. Walks all dialogs because a
    /// spell may surface in multiple ones (Buffs *and* Active Spells)
    /// and we want a name from any of them.
    private func liveSpellName(spellId: String) -> String? {
        for dialog in client.dialogs.values {
            for widget in dialog.widgets {
                if case let .progressBar(id, _, text, _, _) = widget,
                   id == spellId, !text.isEmpty {
                    return text
                }
            }
        }
        return nil
    }

    /// Label for one row in the "Currently active" picker. Falls back
    /// to the Lich spell database when the live bar's text is empty
    /// (some cooldowns surface as just an ID with no `text` attr).
    private func pickerLabel(for bar: ActiveBar) -> String {
        if !bar.text.isEmpty { return bar.text }
        if let cached = store.spellNames.name(forId: bar.spellId), !cached.isEmpty { return cached }
        return "(unnamed)"
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

    // MARK: - Add popovers

    private struct ActiveBar: Identifiable {
        let spellId: String
        let text: String
        var id: String { spellId }
    }

    /// Active bars from the currently-selected window's dialog. Filters
    /// out spell ids that already have a preset so the picker can't
    /// create duplicates.
    private var activeProgressBars: [ActiveBar] {
        let existing = Set(windowConfig.presets.map(\.spellId))
        guard let dialog = client.dialogs[currentWindow.dialogId] else { return [] }
        return dialog.widgets.compactMap { widget -> ActiveBar? in
            if case let .progressBar(id, _, text, _, _) = widget,
               !id.isEmpty, !existing.contains(id) {
                return ActiveBar(spellId: id, text: text)
            }
            return nil
        }
        .sorted { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending }
    }

    private var addPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add to \(currentWindow.displayName)").font(.headline)

            let active = activeProgressBars
            if !active.isEmpty {
                Text("Currently active")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(active) { item in
                            Button {
                                let preset = store.addPreset(spellId: item.spellId, in: currentWindow)
                                selected = .preset(preset.id)
                                showingActivePicker = false
                            } label: {
                                HStack {
                                    Text(pickerLabel(for: item))
                                        .lineLimit(1)
                                    Spacer()
                                    Text(item.spellId)
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 220)
                .background(Color.black.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                Divider()
            } else {
                Text("No active bars in \(currentWindow.displayName) right now.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Text("Add by ID")
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundStyle(.secondary)
            HStack {
                TextField("e.g. 730, 5315", text: $addByIdText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                Button("Add") {
                    let id = addByIdText.trimmingCharacters(in: .whitespaces)
                    guard !id.isEmpty else { return }
                    let preset = store.addPreset(spellId: id, in: currentWindow)
                    selected = .preset(preset.id)
                    addByIdText = ""
                    showingActivePicker = false
                }
                .disabled(addByIdText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 320)
    }

    private var addGroupPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New group in \(currentWindow.displayName)").font(.headline)
            TextField("e.g. Sunfist Sigils", text: $newGroupName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)
            Text("Groups bundle related spells under one styling. Open a spell preset and assign it to this group to apply the group's look.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: 260, alignment: .leading)
            HStack {
                Spacer()
                Button("Cancel") { addingGroup = false }
                Button("Add") {
                    let name = newGroupName.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    let group = store.addGroup(name: name, in: currentWindow)
                    selected = .group(group.id)
                    newGroupName = ""
                    addingGroup = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 300)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detail: some View {
        switch selected {
        case .defaultStyling:
            DefaultStylingDetail(
                styling: Binding(
                    get: { windowConfig.defaultStyling },
                    set: { store.updateDefaultStyling($0, in: currentWindow) }
                ),
                window: currentWindow
            )
            .padding(16)
        case .group(let id):
            if let group = windowConfig.groups.first(where: { $0.id == id }) {
                let memberCount = windowConfig.presets.filter { $0.groupId == id }.count
                GroupDetail(
                    group: group,
                    memberCount: memberCount,
                    store: store,
                    window: currentWindow,
                    onDelete: {
                        let next = nextSelection(after: .group(id))
                        store.removeGroup(id: id, in: currentWindow)
                        selected = next
                    }
                )
                .id(id)
                .padding(16)
            } else {
                emptyDetail
            }
        case .preset(let id):
            if let preset = windowConfig.presets.first(where: { $0.id == id }) {
                PresetDetail(
                    preset: preset,
                    groups: windowConfig.groups,
                    store: store,
                    window: currentWindow,
                    onDelete: {
                        let next = nextSelection(after: .preset(id))
                        store.removePreset(id: id, in: currentWindow)
                        selected = next
                    }
                )
                .id(id)
                .padding(16)
            } else {
                emptyDetail
            }
        }
    }

    /// Visible row sequence in the sidebar — `.defaultStyling`, then
    /// each group (with its members if expanded), then ungrouped
    /// presets. Used to pick the next selection after a delete so the
    /// user lands on the row that takes the deleted one's place
    /// instead of getting bounced to the default styling.
    private var visibleSelectionSequence: [SelectedItem] {
        var seq: [SelectedItem] = [.defaultStyling]
        for group in windowConfig.groups {
            seq.append(.group(group.id))
            if expandedGroups.contains(group.id) {
                for preset in membersOf(group) {
                    seq.append(.preset(preset.id))
                }
            }
        }
        for preset in windowConfig.presets where preset.groupId == nil {
            seq.append(.preset(preset.id))
        }
        return seq
    }

    /// Picks the next sensible selection after `item` is deleted.
    /// Prefers the row immediately following `item` in the list, falls
    /// back to the row before, and resorts to `.defaultStyling` only
    /// when nothing else is selectable.
    private func nextSelection(after item: SelectedItem) -> SelectedItem {
        let seq = visibleSelectionSequence
        guard let idx = seq.firstIndex(of: item) else { return .defaultStyling }
        // Skip the deleted item itself; if it had members (expanded
        // group), skip them too since they vanish with the group.
        var skip = 1
        if case .group(let gid) = item, expandedGroups.contains(gid) {
            skip += membersOf(windowConfig.groups.first { $0.id == gid }!).count
        }
        let afterIdx = idx + skip
        if afterIdx < seq.count { return seq[afterIdx] }
        if idx > 0 { return seq[idx - 1] }
        return .defaultStyling
    }

    private var emptyDetail: some View {
        VStack(spacing: 6) {
            Spacer()
            Text("Select an item to edit.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Import flow

    private func handleImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            let didScope = url.startAccessingSecurityScopedResource()
            defer { if didScope { url.stopAccessingSecurityScopedResource() } }
            let content = try String(contentsOf: url, encoding: .utf8)
            let windows = TimersProfileImporter.parseWindows(content)
            guard !windows.isEmpty else {
                importStatus = "No spell entries found in \(url.lastPathComponent)"
                return
            }
            pendingImport = PendingImport(
                fileName: url.lastPathComponent,
                windows: windows
            )
        } catch {
            importStatus = "Import failed: \(error.localizedDescription)"
        }
    }

    private func applyImport(
        presets: [SpellPreset],
        fileName: String,
        sourceLabel: String,
        target: DialogWindow,
        replaceExisting: Bool
    ) {
        if replaceExisting {
            store.clearWindow(target)
        }
        let result = store.importPresets(presets, into: target)
        currentWindow = target
        if let first = store.windowConfig(for: target).presets
            .first(where: { p in presets.contains(where: { $0.spellId == p.spellId }) }) {
            selected = .preset(first.id)
        }
        let action = replaceExisting
            ? "Replaced — \(result.added) presets"
            : "Imported \(result.added) new, updated \(result.updated)"
        importStatus = "\(action) from \(fileName) (\(sourceLabel) → \(target.displayName))"
    }
}

// MARK: - Default styling detail

private struct DefaultStylingDetail: View {
    @Binding var styling: SpellStyling
    let window: DialogWindow

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Window default").font(.title3.bold())
                    Text("Applies to every \(window.displayName) bar unless overridden by a group or per-spell preset.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview").font(.subheadline.bold())
                    // Default layer has no parents — its own styling
                    // *is* the resolved styling.
                    StylingPreview(
                        resolved: resolvePreview(defaultStyling: styling),
                        displayName: "Sample Spell"
                    )
                }

                Divider()
                StylingFieldsSection(styling: $styling)
            }
        }
    }
}

// MARK: - Group detail

private struct GroupDetail: View {
    let group: SpellGroup
    let memberCount: Int
    let store: SpellPresetStore
    let window: DialogWindow
    let onDelete: () -> Void

    @State private var name: String
    @State private var enabled: Bool
    @State private var styling: SpellStyling

    init(group: SpellGroup, memberCount: Int, store: SpellPresetStore, window: DialogWindow, onDelete: @escaping () -> Void) {
        self.group = group
        self.memberCount = memberCount
        self.store = store
        self.window = window
        self.onDelete = onDelete
        _name    = State(initialValue: group.name)
        _enabled = State(initialValue: group.enabled)
        _styling = State(initialValue: group.styling)
    }

    private var draft: SpellGroup {
        SpellGroup(id: group.id, name: name, styling: styling, enabled: enabled)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Group").font(.system(size: 10, weight: .semibold)).tracking(0.6).foregroundStyle(.secondary)
                        TextField("Group name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                        Text("\(memberCount) \(memberCount == 1 ? "spell" : "spells") use this group. Assign more from any spell's detail pane.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    Toggle("Enabled", isOn: $enabled)
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview").font(.subheadline.bold())
                    // Group styling layered over the window default,
                    // so a group with no `troughColor` inherits the
                    // window's trough in the preview — matching how
                    // it'll render on member bars in-feed.
                    StylingPreview(
                        resolved: resolvePreview(
                            group: SpellGroup(id: group.id, name: name, styling: styling, enabled: enabled),
                            defaultStyling: store.windowConfig(for: window).defaultStyling
                        ),
                        displayName: name.isEmpty ? "Group" : name
                    )
                }

                Divider()
                StylingFieldsSection(
                    styling: $styling,
                    inheritanceLabel: "Inheriting from \(window.displayName) default"
                )
            }
        }
        .onChange(of: draft) { _, new in
            store.updateGroup(new, in: window)
        }
    }
}

// MARK: - Preset detail

private struct PresetDetail: View {
    let preset: SpellPreset
    let groups: [SpellGroup]
    let store: SpellPresetStore
    let window: DialogWindow
    let onDelete: () -> Void

    @State private var displayName: String
    @State private var enabled: Bool
    @State private var groupId: UUID?
    @State private var styling: SpellStyling

    init(preset: SpellPreset, groups: [SpellGroup], store: SpellPresetStore, window: DialogWindow, onDelete: @escaping () -> Void) {
        self.preset = preset
        self.groups = groups
        self.store = store
        self.window = window
        self.onDelete = onDelete
        _displayName = State(initialValue: preset.displayName ?? "")
        _enabled     = State(initialValue: preset.enabled)
        _groupId     = State(initialValue: preset.groupId)
        _styling     = State(initialValue: preset.styling)
    }

    private var draft: SpellPreset {
        SpellPreset(
            id: preset.id,
            spellId: preset.spellId,
            groupId: groupId,
            displayName: displayName.isEmpty ? nil : displayName,
            styling: styling,
            enabled: enabled
        )
    }

    /// Name shown in the preview when the user hasn't typed a custom
    /// display name. Falls through to Lich's spell-name database
    /// (`Spell[id].name` equivalent) before resorting to "Spell #ID".
    private var previewName: String {
        if !displayName.isEmpty { return displayName }
        if let cached = store.spellNames.name(forId: preset.spellId), !cached.isEmpty {
            return cached
        }
        return "Spell #\(preset.spellId)"
    }

    /// Resolved styling for the preview — layers the draft spell
    /// styling over its (currently-selected) group's styling and the
    /// window default. This matches the live-render resolution path,
    /// so toggling a field's "use default" knob in the form makes the
    /// preview immediately switch to the inherited colour/size.
    private var resolvedDraft: ResolvedSpellStyling {
        let group = groupId.flatMap { gid in groups.first(where: { $0.id == gid }) }
        return resolvePreview(
            spell: styling,
            spellEnabled: enabled,
            spellDisplayName: displayName.isEmpty ? nil : displayName,
            group: group,
            defaultStyling: store.windowConfig(for: window).defaultStyling
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview").font(.subheadline.bold())
                    StylingPreview(
                        resolved: resolvedDraft,
                        displayName: previewName
                    )
                }

                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Display name").font(.subheadline.bold())
                    TextField("e.g. TAP Robe", text: $displayName)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Text("Leave blank to use the server's text.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                if !groups.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Group").font(.subheadline.bold())
                        Picker("", selection: $groupId) {
                            Text("None").tag(UUID?.none)
                            ForEach(groups) { group in
                                Text(group.name.isEmpty ? "Unnamed group" : group.name).tag(UUID?.some(group.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                        Text("This spell inherits unset fields from the group's styling.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                Divider()
                StylingFieldsSection(
                    styling: $styling,
                    inheritanceLabel: presetInheritanceLabel
                )
            }
        }
        .onChange(of: draft) { _, new in
            store.updatePreset(new, in: window)
        }
    }

    /// "Inheriting from group X" if a group is assigned and named,
    /// else "Inheriting from <window> default". Drives the inline hint
    /// next to a disabled color toggle so the user knows where the
    /// inherited value will come from.
    private var presetInheritanceLabel: String {
        if let gid = groupId,
           let g = groups.first(where: { $0.id == gid }),
           !g.name.isEmpty {
            return "Inheriting from group \"\(g.name)\""
        }
        return "Inheriting from \(window.displayName) default"
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Spell ID")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(preset.spellId)
                    .font(.system(.title3, design: .monospaced))
            }
            Spacer()
            Toggle("Enabled", isOn: $enabled)
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Reusable styling form

/// The colour / size / duration / hide-bar fields, common to default
/// styling, group styling, and per-spell preset styling.
private struct StylingFieldsSection: View {
    @Binding var styling: SpellStyling
    /// Optional hint shown next to a color row whose toggle is off.
    /// Caller knows the inheritance chain for its layer (group →
    /// window default, preset → group → window default). Pass nil from
    /// the default-styling form (nothing to inherit from).
    var inheritanceLabel: String? = nil

    /// Last non-nil hex per color field. Lets the user toggle a color
    /// off (revert to inherited) and back on without losing the value
    /// they picked. Seeded from the binding on first appear.
    @State private var stashedBarColor: String? = nil
    @State private var stashedTroughColor: String? = nil
    @State private var stashedTextColor: String? = nil
    @State private var stashedFontSize: Double? = nil
    @State private var stashedBarHeight: Double? = nil
    @State private var stashedFullBarSeconds: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Appearance").font(.subheadline.bold())
                colorRow(title: "Bar fill",  keyPath: \.barColor,    fallback: .blue,  stash: $stashedBarColor)
                colorRow(title: "Trough",    keyPath: \.troughColor, fallback: .black, stash: $stashedTroughColor)
                colorRow(title: "Text",      keyPath: \.textColor,   fallback: .white, stash: $stashedTextColor)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Sizing").font(.subheadline.bold())
                sliderRow(
                    title: "Font size",
                    keyPath: \.fontSize,
                    range: 8...20,
                    defaultValue: 13,
                    format: { "\(Int($0))pt" },
                    stash: $stashedFontSize
                )
                sliderRow(
                    title: "Bar height",
                    keyPath: \.barHeight,
                    range: 14...60,
                    defaultValue: 18,
                    format: { "\(Int($0))pt" },
                    help: "Taller bars stand out — useful for spells that mustn't be allowed to expire.",
                    stash: $stashedBarHeight
                )
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("Duration").font(.subheadline.bold())
                durationFieldRow(
                    title: "Custom full bar",
                    keyPath: \.fullBarSeconds,
                    defaultValue: 60,
                    stash: $stashedFullBarSeconds
                )
                Text("Overrides the dialog's window for matching bars. Accepts `3:30`, `5m 10s`, `90s`, or plain seconds.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Divider()

            Toggle("Hide bar", isOn: $styling.hidden)
        }
        .onAppear {
            // Seed every stash from the live styling so toggling a
            // field off-then-on restores its prior value instead of
            // jumping back to the hardcoded fallback default.
            if stashedBarColor        == nil { stashedBarColor        = styling.barColor }
            if stashedTroughColor     == nil { stashedTroughColor     = styling.troughColor }
            if stashedTextColor       == nil { stashedTextColor       = styling.textColor }
            if stashedFontSize        == nil { stashedFontSize        = styling.fontSize }
            if stashedBarHeight       == nil { stashedBarHeight       = styling.barHeight }
            if stashedFullBarSeconds  == nil { stashedFullBarSeconds  = styling.fullBarSeconds }
        }
    }

    private func colorRow(
        title: String,
        keyPath: WritableKeyPath<SpellStyling, String?>,
        fallback: Color,
        stash: Binding<String?>
    ) -> some View {
        let isOn = Binding(
            get: { styling[keyPath: keyPath] != nil },
            set: { newValue in
                if newValue {
                    // Re-enabling: prefer the user's last pick over the
                    // hardcoded fallback so toggling is non-destructive.
                    styling[keyPath: keyPath] = stash.wrappedValue ?? fallback.hexString
                } else {
                    // Disabling: remember the current pick before
                    // clearing so the next toggle-on restores it.
                    if let current = styling[keyPath: keyPath] {
                        stash.wrappedValue = current
                    }
                    styling[keyPath: keyPath] = nil
                }
            }
        )
        let color = Binding<Color>(
            get: { styling[keyPath: keyPath].flatMap(Color.init(hex:)) ?? fallback },
            set: { newValue in
                let hex = newValue.hexString
                styling[keyPath: keyPath] = hex
                stash.wrappedValue = hex
            }
        )
        return HStack(spacing: 8) {
            Toggle(title, isOn: isOn)
                .frame(width: 110, alignment: .leading)
            ColorPicker("", selection: color, supportsOpacity: false)
                .labelsHidden()
                .disabled(!isOn.wrappedValue)
            CSSColorTextField(
                hexBinding: Binding(
                    get: { styling[keyPath: keyPath] },
                    set: { newHex in
                        styling[keyPath: keyPath] = newHex
                        if let newHex { stash.wrappedValue = newHex }
                    }
                )
            )
            .frame(width: 110)
            .disabled(!isOn.wrappedValue)
            if !isOn.wrappedValue, let inheritanceLabel {
                Text(inheritanceLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
        }
    }

    private func sliderRow(
        title: String,
        keyPath: WritableKeyPath<SpellStyling, Double?>,
        range: ClosedRange<Double>,
        defaultValue: Double,
        format: @escaping (Double) -> String,
        help: String? = nil,
        stash: Binding<Double?>
    ) -> some View {
        let isOn = Binding(
            get: { styling[keyPath: keyPath] != nil },
            set: { newValue in
                if newValue {
                    styling[keyPath: keyPath] = stash.wrappedValue ?? defaultValue
                } else {
                    if let current = styling[keyPath: keyPath] {
                        stash.wrappedValue = current
                    }
                    styling[keyPath: keyPath] = nil
                }
            }
        )
        let value = Binding(
            get: { styling[keyPath: keyPath] ?? defaultValue },
            set: { newValue in
                styling[keyPath: keyPath] = newValue
                stash.wrappedValue = newValue
            }
        )
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Toggle(title, isOn: isOn)
                    .frame(width: 110, alignment: .leading)
                Slider(value: value, in: range, step: 1)
                    .disabled(!isOn.wrappedValue)
                Text(format(value.wrappedValue))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(isOn.wrappedValue ? .primary : .tertiary)
                    .frame(width: 50, alignment: .trailing)
            }
            if let help {
                Text(help)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.leading, 110)
            }
        }
    }

    private func durationFieldRow(
        title: String,
        keyPath: WritableKeyPath<SpellStyling, Int?>,
        defaultValue: Int,
        stash: Binding<Int?>
    ) -> some View {
        let isOn = Binding(
            get: { styling[keyPath: keyPath] != nil },
            set: { newValue in
                if newValue {
                    styling[keyPath: keyPath] = stash.wrappedValue ?? defaultValue
                } else {
                    if let current = styling[keyPath: keyPath] {
                        stash.wrappedValue = current
                    }
                    styling[keyPath: keyPath] = nil
                }
            }
        )
        return HStack {
            Toggle(title, isOn: isOn)
                .frame(width: 140, alignment: .leading)
            Spacer()
            DurationTextField(
                binding: Binding(
                    get: { styling[keyPath: keyPath] },
                    set: { newSeconds in
                        styling[keyPath: keyPath] = newSeconds
                        if let newSeconds { stash.wrappedValue = newSeconds }
                    }
                )
            )
            .frame(width: 110)
            .disabled(!isOn.wrappedValue)
        }
    }
}

/// Text field for an `Int?`-seconds styling field that accepts any
/// duration string `DurationFormat.parse` understands — `3:30`,
/// `5m 10s`, `90s`, or plain seconds. Buffered so we don't reparse on
/// every keystroke; commit happens on Return or focus-out, and
/// unparseable input reverts to the last good value.
private struct DurationTextField: View {
    @Binding var binding: Int?

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("e.g. 3:30 or 5m 10s", text: $draft)
            .textFieldStyle(.roundedBorder)
            .font(.system(.caption, design: .monospaced))
            .focused($focused)
            .onSubmit { commit() }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { commit() }
            }
            .onAppear {
                draft = binding.map(DurationFormat.format) ?? ""
            }
            .onChange(of: binding) { _, new in
                if !focused {
                    draft = new.map(DurationFormat.format) ?? ""
                }
            }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Refuse to clear via empty input — toggling the row is the
            // canonical "inherit" path. Restore last good.
            draft = binding.map(DurationFormat.format) ?? ""
            return
        }
        if let secs = DurationFormat.parse(trimmed), secs > 0 {
            binding = secs
            draft = DurationFormat.format(secs)
        } else {
            // Unparseable — revert so the user sees their input was
            // rejected without silently dropping the prior value.
            draft = binding.map(DurationFormat.format) ?? ""
        }
    }
}

/// Text field for a `#RRGGBB` styling field that also accepts CSS3
/// named colors (`red`, `cornflowerblue`) and bare hex (`FF0000`).
/// Edits are kept in local draft state and only committed to the
/// binding when the user presses Return or focus leaves the field —
/// otherwise every keystroke would parse and overwrite the value the
/// user is mid-typing.
private struct CSSColorTextField: View {
    /// `nil` here means "field is disabled / inheriting" — we still
    /// show whatever was last cached so the user sees what would
    /// apply when they re-enable.
    @Binding var hexBinding: String?

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        TextField("e.g. red or #800000", text: $draft)
            .textFieldStyle(.roundedBorder)
            .font(.system(.caption, design: .monospaced))
            .focused($focused)
            .onSubmit { commit() }
            .onChange(of: focused) { _, isFocused in
                if !isFocused { commit() }
            }
            .onAppear { draft = hexBinding ?? "" }
            .onChange(of: hexBinding) { _, new in
                // External update (ColorPicker pick, toggle restore) —
                // mirror into the draft when we aren't actively
                // typing, so the swatch and the field stay in sync.
                if !focused { draft = new ?? "" }
            }
    }

    private func commit() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            // Refuse to clear the field through emptying — toggling the
            // row is the canonical way to "inherit". Restore last good.
            draft = hexBinding ?? ""
            return
        }
        if let resolved = CSSColors.resolve(trimmed) {
            hexBinding = resolved
            draft = resolved
        } else {
            // Unparseable — revert to last good so the user sees the
            // input was rejected without losing prior state.
            draft = hexBinding ?? ""
        }
    }
}

// MARK: - Live preview

/// Mocks a `progressBar` row using a fully-resolved styling so the
/// preview reflects what the bar will actually look like in-feed,
/// including any colour/size that the spell inherits from its group
/// or the window default. Callers compute the resolution themselves
/// because the layer chain differs per kind (default has no parents,
/// group inherits from default, spell inherits from group + default).
private struct StylingPreview: View {
    /// Already-merged styling — caller is responsible for layering.
    let resolved: ResolvedSpellStyling
    /// Effective display name to show inside the bar. Caller passes
    /// the user's override, the cached spell-database name, or a
    /// placeholder.
    let displayName: String

    /// User-draggable fill point so the text's contrast can be eyeballed
    /// against both the bar fill and the trough. Defaults so the label
    /// straddles the fill boundary on first render.
    @State private var previewFill: Double = 0.55

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            previewBar()
            Text(resolved.hidden
                 ? "(Hidden — bar won't render)"
                 : "Drag the fill to test text contrast over bar and trough.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GameTheme.background)
        .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
        .environment(\.colorScheme, .dark)
    }

    private var bar: Color {
        resolved.barColor.flatMap(Color.init(hex:)) ?? Color(red: 0.30, green: 0.55, blue: 1.00)
    }
    private var trough: Color {
        resolved.troughColor.flatMap(Color.init(hex:)) ?? Color.black.opacity(0.4)
    }
    private var text: Color {
        resolved.textColor.flatMap(Color.init(hex:)) ?? Color.white
    }
    private var fontSize: Double { resolved.fontSize ?? 13 }
    private var height: CGFloat { CGFloat(resolved.barHeight ?? 18) }

    @ViewBuilder
    private func previewBar() -> some View {
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                Rectangle().fill(trough)
                Rectangle().fill(bar)
                    .frame(width: geo.size.width * previewFill)
                // Tap/drag anywhere on the bar to move the fill edge.
                // `minimumDistance: 0` so a click also moves it.
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let w = max(geo.size.width, 1)
                                previewFill = max(0, min(1, value.location.x / w))
                            }
                    )
            }
            HStack(spacing: 6) {
                Text("1:30")
                    .font(.system(size: max(fontSize - 3, 9), design: .monospaced))
                    .foregroundStyle(text.opacity(0.85))
                    .monospacedDigit()
                Text(displayName)
                    .font(.system(size: max(fontSize - 2, 9), design: .monospaced))
                    .foregroundStyle(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer()
            }
            .padding(.horizontal, 6)
            .allowsHitTesting(false)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .opacity(resolved.hidden ? 0.3 : 1.0)
    }
}

// MARK: - Resolution helpers for the preview

/// Layers a draft styling over zero, one, or two parents to produce
/// the same `ResolvedSpellStyling` the render path would emit.
/// `enabled = false` on a parent skips that layer entirely.
private func resolvePreview(
    spell: SpellStyling? = nil,
    spellEnabled: Bool = true,
    spellDisplayName: String? = nil,
    group: SpellGroup? = nil,
    defaultStyling: SpellStyling
) -> ResolvedSpellStyling {
    let spellLayer:   SpellStyling? = spellEnabled ? spell : nil
    let groupLayer:   SpellStyling? = (group?.enabled == true) ? group?.styling : nil
    let defaultLayer: SpellStyling  = defaultStyling

    func field<T>(_ kp: KeyPath<SpellStyling, T?>) -> T? {
        spellLayer?[keyPath: kp]
            ?? groupLayer?[keyPath: kp]
            ?? defaultLayer[keyPath: kp]
    }

    let hidden = (spellLayer?.hidden ?? false)
        || (groupLayer?.hidden ?? false)
        || defaultLayer.hidden

    return ResolvedSpellStyling(
        displayName: spellEnabled ? spellDisplayName : nil,
        barColor: field(\.barColor),
        troughColor: field(\.troughColor),
        textColor: field(\.textColor),
        fontSize: field(\.fontSize),
        barHeight: field(\.barHeight),
        fullBarSeconds: field(\.fullBarSeconds),
        hidden: hidden
    )
}

// MARK: - Import target picker

/// Two-step picker: choose source window from the parsed file, then
/// the Grimoire dialog window it should land in. Lich's timers.lic
/// uses arbitrary user-named windows ("Main", "Cooldowns", "Buffs"
/// etc.) so we can't just match by name — the user maps each manually.
private struct ImportTargetSheet: View {
    let fileName: String
    let windows: [TimersProfileImporter.ParsedWindow]
    /// Source window (nil = all merged), target Grimoire window, and
    /// whether to wipe the target's existing presets/groups before
    /// importing (true = single-shot "rebuild from scratch").
    let onChoose: (TimersProfileImporter.ParsedWindow?, DialogWindow, Bool) -> Void
    let onCancel: () -> Void

    @State private var selectedSourceIndex: Int = 0     // -1 = all merged
    @State private var selectedTarget: DialogWindow = .buffs
    @State private var replaceExisting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Import spell presets").font(.headline)
                Text(fileName)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("From window in profile")
                    .font(.system(size: 10, weight: .semibold)).tracking(0.6).foregroundStyle(.secondary)
                Picker("", selection: $selectedSourceIndex) {
                    ForEach(Array(windows.enumerated()), id: \.offset) { idx, window in
                        Text("\(window.name) — \(window.presets.count) presets").tag(idx)
                    }
                    if windows.count > 1 {
                        Divider()
                        Text("All windows merged — \(TimersProfileImporter.merge(windows).count) unique presets").tag(-1)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Into Grimoire window")
                    .font(.system(size: 10, weight: .semibold)).tracking(0.6).foregroundStyle(.secondary)
                Picker("", selection: $selectedTarget) {
                    ForEach(DialogWindow.allCases) { w in
                        Text(w.displayName).tag(w)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Toggle("Replace existing presets and groups in target window", isOn: $replaceExisting)
                .toggleStyle(.checkbox)

            Text(replaceExisting
                 ? "Target window will be wiped clean before importing. Default styling stays."
                 : "Same-spell-ID presets in the target window will be replaced. Other presets stay.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(replaceExisting ? "Replace & Import" : "Import") {
                    let source = selectedSourceIndex >= 0 ? windows[selectedSourceIndex] : nil
                    onChoose(source, selectedTarget, replaceExisting)
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(18)
        .frame(width: 440)
    }
}
