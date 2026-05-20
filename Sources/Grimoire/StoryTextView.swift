import SwiftUI
import AppKit
import GrimoireKit

/// Renders the main story feed inside a single `NSTextView`. This is the
/// only way to get multi-line selection / copy on macOS — SwiftUI's
/// `Text(AttributedString).textSelection(.enabled)` selects within one
/// `Text` view at a time, so a feed built from per-line `Text` views can
/// only ever copy one line.
///
/// Performance note: we append only the *new* lines on each update unless
/// the font or highlights change, so steady-state cost is O(new) rather
/// than O(total).
struct StoryTextView: NSViewRepresentable {
    let lines: [RenderedLine]
    /// Monotonic content revision from `LichClient` — total lines ever
    /// appended to this stream, ignoring cap-trimming. The reconcile path
    /// uses `revision - appliedRevision` as the canonical "how many new
    /// lines arrived" signal, which works correctly even when the visible
    /// `lines.count` is pinned at the cap and stops changing.
    let revision: Int
    let highlights: [Highlight]
    let onLinkClick: (URL) -> Void

    @Environment(\.fontSize) private var fontSize

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        // TextKit 1 (NSLayoutManager), not TextKit 2 (NSTextLayoutManager).
        // TextKit 2 walks every paragraph synchronously on each viewport
        // layout query (`_estimatedTextLocationForVerticalOffset:`), which
        // wedges the main thread for tens of seconds once the feed has a
        // few thousand lines. TextKit 1's flat layout-fragment cache makes
        // those queries O(log n) and stays responsive under bursty appends.
        let textView = NSTextView(usingTextLayoutManager: false)
        textView.frame = NSRect(origin: .zero, size: scrollView.contentSize)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(
            width: CGFloat.greatestFiniteMagnitude,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: .greatestFiniteMagnitude
        )

        textView.isEditable = false
        textView.isSelectable = true
        textView.allowsUndo = false
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.textContainerInset = NSSize(width: 14, height: 10)
        // Hide the NSTextView from the system accessibility tree.
        // Every `.link` attribute in the storage becomes an
        // `NSAccessibilityTextLink` child element automatically; with
        // thousands of lines and multiple links each, macOS's
        // navigation-order merge sort (`__AXNavigationOrderCompareUIElementFrames`)
        // calls grind the main thread for ~10s at a time whenever any
        // a11y hit-test fires (VoiceOver, Hover Text, Accessibility
        // Inspector, etc.). Marking the text view as a non-element
        // removes its whole subtree from the sort. Mouse-click link
        // dispatch still works because the link attribute is intact —
        // we just don't surface the per-link a11y elements.
        textView.setAccessibilityElement(false)
        textView.setAccessibilityChildren([])
        // Override NSTextView's default link styling so our per-run colours
        // (teal entity, green direction) and underline stay authoritative.
        // We deliberately *omit* `.foregroundColor` here — providing any
        // value would override the source attributes uniformly across all
        // links. Without the key, source attributes win.
        textView.linkTextAttributes = [
            .cursor: NSCursor.pointingHand
        ]
        textView.delegate = context.coordinator

