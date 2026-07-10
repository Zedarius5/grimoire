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
    /// Pane name for diagnostics only (e.g. "main", "Thoughts").
    var label: String = "main"

    @Environment(\.fontSize) private var fontSize

    func makeNSView(context: Context) -> NSScrollView {
        // Should happen once per pane mount; firing during gameplay means a
        // parent view dropped+remounted us, which resets scroll to y=0.
        appLog("StoryTextView", "makeNSView[\(label)]: creating fresh NSTextView", level: .info)
        let scrollView = PaneScrollView()
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        // TextKit 1 (NSLayoutManager), not TextKit 2. TextKit 2 walks every
        // paragraph synchronously on each viewport layout query, wedging the
        // main thread for tens of seconds once the feed has a few thousand
        // lines; TextKit 1's flat layout-fragment cache keeps those queries
        // O(log n) under bursty appends.
        let textView = PaneTextView(usingTextLayoutManager: false)
        // Swap in a layout manager that trims trailing whitespace from
        // highlight background fills, so a match that wraps mid-phrase doesn't
        // paint a box past the last visible glyph on the upper line.
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
        // Hide the NSTextView from the system accessibility tree. Every
        // `.link` attribute becomes an `NSAccessibilityTextLink` child; with
        // thousands of links, macOS's navigation-order sort grinds the main
        // thread for ~10s whenever an a11y hit-test fires. Marking the view a
        // non-element removes its whole subtree from the sort. Mouse-click
        // link dispatch still works because the link attribute is intact.
        textView.setAccessibilityElement(false)
        textView.setAccessibilityChildren([])
        // Override NSTextView's default link styling so our per-run colours
        // and underline stay authoritative. Deliberately omit
        // `.foregroundColor` — providing any value would uniformly override
        // the source attributes across all links; without the key, they win.
        textView.linkTextAttributes = [
            .cursor: NSCursor.pointingHand
        ]
        textView.delegate = context.coordinator

        scrollView.documentView = textView

        context.coordinator.scrollView = scrollView
        context.coordinator.textView = textView
        context.coordinator.label = label
        context.coordinator.onLinkClick = onLinkClick
        context.coordinator.attachScrollObservers(to: scrollView)
        // Legacy mouse wheels never post the will/didEndLiveScroll
        // notifications, so without this hook a wheel scroll would leave the
        // follow-bottom intent stale in both directions (see Coordinator).
        scrollView.onUserScrollEvent = { [weak coordinator = context.coordinator] in
            coordinator?.noteUserScrolled()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.label = label
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
        var label: String = "main"
        var onLinkClick: ((URL) -> Void)?

        private var appliedLineCount: Int = 0
        private var appliedRevision: Int = 0
        private var appliedFontSize: Double = 0
        private var appliedHighlightHash: Int = 0
        /// True between scheduling and execution of an async
        /// scroll-to-bottom hop. Coalesces back-to-back reconciles so we
        /// don't call `scrollRangeToVisible` per batch — that AppKit path
        /// forces glyph layout each time and is costly under busy traffic.
        private var scrollToBottomScheduled: Bool = false
        /// Last scroll-y the *user* chose (scroll gesture end, wheel event,
        /// scroller interaction) — adjusted by the front-trim compensation so
        /// it tracks the same content while the cap advances. Restored on
        /// `NSWindow.didBecomeKeyNotification` because AppKit sometimes resets
        /// the clipView's bounds.origin to (0,0) during the key-state
        /// transition, scrolling the user to the top on Cmd-Tab back.
        /// Deliberately NOT refreshed from arbitrary reads of the current clip
        /// position: an involuntary AppKit displacement must never overwrite
        /// the user's position with the broken one.
        private var lastKnownScrollY: CGFloat? = nil
        /// Previous clip-origin y / clip size, for classifying bounds changes
        /// (user scroll vs resize vs involuntary jump) in the observer below.
        private var lastObservedClipY: CGFloat = 0
        private var lastObservedClipSize: NSSize = .zero
        /// Whether the pane should stick to the bottom as new content
        /// arrives. This is USER INTENT, not measured geometry: it flips only
        /// on user-initiated scrolls (trackpad/wheel/scroller). Involuntary
        /// clip displacement — AppKit's key-transition reset, pane-resize
        /// clamps, layout-rebuild collapses — must never change it; the
        /// self-heal observer instead snaps the clip back to the bottom
        /// whenever this is true and the view is displaced. Measuring
        /// stickiness on the fly (the previous design) adopted every
        /// involuntary displacement as if the user had scrolled there, which
        /// froze panes mid-history and made becomeKey restore stale offsets.
        private var followsBottom: Bool = true

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
            // Pre-reconcile scroll snapshot, captured before our mutations.
            let preState = captureScrollState()

            var hasher = Hasher()
            hasher.combine(highlights)
            let highlightHash = hasher.finalize()

            let fontChanged = appliedFontSize != fontSize
            let highlightsChanged = appliedHighlightHash != highlightHash
            let structuralChange = fontChanged || highlightsChanged

            // Source of truth for "how many new lines arrived since the last
            // reconcile." Using revision rather than `lines.count -
            // appliedLineCount` is what makes the at-cap path work: once a
            // stream is pinned at cap, `lines.count` stops changing but
            // `revision` keeps climbing by the number of appends per batch.
            let newSinceApplied = revision - appliedRevision

            // Revision went backwards — reconnect / new session. Any
            // scrolled-up position belongs to the old content; re-arm
            // bottom-following for the fresh feed.
            if newSinceApplied < 0 { followsBottom = true }

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

            // Per-phase timings for diagnostics. Each phase invalidates
            // layout independently, so any phase over 5ms is worth logging.
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
                        preserveVisibleScroll: !followsBottom
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
                    preserveVisibleScroll: !followsBottom
                )
                appliedLineCount = lines.count
                didFrontTrim = true
            } else {
                return
            }

            appliedRevision = revision
            appliedFontSize = fontSize
            appliedHighlightHash = highlightHash

            // Force layout for just the visible region. Storage mutations
            // invalidate NSLayoutManager's glyph cache; if the display cycle
            // fires before AppKit lazily lays those glyphs out, the unfilled
            // range paints as pane background (black holes in the story).
            // Bounded by `visibleRect` so the cost is one screenful, not the
            // whole buffer.
            if let layoutManager = textView.layoutManager,
               let container = textView.textContainer {
                layoutManager.ensureLayout(
                    forBoundingRect: textView.visibleRect,
                    in: container
                )
            }

            // Suppress auto-scroll while the user is dragging the scroll thumb,
            // or in the 400ms after they release, so a burst of lines mid-drag
            // doesn't yank them away from history.
            let userScrolledRecently = userScrolling
                || Date().timeIntervalSince(lastUserScrollEndedAt) < 0.4

            if followsBottom && !userScrolledRecently {
                scheduleScrollToBottom()
            }

            let elapsed = CFAbsoluteTimeGetCurrent() - started
            Diagnostics.shared.recordReconcile(durationMs: elapsed * 1000)
            // Log when the reconcile is slow, did a structural rebuild, or any
            // single phase exceeded 5ms (a long append/trim that holds the
            // layout manager mid-state across a display refresh).
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

            // Log only when the pre-state shows a negative gap (clip past the
            // doc). Deliberately no post-state capture: `captureScrollState()`
            // reads `doc.frame.height`, which on a just-mutated NSTextView
            // forces a full re-layout (hundreds of ms once the buffer is at
            // cap), so a per-reconcile post-capture would be pure overhead.
            if (preState?.gap ?? 0) < -1, let p = preState {
                appLog("StoryTextView", p.description("pre "), level: .info)
            }
        }

        /// Drops `lineCount` lines off the front of `storage` and the
        /// matching entries from `lineCharLengths`, returning the trim's
        /// runtime in ms for diagnostic logging.
        ///
        /// When `preserveVisibleScroll` is true (the user has scrolled up to
        /// read history), measure the removed prefix's height before deleting
        /// and subtract it from the clip view's `bounds.origin.y` after, so the
        /// visible content doesn't slide upward as the cap moves forward. When
        /// the user is at bottom we skip the compensation — the scrollToBottom
        /// path keeps them pinned and a delta would fight it.
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
                // Lay out the about-to-be-removed glyphs so boundingRect
                // reflects their true height. Bounded by `charsToRemove` (one
                // batch's worth of lines), so the cost is small even at cap.
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
                // The user's chosen position just moved with the content —
                // keep the becomeKey restore anchored to the same lines.
                lastKnownScrollY = newY
            }

            return trimMs
        }

        private var isAtBottom: Bool {
            guard let scrollView, let doc = scrollView.documentView else { return true }
            let clipBottom = scrollView.contentView.bounds.origin.y
                + scrollView.contentView.bounds.height
            return (doc.frame.height - clipBottom) <= bottomThreshold
        }

        /// Snapshot of the scroll/clip geometry. A negative `gap` means the
        /// clip view is showing space past the document's bottom edge.
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
        /// visible region. If the visible bottom extends past the layout
        /// frontier when AppKit draws, glyphs aren't generated and the
        /// background paints instead.
        struct LayoutState {
            var storageLength: Int
            var firstUnlaid: Int
            var visibleCharStart: Int
            var visibleCharEnd: Int

            /// True when the bottom of the visible region extends past the
            /// layout frontier.
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

        /// Logs scroll geometry for diagnostics.
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

            // Clip bounds observer with two jobs:
            //  1. Classify user scrolls that post no live-scroll
            //     notifications (scroller thumb/track clicks, selection-drag
            //     autoscroll): origin moved, size unchanged, mouse down →
            //     update the follow-bottom intent from where the user landed.
            //  2. Self-heal: while following the bottom, ANY other
            //     displacement that leaves a real gap (AppKit key-transition
            //     reset, pane-resize clamp, layout collapse) gets snapped
            //     back. The snap re-checks intent when it fires, so a wheel
            //     scroll that lands mid-event (stale state during super's
            //     synchronous bounds change) never fights the user.
            scrollView.contentView.postsBoundsChangedNotifications = true
            scrollObservers.append(NotificationCenter.default.addObserver(
                forName: NSView.boundsDidChangeNotification,
                object: scrollView.contentView,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, let sv = self.scrollView, let doc = sv.documentView else { return }
                    let bounds = sv.contentView.bounds
                    let y = bounds.origin.y
                    let delta = y - self.lastObservedClipY
                    let sizeChanged = bounds.size != self.lastObservedClipSize
                    self.lastObservedClipY = y
                    self.lastObservedClipSize = bounds.size
                    // A live gesture is in progress — didEndLiveScroll (or the
                    // wheel hook) settles the state when it finishes.
                    guard !self.userScrolling else { return }
                    if delta != 0, !sizeChanged, NSEvent.pressedMouseButtons != 0 {
                        // Scroller interaction / selection-drag autoscroll.
                        self.lastKnownScrollY = y
                        self.followsBottom = self.isAtBottom
                        self.lastUserScrollEndedAt = self.followsBottom ? .distantPast : Date()
                        return
                    }
                    let gapToBottom = doc.frame.height - (y + bounds.height)
                    guard gapToBottom > self.bottomThreshold else { return }
                    if self.followsBottom {
                        // DIAG(scroll-to-top): keep logging big involuntary
                        // jumps so the trigger stays visible in the logs even
                        // though we now recover from it.
                        if abs(delta) > 300 {
                            appLog("StoryTextView",
                                   "clip jumped[\(self.label)] while following (self-healing):"
                                   + " y=\(Int(y)) delta=\(Int(delta))"
                                   + " docH=\(Int(doc.frame.height)) gapBottom=\(Int(gapToBottom))"
                                   + " key=\(sv.window?.isKeyWindow == true)", level: .info)
                        }
                        self.scheduleScrollToBottom()
                    } else if abs(delta) > 300 {
                        appLog("StoryTextView",
                               "clip jumped[\(self.label)] (no user scroll): y=\(Int(y)) delta=\(Int(delta))"
                               + " docH=\(Int(doc.frame.height)) gapBottom=\(Int(gapToBottom))"
                               + " key=\(sv.window?.isKeyWindow == true)"
                               + " follows=\(self.followsBottom)", level: .info)
                    }
                }
            })

            // Document-frame observer: TextKit 1 lays out lazily, so the text
            // view's frame can keep growing after a reconcile (or collapse
            // during a structural rebuild) with no clip-bounds change at all.
            // While following the bottom, re-pin whenever growth opens a gap.
            if let doc = scrollView.documentView {
                doc.postsFrameChangedNotifications = true
                scrollObservers.append(NotificationCenter.default.addObserver(
                    forName: NSView.frameDidChangeNotification,
                    object: doc,
                    queue: .main
                ) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self, let sv = self.scrollView, let doc = sv.documentView else { return }
                        guard self.followsBottom, !self.userScrolling else { return }
                        let clip = sv.contentView.bounds
                        let gap = doc.frame.height - (clip.origin.y + clip.height)
                        if gap > self.bottomThreshold {
                            self.scheduleScrollToBottom()
                        }
                    }
                })
            }

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
                    self.followsBottom = self.isAtBottom
                    // If the user released *at* the bottom, treat that as a
                    // deliberate "follow again" gesture: skip the grace
                    // window so the next reconcile auto-scrolls, and snap
                    // now in case lines arrived during the drag.
                    if self.followsBottom {
                        self.lastUserScrollEndedAt = .distantPast
                        self.scrollToBottom()
                    } else {
                        self.lastUserScrollEndedAt = Date()
                    }
                }
            })

            // Window key-state observer. AppKit sometimes scrolls the clip
            // view back to (0,0) when the window becomes key on Cmd-Tab back;
            // restore the position observed before resign (or scrollToBottom if
            // the user was following the bottom). `attachScrollObservers` runs
            // during makeNSView, before the view is in a window hierarchy, so
            // `scrollView.window` is nil here — observe `object: nil` and
            // filter on the source to catch the window once it exists.
            // No didResignKey observer is needed: `lastKnownScrollY` stays
            // fresh via the scroll-end handler and reconcile's pre-mutation
            // snapshot. Don't reference `note` inside the MainActor block —
            // NSNotification isn't Sendable and Swift 6 flags the capture.
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
                        let yBefore = sv.contentView.bounds.origin.y
                        if self.followsBottom {
                            self.scrollToBottom()
                        } else if let y = self.lastKnownScrollY,
                                  abs(sv.contentView.bounds.origin.y - y) > 1 {
                            sv.contentView.scroll(to: NSPoint(x: 0, y: y))
                            sv.reflectScrolledClipView(sv.contentView)
                        }
                        // DIAG(scroll-to-top): record what the key-restore did.
                        let docH = sv.documentView?.frame.height ?? 0
                        appLog("StoryTextView",
                               "becomeKey restore[\(self.label)]: follows=\(self.followsBottom)"
                               + " lastY=\(self.lastKnownScrollY.map { Int($0) } ?? -1)"
                               + " yBefore=\(Int(yBefore)) yAfter=\(Int(sv.contentView.bounds.origin.y))"
                               + " docH=\(Int(docH))", level: .info)
                        // A late AppKit layout pass can still yank us to the top
                        // after we restore — re-check once it settles.
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            guard let self, let sv = self.scrollView else { return }
                            let y2 = sv.contentView.bounds.origin.y
                            let docH2 = sv.documentView?.frame.height ?? 0
                            if y2 < 100, docH2 > 1000 {
                                appLog("StoryTextView",
                                       "becomeKey POST-SETTLE[\(self.label)] at top: y=\(Int(y2)) docH=\(Int(docH2))"
                                       + " follows=\(self.followsBottom)", level: .info)
                            }
                        }
                    }
                }
            })
        }

        /// Called by `PaneScrollView` after every wheel/trackpad scroll event
        /// (including momentum ticks). Legacy mouse wheels post no
        /// live-scroll notifications, so this is the only hook that sees
        /// them. Mirrors the didEndLiveScroll handler: landing at the bottom
        /// re-arms following immediately; anywhere else starts the grace
        /// window that keeps auto-scroll from yanking the user.
        func noteUserScrolled() {
            guard let sv = scrollView else { return }
            lastKnownScrollY = sv.contentView.bounds.origin.y
            followsBottom = isAtBottom
            lastUserScrollEndedAt = followsBottom ? .distantPast : Date()
        }

        /// Coalesced scroll-to-bottom hop. Intent is re-checked when the hop
        /// fires, not just when it's scheduled: the self-heal observer can
        /// schedule a snap from a bounds change that happens synchronously
        /// inside a wheel event (before `noteUserScrolled` updates the
        /// state), and that snap must not fight the user's scroll.
        private func scheduleScrollToBottom() {
            guard !scrollToBottomScheduled else { return }
            scrollToBottomScheduled = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.scrollToBottomScheduled = false
                guard self.followsBottom, !self.userScrolling else { return }
                self.scrollToBottom()
            }
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
            // `scrollRangeToVisible` only lays out enough text to bring the
            // end of the document on-screen, not the entire textContainer.
            // An `ensureLayout(for:)` version stalled the main thread for >1s
            // once the feed grew past a few thousand lines.
            guard let textView, let storage = textView.textStorage else { return }

            // No diagnostic captures here on purpose: reading `doc.frame.height`
            // forces a full layout pass over the storage, which at cap means
            // 500-700ms per line on the main thread. Arguments are kept on the
            // signature so the observer-driven entry points still compile.
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

