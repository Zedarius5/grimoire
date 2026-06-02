import SwiftUI
import GrimoireKit

/// Tells the progress-bar widget how to fill timer-style bars (Active Spells,
/// Buffs, Cooldowns, Debuffs). When `normalize` is on, the fill is a fraction
/// of `windowSeconds` and bars longer than that show an overflow chevron.
/// When off, the bar uses the server-supplied `value` (Wrayth behaviour).
struct TimerBarConfig: Equatable {
    var normalize: Bool
    var windowSeconds: Int

    static let wrayth = TimerBarConfig(normalize: false, windowSeconds: 1800)
}

/// Renders a `Dialog` (script-defined panel) as a docked widget. Widgets that
/// share a `top` value are arranged side-by-side as one row; rows stack
/// top-to-bottom. Each widget's `width` is respected proportionally when set.
struct DialogPane: View {
    let dialog: Dialog
    let onCommand: (String) -> Void
    var timerConfig: TimerBarConfig = .wrayth

    @Environment(\.fontSize) private var fontSize
    /// Needed at the pane level (not just the row level) so `contentHeight`
    /// can ask for the resolved per-spell `barHeight` and report the
    /// pane's true intrinsic height — otherwise ScrollView under-sizes
    /// and Active Spells / Cooldowns won't scroll when full.
    @EnvironmentObject private var spellPresets: SpellPresetStore
    /// Optional wound state — when set, renders a `BodyDiagram` at the top
    /// of the pane (used for the UberBar dialog that emits per-body-part
    /// `<image>` widgets).
    var wounds: Wounds? = nil
    /// Controls the visibility of the pane's *content* (the widget area).
    /// The title bar stays put regardless — only the body fades when this
    /// flips false. Defaults true.
    var isActive: Bool = true

    /// Widgets we actually render — strips Stormfront's "paired time label"
    /// convention (a `<label id='lN'>` next to `<progressBar id='N'>` shows
    /// the same countdown the bar already renders inline) and sorts timer
    /// dialogs (Active Spells / Buffs / Cooldowns) so the soonest-expiring
    /// entry is at the top.
    private var displayableWidgets: [DialogWidget] {
        let barIds: Set<String> = Set(dialog.widgets.compactMap {
            if case .progressBar(let id, _, _, _, _) = $0 { return id }
            return nil
        })
        var filtered = dialog.widgets.filter { widget in
            // Drop body-part image widgets — they feed `Wounds` directly via
            // `gameState.wounds` and render through `BodyDiagram`, not as
            // dialog rows. Leaving them in here reserved an empty row per
            // body part (~280pt of dead-zone in UberBar).
            if case .image = widget { return false }
            if case .label(let id, _, _) = widget,
               id.hasPrefix("l"),
               barIds.contains(String(id.dropFirst())) {
                return false
            }
            return true
        }

        if shouldSortByTime {
            // Extract the sort key once per widget instead of twice
            // per comparison. The old comparator called
            // `widgetTimeSeconds` (→ `parseDurationSeconds` → string
            // parse) on both sides, so a 20-bar pane did ~170 parses
            // per sort and SwiftUI was hitting this multiple times
            // per frame.
            let keyed = filtered.map { (widget: $0, key: widgetTimeSeconds($0)) }
            filtered = keyed.sorted { $0.key < $1.key }.map(\.widget)
        }

        return filtered
    }

    /// True when the dialog is timer-style (multiple progressBars carrying a
    /// `time` attribute, like Active Spells / Buffs / Cooldowns).
    private var shouldSortByTime: Bool {
        var timed = 0
        for w in dialog.widgets {
            if case .progressBar(_, _, _, let time, _) = w,
               let t = time, !t.isEmpty {
                timed += 1
                if timed > 1 { return true }
            }
        }
        return false
    }

    /// Returns the widget's remaining time in seconds, or `Int.max` when the
    /// widget doesn't have a time attribute (so non-timer widgets sort last).
    private func widgetTimeSeconds(_ widget: DialogWidget) -> Int {
        if case .progressBar(_, _, _, let time, _) = widget {
            return parseDurationSeconds(time ?? "") ?? Int.max
        }
        return Int.max
    }

    private func parseDurationSeconds(_ s: String) -> Int? {
        DurationFormat.parse(s)
    }

