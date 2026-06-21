import Foundation

/// A styled span of text within a rendered line.
public struct RenderedRun: Equatable, Sendable {
    public var text: String
    public var style: RunStyle

    public init(text: String, style: RunStyle) {
        self.text = text
        self.style = style
    }
}

/// Visual attributes carried by a run.
public struct RunStyle: Equatable, Hashable, Sendable {
    public var bold: Bool
    /// True inside `<pushBold/>`/`<popBold/>` markers or the `monsterbold`
    /// preset — Stormfront's convention for hostile NPCs. Distinct from `bold`
    /// (plain `<b>` emphasis like item names) so the renderer can colour
    /// monsterbold yellow without dragging item bolds along.
    public var monsterbold: Bool
    public var styleId: String?
    public var link: LinkRef?
    public var isPrompt: Bool
    /// Override foreground colour from a custom Highlight, hex `#RRGGBB`.
    public var highlightFg: String?
    /// Override background colour from a custom Highlight, hex `#RRGGBB`.
    public var highlightBg: String?
    /// Highlight-driven trait additions, stacked on top of the
    /// protocol-derived `bold`/`monsterbold` so a user rule can promote a span
    /// without un-bolding what was already bold. `italic` has only a highlight
    /// source — the SF/Wrayth protocol doesn't emit italic.
    public var highlightBold: Bool
    public var italic: Bool

    public init(
        bold: Bool = false,
        monsterbold: Bool = false,
        styleId: String? = nil,
        link: LinkRef? = nil,
        isPrompt: Bool = false,
        highlightFg: String? = nil,
        highlightBg: String? = nil,
        highlightBold: Bool = false,
        italic: Bool = false
    ) {
        self.bold = bold
        self.monsterbold = monsterbold
        self.styleId = styleId
        self.link = link
        self.isPrompt = isPrompt
        self.highlightFg = highlightFg
        self.highlightBg = highlightBg
        self.highlightBold = highlightBold
        self.italic = italic
    }
}

public enum LinkKind: String, Equatable, Hashable, Sendable {
    case entity
    case direction
}

public struct LinkRef: Equatable, Hashable, Sendable {
    public var exist: String
    public var noun: String?
    public var kind: LinkKind
    /// `<a coord='X' ...>` — the lookup key into the server's `<cmdlist>`
    /// for click-to-command resolution. Nil for direction links and for
    /// older-style `<a exist=...>` entities without a coord.
    public var coord: String?
    /// `<a href='https://...'>` — an external URL the click should open
    /// directly in the user's browser, bypassing the cmdlist lookup.
    public var href: String?
    /// `<d cmd='X'>...</d>` — the literal command string to send when
    /// this link is clicked. Carried directly on the tag (no cmdlist
    /// lookup needed). Used by `<d>` links almost exclusively, but the
    /// server occasionally puts a `cmd` on an `<a>` too.
    public var cmd: String?

    public init(
        exist: String,
        noun: String?,
        kind: LinkKind,
        coord: String? = nil,
        href: String? = nil,
        cmd: String? = nil
    ) {
        self.exist = exist
        self.noun = noun
        self.kind = kind
        self.coord = coord
        self.href = href
        self.cmd = cmd
    }
}

/// One line of game output, broken into styled runs.
public struct RenderedLine: Equatable, Sendable {
    public var runs: [RenderedRun]

    public init(runs: [RenderedRun]) {
        self.runs = runs
    }

    public var plainText: String {
        runs.map(\.text).joined()
    }
}
