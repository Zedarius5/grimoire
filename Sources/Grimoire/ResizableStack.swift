import SwiftUI
import AppKit

/// Vertical or horizontal stack with draggable dividers and per-child size
/// persistence. Sizes (along the stack's axis, in points) live in an external
/// binding so the parent can save/restore them.
enum SplitAxis { case vertical, horizontal }

struct ResizableStack<ItemID: Hashable>: View {
    let axis: SplitAxis
    let items: [ItemID]
    @Binding var sizes: [String: CGFloat]
    let minSize: CGFloat
    let dividerThickness: CGFloat
    let content: (ItemID) -> AnyView

    init(
        axis: SplitAxis,
        items: [ItemID],
        sizes: Binding<[String: CGFloat]>,
        minSize: CGFloat = 80,
        dividerThickness: CGFloat = 6,
        @ViewBuilder content: @escaping (ItemID) -> some View
    ) {
        self.axis = axis
        self.items = items
        self._sizes = sizes
        self.minSize = minSize
        self.dividerThickness = dividerThickness
        self.content = { AnyView(content($0)) }
    }

    private func key(_ id: ItemID) -> String { String(describing: id) }

    var body: some View {
        GeometryReader { geo in
            let total = axis == .vertical ? geo.size.height : geo.size.width
            let dividers = max(0, items.count - 1)
            let available = max(0, total - CGFloat(dividers) * dividerThickness)
            let resolved = resolveSizes(available: available)

            // Key SwiftUI identity on the item id, not the array index.
            // Indexing by position makes any reorder/insertion look like
            // "different content at this slot", so SwiftUI rebuilds the
            // child — which for a StoryTextView pane destroys the underlying
            // NSTextView and resets scroll to the top. Tagging by item id
            // lets SwiftUI move the existing view to its new slot instead.
            let indexed = Array(zip(items.indices, items))
            stackContainer {
                ForEach(indexed, id: \.1) { (idx, item) in
                    content(item)
                        .frame(
                            width: axis == .horizontal ? resolved[idx] : nil,
                            height: axis == .vertical ? resolved[idx] : nil
                        )
                    if idx < dividers {
                        DividerHandle(axis: axis, thickness: dividerThickness) { delta in
                            adjust(at: idx, delta: delta, resolved: resolved)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func stackContainer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        switch axis {
        case .vertical:   VStack(spacing: 0, content: content)
        case .horizontal: HStack(spacing: 0, content: content)
        }
    }

    /// Distributes `available` space among items. Items with a saved size use
    /// it (clamped); items without a saved size split the leftover evenly.
    /// After that initial pass, we always rescale to fit `available` exactly
    /// — covers two important cases:
    ///   • A pane was just dragged out of a column. The remaining panes'
    ///     saved sizes summed to the *original* container width, so they'd
    ///     now leave a dead band where the removed pane used to be. Scale
    ///     up to fill.
    ///   • A pane was dropped into an already-full column. Sizes overflow;
    ///     scale down so the new arrival is on-screen.
    /// User-driven divider drags preserve `sum == available`, so the
    /// rescale is a no-op during normal interaction.
    private func resolveSizes(available: CGFloat) -> [CGFloat] {
        guard !items.isEmpty else { return [] }
        let explicit = items.map { sizes[key($0)] }
        let totalExplicit = explicit.compactMap { $0 }.reduce(0, +)
        let unsizedCount = explicit.filter { $0 == nil }.count
        let leftover = max(0, available - totalExplicit)
        let perUnsized = unsizedCount > 0 ? leftover / CGFloat(unsizedCount) : 0

        var resolved = items.indices.map { idx in
            max(minSize, explicit[idx] ?? perUnsized)
        }

        let total = resolved.reduce(0, +)
        if total > 0, abs(total - available) > 0.5 {
            let scale = available / total
            resolved = resolved.map { max(minSize, $0 * scale) }
        }
        return resolved
    }

    /// Drags the divider between items[idx] and items[idx+1] by `delta`.
    /// Pins every item in the stack to its current resolved size — not just
    /// the two touching the divider — so the whole arrangement's sizes persist
    /// exactly, then applies the drag to the two neighbours.
    private func adjust(at idx: Int, delta: CGFloat, resolved: [CGFloat]) {
        let before = resolved[idx]
        let after  = resolved[idx + 1]
        let newBefore = max(minSize, before + delta)
        let newAfter  = max(minSize, after  - delta)
        // If a clamp kicked in, only apply the symmetric portion.
        let appliedDelta = min(newBefore - before, after - newAfter)
        var newSizes = sizes
        for (i, item) in items.enumerated() {
            newSizes[key(item)] = resolved[i]
        }
        newSizes[key(items[idx])]     = before + appliedDelta
        newSizes[key(items[idx + 1])] = after  - appliedDelta
        sizes = newSizes
    }
}

/// Rectangle handle that turns mouse drags into incremental size deltas.
///
/// We bypass SwiftUI's `DragGesture` because it reports translation in the
/// handle's *local* space, and the handle moves every frame as panels resize
/// — so the handle "chases" the cursor (drag feels half-speed, jittery).
/// Tracking `locationInWindow` from AppKit gives 1:1 cursor mapping.
private struct DividerHandle: View {
    let axis: SplitAxis
    let thickness: CGFloat
    let onDrag: (CGFloat) -> Void

    @State private var dragging: Bool = false

    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(dragging ? 0.18 : 0.08))
            .frame(
                width: axis == .horizontal ? thickness : nil,
                height: axis == .vertical ? thickness : nil
            )
            .overlay(
                DragTracker(
                    axis: axis,
                    onDrag: onDrag,
                    onBegin: { dragging = true },
                    onEnd:   { dragging = false }
                )
            )
    }
}

/// AppKit-backed view that hosts the drag tracking and the resize cursor.
/// Reports a positive `delta` whenever the user moves toward "grow the
/// leading panel" (down for horizontal splits, right for vertical splits).
private struct DragTracker: NSViewRepresentable {
    let axis: SplitAxis
    let onDrag: (CGFloat) -> Void
    let onBegin: () -> Void
    let onEnd: () -> Void

    func makeNSView(context: Context) -> DragTrackerView {
        let view = DragTrackerView()
        view.axis = axis
        view.onDrag = onDrag
        view.onBegin = onBegin
        view.onEnd = onEnd
        return view
    }

    func updateNSView(_ nsView: DragTrackerView, context: Context) {
        nsView.axis = axis
        nsView.onDrag = onDrag
        nsView.onBegin = onBegin
        nsView.onEnd = onEnd
    }
}

private final class DragTrackerView: NSView {
    var axis: SplitAxis = .vertical
    var onDrag: ((CGFloat) -> Void)?
    var onBegin: (() -> Void)?
    var onEnd: (() -> Void)?

    private var lastPos: CGFloat?

    override var wantsDefaultClipping: Bool { false }
    override func hitTest(_ point: NSPoint) -> NSView? {
        // Receive drags but otherwise stay transparent to mouse-tracking.
        bounds.contains(point) ? self : nil
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        let cursor: NSCursor = (axis == .vertical) ? .resizeUpDown : .resizeLeftRight
        addCursorRect(bounds, cursor: cursor)
    }

    override func mouseDown(with event: NSEvent) {
        lastPos = axisValue(of: event.locationInWindow)
        onBegin?()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let last = lastPos else { return }
        let current = axisValue(of: event.locationInWindow)
        // NSWindow's coordinate origin is bottom-left, so an increase in `y`
        // means the mouse moved UP. SwiftUI's VStack grows the leading panel
        // when the divider moves DOWN, so we invert for vertical splits.
        let raw = current - last
        let delta = (axis == .vertical) ? -raw : raw
        lastPos = current
        onDrag?(delta)
    }

    override func mouseUp(with event: NSEvent) {
        lastPos = nil
        onEnd?()
    }

    private func axisValue(of point: NSPoint) -> CGFloat {
        axis == .vertical ? point.y : point.x
    }
}
