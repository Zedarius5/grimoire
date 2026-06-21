import SwiftUI
import AppKit

extension NSPasteboard.PasteboardType {
    /// Private UTI for pane-reorder drag payloads. Keeps our drag data
    /// isolated from text/url/file pasteboard types that other drops in the
    /// window might react to.
    static let grimoirePane = NSPasteboard.PasteboardType("com.zedarius.Grimoire.pane.id")
}

/// Wraps a pane view as a drag source + drop target via AppKit primitives
/// instead of SwiftUI's `.draggable` / `.dropDestination`, which dropped
/// `isTargeted` state and sometimes failed to fire drops when views
/// re-rendered mid-drag.
///
/// Drag starts on click+drag past a small threshold; the drag image is a
/// snapshot of the pane. Drops invoke `onDrop` synchronously (guaranteed by
/// AppKit, not dependent on SwiftUI's reconciler timing).
struct PaneDragWrapper<Content: View>: NSViewRepresentable {
    let paneId: String
    let onDragBegin: (String) -> Void
    let onDragEnd: () -> Void
    let onHoverChange: (Bool) -> Void
    let onDrop: (String) -> Bool

    @ViewBuilder var content: () -> Content

    func makeNSView(context: Context) -> PaneDragNSView<Content> {
        let view = PaneDragNSView<Content>()
        view.attach(rootView: content(),
                    paneId: paneId,
                    onDragBegin: onDragBegin,
                    onDragEnd: onDragEnd,
                    onHoverChange: onHoverChange,
                    onDrop: onDrop)
        return view
    }

    func updateNSView(_ nsView: PaneDragNSView<Content>, context: Context) {
        nsView.update(rootView: content(),
                      paneId: paneId,
                      onDragBegin: onDragBegin,
                      onDragEnd: onDragEnd,
                      onHoverChange: onHoverChange,
                      onDrop: onDrop)
    }
}

/// NSView that hosts SwiftUI pane content and brokers AppKit drag-and-drop
/// on its behalf. Acts as both `NSDraggingSource` (for the outgoing drag)
/// and `NSDraggingDestination` (for incoming drops).
final class PaneDragNSView<Content: View>: NSView, NSDraggingSource {

    private var hosting: NSHostingView<Content>?
    private var paneId: String = ""
    private var onDragBegin: ((String) -> Void)?
    private var onDragEnd: (() -> Void)?
    private var onHoverChange: ((Bool) -> Void)?
    private var onDrop: ((String) -> Bool)?

    private var mouseDownLocation: NSPoint?
    private let dragThreshold: CGFloat = 8

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { false }

    func attach(
        rootView: Content,
        paneId: String,
        onDragBegin: @escaping (String) -> Void,
        onDragEnd: @escaping () -> Void,
        onHoverChange: @escaping (Bool) -> Void,
        onDrop: @escaping (String) -> Bool
    ) {
        let host = NSHostingView(rootView: rootView)
        host.translatesAutoresizingMaskIntoConstraints = false
        addSubview(host)
        NSLayoutConstraint.activate([
            host.topAnchor.constraint(equalTo: topAnchor),
            host.leadingAnchor.constraint(equalTo: leadingAnchor),
            host.trailingAnchor.constraint(equalTo: trailingAnchor),
            host.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        self.hosting = host
        registerForDraggedTypes([.grimoirePane])
        update(rootView: rootView,
               paneId: paneId,
               onDragBegin: onDragBegin,
               onDragEnd: onDragEnd,
               onHoverChange: onHoverChange,
               onDrop: onDrop)
    }

    func update(
        rootView: Content,
        paneId: String,
        onDragBegin: @escaping (String) -> Void,
        onDragEnd: @escaping () -> Void,
        onHoverChange: @escaping (Bool) -> Void,
        onDrop: @escaping (String) -> Bool
    ) {
        hosting?.rootView = rootView
        self.paneId = paneId
        self.onDragBegin = onDragBegin
        self.onDragEnd = onDragEnd
        self.onHoverChange = onHoverChange
        self.onDrop = onDrop
    }

    // MARK: - Drag source

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = event.locationInWindow
        // Don't call super — we want to swallow the down so subview gestures
        // (text selection in StreamPane, etc.) don't immediately consume the
        // click. mouseUp passes through if no drag occurred.
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = mouseDownLocation else { return }
        let now = event.locationInWindow
        let dist = hypot(now.x - start.x, now.y - start.y)
        guard dist >= dragThreshold else { return }
        mouseDownLocation = nil
        beginDrag(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        // If we never crossed the drag threshold, the click is a no-op here:
        // hosted SwiftUI views run their own gesture handling during the
        // drag (before the threshold trips), so link clicks / selection work.
        mouseDownLocation = nil
    }

    private func beginDrag(with event: NSEvent) {
        let item = NSPasteboardItem()
        item.setString(paneId, forType: .grimoirePane)

        let dragItem = NSDraggingItem(pasteboardWriter: item)
        let img = snapshotImage() ?? NSImage(size: bounds.size)
        dragItem.setDraggingFrame(bounds, contents: img)

        beginDraggingSession(with: [dragItem], event: event, source: self)
        onDragBegin?(paneId)
    }

    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .move
    }

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        onDragEnd?()
    }

