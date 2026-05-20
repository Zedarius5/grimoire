import SwiftUI
import GrimoireKit

struct InputBar: View {
    @ObservedObject var client: LichClient
    let gameState: GameState

    @Environment(\.fontSize) private var fontSize

    @State private var text: String = ""
    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil
    @FocusState private var focused: Bool

    /// Minimum length for a command to count as "long enough to repeat" via
    /// Ctrl/Option-Enter macros. Persisted in UserDefaults.
    @AppStorage("grimoire.macroThreshold") private var macroThreshold: Int = 3

    private var isActive: Bool { client.isActive }

    var body: some View {
        HStack(spacing: 8) {
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
                    // Drop the `isActive` gate: we want the field to *try*
                    // for first-responder status from the moment it appears,
                    // so that the instant `client.isActive` flips true after
                    // connect the AppKit field can grab focus during the
                    // same `updateNSView` pass that enables it. Gating on
                    // `isActive` previously created a race where the field
                    // became enabled but no one re-triggered `makeFirstResponder`.
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
        .onChange(of: client.isActive) { _, nowActive in
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

        client.echoLocal("> \(command)")
        client.send(command)

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
        let command = arr[n]
        client.echoLocal("> \(command)")
        client.send(command)
    }
}
