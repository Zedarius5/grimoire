import SwiftUI
import GrimoireKit

/// Standalone window for reviewing and editing macros (key→action bindings).
/// Edits happen against the shared `MacroEngine.config` so changes are live
/// immediately and auto-save to disk.
struct MacroEditorView: View {
    @EnvironmentObject var macros: MacroEngine

    @State private var selectedSetId: Int? = nil
    /// Set by `addBinding` to the new row's id; consumed by the matching
    /// `KeyCaptureField.onAppear` (and the matching ScrollViewReader's
    /// scrollTo) so the user lands focused-and-capturing on the new row.
    @State private var pendingCaptureForId: UUID? = nil

    private var selectedSetIndex: Int? {
        guard let id = selectedSetId else { return nil }
        return macros.config.sets.firstIndex(where: { $0.id == id })
    }

    var body: some View {
        HSplitView {
            setsList
                .frame(minWidth: 200, idealWidth: 240, maxWidth: 320)
            bindingsPanel
                .frame(minWidth: 480)
        }
        .navigationTitle("Macro Editor")
        .onAppear {
            if selectedSetId == nil {
                selectedSetId = macros.config.sets.first?.id
            }
        }
        .onChange(of: macros.config) { _, newValue in
            Preferences.saveMacros(newValue)
        }
    }

    // MARK: - Sets list

