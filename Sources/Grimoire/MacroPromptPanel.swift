import AppKit
import SwiftUI

/// Floating utility panel that prompts the user for a value to substitute
/// into a `\?` slot in a macro action. Matches Wrayth's behavior: small,
/// always-on-top, single-field, Enter to submit, Esc to cancel.
///
/// Lifecycle: a single shared panel is reused across invocations. Showing
/// it for a new macro reconfigures the prompt text and re-focuses the
/// field. Submitting or cancelling hides the panel; it is not destroyed
/// so re-opens are instant.
@MainActor
final class MacroPromptPanel {

    static let shared = MacroPromptPanel()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<PromptContent>?
    private var model = PromptModel()

    private init() {}

    /// Display the panel positioned over the key window. `onSubmit` fires
    /// with the substituted action (the `\?` replaced by the user's text);
    /// the caller is responsible for re-entering the macro engine with it.
    func show(action: String, onSubmit: @escaping (String) -> Void) {
        ensurePanel()
        model.action = action
        model.field = ""
        model.onSubmit = { [weak self] value in
            guard let self else { return }
            self.hide()
            let substituted = action.replacingOccurrences(of: "\\?", with: value, range: action.range(of: "\\?"))
            onSubmit(substituted)
        }
        model.onCancel = { [weak self] in self?.hide() }

        guard let panel else { return }
        positionRelativeToKeyWindow(panel)
        panel.makeKeyAndOrderFront(nil)
        // Slight delay so the panel is on-screen before the field tries
        // for first responder; without this the focus sometimes lands on
        // the parent window instead.
        DispatchQueue.main.async { [weak self] in
            self?.model.focused = true
        }
    }

    func hide() {
        panel?.orderOut(nil)
        model.focused = false
    }

    private func ensurePanel() {
        guard panel == nil else { return }
        let content = PromptContent(model: model)
        let host = NSHostingView(rootView: content)
        let p = FloatingPromptPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
            styleMask: [.titled, .utilityWindow, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        p.title = "Macro Input"
        p.isFloatingPanel = true
        p.level = .floating
        p.hidesOnDeactivate = false
        p.becomesKeyOnlyIfNeeded = false
        p.isMovableByWindowBackground = true
        p.contentView = host
        p.setContentSize(host.fittingSize)
        panel = p
        hostingView = host
    }

    private func positionRelativeToKeyWindow(_ panel: NSPanel) {
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let target: NSRect
        if let key = NSApp.keyWindow ?? NSApp.mainWindow {
            // Center horizontally over the key window, sit just above the
            // bottom edge so it doesn't cover the room description.
            let kf = key.frame
            let w = panel.frame.width
            let h = panel.frame.height
            target = NSRect(
                x: kf.midX - w / 2,
                y: kf.minY + 120,
                width: w,
                height: h
            )
        } else {
            target = NSRect(
                x: screenFrame.midX - panel.frame.width / 2,
                y: screenFrame.midY,
                width: panel.frame.width,
                height: panel.frame.height
            )
        }
        panel.setFrame(target, display: true)
    }
}

/// NSPanel subclass that accepts key status even with `.nonactivatingPanel`
/// — the default refuses, which leaves the SwiftUI TextField unable to
/// receive keystrokes.
private final class FloatingPromptPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Tiny @MainActor-bound observable so the panel's SwiftUI content can be
/// reconfigured across invocations without rebuilding the hosting view.
@MainActor
private final class PromptModel: ObservableObject {
    @Published var action: String = ""
    @Published var field: String = ""
    @Published var focused: Bool = false
    var onSubmit: (String) -> Void = { _ in }
    var onCancel: () -> Void = {}
}

private struct PromptContent: View {
    @ObservedObject var model: PromptModel
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(templatePreview)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(model.action)

            TextField("Enter value", text: $model.field)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit { model.onSubmit(model.field) }

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel") { model.onCancel() }
                    .keyboardShortcut(.cancelAction)
                Button("Send") { model.onSubmit(model.field) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.field.isEmpty)
            }
        }
        .padding(14)
        .frame(width: 360)
        .onChange(of: model.focused) { _, want in
            if want { focused = true }
        }
    }

    /// Shows the macro template with `\?` replaced by a visible `[___]`
    /// so the user can see exactly which slot they're filling and what
    /// surrounds it. Used as a small caption above the field.
    private var templatePreview: String {
        model.action
            .replacingOccurrences(of: "\\?", with: "[___]")
            .replacingOccurrences(of: "\\r", with: " \u{21A9}")
            .replacingOccurrences(of: "\\p", with: " \u{23F8}")
            .replacingOccurrences(of: "\\x", with: "")
    }
}
