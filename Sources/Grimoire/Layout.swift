import Foundation
import GrimoireKit

/// One saved window arrangement: the panes and their split sizes, under a
/// user-facing name. Conforms to `Named` so it can ride inside a `NamedSet`.
struct Layout: Named, Codable, Equatable {
    var name: String
    var panes: [PaneSpec]
    var sizes: [String: CGFloat]
}
