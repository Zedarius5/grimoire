import SwiftUI
import GrimoireKit

/// Owns the user's named window layouts (global — shared across characters)
/// and which one is active. The live arrangement in `ContentView` mirrors the
/// active layout; edits fold back via `updateActive`. Persists the whole set
/// to `Preferences` on every change.
@MainActor
final class LayoutStore: ObservableObject {
    // Named `layoutSet` rather than `set` because `set` is a contextual
    // keyword inside computed-property accessors.
    @Published private(set) var layoutSet: NamedSet<Layout>

    init() {
        if let loaded: NamedSet<Layout> = Preferences.loadLayouts(as: NamedSet<Layout>.self),
           !loaded.items.isEmpty {
            layoutSet = loaded
            return
        }
        // First run with named layouts: migrate the existing arrangement (the
        // last-login character's saved panes) into a "Default" layout so the
        // user keeps their setup. Falls back to the stock layout.
        let last = Preferences.loadLastLogin()
        let hasChar = !last.account.isEmpty && !last.character.isEmpty
        let panes: [PaneSpec] = (hasChar
            ? Preferences.loadPanes(as: [PaneSpec].self, account: last.account, character: last.character)
            : nil) ?? PaneSpec.defaults
        let sizes: [String: CGFloat] = (hasChar
            ? Preferences.loadSizes(account: last.account, character: last.character)
            : nil) ?? PaneSpec.defaultSizes
        layoutSet = NamedSet(items: [Layout(name: "Default", panes: panes, sizes: sizes)])
        Preferences.saveLayouts(layoutSet)
    }

    var names: [String] { layoutSet.items.map(\.name) }
    var activeName: String { layoutSet.activeName }
    var activePanes: [PaneSpec] { layoutSet.active?.panes ?? PaneSpec.defaults }
    var activeSizes: [String: CGFloat] { layoutSet.active?.sizes ?? PaneSpec.defaultSizes }
    var canDelete: Bool { layoutSet.items.count > 1 }

    /// Switch the active layout. No-op if already active or the name is unknown.
    func select(_ name: String) {
        guard name != layoutSet.activeName else { return }
        layoutSet.select(name)
        persist()
    }

    /// Fold the live arrangement back into the active layout (auto-save).
    func updateActive(panes: [PaneSpec]) { layoutSet.updateActive { $0.panes = panes }; persist() }
    func updateActive(sizes: [String: CGFloat]) { layoutSet.updateActive { $0.sizes = sizes }; persist() }

    /// Snapshot the current arrangement under a new name and make it active.
    /// Ignored if the (trimmed) name is blank.
    func addLayout(named name: String, panes: [PaneSpec], sizes: [String: CGFloat]) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        layoutSet.upsert(Layout(name: trimmed, panes: panes, sizes: sizes))
        persist()
    }

    func renameActive(to name: String) { layoutSet.rename(to: name); persist() }
    func deleteActive() { layoutSet.deleteActive(); persist() }

    private func persist() { Preferences.saveLayouts(layoutSet) }
}
