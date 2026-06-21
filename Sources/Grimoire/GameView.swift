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

    /// Equality is keyed on `revision`, not `lines.count`: once a stream
    /// reaches its cap, each append is paired with a front-trim and
    /// `lines.count` stops changing, so `.equatable()` would permanently
    /// freeze the feed. The monotonic `revision` changes on every append.
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

            // Same `StoryTextView` the main story uses, so drag-select and
            // copy behave identically. Side panes render 1pt smaller; we
            // override `\.fontSize` for just this subtree to keep that local.
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
    // Kept ~30°+ apart in hue so they're distinguishable, but in a related
    // range so they read as cohesive.
    static let speech  = Color(red: 1.00, green: 0.68, blue: 0.78)  // warm coral pink — audible
    static let whisper = Color(red: 0.60, green: 0.74, blue: 0.86)  // cool slate blue — private/quiet
    static let thought = Color(red: 0.78, green: 0.65, blue: 1.00)  // soft lavender — internal
}
