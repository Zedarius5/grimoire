import Foundation
import Combine
import GrimoireKit

/// Owns the per-window spell-preset configuration, persists on every
/// mutation, and publishes updates so the live `DialogPane` and the
/// `SpellPresetEditorView` both react instantly.
///
/// The store always carries one `WindowConfig` per `DialogWindow` —
/// the editor relies on this invariant so it can render the four-tab
/// window switcher without nil-checks.
@MainActor
final class SpellPresetStore: ObservableObject {

    @Published var config: SpellPresetConfig = SpellPresetConfig() {
        didSet { Preferences.saveSpellPresets(config) }
    }

    /// Lich's cached spell-name database (`data/effect-list.xml` under the Lich folder).
    /// Read once at init; the editor uses it as a fallback label when no
    /// live dialog text is available.
    let spellNames: SpellNameDatabase

    init(spellNames: SpellNameDatabase = .shared) {
        self.spellNames = spellNames
        // Saved config wins; a first run falls back to the bundled starter
        // presets (Minor Elemental/Spiritual timer groups, GoS sigils,
        // high-vis debuffs) so the preset editor isn't an empty mystery.
        if let loaded = Preferences.loadSpellPresets() ?? Self.bundledStarterConfig() {
            // Ensure every DialogWindow has a config — covers older
            // saved data that pre-dates new windows being added.
            var merged = loaded
            for window in DialogWindow.allCases where !merged.windows.contains(where: { $0.window == window }) {
                merged.update(WindowConfig(window: window))
            }
            self.config = merged
        }
    }

    /// Decodes `Resources/default-spell-presets.json`. Nil (never fatal) if
    /// the resource is missing or fails to decode.
    private static func bundledStarterConfig() -> SpellPresetConfig? {
        guard let url = Bundle.module.url(
            forResource: "default-spell-presets", withExtension: "json"
        ), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SpellPresetConfig.self, from: data)
    }

    /// Total preset count across every window — used by Options
    /// popover's "N presets loaded" status line.
    var totalPresetCount: Int {
        config.windows.reduce(0) { $0 + $1.presets.count }
    }

    /// Read-only window snapshot. Mutations go through the window-
    /// specific helpers below so persistence fires every time.
    func windowConfig(for window: DialogWindow) -> WindowConfig {
        config.config(for: window)
    }

    // MARK: - Default styling

    func updateDefaultStyling(_ styling: SpellStyling, in window: DialogWindow) {
        var w = windowConfig(for: window)
        w.defaultStyling = styling
        config.update(w)
    }

    // MARK: - Preset CRUD (per window)

    /// Inserts a fresh preset for the given spell id in the given
    /// window. If a preset for that id already exists in that window,
    /// returns the existing one (no duplicates).
    @discardableResult
    func addPreset(spellId: String, displayName: String? = nil, in window: DialogWindow) -> SpellPreset {
        var w = windowConfig(for: window)
        if let existing = w.presets.first(where: { $0.spellId == spellId }) {
            return existing
        }
        let fresh = SpellPreset(spellId: spellId, displayName: displayName)
        w.presets.append(fresh)
        config.update(w)
        return fresh
    }

    func updatePreset(_ preset: SpellPreset, in window: DialogWindow) {
        var w = windowConfig(for: window)
        guard let idx = w.presets.firstIndex(where: { $0.id == preset.id }) else { return }
        w.presets[idx] = preset
        config.update(w)
    }

    func removePreset(id: UUID, in window: DialogWindow) {
        var w = windowConfig(for: window)
        w.presets.removeAll { $0.id == id }
        config.update(w)
    }

    // MARK: - Group CRUD (per window)

    @discardableResult
    func addGroup(name: String, in window: DialogWindow) -> SpellGroup {
        var w = windowConfig(for: window)
        let fresh = SpellGroup(name: name)
        w.groups.append(fresh)
        config.update(w)
        return fresh
    }

    func updateGroup(_ group: SpellGroup, in window: DialogWindow) {
        var w = windowConfig(for: window)
        guard let idx = w.groups.firstIndex(where: { $0.id == group.id }) else { return }
        w.groups[idx] = group
        config.update(w)
    }

    func removeGroup(id: UUID, in window: DialogWindow) {
        var w = windowConfig(for: window)
        w.groups.removeAll { $0.id == id }
        // Detach orphaned members so they fall straight through to
        // window-default rather than referencing a stale UUID.
        for i in w.presets.indices where w.presets[i].groupId == id {
            w.presets[i].groupId = nil
        }
        config.update(w)
    }

    /// Wipes every preset and group from a window while preserving its
    /// default styling. The "Replace existing" import path uses this
    /// to give the user a single-shot rebuild instead of forcing them
    /// to delete rows one at a time.
    func clearWindow(_ window: DialogWindow) {
        var w = windowConfig(for: window)
        w.presets.removeAll()
        w.groups.removeAll()
        config.update(w)
    }

    // MARK: - Bulk import

    /// Drops imported presets into the target window (replacing
    /// same-spellId entries, appending new ones). Preserves the
    /// existing preset UUIDs so editor selection survives the import.
    @discardableResult
    func importPresets(
        _ imported: [SpellPreset],
        into window: DialogWindow
    ) -> (added: Int, updated: Int) {
        var w = windowConfig(for: window)
        let bySpellId = Dictionary(
            imported.map { ($0.spellId, $0) },
            uniquingKeysWith: { _, latest in latest }
        )
        var updated = 0
        for i in w.presets.indices {
            if var replacement = bySpellId[w.presets[i].spellId] {
                replacement.id = w.presets[i].id
                replacement.groupId = w.presets[i].groupId  // keep existing group membership
                w.presets[i] = replacement
                updated += 1
            }
        }
        let existing = Set(w.presets.map(\.spellId))
        var added = 0
        for new in imported where !existing.contains(new.spellId) {
            w.presets.append(new)
            added += 1
        }
        config.update(w)
        return (added: added, updated: updated)
    }

    // MARK: - Render-path lookup

    /// Fully-resolved styling for one progress bar in one window,
    /// after spell → group → window-default fall-through. Returns
    /// `ResolvedSpellStyling.empty` for unmanaged spells so callers
    /// can use the same value-type at every site.
    func resolve(spellId: String, in window: DialogWindow) -> ResolvedSpellStyling {
        windowConfig(for: window).resolve(spellId: spellId)
    }
}
