import Foundation
import Combine
import GrimoireKit

/// Owns the user's `HighlightConfig`, persists it on every change, and
/// publishes updates so the game feed and the editor can both react live.
@MainActor
final class HighlightStore: ObservableObject {

    @Published var config: HighlightConfig = HighlightConfig() {
        didSet {
            // Persist on any change. Cheap (small payload, infrequent edits).
            Preferences.saveHighlights(config)
        }
    }

    init() {
        if let saved = Preferences.loadHighlights() {
            self.config = saved
        }
    }

    var highlights: [Highlight] { config.highlights }

    // MARK: - CRUD

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
}
