import SwiftUI
import AppKit
import Combine
import GrimoireKit

@main
struct GrimoireApp: App {
    // App-level ownership so secondary windows (Spell Presets editor)
    // can share the live client state without re-instantiating it.
    @StateObject private var client = LichClient()
    @StateObject private var macros = MacroEngine()
    @StateObject private var highlights = HighlightStore()
    @StateObject private var spellPresets = SpellPresetStore()
    // Hoisted from ContentView so the AppDelegate can SIGTERM the spawned Lich
    // child on Cmd-Q / red-button close; otherwise it orphans and keeps the
    // character in the world past logout.
    @StateObject private var lich = LichProcess()

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("Grimoire") {
            ContentView()
                .environmentObject(client)
                .environmentObject(lich)
                .environmentObject(macros)
                .environmentObject(highlights)
                .environmentObject(spellPresets)
                .onAppear {
                    // Hand the delegate weak refs; retain stays on the
                    // @StateObjects up here.
                    appDelegate.client = client
                    appDelegate.lich = lich
                    // Kill orphan Lich whenever the game-server socket closes
                    // (in-game `QUIT`, network drop, Disconnect). Idempotent —
                    // the Cmd-Q cleanup may call `stop()` again.
                    client.onDisconnect = { [weak lich] in lich?.stop() }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1100, height: 750)
        .commands {
            // File ▸ Open Log… — review an old log with current highlights.
            CommandGroup(after: .newItem) {
                OpenLogMenuItem()
            }
            // "Debug" menu in the menu bar with utilities that aren't part
            // of normal play.
            CommandMenu("Debug") {
                OpenPerfDebugMenuItem()
            }
        }

        Window("Macro Editor", id: "macros") {
            MacroEditorView()
                .environmentObject(macros)
        }
        .defaultSize(width: 920, height: 620)

        Window("Highlights", id: "highlights") {
            HighlightEditorView()
                .environmentObject(highlights)
        }
        .defaultSize(width: 900, height: 600)

        Window("Spell Presets", id: "spell-presets") {
            SpellPresetEditorView()
                .environmentObject(spellPresets)
                .environmentObject(client)
        }
        .defaultSize(width: 920, height: 620)

        Window("Performance", id: "perf-debug") {
            PerfDebugView()
        }
        .defaultSize(width: 520, height: 600)

        // One viewer window per opened log file (keyed by URL).
        WindowGroup(for: URL.self) { $url in
            if let url {
                LogViewerView(url: url)
                    .environmentObject(highlights)
            }
        }
        .defaultSize(width: 900, height: 700)
    }
}

/// Menu-bar item that opens the live perf dashboard for spotting main-thread
/// stalls / over-rendering panes during normal gameplay.
private struct OpenPerfDebugMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Performance") {
            openWindow(id: "perf-debug")
        }
        .keyboardShortcut("p", modifiers: [.command, .option])
    }
}

/// Owns the graceful-shutdown sequence so Cmd-Q, File → Quit, and the red
/// close button all converge on the same cleanup:
///   1. Send `quit` to Lich/GS if still connected (clean in-game logout).
///   2. Wait briefly (cap 3s) for the server to close the socket.
///   3. SIGTERM the spawned Lich child so it doesn't orphan.
///   4. Reply to AppKit so the app actually exits.
///
/// Without this, closing Grimoire leaves `lich.rbw` running with the game
/// session live, so the character lingers in the world past logout.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var client: LichClient?
    weak var lich: LichProcess?

    private var statusSubscription: AnyCancellable?
    private var fallbackTimer: DispatchWorkItem?
    private var didShutdown = false

    /// macOS default is "closing the last window leaves the app
    /// running in the menu bar." We override so the red close button
    /// triggers `applicationShouldTerminate` and runs cleanup.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        let needConnectionFlush = client?.isActive ?? false
        let needLichStop = lich?.isRunning ?? false

        guard needConnectionFlush || needLichStop else {
            return .terminateNow
        }

        if needConnectionFlush, let client {
            client.send("quit")
            // Resolve as soon as the server confirms by closing the
            // socket (status drops out of .connected/.connecting).
            statusSubscription = client.$status
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self, let c = self.client else { return }
                    if !c.isActive { self.completeShutdown() }
                }
            // Hard ceiling so we don't hang forever if the server
            // never closes (offline Lich, network wedged, etc.).
            let work = DispatchWorkItem { [weak self] in self?.completeShutdown() }
            fallbackTimer = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
        } else {
            // Nothing to flush — just kill Lich and reply.
            completeShutdown()
        }

        return .terminateLater
    }

    /// Idempotent end-of-shutdown step: cancel observers, then SIGTERM
    /// Lich and wait for it to actually exit before replying so AppKit
    /// completes the terminate.
    private func completeShutdown() {
        guard !didShutdown else { return }
        didShutdown = true
        statusSubscription?.cancel()
        statusSubscription = nil
        fallbackTimer?.cancel()
        fallbackTimer = nil

        guard let lich, lich.isRunning else {
            NSApp.reply(toApplicationShouldTerminate: true)
            return
        }
        // Give Lich time to save script settings and let scripts wind down
        // after SIGTERM, and reply the instant it's actually gone. The 3s
        // ceiling is a backstop; a clean Lich exit is usually under a second.
        lich.terminateAndWait(timeout: 3) {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
    }
}
