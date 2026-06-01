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
    /// Debounce window for `UserDefaults.set` + the
    /// `NSUserDefaultsDidChange` notification fan-out. With ~900
    /// rules the encoded blob is ~175 KB; without debouncing,
    /// per-keystroke edits in the editor stall the UI because every
    /// keystroke triggers a synchronous save + notification post.
    private static let saveDelay: TimeInterval = 0.5

    init() {
        if let saved = Preferences.loadHighlights() {
            self.config = saved
        }
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

    /// Rule list with group-level fg/bg/traits/enabled pre-merged. The
    /// renderer (StoryTextView env, DialogPane) consumes this so
    /// HighlightProcessor itself stays group-agnostic. Implementation
    /// lives in `HighlightResolver` so it's testable without bringing
    /// in HighlightStore's UI dependencies.
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

    /// Removes the group and detaches all its member rules (sets their
    /// `groupId` back to nil so they keep their own styling -- we never
    /// silently delete user rules). Returns how many rules were
    /// detached so a caller can confirm if it wants to.
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