    /// Widgets grouped into rows. The Stormfront protocol chains widgets
    /// within a row via `anchor_left='other_widget_id'`. We compute each
    /// widget's row leader by following its anchor_left chain until we hit
    /// a widget with no anchor (or one outside the dialog), then group by
    /// leader id. Widgets without anchors form their own one-widget rows.
    private var rows: [[DialogWidget]] {
        let widgets = displayableWidgets
        var idToIndex: [String: Int] = [:]
        for (idx, w) in widgets.enumerated() {
            if let id = w.widgetId { idToIndex[id] = idx }
        }

        func leaderIndex(of startIdx: Int) -> Int {
            var current = startIdx
            var visited: Set<Int> = [current]
            while let anchor = widgets[current].layout.anchorLeft,
                  let next = idToIndex[anchor],
                  !visited.contains(next) {
                visited.insert(next)
                current = next
            }
            return current
        }

        var orderedLeaders: [Int] = []
        var groups: [Int: [DialogWidget]] = [:]
        for (idx, w) in widgets.enumerated() {
            let leader = leaderIndex(of: idx)
            if groups[leader] == nil { orderedLeaders.append(leader) }
            groups[leader, default: []].append(w)
        }
        return orderedLeaders.compactMap { groups[$0] }
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("DialogPane:\(dialog.id)")
        // The 1Hz ticker that drives per-bar countdowns used to live HERE
        // as a pane-level TimelineView wrapping the entire content. That
        // meant every widget body in the pane (including labels and
        // links that don't care about elapsed time) re-evaluated each
        // second -- with ~92 widgets across all dialogs, the
        // pane-evals counter was sitting at 92+ per second of pure
        // overhead under no game activity.
        //
        // Now the ticker lives INSIDE the progress-bar branch of
        // `DialogWidgetView` (the only widget kind that depends on
        // elapsed time). Labels / links / separators are stable
        // between data updates.
        return renderedBody()
    }

    private func renderedBody() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(dialog.title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(GameTheme.paneTitle)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(GameTheme.paneHeader)

            // Widget content fades on disconnect; title bar above stays
            // visible so the user can still see which pane is which.
            ScrollView {
                GeometryReader { geo in
                    if let wounds, !sideBySideRows.isEmpty {
                        woundsLayout(wounds: wounds, geo: geo)
                    } else {
                        plainLayout(geo: geo)
                    }
                }
                .frame(minHeight: contentHeight)
            }
            .opacity(isActive ? 1 : 0)
            .animation(.easeInOut(duration: 1.25), value: isActive)
        }
        .background(GameTheme.background)
        .overlay(
            Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .environment(\.colorScheme, .dark)
    }

    /// Height estimate the ScrollView's GeometryReader uses as a minimum
    /// so the content lays out at the right size. Walks each row and
    /// sums per-widget heights so a pane with tall progressBars (per-
    /// spell `barHeight` overrides on Active Spells / Cooldowns etc.)
    /// reports its true intrinsic height — otherwise the ScrollView
    /// thinks it fits when it doesn't, and won't scroll.
    private var contentHeight: CGFloat {
        if wounds != nil {
            // Label-only rows sit BESIDE the body diagram so they don't
            // add to vertical extent; only the body diagram and the
            // bars-below section stack vertically.
            let topBlock = max(Self.bodyDiagramHeight, CGFloat(sideBySideRows.count) * 18)
            let bottomBlock = remainingRows.reduce(0.0) { $0 + rowHeight($1) }
            return max(32, topBlock + bottomBlock + 12)
        }
        let total = rows.reduce(0.0) { $0 + rowHeight($1) }
        return max(32, total + 8)
    }

    /// Tallest widget in a row + 1pt vstack spacing. Mirrors the actual
    /// rendered heights so contentHeight doesn't underestimate.
    private func rowHeight(_ widgets: [DialogWidget]) -> CGFloat {
        let window = DialogWindow(rawValue: dialog.id)
        let perWidget: [CGFloat] = widgets.map { widget in
            switch widget {
            case .progressBar(let id, _, _, _, _):
                let resolved: ResolvedSpellStyling = window
                    .map { spellPresets.resolve(spellId: id, in: $0) } ?? .empty
                return CGFloat(resolved.barHeight ?? 18)
            case .label, .link:
                return 16
            case .separator:
                return 8
            case .image:
                return 0   // filtered out in displayableWidgets
            }
        }
        return (perWidget.max() ?? 18) + 1   // +1 for VStack spacing
    }

