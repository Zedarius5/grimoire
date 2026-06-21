import Foundation

/// What kind of highlight this is. Splits the editor into two lists but the
/// rendering pipeline treats both identically — both fire whenever their
/// `text` matches a span in a feed line.
public enum HighlightKind: String, Codable, Equatable, Hashable, Sendable, CaseIterable {
    /// Generic phrase / keyword highlight (the `<strings>` block in Wrayth).
    case text
    /// Character/player name highlight (the `<names>` block in Wrayth).
    case name
}

/// One custom highlight rule — when `text` matches inside a line, the matched
/// span (or the entire line, if `entireLine`) is repainted with the given
/// foreground and/or background colors.
public struct Highlight: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var text: String
    /// Hex `#RRGGBB`. Nil means leave the existing foreground.
    public var fgColor: String?
    /// Hex `#RRGGBB`. Nil means no background fill.
    public var bgColor: String?
    public var entireLine: Bool
    public var caseSensitive: Bool
    public var wholeWord: Bool
    public var enabled: Bool
    public var kind: HighlightKind
    /// When true, `text` is interpreted as an ICU regex pattern (as
    /// `NSRegularExpression` understands it). Compiles to a regex
    /// cached per pattern string in `HighlightProcessor`.
    public var usesPattern: Bool
    /// Font-trait additions applied to matched spans. Stack on top of the
    /// protocol-derived `<b>` / monsterbold bold (additive, never un-bolding).
    public var bold: Bool
    public var italic: Bool
    /// Optional `HighlightGroup` membership. When set, fields the rule
    /// leaves unset (fgColor, bgColor) inherit from the group's
    /// defaults, and the rule is only active when both the rule and
    /// its group are enabled. See `HighlightStore.effectiveHighlights`
    /// for the resolution.
    public var groupId: UUID?
    /// Persisted last-chosen fg / bg. The editor stashes the active color here
    /// when a color toggle is turned off, so re-enabling it (even across
    /// restarts) restores the color. Editor-only; the processor never reads these.
    public var stashedFgColor: String?
    public var stashedBgColor: String?
    /// When true (or when the rule's group has notify on), a match
    /// against this rule posts a macOS notification containing the
    /// matched line. Throttled per-rule so a chatty match doesn't
    /// flood the notification center.
    public var notify: Bool

    public init(
        id: UUID = UUID(),
        text: String = "",
        fgColor: String? = nil,
        bgColor: String? = nil,
        entireLine: Bool = false,
        caseSensitive: Bool = false,
        wholeWord: Bool = false,
        enabled: Bool = true,
        kind: HighlightKind = .text,
        usesPattern: Bool = false,
        bold: Bool = false,
        italic: Bool = false,
        groupId: UUID? = nil,
        stashedFgColor: String? = nil,
        stashedBgColor: String? = nil,
        notify: Bool = false
    ) {
        self.id = id
        self.text = text
        self.fgColor = fgColor
        self.bgColor = bgColor
        self.entireLine = entireLine
        self.caseSensitive = caseSensitive
        self.wholeWord = wholeWord
        self.enabled = enabled
        self.kind = kind
        self.usesPattern = usesPattern
        self.bold = bold
        self.italic = italic
        self.groupId = groupId
        self.stashedFgColor = stashedFgColor
        self.stashedBgColor = stashedBgColor
        self.notify = notify
    }

    // Custom decoding for backward compat: fields added later decode to safe
    // defaults on older configs, and removed `underline`/`strikethrough` keys
    // are ignored (no migration).
    private enum CodingKeys: String, CodingKey {
        case id, text, fgColor, bgColor, entireLine, caseSensitive, wholeWord, enabled, kind, usesPattern
        case bold, italic, groupId, stashedFgColor, stashedBgColor, notify
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id            = try c.decode(UUID.self,  forKey: .id)
        self.text          = try c.decode(String.self, forKey: .text)
        self.fgColor       = try c.decodeIfPresent(String.self, forKey: .fgColor)
        self.bgColor       = try c.decodeIfPresent(String.self, forKey: .bgColor)
        self.entireLine    = try c.decode(Bool.self,  forKey: .entireLine)
        self.caseSensitive = try c.decode(Bool.self,  forKey: .caseSensitive)
        self.wholeWord     = try c.decode(Bool.self,  forKey: .wholeWord)
        self.enabled       = try c.decode(Bool.self,  forKey: .enabled)
        self.kind          = (try? c.decode(HighlightKind.self, forKey: .kind)) ?? .text
        self.usesPattern   = (try? c.decode(Bool.self, forKey: .usesPattern)) ?? false
        self.bold          = (try? c.decode(Bool.self, forKey: .bold)) ?? false
        self.italic        = (try? c.decode(Bool.self, forKey: .italic)) ?? false
        self.groupId       = try c.decodeIfPresent(UUID.self, forKey: .groupId)
        self.stashedFgColor = try c.decodeIfPresent(String.self, forKey: .stashedFgColor)
        self.stashedBgColor = try c.decodeIfPresent(String.self, forKey: .stashedBgColor)
        self.notify        = (try? c.decode(Bool.self, forKey: .notify)) ?? false
    }
}

