import SwiftUI
import GrimoireKit

/// Standalone window for reviewing and editing macros (key→action bindings).
/// Edits happen against the shared `MacroEngine.config` so changes are live
/// immediately and auto-save to disk.
struct MacroEditorView: View {
    @EnvironmentObject var macros: MacroEngine

    @State private var selectedSetId: Int? = nil

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
        HStack {
            Text("Name")
            TextField("", text: $macros.config.sets[setIdx].name)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 280)
            Spacer()
            Button("Activate this set") {
                macros.setActive(setId: macros.config.sets[setIdx].id)
            }
            .disabled(macros.activeSetId == macros.config.sets[setIdx].id)
        }
        .padding(12)
    }

    private func bindingsList(setIdx: Int) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 6) {
                if macros.config.sets[setIdx].bindings.isEmpty {
                    Text("No bindings yet.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    columnHeaders
                    ForEach($macros.config.sets[setIdx].bindings) { $binding in
                        BindingRow(binding: $binding) {
                            deleteBinding(setIdx: setIdx, id: binding.id)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
            Text("Syntax: `\\r` = submit · `\\x` = clear-first · `\\?` = template cursor · `{Token}` = built-in")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    // MARK: - Mutations

    private func addBinding(setIdx: Int) {
        macros.config.sets[setIdx].bindings.append(MacroBinding(key: "", action: ""))
    }

    private func deleteBinding(setIdx: Int, id: UUID) {
        macros.config.sets[setIdx].bindings.removeAll { $0.id == id }
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

private struct BindingRow: View {
    @Binding var binding: MacroBinding
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("e.g. F1, Alt-Ctrl-E, Keypad 1", text: $binding.key)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(width: 180)
            TextField("e.g. stance def\\r or {RepeatLast}", text: $binding.action)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .frame(maxWidth: .infinity)
            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
        }
    }
}