        scrollView.documentView = textView

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        context.coordinator.onLinkClick = onLinkClick
        context.coordinator.attachScrollObservers(to: scrollView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onLinkClick = onLinkClick
        context.coordinator.reconcile(
            lines: lines,
            revision: revision,
            fontSize: fontSize,
            highlights: highlights
        )
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        weak var scrollView: NSScrollView?
        weak var textView: NSTextView?
        var onLinkClick: ((URL) -> Void)?

        private var appliedLineCount: Int = 0
        private var appliedRevision: Int = 0
        private var appliedFontSize: Double = 0
        private var appliedHighlightHash: Int = 0

        /// True while the user is actively dragging the scroll thumb or
        /// using a trackpad scroll. Suppresses auto-scroll-to-bottom so a
        /// burst of new lines arriving mid-drag doesn't yank them.
        private var userScrolling: Bool = false
        /// Timestamp of the most recent live-scroll end, so we keep
        /// suppressing auto-scroll briefly after the user releases.
        private var lastUserScrollEndedAt: Date = .distantPast
        private var scrollObservers: [NSObjectProtocol] = []

        /// Character lengths (including the joining newline) of each line
        /// currently rendered into the text storage. Lets us do an
        /// O(dropped-line-count) front-delete when LichClient trims its
        /// buffer, instead of a full structural rebuild that resets the
        /// scroll position.
        private var lineCharLengths: [Int] = []

        private let bottomThreshold: CGFloat = 40

        func reconcile(
            lines: [RenderedLine],
            revision: Int,
            fontSize: Double,
            highlights: [Highlight]
        ) {
            guard let textView, let storage = textView.textStorage else { return }
            let started = CFAbsoluteTimeGetCurrent()
            // Pre-reconcile scroll snapshot — captures any "blank zone"
            // state (gap < 0) before our mutations.
            let preState = captureScrollState()

            var hasher = Hasher()
            hasher.combine(highlights)
            let highlightHash = hasher.finalize()

            let fontChanged = appliedFontSize != fontSize
            let highlightsChanged = appliedHighlightHash != highlightHash
            let structuralChange = fontChanged || highlightsChanged

            // `newSinceApplied` is the source of truth for "how many new
            // lines arrived since we last reconciled." Using this rather
            // than `lines.count - appliedLineCount` is what makes the
            // at-cap path work — once a stream is pinned at its cap,
            // `lines.count` stops changing but `revision` keeps climbing
            // by exactly the number of appends per batch.
            let newSinceApplied = revision - appliedRevision

            let wasAtBottom = isAtBottom
            var newLines = 0
            var didStructuralRebuild = false
            var didFrontTrim = false

            // Rebuild from scratch if:
            //  - font/highlight changed (existing case),
            //  - revision went backwards (reconnect / client reset), or
            //  - the gap is bigger than `lines` itself, meaning the cap
            //    trimmed away more than we could reconstruct incrementally.
            let mustRebuild = structuralChange
                || newSinceApplied < 0
                || newSinceApplied > lines.count

            // Per-phase timings — captured so we can see whether the
            // "blank for a second" symptom correlates with a slow build,
            // a slow append, or a slow front-trim. Each phase invalidates
            // layout in the text manager independently, so any phase
            // taking >5ms is suspicious.
            var buildMs: Double = 0
            var appendMs: Double = 0
            var trimMs: Double = 0

            if mustRebuild {
                let bStart = CFAbsoluteTimeGetCurrent()
                let (attr, lengths) = buildAllWithLengths(
                    lines: lines, fontSize: fontSize, highlights: highlights
                )
                buildMs = (CFAbsoluteTimeGetCurrent() - bStart) * 1000

                let aStart = CFAbsoluteTimeGetCurrent()
                storage.setAttributedString(attr)
                appendMs = (CFAbsoluteTimeGetCurrent() - aStart) * 1000

                lineCharLengths = lengths
                appliedLineCount = lines.count
                newLines = lines.count
                didStructuralRebuild = true
            } else if newSinceApplied > 0 {
                // The last `newSinceApplied` entries of `lines` are the
                // newly-arrived ones — append them to storage.
                let slice = Array(lines.suffix(newSinceApplied))

                let bStart = CFAbsoluteTimeGetCurrent()
                let (attr, lengths) = buildAllWithLengths(
                    lines: slice, fontSize: fontSize, highlights: highlights
                )
                buildMs = (CFAbsoluteTimeGetCurrent() - bStart) * 1000

                let aStart = CFAbsoluteTimeGetCurrent()
                storage.append(attr)
                appendMs = (CFAbsoluteTimeGetCurrent() - aStart) * 1000

                lineCharLengths.append(contentsOf: lengths)
                appliedLineCount += newSinceApplied
                newLines = newSinceApplied

                // At-cap shift: client trimmed the same number off its
                // front that we just appended to its tail. Mirror that in
                // storage so visible line count tracks `lines.count`.
                if appliedLineCount > lines.count {
                    let extra = appliedLineCount - lines.count
                    let safeExtra = min(extra, lineCharLengths.count)
                    let charsToRemove = lineCharLengths.prefix(safeExtra).reduce(0, +)
                    if charsToRemove > 0, charsToRemove <= storage.length {
                        let tStart = CFAbsoluteTimeGetCurrent()
                        storage.deleteCharacters(in: NSRange(location: 0, length: charsToRemove))
                        trimMs = (CFAbsoluteTimeGetCurrent() - tStart) * 1000
                    }
                    lineCharLengths.removeFirst(safeExtra)
                    appliedLineCount -= safeExtra
                    didFrontTrim = true
                }
            } else if lines.count < appliedLineCount {
                // No new content but the buffer shrank — external trim
                // (e.g., disconnect-clear). Mirror it.
                let dropped = appliedLineCount - lines.count
                let safeDropped = min(dropped, lineCharLengths.count)
                let charsToRemove = lineCharLengths.prefix(safeDropped).reduce(0, +)
                if charsToRemove > 0, charsToRemove <= storage.length {
                    let tStart = CFAbsoluteTimeGetCurrent()
                    storage.deleteCharacters(in: NSRange(location: 0, length: charsToRemove))
                    trimMs = (CFAbsoluteTimeGetCurrent() - tStart) * 1000
                }
                lineCharLengths.removeFirst(safeDropped)
                appliedLineCount = lines.count
                didFrontTrim = true
            } else {
                return
            }

            appliedRevision = revision
            appliedFontSize = fontSize
            appliedHighlightHash = highlightHash

            // Suppress auto-scroll while the user is actively dragging the
            // scroll thumb, or in the 400ms after they release. Without
            // this, a burst of lines mid-drag yanks the view to the bottom
            // and the user can't escape the auto-follow to read history.
            let userScrolledRecently = userScrolling
                || Date().timeIntervalSince(lastUserScrollEndedAt) < 0.4

            if wasAtBottom && !userScrolledRecently {
                // Diagnostic: capture the mutation-end timestamp and a
                // snapshot of layout state so `scrollToBottom` can log
                // (a) how long the async hop took and (b) whether the
                // visible bottom was still un-laid-out at scroll-fire
                // time. If the visible bottom is past
                // `firstUnlaidCharacterIndex`, AppKit can draw the
                // un-laid region as background (the suspected source of
                // the "black for a second" flash).
                let mutationCompletedAt = CFAbsoluteTimeGetCurrent()
                let mutationLayout = captureLayoutState()
                DispatchQueue.main.async { [weak self] in
                    self?.scrollToBottom(
                        mutationCompletedAt: mutationCompletedAt,
                        mutationLayout: mutationLayout
                    )
                }
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - started
            // Log when total reconcile is slow, when we did a structural
            // rebuild, OR when any single phase exceeded 5ms — the
            // last condition is what catches the "blank for a second"
            // suspect: a long append or trim that holds the layout
            // manager mid-state across a display refresh.
            let anyPhaseSlow = buildMs > 5 || appendMs > 5 || trimMs > 5
            if elapsed > 0.1 || didStructuralRebuild || anyPhaseSlow {
                appLog(
                    "StoryTextView",
                    "Reconcile \(String(format: "%.0f", elapsed * 1000))ms"
                    + " (build=\(String(format: "%.1f", buildMs))ms"
                    + " append=\(String(format: "%.1f", appendMs))ms"
                    + " trim=\(String(format: "%.1f", trimMs))ms),"
                    + " \(newLines) new, structural=\(didStructuralRebuild),"
                    + " frontTrim=\(didFrontTrim), total=\(self.appliedLineCount)",
                    level: .info
                )
            }

            // Blank-screen diagnostic: log pre- and post-reconcile scroll
            // state whenever something is suspicious — either the pre-state
            // had a negative gap (clip was past the doc, the suspected
            // "blank zone"), or the doc height changed meaningfully across
            // this reconcile, or we did a front-trim (front-trims are the
            // most-likely culprit since they shrink the doc).
            let postState = captureScrollState()
            let preHadBlank = (preState?.gap ?? 0) < -1
            let postHasBlank = (postState?.gap ?? 0) < -1
            let docShifted: Bool = {
                guard let p = preState, let q = postState else { return false }
                return abs(p.docH - q.docH) > 1
            }()
            if preHadBlank || postHasBlank || didFrontTrim || docShifted {
                if let p = preState { appLog("StoryTextView", p.description("pre "), level: .info) }
                if let q = postState { appLog("StoryTextView", q.description("post"), level: .info) }
            }
        }

        private var isAtBottom: Bool {
            guard let scrollView, let doc = scrollView.documentView else { return true }
            let clipBottom = scrollView.contentView.bounds.origin.y
                + scrollView.contentView.bounds.height
            return (doc.frame.height - clipBottom) <= bottomThreshold
        }

        /// Snapshot of the scroll/clip geometry. Used by the blank-screen
        /// diagnostic — when `gap` is negative the clip view is showing
        /// space *past* the document's bottom edge, which is the
        /// suspected cause of the "story goes blank for a second" symptom.
        private struct ScrollState {
            var scrollY: CGFloat
            var clipH: CGFloat
            var docH: CGFloat
            var gap: CGFloat   // docH - clipBottom (positive = content extends below; negative = clip past end)

            func description(_ context: String) -> String {
                "scroll[\(context)] y=\(Int(scrollY)) clipH=\(Int(clipH)) docH=\(Int(docH)) gap=\(Int(gap))"
            }
        }

        private func captureScrollState() -> ScrollState? {
            guard let scrollView, let doc = scrollView.documentView else { return nil }
            let scrollY = scrollView.contentView.bounds.origin.y
            let clipH = scrollView.contentView.bounds.height
            let docH = doc.frame.height
            return ScrollState(
                scrollY: scrollY,
                clipH: clipH,
                docH: docH,
                gap: docH - (scrollY + clipH)
            )
        }

        /// Snapshot of the layout manager's progress vs the storage and the
        /// visible region. The "black for a second" hypothesis is that
        /// `firstUnlaidCharacterIndex < visibleCharRange.upperBound` at the
        /// moment AppKit draws — i.e. the visible bottom is past the layout
        /// frontier, so glyphs aren't generated and the background is what
        /// gets drawn.
        struct LayoutState {
            var storageLength: Int
            var firstUnlaid: Int
            var visibleCharStart: Int
            var visibleCharEnd: Int

            /// True when the bottom of the visible region extends past the
            /// layout frontier — the suspected condition for the flash.
            var visibleBottomUnlaid: Bool {
                firstUnlaid < visibleCharEnd
            }
        }

        private func captureLayoutState() -> LayoutState? {
            guard let textView,
                  let storage = textView.textStorage,
                  let lm = textView.layoutManager,
                  let container = textView.textContainer
            else { return nil }
            let visibleRect = textView.visibleRect
            let visibleGlyphRange = lm.glyphRange(forBoundingRect: visibleRect, in: container)
            let visibleCharRange = lm.characterRange(
                forGlyphRange: visibleGlyphRange,
                actualGlyphRange: nil
            )
            return LayoutState(
                storageLength: storage.length,
                firstUnlaid: lm.firstUnlaidCharacterIndex(),
                visibleCharStart: visibleCharRange.location,
                visibleCharEnd: visibleCharRange.location + visibleCharRange.length
            )
        }

        /// Logs scroll geometry whenever it's "interesting" — gap < 0 (the
        /// blank condition), or any change from the last logged state in
        /// the gap or docH dimensions worth recording. Pre-/post-reconcile
        /// and on scroll-to-bottom calls.
        private func logScroll(_ context: String) {
            guard let state = captureScrollState() else { return }
            appLog("StoryTextView", state.description(context), level: .info)
        }

        /// Hook the AppKit live-scroll notifications so we can know when
        /// the user is actively dragging the thumb (or trackpad-scrolling).
        /// Auto-scroll-to-bottom is suppressed during that window so a
        /// burst of new content doesn't yank the user away from history.
        func attachScrollObservers(to scrollView: NSScrollView) {
            for token in scrollObservers {
                NotificationCenter.default.removeObserver(token)
            }
            scrollObservers.removeAll()

            scrollObservers.append(NotificationCenter.default.addObserver(
                forName: NSScrollView.willStartLiveScrollNotification,
                object: scrollView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.userScrolling = true }
            })
            scrollObservers.append(NotificationCenter.default.addObserver(
                forName: NSScrollView.didEndLiveScrollNotification,
                object: scrollView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    self.userScrolling = false
                    // If the user released *at* the bottom, treat that as a
                    // deliberate "follow again" gesture: skip the grace
                    // window so the next reconcile auto-scrolls, and snap
                    // now in case lines arrived during the drag.
                    if self.isAtBottom {
                        self.lastUserScrollEndedAt = .distantPast
                        self.scrollToBottom()
                    } else {
                        self.lastUserScrollEndedAt = Date()
                    }
                }
            })
        }

