import SwiftUI
import GrimoireKit

@main
struct GrimoireApp: App {
    @StateObject private var macros = MacroEngine()
    @StateObject private var highlights = HighlightStore()

    var body: some Scene {
        WindowGroup("Grimoire") {
            ContentView()
                .environmentObject(macros)
                .environmentObject(highlights)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1100, height: 750)
        .commands {
            // "Debug" menu in the menu bar with utilities that aren't part
            // of normal play — currently just the icon browser.
            CommandMenu("Debug") {
                OpenIconBrowserMenuItem()
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

        Window("Icon Browser", id: "icons") {
            IconBrowserView()
        }
        .defaultSize(width: 820, height: 620)
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
