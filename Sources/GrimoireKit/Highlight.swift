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
    /// Font-trait additions applied to matched spans. Stack on top of
    /// the protocol-derived `<b>` / monsterbold bold, so a user rule
    /// can promote a span without un-bolding anything already bolded.
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool

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
        underline: Bool = false,
        strikethrough: Bool = false
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
        self.underline = underline
        self.strikethrough = strikethrough
    }

    // Custom decoding so configs saved before any of these later fields
    // existed still load -- anything missing gets a backward-compatible
    // default (text kind, literal matching, no font traits).
    private enum CodingKeys: String, CodingKey {
        case id, text, fgColor, bgColor, entireLine, caseSensitive, wholeWord, enabled, kind, usesPattern
        case bold, italic, underline, strikethrough
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
        self.underline     = (try? c.decode(Bool.self, forKey: .underline)) ?? false
        self.strikethrough = (try? c.decode(Bool.self, forKey: .strikethrough)) ?? false
    }
}

public struct HighlightConfig: Codable, Equatable, Sendable {
    public var highlights: [Highlight]

    public init(highlights: [Highlight] = []) {
        self.highlights = highlights
    }
}
