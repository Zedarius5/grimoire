import SwiftUI
import GrimoireKit

/// The main story feed. Backed by `NSTextView` (via `StoryTextView`) so the
/// user can drag-select across multiple lines — a SwiftUI `Text`-per-line
/// LazyVStack can only ever select within a single line.
struct GameView: View, Equatable {
    let lines: [RenderedLine]
    let revision: Int
    let fontSize: Double
    let onLinkClick: (URL) -> Void

    @Environment(\.highlights) private var highlights

    /// Equality is keyed on `revision`, not `lines.count`. Once a stream
    /// reaches its cap, every new append is paired with a front-trim and
    /// `lines.count` stops changing — `.equatable()` would then
    /// permanently short-circuit body re-evaluation and the feed would
    /// visually freeze even while new content is being applied. The
    /// monotonic revision from `LichClient` changes on every append, so
    /// we re-evaluate whenever there's real new content.
    nonisolated static func == (lhs: GameView, rhs: GameView) -> Bool {
        lhs.fontSize == rhs.fontSize && lhs.revision == rhs.revision
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("main")
        StoryTextView(
            lines: lines,
            revision: revision,
            fontSize: fontSize,
            highlights: highlights,
            onLinkClick: onLinkClick
        )
        .background(GameTheme.background)
        .environment(\.colorScheme, .dark)
    }
}

/// A titled, bordered pane that shows a side stream (Thoughts, Familiar, etc.).
struct StreamPane: View, Equatable {
    let title: String
    let lines: [RenderedLine]
    let revision: Int
    let fontSize: Double
    /// Controls the visibility of the pane's *content*. The title
    /// header stays put regardless — only the body fades when this
    /// flips false.
    var isActive: Bool = true
    /// Click handler for `<a>`/`<d>` links inside lines. Same handler
    /// shape the main story uses — typically dispatches to
    /// `GrimoireLinkRouter`. Defaults to a no-op so test/preview call
    /// sites don't have to wire it up.
    var onLinkClick: (URL) -> Void = { _ in }

    @Environment(\.highlights) private var highlights

    /// See note on `GameView.==` — `lines.count` freezes once the stream
    /// hits its cap, so we key equality on the monotonic revision instead.
    /// `isActive` is included so flipping it triggers body re-evaluation
    /// and the fade reliably fires. `onLinkClick` is intentionally
    /// excluded because closures aren't `Equatable`; the handler we pass
    /// is stable across renders anyway.
    nonisolated static func == (lhs: StreamPane, rhs: StreamPane) -> Bool {
        lhs.title == rhs.title &&
        lhs.fontSize == rhs.fontSize &&
        lhs.revision == rhs.revision &&
        lhs.isActive == rhs.isActive
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("stream:\(title)")
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(0.8)
                    .foregroundStyle(GameTheme.paneTitle)
                Spacer()
                if !lines.isEmpty && isActive {
                    Text("\(lines.count)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(GameTheme.paneHeader)

            // Use the same `StoryTextView` (TextKit 1 NSTextView) the
            // main story uses, so drag-select across multiple lines
            // and copy work the same way here as they do in the main
            // feed. The per-pane line cap (500) is enforced by
            // LichClient; StoryTextView's reconcile handles the
            // append + trim. Only the text view fades on disconnect —
            // the title bar above stays put.
            StoryTextView(
                lines: lines,
                revision: revision,
                fontSize: fontSize - 1,
                highlights: highlights,
                onLinkClick: onLinkClick
            )
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 1.25), value: isActive)
        }
        .background(GameTheme.background)
        .overlay(
            Rectangle()
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }
}

/// Renders a single `RenderedLine` as a styled, wrapping line of text.
/// Reads `\.highlights` from the environment and applies them on the fly so
/// edits made in the highlight editor are reflected immediately in the feed.
/// Uses `AttributedString` so per-run background colours work alongside
/// foreground colours within a single wrapping line.
struct LineView: View {
    let line: RenderedLine
    let fontSize: Double
    @Environment(\.highlights) private var highlights

    private var processedLine: RenderedLine {
        highlights.isEmpty
            ? line
            : HighlightProcessor.apply(highlights, to: line)
    }

