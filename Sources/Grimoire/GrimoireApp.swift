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
    // Hoisted from ContentView so the AppDelegate can SIGTERM the
    // spawned Lich child on Cmd-Q / red-button close (otherwise it
    // orphans, keeping the character "in the world" past logout —
    // animate refresh stalls, sustains tick down).
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
                    // Hand the delegate the references it needs. Weak
                    // refs in the delegate, so retain stays on the
                    // @StateObjects up here.
                    appDelegate.client = client
                    appDelegate.lich = lich
                    // Kill orphan Lich whenever the game-server-side
                    // socket closes (in-game `QUIT`, network drop,
                    // explicit Disconnect button). Idempotent — the
                    // Cmd-Q cleanup calls `stop()` again, that's fine.
                    client.onDisconnect = { [weak lich] in lich?.stop() }
                }
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1100, height: 750)
        .commands {
            // "Debug" menu in the menu bar with utilities that aren't part
            // of normal play — icon browser + wounds preview harness.
            CommandMenu("Debug") {
                OpenIconBrowserMenuItem()
                OpenWoundsDebugMenuItem()
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

        Window("Icon Browser", id: "icons") {
            IconBrowserView()
        }
        .defaultSize(width: 820, height: 620)

        Window("Wounds Debug", id: "wounds-debug") {
            WoundsDebugView()
        }
        .defaultSize(width: 720, height: 540)
    }
}

/// Menu-bar item that opens the Icon Browser window. Lives as its own
/// SwiftUI view so it can use the `openWindow` environment value (which
/// isn't accessible from inside the `body` of an `App`).
private struct OpenIconBrowserMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Icon Browser") {
            openWindow(id: "icons")
        }
        .keyboardShortcut("i", modifiers: [.command, .option])
    }
}

/// Menu-bar item that opens the Wounds Debug window. Use this while
/// iterating on `BodyDiagram` visuals so you don't have to take damage
/// in-game to see how each wound/scar rank renders.
private struct OpenWoundsDebugMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Wounds Debug") {
            openWindow(id: "wounds-debug")
        }
        .keyboardShortcut("w", modifiers: [.command, .option])
    }
}

/// Owns the graceful-shutdown sequence so Cmd-Q, File → Quit, and the
/// red close button all converge on the same cleanup:
///   1. Send `quit` to Lich/GS if still connected (clean in-game logout).
///   2. Wait briefly (cap 3s) for the server to close the socket.
///   3. SIGTERM the spawned Lich child so it doesn't orphan.
///   4. Reply to AppKit so the app actually exits.
///
/// Without this, closing Grimoire leaves `lich.rbw` running with the
/// game session live — the character lingers as linkdead, sustains
/// tick down, Animate Dead pets eventually die because the refresh
/// script's frontend is gone but the character is still in the world.
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

    /// Idempotent end-of-shutdown step: cancel observers, SIGTERM
    /// Lich, give the signal a moment to land, then reply true so
    /// AppKit completes the terminate.
    private func completeShutdown() {
        guard !didShutdown else { return }
        didShutdown = true
        statusSubscription?.cancel()
        statusSubscription = nil
        fallbackTimer?.cancel()
        fallbackTimer = nil

        lich?.stop()
        // Brief settle window for SIGTERM. Process termination is
        // typically <50ms; we wait a bit longer to be safe.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.reply(toApplicationShouldTerminate: true)
        }
    }
}
