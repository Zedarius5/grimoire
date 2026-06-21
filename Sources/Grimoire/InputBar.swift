import SwiftUI
import GrimoireKit

/// Takes only the values it reads (plus an `onSend` closure) rather than an
/// `@ObservedObject var client: LichClient`, so it isn't woken on every
/// LichClient publish — only when the values that matter change.
///
/// NOTE: do NOT add `.equatable()` to InputBar at the call site. Its internal
/// @State (`text`, `history`, `historyIndex`, `focused`) drives visible UI;
/// an Equatable wrap would short-circuit body on @State-only changes, so
/// history navigation and macro-fills would stop propagating.
struct InputBar: View {
    let isActive: Bool
    let gameState: GameState
    /// Called for both user-submitted commands and macro-repeat
    /// requests. Caller (ContentView) bundles `client.echoLocal` +
    /// `client.send` into this closure so we don't need to hold a
    /// reference to LichClient and subscribe to every publish.
    let onSend: (String) -> Void

    @Environment(\.fontSize) private var fontSize

    @State private var text: String = ""
    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil
    @FocusState private var focused: Bool

    /// Minimum length for a command to count as "long enough to repeat" via
    /// Ctrl/Option-Enter macros. Persisted in UserDefaults.
    @AppStorage("grimoire.macroThreshold") private var macroThreshold: Int = 3

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("InputBar")
        return HStack(spacing: 8) {
            Text(">")
                .font(.system(size: fontSize, design: .monospaced))
                .foregroundStyle(isActive ? GameTheme.foreground : Color.gray.opacity(0.6))

            ZStack(alignment: .leading) {
                // Bricks sit behind the input text, left-anchored, so an
                // active roundtime is immediately visible at the cursor edge.
                RoundtimeBricks(state: gameState)

                CommandTextField(
                    text: $text,
                    placeholder: isActive ? "Type a command..." : "Connect to Lich to send commands",
                    isEnabled: isActive,
                    foregroundColor: NSColor(GameTheme.foreground),
                    insertionPointColor: NSColor(GameTheme.foreground),
                    // Not gated on `isActive`: the field should try for
                    // first-responder from the moment it appears, so the
                    // instant `isActive` flips true after connect it can grab
                    // focus in the same `updateNSView` pass that enables it.
                    // Gating on `isActive` left the field enabled with no one
                    // re-triggering `makeFirstResponder`.
                    shouldFocus: focused,
                    onSubmit: submit,
                    onCtrlReturn:   { repeatNthQualifying(0) },
                    onOptionReturn: { repeatNthQualifying(1) },
                    onUpArrow:      recallPrevious,
                    onDownArrow:    recallNext
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.white.opacity(0.08)),
            alignment: .top
        )
        .environment(\.colorScheme, .dark)
        .onAppear { focused = true }
        .onChange(of: isActive) { _, nowActive in
            if nowActive { focused = true }
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroRepeatLast)) { _ in
            repeatNthQualifying(0)
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroRepeatSecondToLast)) { _ in
            repeatNthQualifying(1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroReturnOrRepeatLast)) { _ in
            if text.isEmpty { repeatNthQualifying(0) } else { submit() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroHistoryPrev)) { _ in
            recallPrevious()
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroHistoryNext)) { _ in
            recallNext()
        }
        .onReceive(NotificationCenter.default.publisher(for: .grimoireMacroFillInput)) { note in
            if let s = note.object as? String {
                text = s
                focused = true
            }
        }
    }

    private func submit() {
        let command = text.trimmingCharacters(in: .whitespaces)
        text = ""
        historyIndex = nil
        guard !command.isEmpty, isActive else { return }

        onSend(command)

        // Append to history; avoid back-to-back duplicates
        if history.last != command {
            history.append(command)
        }
        // Cap history at a sensible size
        if history.count > 500 {
            history.removeFirst(history.count - 500)
        }
    }

    private func recallPrevious() {
        guard !history.isEmpty else { return }
        let nextIndex: Int
        if let i = historyIndex {
            nextIndex = max(0, i - 1)
        } else {
            nextIndex = history.count - 1
        }
        historyIndex = nextIndex
        text = history[nextIndex]
    }

    private func recallNext() {
        guard let i = historyIndex else { return }
        if i + 1 >= history.count {
            historyIndex = nil
            text = ""
        } else {
            historyIndex = i + 1
            text = history[i + 1]
        }
    }

    /// Resubmits the nth most-recent command whose length meets the macro
    /// threshold. `n == 0` is the most recent qualifying command (Ctrl+Enter),
    /// `n == 1` is the one before that (Option+Enter), and so on.
    ///
    /// We intentionally don't append to history — otherwise spamming
    /// Option+Enter 8 times would shift "second-to-last" with each press.
    private func repeatNthQualifying(_ n: Int) {
        guard isActive else { return }
        let qualifying = history.reversed().filter { $0.count >= macroThreshold }
        let arr = Array(qualifying)
        guard arr.indices.contains(n) else { return }
        onSend(arr[n])
    }
}
