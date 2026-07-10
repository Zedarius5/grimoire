import Foundation
import Combine
import GrimoireKit

/// Owns the user's `HighlightConfig`, persists it on every change, and
/// publishes updates so the game feed and the editor can both react live.
@MainActor
final class HighlightStore: ObservableObject {

    @Published var config: HighlightConfig = HighlightConfig() {
        didSet { scheduleSave() }
    }

    private var saveTask: Task<Void, Never>?
    /// Debounce window for the `UserDefaults.set` + `NSUserDefaultsDidChange`
    /// fan-out. The encoded blob is large (~175 KB at ~900 rules), so
    /// per-keystroke synchronous saves would stall the UI without debouncing.
    private static let saveDelay: TimeInterval = 0.5

    init() {
        if let saved = Preferences.loadHighlights() {
            self.config = saved
        } else if let starter = Self.bundledStarterConfig() {
            // First run: seed the starter library (crit-fatal groups,
            // damage tints, mob-death, a notify example) so a new user
            // sees working highlights instead of an empty editor.
            self.config = starter
        }
    }

    /// Decodes `Resources/default-highlights.json`. Nil (never fatal) if the
    /// resource is missing or fails to decode — an empty config is a usable
    /// fallback, just a blank slate.
    private static func bundledStarterConfig() -> HighlightConfig? {
        guard let url = Bundle.module.url(
            forResource: "default-highlights", withExtension: "json"
        ), let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(HighlightConfig.self, from: data)
    }

    deinit {
        saveTask?.cancel()
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let snapshot = config
        saveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.saveDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            Preferences.saveHighlights(snapshot)
        }
    }

    var highlights: [Highlight] { config.highlights }
    var groups: [HighlightGroup] { config.groups }

    /// Rule list with group-level fg/bg/traits/enabled pre-merged, so the
    /// renderer consumes resolved rules and HighlightProcessor stays
    /// group-agnostic. Implemented in `HighlightResolver` to keep it testable
    /// without HighlightStore's UI dependencies.
    var effectiveHighlights: [Highlight] {
        HighlightResolver.resolve(config.highlights, groups: config.groups)
    }

    // MARK: - Rule CRUD

    func add(_ rule: Highlight = Highlight()) -> Highlight {
        var fresh = rule
        if fresh.id == (Highlight().id) { fresh.id = UUID() }  // ensure unique
        config.highlights.append(fresh)
        return fresh
    }

    func update(_ rule: Highlight) {
        guard let idx = config.highlights.firstIndex(where: { $0.id == rule.id }) else { return }
        config.highlights[idx] = rule
    }

    func remove(id: UUID) {
        config.highlights.removeAll { $0.id == id }
    }

    func replaceAll(with rules: [Highlight]) {
        config.highlights = rules
    }

    // MARK: - Group CRUD

    @discardableResult
    func addGroup(_ group: HighlightGroup = HighlightGroup(name: "New Group")) -> HighlightGroup {
        var fresh = group
        if fresh.id == (HighlightGroup().id) { fresh.id = UUID() }
        config.groups.append(fresh)
        return fresh
    }

    func updateGroup(_ group: HighlightGroup) {
        guard let idx = config.groups.firstIndex(where: { $0.id == group.id }) else { return }
        config.groups[idx] = group
    }

    /// Removes the group and detaches its member rules (clears their `groupId`
    /// so they keep their own styling; member rules are never deleted).
    /// Returns the number of rules detached.
    @discardableResult
    func removeGroup(id: UUID) -> Int {
        var detached = 0
        config.highlights = config.highlights.map { rule in
            guard rule.groupId == id else { return rule }
            detached += 1
            var copy = rule
            copy.groupId = nil
            return copy
        }
        config.groups.removeAll { $0.id == id }
        return detached
    }
}