    var body: some View {
        Text(buildAttributed(processedLine))
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(GameTheme.foreground)
            .textSelection(.enabled)
            .lineSpacing(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            // Each `<a>`/`<d>` link in the AttributedString becomes an
            // `NSAccessibilityTextLink` element. Across thousands of
            // lines that's thousands of elements; macOS Accessibility's
            // O(N log N) navigation-order sort calls
            // `__AXNavigationOrderCompareUIElementFrames` for every
            // pair, fetching frames from SwiftUI each time. That wedges
            // the main thread for ~10 seconds at a time on any
            // accessibilityHitTest (e.g., a VoiceOver cursor probe,
            // Hover Text, or Accessibility Inspector query).
            //
            // Hiding the line from accessibility entirely eliminates
            // the elements from the tree and the sort cost vanishes.
            // Trade-off: screen readers can't navigate link-by-link
            // inside the story feed. Acceptable for now; if a11y
            // support comes up later we'd need a different mechanism
            // (custom rotor, batched links, or hidden-by-default
            // behind a setting).
            .accessibilityHidden(true)
    }

    private func buildAttributed(_ line: RenderedLine) -> AttributedString {
        var output = AttributedString()
        for run in line.runs where !run.text.isEmpty {
            var seg = AttributedString(run.text)
            let s = run.style

            // Only set seg.font when bold — Text(AttributedString) is happy
            // to inherit the outer `.font(...)` modifier for unset runs, and
            // setting it on every segment caused some lines to render blank.
            if s.bold || s.monsterbold || s.styleId == "roomName" {
                seg.font = .system(size: fontSize, design: .monospaced).bold()
            }

            // Foreground precedence: highlight rule wins over everything; then
            // monsterbold (NPCs / hostile creatures — Stormfront's yellow), then
            // prompt / roomName / link / roomDesc. Otherwise leave it unset so
            // the outer `.foregroundStyle(GameTheme.foreground)` applies.
            if let fg = s.highlightFg, let c = Color(hex: fg) {
                seg.foregroundColor = c
            } else if s.monsterbold {
                seg.foregroundColor = GameTheme.monsterbold
            } else if s.isPrompt {
                seg.foregroundColor = GameTheme.prompt
            } else if s.styleId == "roomName" {
                seg.foregroundColor = GameTheme.roomName
            } else if s.styleId == "speech" {
                seg.foregroundColor = GameTheme.speech
            } else if s.styleId == "whisper" {
                seg.foregroundColor = GameTheme.whisper
            } else if s.styleId == "thought" {
                seg.foregroundColor = GameTheme.thought
            } else if let link = s.link {
                switch link.kind {
                case .entity:
                    seg.foregroundColor = GameTheme.entityLink
                case .direction:
                    seg.foregroundColor = GameTheme.directionLink
                }
                // Underline anything we treat as a clickable link so the user
                // can see what's interactive at a glance, regardless of which
                // colour it's painted in.
                if let url = link.clickURL() {
                    seg.link = url
                    seg.underlineStyle = .single
                }
            } else if s.styleId == "roomDesc" {
                seg.foregroundColor = GameTheme.roomDesc
            }

            if let bg = s.highlightBg, let c = Color(hex: bg) {
                seg.backgroundColor = c
            }

            output.append(seg)
        }
        return output
    }
}

// MARK: - Environment key for live highlights

private struct HighlightsEnvironmentKey: EnvironmentKey {
    static let defaultValue: [Highlight] = []
}

extension EnvironmentValues {
    var highlights: [Highlight] {
        get { self[HighlightsEnvironmentKey.self] }
        set { self[HighlightsEnvironmentKey.self] = newValue }
    }
}

// MARK: - Hex color helper

extension Color {
    /// Parses `"#RGB"`, `"#RRGGBB"`, or `"#RRGGBBAA"`. Returns `nil` for
    /// malformed inputs so callers can fall back to a default.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard let value = UInt64(s, radix: 16) else { return nil }
        let r, g, b, a: Double
        switch s.count {
        case 3:
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double( value       & 0xF) / 15
            a = 1
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8)  & 0xFF) / 255
            b = Double( value        & 0xFF) / 255
            a = 1
        case 8:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8)  & 0xFF) / 255
            a = Double( value        & 0xFF) / 255
        default:
            return nil
        }
        self = Color(red: r, green: g, blue: b, opacity: a)
    }

    /// `#RRGGBB` round-trip — alpha is dropped for editor simplicity.
    var hexString: String? {
        let ns = NSColor(self).usingColorSpace(.sRGB) ?? NSColor(self)
        let r = Int((ns.redComponent   * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent  * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

enum GameTheme {
    static let background = Color(red: 0.07, green: 0.07, blue: 0.09)
    static let paneHeader = Color(red: 0.11, green: 0.11, blue: 0.14)
    static let paneTitle = Color(red: 0.65, green: 0.70, blue: 0.85)
    static let foreground = Color(red: 0.88, green: 0.88, blue: 0.90)
    static let roomName = Color(red: 1.00, green: 0.82, blue: 0.36)
    static let roomDesc = Color(red: 0.80, green: 0.80, blue: 0.84)
    static let entityLink = Color(red: 0.55, green: 0.86, blue: 1.00)
    static let directionLink = Color(red: 0.58, green: 0.95, blue: 0.58)
    static let prompt = Color(red: 0.55, green: 0.55, blue: 0.60)
    static let monsterbold = Color(red: 1.00, green: 0.85, blue: 0.20)

    // Speech family — Stormfront <preset id="speech"|"whisper"|"thought">.
    // Same warm-to-cool gradient across the pink-magenta-lavender range so
    // they read as related but immediately distinguishable. Hue separation
    // (~30°+ apart) is what makes them feel "notably different"; staying
    // in the same family is what makes them feel cohesive.
    static let speech  = Color(red: 1.00, green: 0.68, blue: 0.78)  // warm coral pink — audible
    static let whisper = Color(red: 0.78, green: 0.55, blue: 0.68)  // dusty rose, muted — quiet
    static let thought = Color(red: 0.78, green: 0.65, blue: 1.00)  // soft lavender — internal
}