    private var setsList: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Macro Sets").font(.headline)
                Spacer()
                Button {
                    addSet()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add new set")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            List(macros.config.sets, selection: $selectedSetId) { set in
                HStack {
                    Text("\(set.id)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .frame(width: 22, alignment: .trailing)
                    Text(set.name)
                    Spacer()
                    Text("\(set.bindings.count)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                    if set.id == macros.activeSetId {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .tag(set.id)
                .contextMenu {
                    Button("Activate") { macros.setActive(setId: set.id) }
                    if set.id != 0 {
                        Button("Delete set", role: .destructive) { deleteSet(set.id) }
                    }
                }
            }
        }
    }

    // MARK: - Bindings panel

    @ViewBuilder
    private var bindingsPanel: some View {
        if let setIdx = selectedSetIndex {
            VStack(spacing: 0) {
                header(setIdx: setIdx)
                Divider()
                bindingsList(setIdx: setIdx)
                Divider()
                footer(setIdx: setIdx)
            }
        } else {
            VStack {
                Image(systemName: "keyboard")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Pick a set on the left.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func header(setIdx: Int) -> some View {
        // Wrap in an inner view with stable identity so the local-state
        // name draft below resets on set switch (and flushes on the
        // outgoing set's `.onDisappear`).
        SetNameHeader(
            set: macros.config.sets[setIdx],
            isActive: macros.activeSetId == macros.config.sets[setIdx].id,
            onCommitName: { newName in
                guard let i = macros.config.sets.firstIndex(where: { $0.id == macros.config.sets[setIdx].id }) else { return }
                if macros.config.sets[i].name != newName {
                    macros.config.sets[i].name = newName
                }
            },
            onActivate: {
                macros.setActive(setId: macros.config.sets[setIdx].id)
            }
        )
        .id(macros.config.sets[setIdx].id)
    }

    private func bindingsList(setIdx: Int) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if macros.config.sets[setIdx].bindings.isEmpty {
                        Text("No bindings yet.")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        columnHeaders
                        ForEach(macros.config.sets[setIdx].bindings) { binding in
                            BindingRow(
                                binding: binding,
                                requestedCaptureForId: $pendingCaptureForId,
                                onCommit: { updated in
                                    commitBinding(setIdx: setIdx, updated: updated)
                                },
                                onDelete: {
                                    deleteBinding(setIdx: setIdx, id: binding.id)
                                }
                            )
                            .id(binding.id)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .onChange(of: pendingCaptureForId) { _, new in
                // Scroll the freshly-added row into view so capture mode
                // is visible instead of falling off the bottom of the list.
                if let id = new {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var columnHeaders: some View {
        HStack(spacing: 8) {
            Text("Key")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(width: 180, alignment: .leading)
            Text("Action")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Color.clear.frame(width: 24)
        }
    }

    private func footer(setIdx: Int) -> some View {
        HStack {
            Button {
                addBinding(setIdx: setIdx)
            } label: {
                Label("Add binding", systemImage: "plus")
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Keys: F1-F15 · LEFT/RIGHT/UP/DOWN · Page Up/Page Down · Home/End · Enter/Tab/Space/Esc/Backspace/Delete/Insert · Keypad 0-9 · letters · prefix with Shift-/Ctrl-/Alt-/Cmd-")
                Text("Action: `\\r` = submit · `\\p[N]` = pause N sec · `@` = cursor here · `\\?` = popup prompt · `\\x` = clear-first · `{Token}` = built-in")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    // MARK: - Mutations

    private func addBinding(setIdx: Int) {
        let fresh = MacroBinding(key: "", action: "")
        macros.config.sets[setIdx].bindings.append(fresh)
        // Trigger scroll-to-and-auto-capture for the new row.
        pendingCaptureForId = fresh.id
    }

    private func deleteBinding(setIdx: Int, id: UUID) {
        macros.config.sets[setIdx].bindings.removeAll { $0.id == id }
    }

    private func commitBinding(setIdx: Int, updated: MacroBinding) {
        guard let i = macros.config.sets[setIdx].bindings.firstIndex(where: { $0.id == updated.id }) else { return }
        // Skip the write if nothing meaningful changed. Without this guard
        // the row's `.onDisappear` flush would still trip `@Published`
        // when the user just navigates away.
        if macros.config.sets[setIdx].bindings[i] != updated {
            macros.config.sets[setIdx].bindings[i] = updated
        }
    }

    private func addSet() {
        let nextId = (macros.config.sets.map(\.id).max() ?? -1) + 1
        macros.config.sets.append(MacroSet(id: nextId, name: "Set \(nextId)"))
        selectedSetId = nextId
    }

    private func deleteSet(_ id: Int) {
        macros.config.sets.removeAll { $0.id == id }
        if selectedSetId == id {
            selectedSetId = macros.config.sets.first?.id
        }
    }
}

/// Set-header strip with the editable name field. Local-state name
/// draft commits on `.onDisappear` (set switch or editor close) so
/// typing into the field doesn't cascade through the engine on every
/// keystroke.
private struct SetNameHeader: View {
    let set: MacroSet
    let isActive: Bool
    let onCommitName: (String) -> Void
    let onActivate: () -> Void

    @State private var nameDraft: String

    init(set: MacroSet, isActive: Bool, onCommitName: @escaping (String) -> Void, onActivate: @escaping () -> Void) {
        self.set = set
        self.isActive = isActive
        self.onCommitName = onCommitName
        self.onActivate = onActivate
        _nameDraft = State(initialValue: set.name)
    }

    var body: some View {
        HStack {
            Text("Name")
            TextField("", text: $nameDraft)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)
            Spacer()
            Button("Activate this set", action: onActivate)
                .disabled(isActive)
        }
        .padding(12)
        .onDisappear {
            onCommitName(nameDraft)
        }
    }
}

/// Row in the macro bindings list.
///
/// Holds local `@State` for both editable fields and ONLY commits back to
/// the store on `.onDisappear` -- i.e. when the row is removed from the
/// view tree, which happens on editor-window close, set switch, or
/// delete. Until then every edit stays purely local, so the rest of the
/// app sees the prior committed binding and there's no per-keystroke
/// `@Published` cascade through `MacroEngine.config`. Mirrors the same
/// pattern as `HighlightDetail` so editor latency is decoupled from
/// collection size at every typing speed.
private struct BindingRow: View {
    let binding: MacroBinding
    @Binding var requestedCaptureForId: UUID?
    let onCommit: (MacroBinding) -> Void
    let onDelete: () -> Void

    @State private var keyDraft: String
    @State private var actionDraft: String
    @State private var didDelete: Bool = false

    init(
        binding: MacroBinding,
        requestedCaptureForId: Binding<UUID?>,
        onCommit: @escaping (MacroBinding) -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.binding = binding
        self._requestedCaptureForId = requestedCaptureForId
        self.onCommit = onCommit
        self.onDelete = onDelete
        _keyDraft = State(initialValue: binding.key)
        _actionDraft = State(initialValue: binding.action)
    }

    private var draft: MacroBinding {
        MacroBinding(id: binding.id, key: keyDraft, action: actionDraft)
    }

    var body: some View {
        HStack(spacing: 8) {
            KeyCaptureField(
                keyName: $keyDraft,
                id: binding.id,
                requestedCaptureForId: $requestedCaptureForId
            )
            .frame(width: 220)

            TextField("e.g. stance def\\r or {RepeatLast}", text: $actionDraft)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity)

            Button(role: .destructive) {
                didDelete = true
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
        .onDisappear {
            // Suppress the flush when the user just hit Delete --
            // otherwise the local draft would resurrect the row we
            // just removed.
            guard !didDelete else { return }
            onCommit(draft)
        }
    }
}