        /// Plain entry point (no diagnostic context) — used by the
        /// live-scroll observer's "release at bottom" path.
        private func scrollToBottom() {
            scrollToBottom(mutationCompletedAt: nil, mutationLayout: nil)
        }

        private func scrollToBottom(
            mutationCompletedAt: CFAbsoluteTime?,
            mutationLayout: LayoutState?
        ) {
            // `scrollRangeToVisible` is targeted — it only lays out enough
            // text to bring the end of the document on-screen, instead of
            // the entire textContainer. The previous `ensureLayout(for:)`
            // version stalled the main thread for >1s once the feed grew
            // past a few thousand lines.
            guard let textView, let storage = textView.textStorage else { return }

            // Diagnostic: capture layout state at scroll-fire time, before
            // any further mutation. We then have three snapshots:
            //   mutationLayout  — right after the storage mutation
            //   preFireLayout   — right before scrollRangeToVisible runs
            //                     (i.e. the moment AppKit *could* have drawn
            //                     between the reconcile returning and us
            //                     getting here from the async hop)
            // If `visibleBottomUnlaid` is true at preFire, that's the
            // smoking-gun condition for the "black for a second" flash —
            // visible glyphs weren't generated before drawing.
            if let preFire = captureLayoutState() {
                let delayMs: String
                if let started = mutationCompletedAt {
                    delayMs = String(format: "%.1f", (CFAbsoluteTimeGetCurrent() - started) * 1000)
                } else {
                    delayMs = "n/a"
                }
                let mutUnlaid = mutationLayout?.visibleBottomUnlaid ?? false
                if mutUnlaid || preFire.visibleBottomUnlaid {
                    appLog(
                        "StoryTextView",
                        "BLACKFLASH suspect: hopDelay=\(delayMs)ms"
                        + " | mut[unlaid=\(mutationLayout?.firstUnlaid ?? -1)"
                        + " visible=\(mutationLayout?.visibleCharStart ?? -1)..\(mutationLayout?.visibleCharEnd ?? -1)"
                        + " storage=\(mutationLayout?.storageLength ?? -1)]"
                        + " preFire[unlaid=\(preFire.firstUnlaid)"
                        + " visible=\(preFire.visibleCharStart)..\(preFire.visibleCharEnd)"
                        + " storage=\(preFire.storageLength)]"
                        + " mutUnlaid=\(mutUnlaid) preFireUnlaid=\(preFire.visibleBottomUnlaid)",
                        level: .info
                    )
                }
            }

            // Log the state we're correcting from, but only when it's
            // interesting — i.e., the clip is in the blank zone past the
            // doc end (gap < -1). Otherwise we'd spam the log on every
            // sticky-follow tick.
            if let state = captureScrollState(), state.gap < -1 {
                appLog("StoryTextView", state.description("BLANK→scroll"), level: .info)
            }
            textView.scrollRangeToVisible(NSRange(location: storage.length, length: 0))
        }