/// Scroll view for story/stream panes. Reports every wheel/trackpad scroll
/// event to the coordinator *after* AppKit has applied it, so the
/// follow-bottom intent can be updated from where the user actually landed.
/// Needed because legacy mouse wheels never post
/// `will/didEndLiveScrollNotification` — without this hook, wheel scrolls
/// were invisible to the coordinator and its intent state went stale.
final class PaneScrollView: NSScrollView {
    var onUserScrollEvent: (@MainActor () -> Void)?

    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        onUserScrollEvent?()
    }
}

/// Read-only pane text view (story feed, stream panes, highlight-editor test
/// pane). Keeps right-click > Copy working under sticky input focus: the
/// standard NSTextView context-menu items are nil-targeted and route through
/// the window's first responder, which (via `CommandNSTextField`'s focus
/// reclaim) is the command input's empty field editor — so Copy validated
/// itself disabled even with a visible selection. Retargeting Copy at this
/// view makes both validation and the action use the right view.
final class PaneTextView: NSTextView {
    override func menu(for event: NSEvent) -> NSMenu? {
        guard let menu = super.menu(for: event) else { return nil }
        for item in menu.items where item.action == #selector(NSText.copy(_:)) {
            item.target = self
        }
        return menu
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
            // SF Mono ships an italic face; the .italic trait picks it up, with
            // a synthesised oblique fallback if a weight+italic combo isn't shipped.
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
///    doesn't extend past the last visible glyph. Only `width` is
///    modified — origin/height come straight from AppKit's `rectArray`
///    (the known-good positioning); re-deriving the rect from
///    `boundingRect` produced misalignment.
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

            // Measure the trailing whitespace's width via boundingRect,
            // consuming only the width (never its origin).
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

