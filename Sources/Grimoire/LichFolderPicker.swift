import AppKit
import GrimoireKit

/// Modal folder picker for locating the user's Lich install. Re-prompts until
/// the chosen folder is a valid Lich folder (contains `lich.rbw`) or the user
/// cancels. Returns the chosen valid root, or nil on cancel.
@MainActor
enum LichFolderPicker {
    static func prompt() -> String? {
        while true {
            let panel = NSOpenPanel()
            panel.title = "Locate your Lich folder"
            panel.message = "Choose the folder that contains lich.rbw (for example ~/Lich5)."
            panel.prompt = "Choose"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser

            guard panel.runModal() == .OK, let url = panel.url else { return nil }
            if LichLocation.isValid(url.path) { return url.path }

            // Picked something that isn't a Lich install — explain and let
            // them try again.
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "That folder isn't a Lich install"
            alert.informativeText = "It doesn't contain lich.rbw. Pick the folder where Lich is installed — it has a lich.rbw file inside."
            alert.addButton(withTitle: "Try Again")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() != .alertFirstButtonReturn { return nil }
        }
    }
}
