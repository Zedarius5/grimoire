import SwiftUI
import AppKit
import GrimoireKit

/// Hotkey-capture field — click to enter capture mode, press a key combo to
/// bind it, Esc to cancel. Used for the macro editor's `key` column instead
/// of a free-form TextField, which also avoids a per-keystroke `@Published`
/// cascade on every character typed.
struct KeyCaptureField: View {
    @Binding var keyName: String

    /// When `requestedCaptureForId` matches this row's id, the field
    /// auto-enters capture mode on appear. The parent clears the request
    /// after it's been consumed. Used so adding a new binding lands the
    /// user directly in capture mode without an extra click.
    var id: UUID
    @Binding var requestedCaptureForId: UUID?

    @State private var capturing: Bool = false
    @State private var monitor: Any? = nil
    /// Used to suppress the runtime macro engine while this field is capturing,
    /// so a keystroke meant to bind a macro doesn't fire the existing one.
    @EnvironmentObject private var macros: MacroEngine

    var body: some View {
        Button {
            capturing.toggle()
        } label: {
            HStack {
                Text(displayLabel)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(labelColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(borderColor, lineWidth: capturing ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .help(capturing
              ? "Press a key combo to bind. Esc cancels."
              : "Click to capture a key combo.")
        .onChange(of: capturing) { _, want in
            if want { startCapture() } else { endCapture() }
        }
        .onAppear {
            // Auto-capture on appear when the parent requested it for
            // this row (e.g., the user just clicked "Add binding").
            if requestedCaptureForId == id {
                requestedCaptureForId = nil
                capturing = true
            }
        }
        .onChange(of: requestedCaptureForId) { _, new in
            if new == id {
                requestedCaptureForId = nil
                capturing = true
            }
        }
        .onDisappear { endCapture() }
    }

    private var displayLabel: String {
        if capturing { return "Press a key combo... (Esc to cancel)" }
        if keyName.isEmpty { return "Click to set key" }
        return keyName
    }

    private var labelColor: Color {
        if capturing { return .accentColor }
        if keyName.isEmpty { return .secondary }
        return .primary
    }

    private var borderColor: Color {
        capturing ? .accentColor : Color.gray.opacity(0.35)
    }

    private func startCapture() {
        guard monitor == nil else { return }
        // Suppress the runtime macro engine while capturing so the keystroke
        // binds the macro instead of firing the existing one into the game.
        macros.beginKeyCapture()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Esc with no modifiers cancels capture without writing.
            // (Modifier-Esc, e.g. Shift-Esc, is still a valid bind.)
            let mods = event.modifierFlags.intersection([.shift, .control, .option, .command])
            if event.keyCode == 53, mods.isEmpty {
                Task { @MainActor in capturing = false }
                return nil
            }
            // Compute canonical name via the same code path the runtime
            // matcher uses, so what we display here is exactly what will
            // be compared at keystroke time.
            if let combo = MacroEngine.canonicalKey(for: event) {
                Task { @MainActor in
                    keyName = combo
                    capturing = false
                }
                return nil
            }
            // Unmappable key (caps lock, fn-only, etc.) — let the event
            // pass through and keep listening.
            return event
        }
    }

    private func endCapture() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
            macros.endKeyCapture()
        }
    }
}