    // MARK: - Drop destination

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard let sourceId = sender.draggingPasteboard.string(forType: .grimoirePane),
              sourceId != paneId
        else { return [] }
        onHoverChange?(true)
        return .move
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard let sourceId = sender.draggingPasteboard.string(forType: .grimoirePane),
              sourceId != paneId
        else { return [] }
        return .move
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        onHoverChange?(false)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let sourceId = sender.draggingPasteboard.string(forType: .grimoirePane) else {
            return false
        }
        let handled = onDrop?(sourceId) ?? false
        onHoverChange?(false)
        return handled
    }

    override func draggingEnded(_ sender: any NSDraggingInfo) {
        onHoverChange?(false)
    }

    // MARK: - Misc

    private func snapshotImage() -> NSImage? {
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        guard let rep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        cacheDisplay(in: bounds, to: rep)
        let img = NSImage(size: bounds.size)
        img.addRepresentation(rep)
        return img
    }
}

// MARK: - Empty-region drop targets

/// Drop-only zone for empty regions (left/right columns or top/bottom rows
/// in the center column). Renders SwiftUI chrome — dashed border, "Drop
/// here" label — that highlights on hover, with an `NSView` in the
/// background that handles the actual drag protocol.
struct EmptyRegionDropZone: View {
    let label: String
    let onDrop: (String) -> Bool

    @State private var hovering: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    hovering ? Color.accentColor : Color.white.opacity(0.25),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                )
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(hovering ? Color.accentColor.opacity(0.12) : Color.clear)
                )
            VStack(spacing: 6) {
                Image(systemName: "square.dashed")
                    .font(.title3)
                Text("Drop here")
                    .font(.system(size: 11, weight: .semibold))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(hovering ? Color.accentColor : .secondary)
            .multilineTextAlignment(.center)
        }
        .padding(6)
        .background(
            RegionDropTarget(
                onHoverChange: { hovering = $0 },
                onDrop: onDrop
            )
        )
        .animation(.easeInOut(duration: 0.12), value: hovering)
    }
}

/// `NSViewRepresentable` that exposes only the drop-destination half of
/// the drag protocol — used by `EmptyRegionDropZone` so empty regions
/// can accept dragged panes.
struct RegionDropTarget: NSViewRepresentable {
    let onHoverChange: (Bool) -> Void
    let onDrop: (String) -> Bool

    func makeNSView(context: Context) -> RegionDropNSView {
        let view = RegionDropNSView()
        view.onHoverChange = onHoverChange
        view.onDrop = onDrop
        view.registerForDraggedTypes([.grimoirePane])
        return view
    }

    func updateNSView(_ nsView: RegionDropNSView, context: Context) {
        nsView.onHoverChange = onHoverChange
        nsView.onDrop = onDrop
    }
}

final class RegionDropNSView: NSView {
    var onHoverChange: ((Bool) -> Void)?
    var onDrop: ((String) -> Bool)?

    override var isFlipped: Bool { true }

    override func draggingEntered(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.string(forType: .grimoirePane) != nil else { return [] }
        onHoverChange?(true)
        return .move
    }

    override func draggingUpdated(_ sender: any NSDraggingInfo) -> NSDragOperation {
        guard sender.draggingPasteboard.string(forType: .grimoirePane) != nil else { return [] }
        return .move
    }

    override func draggingExited(_ sender: (any NSDraggingInfo)?) {
        onHoverChange?(false)
    }

    override func performDragOperation(_ sender: any NSDraggingInfo) -> Bool {
        guard let id = sender.draggingPasteboard.string(forType: .grimoirePane) else {
            return false
        }
        let handled = onDrop?(id) ?? false
        onHoverChange?(false)
        return handled
    }

    override func draggingEnded(_ sender: any NSDraggingInfo) {
        onHoverChange?(false)
    }
}
