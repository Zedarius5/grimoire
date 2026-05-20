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
    let fontSize: Double
    let onCommand: (String) -> Void
    var timerConfig: TimerBarConfig = .wrayth
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
            filtered.sort { lhs, rhs in
                widgetTimeSeconds(lhs) < widgetTimeSeconds(rhs)
            }
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
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":").map { Int($0) ?? 0 }
            switch parts.count {
            case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
            case 2: return parts[0] * 60 + parts[1]
            default: return nil
            }
        }
        if trimmed.hasSuffix("s") { return Int(trimmed.dropLast()) }
        return Int(trimmed)
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
        // TimelineView re-renders the inner content every second, giving us a
        // reliable 1Hz tick for the per-bar countdown without any @State
        // gymnastics that fight SwiftUI's diffing.
        TimelineView(.periodic(from: .now, by: 1.0)) { context in
            let elapsed = max(0, context.date.timeIntervalSince(dialog.lastUpdated))
            renderedBody(elapsedSinceUpdate: elapsed)
        }
    }

    private func renderedBody(elapsedSinceUpdate: TimeInterval) -> some View {
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
                        woundsLayout(wounds: wounds, geo: geo, elapsedSinceUpdate: elapsedSinceUpdate)
                    } else {
                        plainLayout(geo: geo, elapsedSinceUpdate: elapsedSinceUpdate)
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

    /// Height estimate the ScrollView's GeometryReader uses as a minimum so
    /// the content lays out at the right size. In the wounds layout, the
    /// label-only rows live *beside* the body diagram (so they don't add to
    /// vertical extent) — only the body diagram and the bars-below section
    /// stack vertically. Prevously this added a flat +180 which left a large
    /// dead-zone at the bottom of UberBar after the diagram was slimmed down.
    private var contentHeight: CGFloat {
        if wounds != nil {
            let topBlock = max(Self.bodyDiagramHeight, CGFloat(sideBySideRows.count) * 18)
            let bottomBlock = CGFloat(remainingRows.count) * 20
            return max(32, topBlock + bottomBlock + 12)
        }
        return max(32, CGFloat(rows.count) * 18 + 8)
    }

    /// Should track the BodyDiagram's `maxHeight` in BodyDiagram.swift.
    private static let bodyDiagramHeight: CGFloat = 120

    private static let bodyDiagramWidth: CGFloat = 80

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
    private func woundsLayout(wounds: Wounds, geo: GeometryProxy, elapsedSinceUpdate: TimeInterval) -> some View {
        let topRows = sideBySideRows
        let rest = remainingRows
        let rightWidth = max(120, geo.size.width - Self.bodyDiagramWidth - 12)

        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .top, spacing: 6) {
                BodyDiagram(wounds: wounds)
                    .frame(width: Self.bodyDiagramWidth)
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(topRows.indices, id: \.self) { idx in
                        rowView(topRows[idx],
                                paneWidth: rightWidth,
                                elapsedSinceUpdate: elapsedSinceUpdate)
                    }
                }
                .frame(width: rightWidth, alignment: .leading)
            }

            if !rest.isEmpty {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(rest.indices, id: \.self) { idx in
                        rowView(rest[idx],
                                paneWidth: geo.size.width - 8,
                                elapsedSinceUpdate: elapsedSinceUpdate)
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func plainLayout(geo: GeometryProxy, elapsedSinceUpdate: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(rows.indices, id: \.self) { rowIdx in
                rowView(rows[rowIdx],
                        paneWidth: geo.size.width - 8,
                        elapsedSinceUpdate: elapsedSinceUpdate)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func rowView(
        _ widgets: [DialogWidget],
        paneWidth: CGFloat,
        elapsedSinceUpdate: TimeInterval
    ) -> some View {
        let widths = distributedWidths(for: widgets, paneWidth: paneWidth)
        HStack(spacing: 4) {
            ForEach(widgets.indices, id: \.self) { idx in
                DialogWidgetView(
                    widget: widgets[idx],
                    fontSize: fontSize,
                    width: widths[idx],
                    timerConfig: timerConfig,
                    elapsedSinceUpdate: elapsedSinceUpdate,
                    onCommand: onCommand
                )
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

private struct DialogWidgetView: View {
    let widget: DialogWidget
    let fontSize: Double
    let width: CGFloat?
    let timerConfig: TimerBarConfig
    let elapsedSinceUpdate: TimeInterval
    let onCommand: (String) -> Void

    var body: some View {
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
                Text(text)
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
                Text(text)
                    .font(.system(size: fontSize - 1, design: .monospaced))
                    .foregroundStyle(GameTheme.entityLink)
                    .underline()
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .modifier(WidthModifier(width: width, alignment: .leading))
            }
            .buttonStyle(.plain)

        case .progressBar(let id, let value, let text, let time, _):
            let remainingSeconds = liveRemainingSeconds(time)
            let liveTime = remainingSeconds.map(formatDurationSeconds)
                ?? (time?.trimmingCharacters(in: .whitespacesAndNewlines))

            // Timer-style bars (Active Spells / Buffs / Cooldowns / Debuffs)
            // get a fixed-window fill so the visual length actually means
            // something. The window is per-dialog (configurable in Options).
            // Bars without a `time` attribute (health/mana/etc.) always use
            // the server's `value`. When `timerConfig.normalize` is off we
            // also fall back to the server `value` for timer bars — that's
            // the Wrayth/Stormfront default ("% of original duration").
            let timerStyle = timerConfig.normalize && remainingSeconds != nil
            let fillFraction: Double = {
                if timerStyle, let secs = remainingSeconds {
                    return min(1.0, Double(secs) / Double(timerConfig.windowSeconds))
                }
                return Double(max(0, min(100, value))) / 100.0
            }()
            let overflow = timerStyle && (remainingSeconds ?? 0) > timerConfig.windowSeconds

            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().fill(Color.black.opacity(0.4))
                    Rectangle()
                        .fill(barColor(for: id).opacity(0.65))
                        .frame(width: geo.size.width * CGFloat(fillFraction))
                }
                HStack(spacing: 6) {
                    if let liveTime, !liveTime.isEmpty {
                        Text(liveTime)
                            .font(.system(size: max(fontSize - 3, 9), design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                            .monospacedDigit()
                    }
                    Text(text)
                        .font(.system(size: fontSize - 2, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if overflow {
                        Image(systemName: "chevron.right.2")
                            .font(.system(size: max(fontSize - 4, 8), weight: .bold))
                            .foregroundStyle(.white.opacity(0.75))
                            .help("Remaining duration exceeds the 30-minute bar window")
                    }
                }
                .padding(.horizontal, 6)
            }
            .modifier(WidthModifier(width: width, height: 18))
            .clipShape(RoundedRectangle(cornerRadius: 3))

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
    /// of non-timer bars like Health / Mana).
    fileprivate func liveRemainingSeconds(_ original: String?) -> Int? {
        guard let original, !original.isEmpty else { return nil }
        guard let seconds = parseDurationSeconds(original) else { return nil }
        return max(0, seconds - Int(elapsedSinceUpdate.rounded()))
    }

    /// Parses "HH:MM:SS", "MM:SS", or "Ns" / plain integer seconds.
    private func parseDurationSeconds(_ s: String) -> Int? {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        if trimmed.contains(":") {
            let parts = trimmed.split(separator: ":").map { Int($0) ?? 0 }
            switch parts.count {
            case 3: return parts[0] * 3600 + parts[1] * 60 + parts[2]
            case 2: return parts[0] * 60 + parts[1]
            default: return nil
            }
        }
        if trimmed.hasSuffix("s") { return Int(trimmed.dropLast()) }
        return Int(trimmed)
    }

    private func formatDurationSeconds(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if h > 0 { return String(format: "%02d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
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
