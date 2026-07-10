import Foundation

/// Anything that carries a mutable display name. Conformers ride inside a
/// `NamedSet` as its items.
public protocol Named {
    var name: String { get set }
}

/// An ordered collection of uniquely-named items with one "active" selection.
///
/// Pure value type: the item payload (panes, sizes, whatever) rides along
/// untouched — only the name/ordering/active-pointer logic lives here, so it's
/// unit-testable without the app-target types it ultimately carries. Names are
/// unique case-insensitively, and every operation keeps `activeName` pointing
/// at a real item (or "" when empty).
public struct NamedSet<Item: Named & Equatable>: Equatable {
    public private(set) var items: [Item]
    public private(set) var activeName: String

    public init(items: [Item], activeName: String? = nil) {
        self.items = items
        self.activeName = activeName ?? items.first?.name ?? ""
        normalizeActive()
    }

    /// The currently-active item, if any.
    public var active: Item? { items.first { $0.name.caseInsensitiveEquals(activeName) } }

    /// Switch the active selection — only to a name that exists.
    public mutating func select(_ name: String) {
        if items.contains(where: { $0.name.caseInsensitiveEquals(name) }) {
            activeName = name
        }
    }

    /// Insert, or replace an existing item with the same name (case-insensitive),
    /// and make it active.
    public mutating func upsert(_ item: Item) {
        items.removeAll { $0.name.caseInsensitiveEquals(item.name) }
        items.append(item)
        activeName = item.name
    }

    /// Mutate the active item in place — used to fold live edits back into the
    /// active layout (auto-save).
    public mutating func updateActive(_ transform: (inout Item) -> Void) {
        guard let idx = activeIndex else { return }
        transform(&items[idx])
    }

    /// Rename the active item, keeping it active. No-op when the new name is
    /// blank or collides with a *different* existing item.
    public mutating func rename(to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, let idx = activeIndex else { return }
        let collides = items.enumerated().contains {
            $0.offset != idx && $0.element.name.caseInsensitiveEquals(trimmed)
        }
        guard !collides else { return }
        items[idx].name = trimmed
        activeName = trimmed
    }

    /// Remove the active item and move the active pointer to the first
    /// remaining one. Refuses to delete the last item.
    public mutating func deleteActive() {
        guard items.count > 1, let idx = activeIndex else { return }
        items.remove(at: idx)
        activeName = items.first?.name ?? ""
    }

    private var activeIndex: Int? {
        items.firstIndex { $0.name.caseInsensitiveEquals(activeName) }
    }

    private mutating func normalizeActive() {
        if active == nil { activeName = items.first?.name ?? "" }
    }
}

extension NamedSet: Codable where Item: Codable {}

private extension String {
    func caseInsensitiveEquals(_ other: String) -> Bool {
        caseInsensitiveCompare(other) == .orderedSame
    }
}
