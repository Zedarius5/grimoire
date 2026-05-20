import Foundation

/// Observable state for the pane drag-and-drop interaction. ContentView holds
/// one instance as `@StateObject` and reads its published properties to
/// render the source-ghost overlay and the hover-target ring; `PaneDragWrapper`
/// invokes `beginDrag` / `endDrag` from its AppKit drag callbacks.
///
/// A monotonically-increasing `generation` token is bundled with each drag so
/// the 15-second fallback timeout can tell whether a later drag has already
/// taken over (in which case the timeout is a no-op). Without it, a
/// dropped-but-orphaned drag could leave the source pane stuck at 35% opacity
/// indefinitely.
@MainActor
final class PaneDragState: ObservableObject {
    @Published var draggingPaneId: String? = nil
    @Published var hoverTargetId:  String? = nil

    /// Monotonically-increasing token. Bumped on every `beginDrag`; the
    /// fallback reset task only fires if `generation` matches the value
    /// captured at drag start, so a quick second drag doesn't have its
    /// fresh state stomped by the previous timeout.
    private var generation: Int = 0

    func beginDrag(id: String) {
        generation &+= 1
        let gen = generation
        draggingPaneId = id
        hoverTargetId  = nil
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(15))
            guard let self else { return }
            if self.generation == gen, self.draggingPaneId == id {
                self.endDrag()
            }
        }
    }

    func endDrag() {
        draggingPaneId = nil
        hoverTargetId  = nil
    }

    /// Called from `PaneDragWrapper.onHoverChange`. Clears only when the
    /// outgoing hover matches the current target so a stale "leave" callback
    /// can't wipe a fresh "enter".
    func hoverChanged(id: String, hovering: Bool) {
        if hovering {
            hoverTargetId = id
        } else if hoverTargetId == id {
            hoverTargetId = nil
        }
    }
}