        // MARK: NSTextViewDelegate

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            let url: URL?
            switch link {
            case let u as URL:    url = u
            case let s as String: url = URL(string: s)
            default:              url = nil
            }
            guard let url else { return false }
            onLinkClick?(url)
            return true
        }
    }
}

// MARK: - Attributed-string construction

@MainActor
private func buildAllWithLengths(
    lines: [RenderedLine],
    fontSize: Double,
    highlights: [Highlight]
) -> (attributed: NSAttributedString, lineLengths: [Int]) {
    let result = NSMutableAttributedString()
    var lengths: [Int] = []
    lengths.reserveCapacity(lines.count)
    for line in lines {
        let processed = highlights.isEmpty
            ? line
            : HighlightProcessor.apply(highlights, to: line)
        let before = result.length
        appendLine(processed, into: result, fontSize: CGFloat(fontSize))
        // Every line gets a terminating newline so subsequent appends sit
        // on their own row. Including the newline in the per-line char
        // count makes front-trim arithmetic exact.
        result.append(NSAttributedString(string: "\n"))
        lengths.append(result.length - before)
    }
    return (result, lengths)
}

@MainActor
private func appendLine(
    _ line: RenderedLine,
    into out: NSMutableAttributedString,
    fontSize: CGFloat
) {
    for run in line.runs where !run.text.isEmpty {
        let s = run.style
        var attrs: [NSAttributedString.Key: Any] = [:]

        let bold = s.bold || s.monsterbold || s.styleId == "roomName"
        attrs[.font] = NSFont.monospacedSystemFont(
            ofSize: fontSize,
            weight: bold ? .bold : .regular
        )

        let fg: NSColor
        if let hex = s.highlightFg, let c = NSColor(hexString: hex) {
            fg = c
        } else if s.monsterbold {
            fg = NSColor(GameTheme.monsterbold)
        } else if s.isPrompt {
            fg = NSColor(GameTheme.prompt)
        } else if s.styleId == "roomName" {
            fg = NSColor(GameTheme.roomName)
        } else if s.styleId == "speech" {
            fg = NSColor(GameTheme.speech)
        } else if s.styleId == "whisper" {
            fg = NSColor(GameTheme.whisper)
        } else if s.styleId == "thought" {
            fg = NSColor(GameTheme.thought)
        } else if let link = s.link {
            fg = link.kind == .direction
                ? NSColor(GameTheme.directionLink)
                : NSColor(GameTheme.entityLink)
        } else if s.styleId == "roomDesc" {
            fg = NSColor(GameTheme.roomDesc)
        } else {
            fg = NSColor(GameTheme.foreground)
        }
        attrs[.foregroundColor] = fg

        if let hex = s.highlightBg, let c = NSColor(hexString: hex) {
            attrs[.backgroundColor] = c
        }

        if let link = s.link, let url = link.clickURL() {
            attrs[.link] = url
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            attrs[.underlineColor] = fg
        }

        out.append(NSAttributedString(string: run.text, attributes: attrs))
    }
}

