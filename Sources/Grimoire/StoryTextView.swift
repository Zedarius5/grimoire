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
        // Swap in a layout manager that trims trailing whitespace from
        // highlight background fills, so a match like "fat palm rat"
        // that wraps after "fat" doesn't paint a box past the last
        // visible glyph on the upper line.
        if let oldLM = textView.layoutManager,
           let container = textView.textContainer,
           let storage = textView.textStorage {
            let tightLM = TightBackgroundLayoutManager()
            storage.removeLayoutManager(oldLM)
            storage.addLayoutManager(tightLM)
            tightLM.addTextContainer(container)
        }
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
        /// True between scheduling and execution of an async
        /// scroll-to-bottom hop. Coalesces back-to-back reconciles so
        /// we don't call `scrollRangeToVisible` once per batch — that
        /// AppKit path forces glyph layout each time and was costing
        /// ~10% of main-thread CPU under busy game traffic.
        private var scrollToBottomScheduled: Bool = false
        /// Last known good scroll-y while the window was key. Used to
        /// restore position on `NSWindow.didBecomeKeyNotification`
        /// because AppKit sometimes resets the clipView's bounds.origin
        /// to (0,0) during the key-state transition, scrolling the
        /// user to the top of the doc on Cmd-Tab back.
        private var lastKnownScrollY: CGFloat? = nil
        /// Whether the user was parked at the bottom the last time we
        /// observed scroll state. If true, becomeKey re-fires
        /// scrollToBottom (so any new content that arrived while
        /// backgrounded gets brought into view) instead of restoring
        /// the absolute y-offset.
        private var wasAtBottomAtLastObserve: Bool = true

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
            // Snapshot the current scroll position so the
            // window-becomeKey observer has a recent value to restore
            // if AppKit reset the clip view during a Cmd-Tab cycle.
            if let sv = scrollView {
                lastKnownScrollY = sv.contentView.bounds.origin.y
                wasAtBottomAtLastObserve = isAtBottom
            }
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
                    trimMs = frontTrim(
                        lineCount: safeExtra,
                        storage: storage,
                        textView: textView,
                        preserveVisibleScroll: !wasAtBottom
                    )
                    appliedLineCount -= safeExtra
                    didFrontTrim = true
                }
            } else if lines.count < appliedLineCount {
                // No new content but the buffer shrank — external trim
                // (e.g., disconnect-clear). Mirror it.
                let dropped = appliedLineCount - lines.count
                let safeDropped = min(dropped, lineCharLengths.count)
                trimMs = frontTrim(
                    lineCount: safeDropped,
                    storage: storage,
                    textView: textView,
                    preserveVisibleScroll: !wasAtBottom
                )
                appliedLineCount = lines.count
                didFrontTrim = true
            } else {
                return
            }

            appliedRevision = revision
            appliedFontSize = fontSize
            appliedHighlightHash = highlightHash

            // Force layout for just the currently-visible region. Storage
            // mutations invalidate NSLayoutManager's glyph cache for the
            // affected range; if the display cycle fires before AppKit
            // lazy-lays-out those glyphs, the unfilled range paints as
            // pane background — the "black holes inside the visible
            // story" symptom that shows up around big container/INV
            // dumps. Bounded by `visibleRect` so the cost is one
            // screenful of layout, not the whole buffer.
            if let layoutManager = textView.layoutManager,
               let container = textView.textContainer {
                layoutManager.ensureLayout(
                    forBoundingRect: textView.visibleRect,
                    in: container
                )
            }

            // Suppress auto-scroll while the user is actively dragging the
            // scroll thumb, or in the 400ms after they release. Without
            // this, a burst of lines mid-drag yanks the view to the bottom
            // and the user can't escape the auto-follow to read history.
            let userScrolledRecently = userScrolling
                || Date().timeIntervalSince(lastUserScrollEndedAt) < 0.4

            if wasAtBottom && !userScrolledRecently, !scrollToBottomScheduled {
                scrollToBottomScheduled = true
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.scrollToBottomScheduled = false
                    self.scrollToBottom(
                        mutationCompletedAt: nil,
                        mutationLayout: nil
                    )
                }
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - started
            Diagnostics.shared.recordReconcile(durationMs: elapsed * 1000)
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

            // Blank-screen diagnostic: log when the *pre*-state already
            // shows a negative gap (clip past the doc — the suspected
            // "blank zone"). We deliberately don't capture a post-state
            // here: `captureScrollState()` reads `doc.frame.height`,
            // which on a just-mutated NSTextView forces a full
            // re-layout of the storage (hundreds of ms once the buffer
            // hits cap). The blank-screen investigation that justified
            // the cost is closed, so the per-reconcile capture is now
            // pure overhead.
            if (preState?.gap ?? 0) < -1, let p = preState {
                appLog("StoryTextView", p.description("pre "), level: .info)
            }
        }

        /// Drops `lineCount` lines off the front of `storage` and the
        /// matching entries from `lineCharLengths`, returning the trim's
        /// runtime in ms for diagnostic logging.
        ///
        /// When `preserveVisibleScroll` is true (the user has scrolled up
        /// to read history), measure the height of the to-be-removed
        /// prefix BEFORE deleting and subtract it from the clip view's
        /// `bounds.origin.y` AFTER deleting, so the visible content
        /// doesn't shift. Without this, every front-trim at cap causes
        /// the user's reading position to slide upward as new lines push
        /// the cap forward. When the user is at bottom we skip the
        /// compensation — the existing scrollToBottom path keeps them
        /// pinned to the tail and applying a delta would fight it.
        private func frontTrim(
            lineCount: Int,
            storage: NSTextStorage,
            textView: NSTextView,
            preserveVisibleScroll: Bool
        ) -> Double {
            guard lineCount > 0, lineCount <= lineCharLengths.count else { return 0 }
            let charsToRemove = lineCharLengths.prefix(lineCount).reduce(0, +)
            guard charsToRemove > 0, charsToRemove <= storage.length else {
                lineCharLengths.removeFirst(lineCount)
                return 0
            }

            var removedHeight: CGFloat = 0
            if preserveVisibleScroll,
               let lm = textView.layoutManager,
               let container = textView.textContainer {
                let charRange = NSRange(location: 0, length: charsToRemove)
                let glyphRange = lm.glyphRange(
                    forCharacterRange: charRange,
                    actualCharacterRange: nil
                )
                // Ensure the about-to-be-removed glyphs are laid out so the
                // boundingRect we read back reflects their true height.
                // Bounded by `charsToRemove` (one batch's worth of lines),
                // so the cost is small even at cap.
                lm.ensureLayout(forGlyphRange: glyphRange)
                removedHeight = lm.boundingRect(
                    forGlyphRange: glyphRange,
                    in: container
                ).height
            }

            let tStart = CFAbsoluteTimeGetCurrent()
            storage.deleteCharacters(in: NSRange(location: 0, length: charsToRemove))
            let trimMs = (CFAbsoluteTimeGetCurrent() - tStart) * 1000
            lineCharLengths.removeFirst(lineCount)

            if preserveVisibleScroll, removedHeight > 0,
               let clip = scrollView?.contentView {
                let newY = max(0, clip.bounds.origin.y - removedHeight)
                clip.scroll(to: NSPoint(x: clip.bounds.origin.x, y: newY))
                scrollView?.reflectScrolledClipView(clip)
            }

            return trimMs
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
                    // Snapshot the scroll position the user settled on,
                    // so Cmd-Tab restore has a fresh reference point.
                    self.lastKnownScrollY = scrollView.contentView.bounds.origin.y
                    self.wasAtBottomAtLastObserve = self.isAtBottom
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

            // Window key-state observers. AppKit sometimes scrolls the
            // clip view back to (0,0) when the window becomes key on
            // Cmd-Tab back; restore the position we observed before
            // the resign (or fire scrollToBottom if the user was
            // following the bottom). `attachScrollObservers` runs
            // during makeNSView, before SwiftUI has placed the view
            // in a window hierarchy, so `scrollView.window` is nil
            // here. Observe `object: nil` and filter on the
            // notification's source so we catch the window once it
            // exists.
            // We don't need a didResignKey observer — `lastKnownScrollY`
            // is kept fresh by the scroll-end handler above and by
            // reconcile's pre-mutation snapshot. By the time the
            // window resigns key, the latest user scroll position is
            // already captured. We deliberately don't reference `note`
            // inside the MainActor block — NSNotification isn't
            // Sendable and Swift 6 flags the capture.
            scrollObservers.append(NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self,
                          let sv = self.scrollView,
                          sv.window?.isKeyWindow == true
                    else { return }
                    // Restore *after* AppKit's own key-state layout
                    // pass — otherwise our scroll() gets clobbered.
                    DispatchQueue.main.async { [weak self] in
                        guard let self, let sv = self.scrollView else { return }
                        if self.wasAtBottomAtLastObserve {
                            self.scrollToBottom()
                        } else if let y = self.lastKnownScrollY,
                                  abs(sv.contentView.bounds.origin.y - y) > 1 {
                            sv.contentView.scroll(to: NSPoint(x: 0, y: y))
                            sv.reflectScrolledClipView(sv.contentView)
                        }
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

            // No diagnostic captures here on purpose. The previous
            // `captureLayoutState()` + `captureScrollState()` pair read
            // `doc.frame.height` and forced a full layout pass over
            // every glyph in the storage — once the buffer hit its cap
            // and front-trim fired on every reconcile, that meant a
            // 500-700ms layout per line on the main thread. The
            // blank-screen investigation that needed those snapshots
            // is closed; arguments are kept on the signature so the
            // observer-driven entry points still compile.
            _ = mutationCompletedAt
            _ = mutationLayout

            // Target the last real character (the trailing `\n` of the
            // final laid-out line) instead of `storage.length`. The
            // one-past-the-end position lives in the extra line
            // fragment that `TightBackgroundLayoutManager` deliberately
            // zeroes — pointing AppKit there resolves to rect (0,0)
            // and scrolls to the top.
            guard storage.length > 0 else { return }
            let lastIndex = storage.length - 1
            textView.scrollRangeToVisible(NSRange(location: lastIndex, length: 0))
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

        // Bold from any source (protocol `<b>`, monsterbold, the room
        // name style, OR a user highlight rule with bold).
        let bold = s.bold || s.monsterbold || s.highlightBold || s.styleId == "roomName"
        let italic = s.italic
        let base = NSFont.monospacedSystemFont(
            ofSize: fontSize,
            weight: bold ? .bold : .regular
        )
        if italic {
            // SF Mono ships with an italic face; descriptors with the
            // .italic trait pick it up. Falls back to a synthesised
            // oblique if a particular weight+italic combo isn't shipped.
            let italicDescriptor = base.fontDescriptor.withSymbolicTraits(.italic)
            attrs[.font] = NSFont(descriptor: italicDescriptor, size: fontSize) ?? base
        } else {
            attrs[.font] = base
        }

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

        if let link = s.link, let url = link.clickURL(fallbackText: run.text) {
            attrs[.link] = url
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
            attrs[.underlineColor] = fg
        }

        out.append(NSAttributedString(string: run.text, attributes: attrs))
    }
}

/// `NSLayoutManager` subclass with two narrow jobs:
///
/// 1. Suppress the empty line fragment AppKit appends after a trailing
///    `\n`. Without this, every non-editable pane shows a line-height
///    gap of dead space at the bottom (because `buildAllWithLengths`
///    terminates every line with `\n`).
///
/// 2. When a highlight's per-line range ends in whitespace at a wrap
///    point, shrink the width of that line's background fill so it
///    doesn't extend past the last visible glyph. We deliberately
///    only modify *width* — origin/height come straight from AppKit's
///    `rectArray`, which is the known-good positioning. Prior attempts
///    that re-derived the rect from `boundingRect` ended up misaligned.
final class TightBackgroundLayoutManager: NSLayoutManager {
    override func setExtraLineFragmentRect(
        _ fragmentRect: NSRect,
        usedRect: NSRect,
        textContainer container: NSTextContainer
    ) {
        super.setExtraLineFragmentRect(.zero, usedRect: .zero, textContainer: container)
    }

    override func fillBackgroundRectArray(
        _ rectArray: UnsafePointer<NSRect>,
        count rectCount: Int,
        forCharacterRange charRange: NSRange,
        color: NSColor
    ) {
        guard let container = textContainers.first,
              let storage = textStorage
        else {
            super.fillBackgroundRectArray(
                rectArray, count: rectCount,
                forCharacterRange: charRange, color: color
            )
            return
        }
        let highlightGlyphRange = glyphRange(
            forCharacterRange: charRange, actualCharacterRange: nil
        )
        guard highlightGlyphRange.length > 0 else {
            super.fillBackgroundRectArray(
                rectArray, count: rectCount,
                forCharacterRange: charRange, color: color
            )
            return
        }

        color.setFill()
        let text = storage.string as NSString
        var consumedRects = 0

        enumerateLineFragments(forGlyphRange: highlightGlyphRange) {
            [weak self] _, _, _, lineGlyphRange, stop in
            guard let self else { return }
            guard consumedRects < rectCount else {
                stop.pointee = true
                return
            }
            let raw = rectArray[consumedRects]
            consumedRects += 1

            let intersection = NSIntersectionRange(
                highlightGlyphRange, lineGlyphRange
            )
            guard intersection.length > 0 else {
                raw.fill()
                return
            }
            let lineChars = self.characterRange(
                forGlyphRange: intersection, actualGlyphRange: nil
            )
            guard lineChars.length > 0 else {
                raw.fill()
                return
            }

            // Count trailing whitespace chars in this line's slice.
            var trimChars = 0
            while trimChars < lineChars.length {
                let idx = lineChars.location + lineChars.length - 1 - trimChars
                let unit = text.character(at: idx)
                guard let scalar = Unicode.Scalar(unit),
                      CharacterSet.whitespacesAndNewlines.contains(scalar)
                else { break }
                trimChars += 1
            }
            if trimChars == 0 {
                raw.fill()
                return
            }

            // Measure the trailing whitespace's width via boundingRect.
            // We only consume the *width*, never its origin — that's
            // what makes this safe vs the earlier coord-derived rewrite.
            let trimRange = NSRange(
                location: lineChars.location + lineChars.length - trimChars,
                length: trimChars
            )
            let trimGlyphs = self.glyphRange(
                forCharacterRange: trimRange, actualCharacterRange: nil
            )
            let trimWidth = self.boundingRect(
                forGlyphRange: trimGlyphs, in: container
            ).width
            // Defensive: bail out to the default rect if the measured
            // width is garbage (NaN, zero, or wider than the rect).
            guard trimWidth.isFinite, trimWidth > 0, trimWidth < raw.width else {
                raw.fill()
                return
            }
            var fill = raw
            fill.size.width = raw.width - trimWidth
            fill.fill()
        }

        // If AppKit handed us more rects than line fragments returned
        // (shouldn't happen, but harmless to cover), draw the rest as-is.
        while consumedRects < rectCount {
            rectArray[consumedRects].fill()
            consumedRects += 1
        }
    }
}

