import Foundation

/// A single row from the server's `<cmdlist>` — a named command template the
/// client uses to resolve `<a coord='X' noun='Y' exist='Z'>` clicks into
/// real game commands. The template can contain three substitution chars
/// (Wrayth's convention, mirrored by warlock3):
///
/// - `@` — replaced by the link's `noun` attribute
/// - `#` — replaced by `#<exist>` (the link's entity id, prefixed)
/// - `%` — replaced by a per-menu-item `noun` when resolving a `<mi>` row
public struct CmdDefinition: Equatable, Hashable, Sendable {
    public var coord: String
    public var command: String
    public var menu: String
    public var menuCategory: String

    public init(coord: String, command: String, menu: String = "", menuCategory: String = "") {
        self.coord = coord
        self.command = command
        self.menu = menu
        self.menuCategory = menuCategory
    }

    /// Substitutes the `@` / `#` / `%` placeholders against the supplied
    /// values. Empty values are dropped (the placeholder becomes empty).
    public func resolve(noun: String?, exist: String?, menuItemNoun: String? = nil) -> String {
        Self.substitute(command, noun: noun, exist: exist, menuItemNoun: menuItemNoun)
    }

    /// Same substitution rules, applied to the `menu` field — the human-
    /// readable label Wrayth/Warlock show in the context menu. The label
    /// template usually contains `@` so it renders e.g. "look at Endaro"
    /// instead of "look at @".
    public func resolvedLabel(noun: String?, exist: String?, menuItemNoun: String? = nil) -> String {
        let template = menu.isEmpty ? command : menu
        return Self.substitute(template, noun: noun, exist: exist, menuItemNoun: menuItemNoun)
    }

    private static func substitute(
        _ template: String,
        noun: String?,
        exist: String?,
        menuItemNoun: String?
    ) -> String {
        var out = template
        out = out.replacingOccurrences(of: "@", with: noun ?? "")
        if let exist, !exist.isEmpty {
            out = out.replacingOccurrences(of: "#", with: "#\(exist)")
        } else {
            out = out.replacingOccurrences(of: "#", with: "")
        }
        out = out.replacingOccurrences(of: "%", with: menuItemNoun ?? "")
        return out
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}
