import Foundation

/// One row in a server-driven context menu. Each row resolves to a command
/// the server will execute when chosen — `coord` indexes into the existing
/// `cmdlist`, with `noun` providing the `%` substitution per warlock3's
/// convention. We resolve at render time so the menu UI shows the correctly
/// templated label and command text.
public struct MenuItem: Equatable, Hashable, Sendable, Identifiable {
    public let id = UUID()
    public var coord: String
    public var noun: String?
    public var category: String

    public init(coord: String, noun: String? = nil, category: String = "") {
        self.coord = coord
        self.noun = noun
        self.category = category
    }
}

/// A bundle of menu items keyed by the server's transient `id` token. The
/// client correlates a `<menu id='X'>` arrival with its earlier
/// `_menu #<exist> X` request via this id.
public struct ServerMenu: Equatable, Hashable, Sendable {
    public var id: String
    public var items: [MenuItem]

    public init(id: String, items: [MenuItem]) {
        self.id = id
        self.items = items
    }
}