    /// Should track `BodyDiagram.totalSize` in BodyDiagram.swift. The
    /// paperdoll refactor (2026-05-20) grew the widget from 80×120 to
    /// 110×150; labeled off-body pips (L.Eye, R.Eye, Back, Nrvs) live
    /// inside the silhouette frame in the dead space above the
    /// shoulders and beside the legs.
    private static let bodyDiagramHeight: CGFloat = 150

    private static let bodyDiagramWidth: CGFloat = 110

    /// Leading rows that should sit alongside the body diagram — only the
    /// initial label-only rows (no progressBars). As soon as we hit a row
    /// with a bar (HP/Mana/etc.), the rest stack full-width below the diagram.
    private var sideBySideRows: [[DialogWidget]] {
        var result: [[DialogWidget]] = []
        for row in rows {
            let hasBar = row.contains { widget in
                if case .progressBar = widget { return true }
                return false
            }
            if hasBar { break }
            result.append(row)
        }
        return result
    }

    private var remainingRows: [[DialogWidget]] {
        Array(rows.dropFirst(sideBySideRows.count))
    }

    @ViewBuilder
    private func woundsLayout(wounds: Wounds, geo: GeometryProxy) -> some View {
        // Compute the row partition once per layout pass — the old
        // path called `rows` three times (once from `sideBySideRows`,
        // twice from `remainingRows` via `sideBySideRows`+`rows`),
        // each of which ran the displayableWidgets filter+sort.
        let partition: (top: [[DialogWidget]], rest: [[DialogWidget]]) = {
            let all = rows
            let split = all.firstIndex(where: { row in
                row.contains { widget in
                    if case .progressBar = widget { return true }
                    return false
                }
            }) ?? all.count
            return (Array(all.prefix(split)), Array(all.dropFirst(split)))
        }()
        let topRows = partition.top
        let rest = partition.rest
        let rightWidth = max(120, geo.size.width - Self.bodyDiagramWidth - 12)

        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 6) {
                BodyDiagram(wounds: wounds)
                    .frame(width: Self.bodyDiagramWidth)
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(topRows.indices, id: \.self) { idx in
                        rowView(topRows[idx], paneWidth: rightWidth)
                    }
                }
                .frame(width: rightWidth, alignment: .leading)
            }

            if !rest.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(rest.indices, id: \.self) { idx in
                        rowView(rest[idx], paneWidth: geo.size.width - 8)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func plainLayout(geo: GeometryProxy) -> some View {
        // Cache `rows` once per layout pass — otherwise both
        // `rows.indices` and the `rows[rowIdx]` subscript inside the
        // ForEach re-evaluate the computed property, each call running
        // the displayableWidgets filter + sort from scratch.
        let allRows = rows
        VStack(alignment: .leading, spacing: 1) {
            ForEach(allRows.indices, id: \.self) { rowIdx in
                rowView(allRows[rowIdx], paneWidth: geo.size.width - 8)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func rowView(
        _ widgets: [DialogWidget],
        paneWidth: CGFloat
    ) -> some View {
        let widths = distributedWidths(for: widgets, paneWidth: paneWidth)
        // Map the Stormfront dialog id to one of the four known preset
        // windows. Returns nil for dialogs that don't have a window
        // (e.g. UberBar), in which case preset resolution is a no-op.
        let presetWindow = DialogWindow(rawValue: dialog.id)
        HStack(spacing: 4) {
            ForEach(widgets.indices, id: \.self) { idx in
                DialogWidgetView(
                    widget: widgets[idx],
                    width: widths[idx],
                    timerConfig: timerConfig,
                    dialogLastUpdated: dialog.lastUpdated,
                    onCommand: onCommand,
                    presetWindow: presetWindow
                )
                .equatable()
            }
        }
    }

    /// Stormfront scripts declare widget widths in raw pixels (e.g. UberBar
    /// emits 50px per cell), which assumes a much larger client viewport than
    /// our docked SwiftUI panes. We rescale those declarations to proportions
    /// of the actual pane width so labels like "AVG/Hr:" aren't truncated.
    /// Rows with no widths fall back to even distribution.
    private func distributedWidths(for widgets: [DialogWidget], paneWidth: CGFloat) -> [CGFloat] {
        let count = widgets.count
        guard count > 0 else { return [] }
        let spacing = CGFloat(max(0, count - 1)) * 4
        let usable = max(0, paneWidth - spacing)

        let declared = widgets.map { $0.layout.width?.resolve(against: paneWidth) ?? 0 }
        let total = declared.reduce(0, +)
        if total > 0 {
            return declared.map { $0 / total * usable }
        }
        let per = usable / CGFloat(count)
        return Array(repeating: per, count: count)
    }
}

/// Applies either a fixed width or a `maxWidth: .infinity` stretch, depending
/// on whether a width was supplied. Used by every dialog widget so that the
/// last widget in a row can fill leftover space.
private struct WidthModifier: ViewModifier {
    let width: CGFloat?
    var height: CGFloat? = nil
    var alignment: Alignment = .center

    func body(content: Content) -> some View {
        if let width {
            content.frame(width: width, height: height, alignment: alignment)
        } else if let height {
            content.frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: alignment)
        } else {
            content.frame(maxWidth: .infinity, alignment: alignment)
        }
    }
}

/// Equatable so SwiftUI can skip the body call when a parent re-render
/// (e.g. ContentView reacting to an unrelated LichClient @Published
/// change like a vital tick) creates a new copy of the view with
/// identical data. Without this, every ContentView re-render walked
/// through every DialogWidgetView body in the app -- visible in the
/// pane-eval log as DialogWidget=188/376/etc. per heartbeat. The
/// closure `onCommand` is intentionally excluded from the comparison;
/// it's stable across renders in practice and treating it as
/// always-equal is safe (we never bind a "different" onCommand to the
/// same logical row).
private struct DialogWidgetView: View, Equatable {
    let widget: DialogWidget
    let width: CGFloat?
    let timerConfig: TimerBarConfig
    /// Used by the progress-bar branch's inner TimelineView to compute
    /// "time elapsed since the server last sent this dialog's values"
    /// for the live countdown. Other widget kinds don't read this.
    let dialogLastUpdated: Date
    let onCommand: (String) -> Void
    /// Which preset window (if any) backs this row's dialog. Nil for
    /// non-managed dialogs like UberBar — skips preset resolution.
    let presetWindow: DialogWindow?

    nonisolated static func == (lhs: DialogWidgetView, rhs: DialogWidgetView) -> Bool {
        guard lhs.widget == rhs.widget,
              lhs.width == rhs.width,
              lhs.timerConfig == rhs.timerConfig,
              lhs.presetWindow == rhs.presetWindow
        else { return false }
        // `dialogLastUpdated` only matters for progress bars (their
        // inner TimelineView reads it to compute the countdown's
        // elapsed value). Labels / links / separators don't read it,
        // so we DON'T compare it for them -- otherwise every dialog
        // update (~1Hz under active gameplay) would fail equality for
        // every static widget in that dialog, defeating the whole
        // point of the Equatable skip.
        if case .progressBar = lhs.widget {
            return lhs.dialogLastUpdated == rhs.dialogLastUpdated
        }
        return true
    }

    @Environment(\.fontSize) private var fontSize
    @EnvironmentObject private var spellPresets: SpellPresetStore
    /// Highlight rules are evaluated against label/link text in dialog
    /// widgets so user rules apply uniformly across every window
    /// (story feed, side streams, and dialog panes like
    /// `;playerwindow`'s output). Empty when the user has no rules,
    /// in which case `HighlightProcessor.apply` short-circuits.
    @EnvironmentObject private var highlights: HighlightStore

    /// Runs the user's highlight rules over `text` and returns an
    /// AttributedString carrying any matched fg/bg overrides. The
    /// caller still applies the widget's default styling (color,
    /// font, etc.) -- this layer only overlays user-defined rules.
    private func highlighted(_ text: String) -> AttributedString {
        let line = RenderedLine(runs: [
            RenderedRun(text: text, style: RunStyle())
        ])
        let processed = HighlightProcessor.apply(highlights.effectiveHighlights, to: line)
        var out = AttributedString()
        for run in processed.runs {
            var seg = AttributedString(run.text)
            if let hex = run.style.highlightFg, let c = Color(hex: hex) {
                seg.foregroundColor = c
            }
            if let hex = run.style.highlightBg, let c = Color(hex: hex) {
                seg.backgroundColor = c
            }
            out += seg
        }
        return out
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("DialogWidget")
        switch widget {
        case .label(_, let text, _):
            // Treat "Essence N/M" labels as progress bars — the uberbar script
            // emits them as plain labels for non-Sorcerer professions, but the
            // user always wants to see the ratio at a glance.
            if let (filled, total) = parseEssence(text) {
                essenceBar(text: text, filled: filled, total: total)
                    .modifier(WidthModifier(width: width, height: 18))
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            } else {
                Text(highlighted(text))
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundStyle(GameTheme.foreground)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .modifier(WidthModifier(width: width, alignment: .leading))
            }

        case .link(_, let text, let cmd, _):
            Button {
                if let cmd, !cmd.isEmpty { onCommand(cmd) }
            } label: {
                Text(highlighted(text))
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundStyle(GameTheme.entityLink)
                    .underline()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .modifier(WidthModifier(width: width, alignment: .leading))
            }
            .buttonStyle(.plain)

        case .progressBar(let id, let value, let text, let time, _):
            // Resolved styling pulls spell → group → window-default
            // → hardcoded. `.empty` for dialogs we don't manage
            // (e.g. UberBar) or spells with no overrides anywhere.
            let resolved: ResolvedSpellStyling = presetWindow
                .map { spellPresets.resolve(spellId: id, in: $0) }
                ?? .empty

            if resolved.hidden {
                EmptyView()
            } else {
                // Local 1Hz TimelineView so ONLY the bar's time-dependent
                // rendering re-runs each second. The rest of the dialog
                // pane's widgets (labels / links / separators) stay
                // frozen between data updates.
                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    let elapsed = max(0, context.date.timeIntervalSince(dialogLastUpdated))
                    let remainingSeconds = liveRemainingSeconds(time, elapsed: elapsed)
                    let liveTime = remainingSeconds.map(formatDurationSeconds)
                        ?? (time?.trimmingCharacters(in: .whitespacesAndNewlines))

                // Effective window: a per-spell / group / default
                // override (e.g. a single cooldown bar that should
                // fill against 30s) takes precedence over the
                // per-dialog default.
                let effectiveWindow = resolved.fullBarSeconds ?? timerConfig.windowSeconds

                let timerStyle = timerConfig.normalize && remainingSeconds != nil
                let fillFraction: Double = {
                    if timerStyle, let secs = remainingSeconds {
                        return min(1.0, Double(secs) / Double(effectiveWindow))
                    }
                    return Double(max(0, min(100, value))) / 100.0
                }()
                let overflow = timerStyle && (remainingSeconds ?? 0) > effectiveWindow

                let resolvedBarColor = resolved.barColor
                    .flatMap(Color.init(hex:))
                    ?? barColor(for: id)
                let resolvedTroughColor = resolved.troughColor
                    .flatMap(Color.init(hex:))
                    ?? Color.black.opacity(0.4)
                let resolvedTextColor = resolved.textColor
                    .flatMap(Color.init(hex:))
                    ?? Color.white
                let resolvedFontSize = resolved.fontSize ?? fontSize
                let resolvedHeight: CGFloat = resolved.barHeight.map { CGFloat($0) } ?? 18
                // Fallback chain: user override → server-supplied live
                // text → name cache (Lich XML + previously observed
                // bars, so cooldown ids that haven't fired this session
                // still get labelled) → raw `text`.
                let displayText: String = {
                    if let custom = resolved.displayName, !custom.isEmpty { return custom }
                    if !text.isEmpty, text != id { return text }
                    return spellPresets.spellNames.name(forId: id) ?? text
                }()

                ZStack(alignment: .leading) {
                    GeometryReader { geo in
                        Rectangle().fill(resolvedTroughColor)
                        Rectangle()
                            .fill(resolvedBarColor)
                            .frame(width: geo.size.width * CGFloat(fillFraction))
                    }
                    HStack(spacing: 6) {
                        if let liveTime, !liveTime.isEmpty {
                            Text(liveTime)
                                .font(.system(size: max(resolvedFontSize - 3, 9), design: .monospaced))
                                .foregroundStyle(resolvedTextColor.opacity(0.85))
                                .monospacedDigit()
                        }
                        Text(displayText)
                            .font(.system(size: max(resolvedFontSize - 2, 9), design: .monospaced))
                            .foregroundStyle(resolvedTextColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                        if overflow {
                            Image(systemName: "chevron.right.2")
                                .font(.system(size: max(resolvedFontSize - 4, 8), weight: .bold))
                                .foregroundStyle(resolvedTextColor.opacity(0.75))
                                .help("Remaining duration exceeds the bar window")
                        }
                    }
                    .padding(.horizontal, 6)
                }
                .modifier(WidthModifier(width: width, height: resolvedHeight))
                .clipShape(RoundedRectangle(cornerRadius: 3))
                }  // TimelineView
            }

        case .image:
            EmptyView()

        case .separator:
            Divider().background(Color.white.opacity(0.15))
        }
    }

    /// Pulls `N` and `M` out of a label like "Essence 3/5". Returns nil when
    /// the text doesn't match the prefix or carries non-numeric values.
    fileprivate func parseEssence(_ text: String) -> (Int, Int)? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.lowercased().hasPrefix("essence") else { return nil }
        let after = trimmed.dropFirst("Essence".count).trimmingCharacters(in: .whitespaces)
        let parts = after.split(separator: "/", maxSplits: 1)
        guard parts.count == 2,
              let lhs = Int(parts[0].trimmingCharacters(in: .whitespaces)),
              let rhs = Int(parts[1].trimmingCharacters(in: .whitespaces)),
              rhs > 0
        else { return nil }
        return (lhs, rhs)
    }

    @ViewBuilder
    fileprivate func essenceBar(text: String, filled: Int, total: Int) -> some View {
        let fraction = max(0, min(1, Double(filled) / Double(total)))
        ZStack(alignment: .leading) {
            GeometryReader { geo in
                Rectangle().fill(Color.black.opacity(0.4))
                Rectangle()
                    .fill(Color(red: 0.55, green: 0.30, blue: 0.85).opacity(0.65))
                    .frame(width: geo.size.width * fraction)
            }
            Text(text)
                .font(.system(size: fontSize - 2, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
        }
    }

    /// Parses the time attribute and subtracts elapsed seconds since the
    /// dialog last updated. Returns `nil` for unparseable strings (typical
    /// of non-timer bars like Health / Mana). `elapsed` is provided by
    /// the progress bar's local TimelineView so the countdown ticks at
    /// 1Hz without re-rendering the rest of the dialog.
    fileprivate func liveRemainingSeconds(_ original: String?, elapsed: TimeInterval) -> Int? {
        guard let original, !original.isEmpty else { return nil }
        guard let seconds = parseDurationSeconds(original) else { return nil }
        return max(0, seconds - Int(elapsed.rounded()))
    }

    /// Parses durations the server sends on `<progressBar time="…">`.
    /// Delegates to the shared `DurationFormat` helper so the editor's
    /// custom-full-bar input and this live-render path agree on what
    /// "3:30" or "5m" means.
    private func parseDurationSeconds(_ s: String) -> Int? {
        DurationFormat.parse(s)
    }

    private func formatDurationSeconds(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        // Drop leading zeros on the leftmost component — no in-game
        // spell ever runs more than 9 hours, so the extra width is
        // dead pixels. Minutes and seconds keep their zero-pad so
        // ":05" doesn't collapse to ":5".
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%d:%02d", m, s)
    }

    /// Bar fill color by id. Standard Stormfront vital ids get their canonical
    /// colors; everything else (TP/ATP/mind/exp/buff timers) falls back to a
    /// neutral blue.
    private func barColor(for id: String) -> Color {
        switch id {
        case "health":  return Color(red: 0.85, green: 0.20, blue: 0.20)
        case "mana":    return Color(red: 0.30, green: 0.55, blue: 1.00)
        case "stamina": return Color(red: 0.95, green: 0.70, blue: 0.20)
        case "spirit":  return Color(red: 0.80, green: 0.80, blue: 0.85)
        case "pbarStance":  return Color(red: 0.55, green: 0.85, blue: 0.55)
        case "mindState":   return Color(red: 0.65, green: 0.55, blue: 0.85)
        case "encumlevel":  return Color(red: 0.65, green: 0.55, blue: 0.85)
        default:        return Color(red: 0.30, green: 0.55, blue: 1.00)
        }
    }
}