/// A named bundle of styling and behavior applied to all member rules.
/// Members override per-field — a rule with its own `fgColor` ignores
/// the group's, but a rule that leaves `fgColor` unset inherits from here.
///
/// Mirrors the spell-preset group pattern in `SpellGroup`, letting related
/// rules be organized together and share styling + notification defaults.
public struct HighlightGroup: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    /// Default foreground / background. Member rules inherit these
    /// when their own field is nil.
    public var fgColor: String?
    public var bgColor: String?
    /// Trait additions that OR with each member rule's own toggles. The group
    /// is the floor: a member rule can promote (enable) but not demote these.
    public var bold: Bool
    public var italic: Bool
    public var entireLine: Bool
    public var caseSensitive: Bool
    public var wholeWord: Bool
    /// Master toggle. When false, every member rule is treated as disabled;
    /// each rule's own `enabled` flag is preserved so flipping the group back
    /// on restores the prior state.
    public var enabled: Bool
    /// When true, a match by any member rule posts a macOS notification with
    /// the matched line as the body. ORs with each rule's own `notify`.
    public var notify: Bool
    /// Persisted last-chosen fg / bg, mirrors the stash on Highlight.
    /// Lets the user toggle "Default text color" off and back on
    /// without losing the color value, even across app restarts.
    public var stashedFgColor: String?
    public var stashedBgColor: String?

    public init(
        id: UUID = UUID(),
        name: String = "",
        fgColor: String? = nil,
        bgColor: String? = nil,
        bold: Bool = false,
        italic: Bool = false,
        entireLine: Bool = false,
        caseSensitive: Bool = false,
        wholeWord: Bool = false,
        enabled: Bool = true,
        notify: Bool = false,
        stashedFgColor: String? = nil,
        stashedBgColor: String? = nil
    ) {
        self.id = id
        self.name = name
        self.fgColor = fgColor
        self.bgColor = bgColor
        self.bold = bold
        self.italic = italic
        self.entireLine = entireLine
        self.caseSensitive = caseSensitive
        self.wholeWord = wholeWord
        self.enabled = enabled
        self.notify = notify
        self.stashedFgColor = stashedFgColor
        self.stashedBgColor = stashedBgColor
    }

    // Backward-compat decode: stash fields and the matching flags
    // (entireLine/caseSensitive/wholeWord) decode to nil/false on older configs.
    private enum CodingKeys: String, CodingKey {
        case id, name, fgColor, bgColor, bold, italic, enabled, notify, stashedFgColor, stashedBgColor
        case entireLine, caseSensitive, wholeWord
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id      = try c.decode(UUID.self, forKey: .id)
        self.name    = try c.decode(String.self, forKey: .name)
        self.fgColor = try c.decodeIfPresent(String.self, forKey: .fgColor)
        self.bgColor = try c.decodeIfPresent(String.self, forKey: .bgColor)
        self.bold    = try c.decode(Bool.self, forKey: .bold)
        self.italic  = try c.decode(Bool.self, forKey: .italic)
        self.enabled = try c.decode(Bool.self, forKey: .enabled)
        self.notify  = try c.decode(Bool.self, forKey: .notify)
        self.stashedFgColor = try c.decodeIfPresent(String.self, forKey: .stashedFgColor)
        self.stashedBgColor = try c.decodeIfPresent(String.self, forKey: .stashedBgColor)
        self.entireLine    = (try? c.decode(Bool.self, forKey: .entireLine))    ?? false
        self.caseSensitive = (try? c.decode(Bool.self, forKey: .caseSensitive)) ?? false
        self.wholeWord     = (try? c.decode(Bool.self, forKey: .wholeWord))     ?? false
    }
}

/// Resolves a flat rule list against the user's groups. Member rules
/// of a group inherit unset fg/bg from the group, OR their bold/italic
/// flags with the group's, and are treated as disabled when the group
/// itself is disabled. Pure value -- safe to call from any thread.
public enum HighlightResolver {
    public static func resolve(_ rules: [Highlight], groups: [HighlightGroup]) -> [Highlight] {
        guard !groups.isEmpty else { return rules }
        let byId = Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
        return rules.map { rule in
            guard let gid = rule.groupId, let group = byId[gid] else { return rule }
            var resolved = rule
            resolved.enabled = rule.enabled && group.enabled
            if resolved.fgColor == nil { resolved.fgColor = group.fgColor }
            if resolved.bgColor == nil { resolved.bgColor = group.bgColor }
            resolved.bold          = resolved.bold          || group.bold
            resolved.italic        = resolved.italic        || group.italic
            resolved.entireLine    = resolved.entireLine    || group.entireLine
            resolved.caseSensitive = resolved.caseSensitive || group.caseSensitive
            resolved.wholeWord     = resolved.wholeWord     || group.wholeWord
            resolved.notify        = resolved.notify        || group.notify
            return resolved
        }
    }
}

public struct HighlightConfig: Codable, Equatable, Sendable {
    public var highlights: [Highlight]
    public var groups: [HighlightGroup]

    public init(highlights: [Highlight] = [], groups: [HighlightGroup] = []) {
        self.highlights = highlights
        self.groups = groups
    }

    // Custom decoding so configs saved before `groups` existed still
    // load -- pre-grouping configs decode with `groups = []`.
    private enum CodingKeys: String, CodingKey {
        case highlights, groups
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.highlights = try c.decode([Highlight].self, forKey: .highlights)
        self.groups     = (try? c.decode([HighlightGroup].self, forKey: .groups)) ?? []
    }
}
