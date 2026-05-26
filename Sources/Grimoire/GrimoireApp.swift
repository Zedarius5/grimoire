import SwiftUI
import GrimoireKit

@main
struct GrimoireApp: App {
    // App-level ownership so secondary windows (Spell Presets editor)
    // can share the live client state without re-instantiating it.
    @StateObject private var client = LichClient()
    @StateObject private var macros = MacroEngine()
    @StateObject private var highlights = HighlightStore()
    @StateObject private var spellPresets = SpellPresetStore()

    var body: some Scene {
        WindowGroup("Grimoire") {
            ContentView()
                .environmentObject(client)
                .environmentObject(macros)
                .environmentObject(highlights)
                .environmentObject(spellPresets)
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
