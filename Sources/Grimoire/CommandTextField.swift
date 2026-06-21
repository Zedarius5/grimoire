import SwiftUI
import AppKit

/// AppKit-backed text input for the command bar. We need this instead of
/// SwiftUI's TextField because:
///
/// 1. macOS's NSTextField shows a Cut/Copy/Paste/Writing Tools context menu
///    on Ctrl+Return — SwiftUI doesn't expose a way to suppress it. We
///    override `menu(for:)` to return nil.
/// 2. Ctrl+Return / Option+Return / Up / Down need to be consumed cleanly
///    before AppKit's default field-editor handling runs.
struct CommandTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isEnabled: Bool
    var foregroundColor: NSColor
    var insertionPointColor: NSColor
    var shouldFocus: Bool

    var onSubmit:        () -> Void
    var onCtrlReturn:    () -> Void
    var onOptionReturn:  () -> Void
    var onUpArrow:       () -> Void
    var onDownArrow:     () -> Void

    /// User-controlled font size, sourced from the `\.fontSize` environment
    /// (set once at ContentView's root, overridden per-pane where needed).
    @Environment(\.fontSize) private var fontSize: Double

    func makeNSView(context: Context) -> CommandNSTextField {
        let field = CommandNSTextField()
        field.isBordered = false
        field.drawsBackground = false
        field.backgroundColor = .clear
        field.focusRingType = .none
        field.bezelStyle = .squareBezel
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.onCommit(_:))
        field.callbacks = context.coordinator
        return field
    }

    func updateNSView(_ field: CommandNSTextField, context: Context) {
        let wasEnabled = field.isEnabled

        if field.stringValue != text {
            field.stringValue = text
            // NSTextField selects-all on programmatic stringValue updates
            // while focused, so up-arrow history recall (and macro template
            // fills) would land with the entire line highlighted. Collapse
            // the selection to a caret at the end so the user can keep
            // typing immediately.
            if let editor = field.currentEditor() {
                let len = (text as NSString).length
                editor.selectedRange = NSRange(location: len, length: 0)
            }
        }
        field.placeholderString = placeholder
        field.isEnabled = isEnabled
        field.font = NSFont.monospacedSystemFont(ofSize: CGFloat(fontSize), weight: .regular)
        field.textColor = foregroundColor
        field.customInsertionPointColor = insertionPointColor
        context.coordinator.parent = self

        // Grab focus when either `shouldFocus` is set, or the field just
        // transitioned disabled → enabled (client became active after
        // connect). In the latter case `focused` was already set in
        // `.onAppear`, so setting it again is a no-op — we must reclaim
        // first-responder here, the instant the field becomes eligible.
        let justEnabled = !wasEnabled && isEnabled
        if (shouldFocus || justEnabled),
           field.window?.firstResponder !== field.currentEditor() {
            DispatchQueue.main.async {
                field.window?.makeFirstResponder(field)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    @MainActor
    final class Coordinator: NSObject, NSTextFieldDelegate, CommandTextFieldCallbacks {
        var parent: CommandTextField

        init(parent: CommandTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notif: Notification) {
            if let field = notif.object as? NSTextField {
                parent.text = field.stringValue
            }
        }

        @objc func onCommit(_ sender: NSTextField) {
            parent.onSubmit()
        }

        /// AppKit calls this when the field editor wants to perform a system
        /// command in response to a key event. We intercept the command-key
        /// equivalents we care about and consume them by returning true.
        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            switch commandSelector {
            case #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)):
                // Triggered by Ctrl+Return AND Option+Return. The selector
                // doesn't tell us which one — peek at the current event.
                if let event = NSApp.currentEvent {
                    if event.modifierFlags.contains(.control) {
                        parent.onCtrlReturn(); return true
                    }
                    if event.modifierFlags.contains(.option) {
                        parent.onOptionReturn(); return true
                    }
                }
                return true // swallow unconditionally — never insert a literal newline

            case #selector(NSResponder.moveUp(_:)):
                parent.onUpArrow(); return true

            case #selector(NSResponder.moveDown(_:)):
                parent.onDownArrow(); return true

            default:
                return false
            }
        }

        // Fallback for the rare case the field isn't using a field editor
        // (no focused responder yet): the NSTextField subclass's own keyDown
        // override calls this.
        func handleSpecialKey(_ event: NSEvent) -> Bool {
            switch Int(event.keyCode) {
            case 36, 76:
                let mods = event.modifierFlags
                if mods.contains(.control) { parent.onCtrlReturn();   return true }
                if mods.contains(.option)  { parent.onOptionReturn(); return true }
                return false
            case 126: parent.onUpArrow();   return true
            case 125: parent.onDownArrow(); return true
            default:  return false
            }
        }
    }
}

@MainActor
protocol CommandTextFieldCallbacks: AnyObject {
    func handleSpecialKey(_ event: NSEvent) -> Bool
}

/// NSTextField subclass that suppresses the contextual menu entirely and
/// gives a callbacks hook for Ctrl/Option+Return and arrow-key handling.
///
/// Also self-restores focus: whenever its window becomes key (the user
/// switched back to Grimoire) or a menu/popover dismisses, the field grabs
/// first-responder status again so the user can type immediately without
/// re-clicking the input.
final class CommandNSTextField: NSTextField {
    weak var callbacks: CommandTextFieldCallbacks?
    var customInsertionPointColor: NSColor = .white {
        didSet { applyInsertionPointColor() }
    }

    private var focusObservers: [NSObjectProtocol] = []
    private var clickMonitor: Any?
    /// The read-only pane we most recently stole first-responder status
    /// from. Its text selection survives the steal, but Cmd+C routes to
    /// *us* — so `performKeyEquivalent` consults this view to copy the
    /// selection the user made. Weak: panes get remounted by SwiftUI.
    private weak var lastSelectionSource: NSTextView?

    // No deinit cleanup — observer tokens live for the lifetime of this
    // object and AppKit views aren't torn down before app exit anyway.
    // Avoiding a deinit also sidesteps Swift 6's "cannot access
    // non-Sendable property from nonisolated deinit".

    /// Kills the Cut/Copy/Paste/Writing Tools menu that macOS pops up on
    /// Ctrl+Return (and right-click) inside an NSTextField.
    override func menu(for event: NSEvent) -> NSMenu? { nil }

    override func keyDown(with event: NSEvent) {
        if callbacks?.handleSpecialKey(event) == true { return }
        super.keyDown(with: event)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if callbacks?.handleSpecialKey(event) == true { return true }
        if isCopyKeyEquivalent(event), copyPaneSelection() { return true }
        return super.performKeyEquivalent(with: event)
    }

    private func isCopyKeyEquivalent(_ event: NSEvent) -> Bool {
        let mods = event.modifierFlags
            .intersection(.deviceIndependentFlagsMask)
            .subtracting(.capsLock)  // caps lock shouldn't break Cmd+C
        return mods == .command
            && event.charactersIgnoringModifiers?.lowercased() == "c"
    }

    /// Cmd+C fallthrough for sticky focus: the input holds first-responder
    /// status ~always, so a selection in a read-only pane can never receive
    /// the Copy action through the responder chain (Edit > Copy validates
    /// against our empty field editor and disables itself). When the input
    /// has no selection of its own, copy the stashed pane selection instead.
    /// Returns false (deferring to normal handling) when the input — or any
    /// other field — has a real selection or focus of its own.
    private func copyPaneSelection() -> Bool {
        guard let win = window,
              let editor = currentEditor(),
              win.firstResponder === editor,        // input is focused...
              editor.selectedRange.length == 0,     // ...with nothing selected
              let pane = lastSelectionSource,
              pane.window === win,
              pane.selectedRange().length > 0
        else { return false }
        // NSTextView.copy(_:) writes the selection to the pasteboard
        // directly — no first-responder status required.
        pane.copy(nil)
        return true
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        applyInsertionPointColor()
        return result
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Drop any previous observers when the field is re-parented to a
        // different window (rare in practice but cheap to handle).
        for token in focusObservers {
            NotificationCenter.default.removeObserver(token)
        }
        focusObservers.removeAll()
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
        guard let window else { return }

        // Make the field the first responder on initial appearance so the
        // user can start typing immediately after the app opens.
        DispatchQueue.main.async { [weak self] in
            self?.reclaimFocus()
        }

        // When the window becomes key again (user Cmd-Tabs back to Grimoire),
        // restore focus. didResignKey fires when leaving — no action needed.
        focusObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: window,
                queue: .main
            ) { [weak self] _ in
                // `queue: .main` guarantees this fires on main despite the
                // @Sendable closure type, so touch main-actor state directly.
                MainActor.assumeIsolated {
                    self?.reclaimFocus()
                }
            }
        )

        // Observe app-level becomeActive too: on Cmd-Tab, AppKit sometimes
        // re-sets the first responder after the per-window didBecomeKey
        // fires, so catching both covers cases where one misses.
        focusObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.reclaimFocus()
                }
            }
        )

        // Window-level click monitor: any mouse-down routes focus back to
        // the input, EXCEPT when the click landed on another editable text
        // editor. Runs after the click is processed so links / selection
        // work first, then we reclaim.
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, event.window === self.window else { return event }
            DispatchQueue.main.async { [weak self] in
                self?.reclaimFocusUnlessAnotherFieldFocused()
            }
            return event
        }

        // After any menu finishes tracking (context menu, popover, etc.),
        // the previous first responder is often nil. Reclaim it.
        focusObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSMenu.didEndTrackingNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self else { return }
                DispatchQueue.main.async {
                    guard let win = self.window, win.isKeyWindow else { return }
                    if win.firstResponder !== self.currentEditor() {
                        self.stashPaneSelectionSource(win)
                        win.makeFirstResponder(self)
                    }
                }
            }
        )
    }

    /// Unconditional focus reclaim. Used by window/app activation paths
    /// where we know nothing else is competing for focus.
    private func reclaimFocus() {
        guard let win = window, win.isKeyWindow else { return }
        if win.firstResponder !== currentEditor() {
            stashPaneSelectionSource(win)
            win.makeFirstResponder(self)
        }
    }

    /// If the responder we're about to steal focus from is a read-only
    /// pane text view, remember it — its selection stays alive after
    /// the steal and `copyPaneSelection()` needs to find it on Cmd+C.
    /// Clicking a *different* pane afterwards re-stashes (or, with no
    /// selection, makes the next Cmd+C a no-op fallthrough), which
    /// matches the "focus follows last click" intuition.
    private func stashPaneSelectionSource(_ win: NSWindow) {
        if let tv = win.firstResponder as? NSTextView,
           !tv.isFieldEditor, !tv.isEditable {
            lastSelectionSource = tv
        }
    }

    /// Focus reclaim that respects another editable text editor in the
    /// same window — used by the click monitor so clicking into, e.g.,
    /// the highlight editor's match-text field doesn't bounce focus
    /// back to the game's input.
    private func reclaimFocusUnlessAnotherFieldFocused() {
        guard let win = window, win.isKeyWindow else { return }
        // If a different field's editor (not ours) took focus, leave it.
        if let fr = win.firstResponder as? NSText, fr !== currentEditor(), fr.isEditable {
            return
        }
        // Some text fields use NSTextField (not NSText) as first responder
        // when their field-editor isn't installed yet. Cover that too.
        if let other = win.firstResponder as? NSTextField, other !== self {
            return
        }
        if win.firstResponder !== currentEditor() {
            stashPaneSelectionSource(win)
            win.makeFirstResponder(self)
        }
    }

    private func applyInsertionPointColor() {
        guard let editor = currentEditor() as? NSTextView else { return }
        editor.insertionPointColor = customInsertionPointColor
        // With `drawsBackground = false` and a clear backgroundColor (so the
        // dark theme shows through), AppKit draws the selection rect at ~0
        // alpha — selected text looks invisible. Re-assert the system
        // selection colours so the highlight stays legible.
        editor.selectedTextAttributes = [
            .backgroundColor: NSColor.selectedTextBackgroundColor,
            .foregroundColor: NSColor.selectedTextColor
        ]
    }
}
