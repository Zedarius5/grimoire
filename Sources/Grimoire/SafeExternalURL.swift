import AppKit
import Foundation

/// Centralised, user-guarded path for opening external URLs that originate
/// from the game connection — server-pushed `<LaunchURL>` directives and
/// clicked `<a href>` links.
///
/// Game data is only semi-trusted (a compromised connection or third-party
/// Lich script could inject a link), so we never hand a URL straight to the OS:
///
///   - http/https links: confirm with the user, showing the full URL.
///   - any other scheme (file://, custom app schemes, javascript:, …): refuse
///     and explain, since those can launch apps or open files without warning.
@MainActor
enum SafeExternalURL {

    /// Decision for a given URL. Split out as a pure function so the policy is
    /// obvious and reviewable at a glance: only real web links are openable.
    enum Decision: Equatable { case confirmWeb, blockScheme }

    static func decision(for url: URL) -> Decision {
        switch url.scheme?.lowercased() {
        case "http", "https": return .confirmWeb
        default:              return .blockScheme
        }
    }

    static func open(_ url: URL) {
        switch decision(for: url) {
        case .confirmWeb:  confirmAndOpenWeb(url)
        case .blockScheme: explainBlocked(url)
        }
    }

    private static func confirmAndOpenWeb(_ url: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Open this link in your browser?"
        alert.informativeText = """
        This web link came from your game connection. Only open it if you \
        trust where it leads.

        \(url.absoluteString)
        """
        alert.addButton(withTitle: "Open Link")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }

    private static func explainBlocked(_ url: URL) {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = "Blocked a non-web link"
        alert.informativeText = """
        Your game connection tried to open a link that isn't a normal web \
        (http/https) address, so Grimoire blocked it to keep you safe. Links \
        like this can launch other apps or open files on your Mac without \
        warning.

        Blocked link:
        \(url.absoluteString)
        """
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
