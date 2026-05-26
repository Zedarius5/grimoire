import SwiftUI
import GrimoireKit

/// The main story feed. Backed by `NSTextView` (via `StoryTextView`) so the
/// user can drag-select across multiple lines — a SwiftUI `Text`-per-line
/// LazyVStack can only ever select within a single line.
struct GameView: View, Equatable {
    let lines: [RenderedLine]
    let revision: Int
    let onLinkClick: (URL) -> Void

    @Environment(\.highlights) private var highlights
    @Environment(\.fontSize) private var fontSize

    /// Equality is keyed on `revision`, not `lines.count`. Once a stream
    /// reaches its cap, every new append is paired with a front-trim and
    /// `lines.count` stops changing — `.equatable()` would then
    /// permanently short-circuit body re-evaluation and the feed would
    /// visually freeze even while new content is being applied. The
    /// monotonic revision from `LichClient` changes on every append, so
    /// we re-evaluate whenever there's real new content.
    nonisolated static func == (lhs: GameView, rhs: GameView) -> Bool {
        lhs.revision == rhs.revision
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("main")
        StoryTextView(
            lines: lines,
            revision: revision,
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
    @Environment(\.fontSize) private var fontSize

    /// See note on `GameView.==` — `lines.count` freezes once the stream
    /// hits its cap, so we key equality on the monotonic revision instead.
    /// `isActive` is included so flipping it triggers body re-evaluation
    /// and the fade reliably fires. `onLinkClick` is intentionally
    /// excluded because closures aren't `Equatable`; the handler we pass
    /// is stable across renders anyway.
    nonisolated static func == (lhs: StreamPane, rhs: StreamPane) -> Bool {
        lhs.title == rhs.title &&
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
            //
            // Side panes render text 1pt smaller than the main feed.
            // Overriding `\.fontSize` for just this subtree keeps that
            // adjustment localised without re-introducing the explicit
            // parameter pass-through.
            StoryTextView(
                lines: lines,
                revision: revision,
                highlights: highlights,
                onLinkClick: onLinkClick
            )
            .environment(\.fontSize, fontSize - 1)
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

// MARK: - Environment keys

private struct HighlightsEnvironmentKey: EnvironmentKey {
    static let defaultValue: [Highlight] = []
}

private struct FontSizeEnvironmentKey: EnvironmentKey {
    /// Matches `ContentView`'s default `@State` value so an unset env still
    /// renders with the expected base size.
    static let defaultValue: Double = 13
}

extension EnvironmentValues {
    var highlights: [Highlight] {
        get { self[HighlightsEnvironmentKey.self] }
        set { self[HighlightsEnvironmentKey.self] = newValue }
    }

    /// The user-chosen text size for the feed and side panes. Sourced from
    /// the slider in `OptionsPopover`; ContentView injects it onto the view
    /// tree once so downstream views don't need to thread it as a parameter.
    var fontSize: Double {
        get { self[FontSizeEnvironmentKey.self] }
        set { self[FontSizeEnvironmentKey.self] = newValue }
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

    // Wound badges — flat-colour pips for the paperdoll. Severity (1/2/3)
    // is conveyed by the number printed in the pip, not by gradient shading.
    static let woundInjury = Color(red: 0.86, green: 0.16, blue: 0.16)   // crimson red
    static let woundScar   = Color(red: 0.82, green: 0.66, blue: 0.43)   // warm tan

    // Speech family — Stormfront <preset id="speech"|"whisper"|"thought">.
    // Same warm-to-cool gradient across the pink-magenta-lavender range so
    // they read as related but immediately distinguishable. Hue separation
    // (~30°+ apart) is what makes them feel "notably different"; staying
    // in the same family is what makes them feel cohesive.
    static let speech  = Color(red: 1.00, green: 0.68, blue: 0.78)  // warm coral pink — audible
    static let whisper = Color(red: 0.60, green: 0.74, blue: 0.86)  // cool slate blue, muted — private/quiet (visually distinct from speech's warm pink)
    static let thought = Color(red: 0.78, green: 0.65, blue: 1.00)  // soft lavender — internal
}
