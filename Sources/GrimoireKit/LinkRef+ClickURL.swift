import Foundation

/// `grimoire://` URL encoding of a clickable link, used by the Story /
/// Dialog views to attach an `.link` attribute that the app's URL
/// router intercepts. Pure URL building -- no AppKit / SwiftUI -- so
/// it lives in GrimoireKit and is unit-testable.
///
/// Routes:
/// - `grimoire://href?url=...`  external URL (always wins when set).
/// - `grimoire://cmd?value=...` literal verbatim command to send.
///                              From a `<d cmd='X'>` tag, OR (if
///                              direction-kind and no other info) from
///                              the run's visible text via
///                              `fallbackText:` -- that's the bare
///                              `<d>VERB</d>` convention.
/// - `grimoire://cli?coord=...&exist=...&noun=...`
///                              entity link the host routes through
///                              the server's `<cmdlist>`.
/// - `grimoire://dir?value=...` direction link with no `cmd`, fallback
///                              to noun/exist as the direction value.
public extension LinkRef {
    /// Returns a `grimoire://` URL encoding everything we need to
    /// resolve this link at click time. Returns nil for links with no
    /// actionable info.
    ///
    /// `fallbackText` is the run's visible text. SF/Wrayth's
    /// `<d>VERB</d>` convention (no `cmd` attribute, no `exist`/`noun`)
    /// means "clicking sends the visible text as a command" -- e.g.
    /// `<d>ASCENSION LEARN CONFIRM</d>` clicked = sending "ASCENSION
    /// LEARN CONFIRM". Without the fallback those clicks were dead.
    func clickURL(fallbackText: String? = nil) -> URL? {
        var components = URLComponents()
        components.scheme = "grimoire"

        if let href, !href.isEmpty {
            components.host = "href"
            components.queryItems = [URLQueryItem(name: "url", value: href)]
            return components.url
        }

        // `<d cmd='X'>...</d>` (and rarely `<a cmd='X'>...</a>`) carry
        // the click target verbatim.
        if let cmd, !cmd.isEmpty {
            components.host = "cmd"
            components.queryItems = [URLQueryItem(name: "value", value: cmd)]
            return components.url
        }

        // Bare `<d>VERB</d>` with no attributes: the visible text IS
        // the command. Only do this for direction-kind links so we
        // don't try to send entity descriptions ("pink-nosed grey and
        // white kitten") as commands.
        if kind == .direction,
           let text = fallbackText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !text.isEmpty {
            components.host = "cmd"
            components.queryItems = [URLQueryItem(name: "value", value: text)]
            return components.url
        }

        switch kind {
        case .entity:
            components.host = "cli"
            var items: [URLQueryItem] = []
            if let coord, !coord.isEmpty {
                items.append(URLQueryItem(name: "coord", value: coord))
            }
            if !exist.isEmpty {
                items.append(URLQueryItem(name: "exist", value: exist))
            }
            if let noun, !noun.isEmpty {
                items.append(URLQueryItem(name: "noun", value: noun))
            }
            // Need *something* to click against.
            guard !items.isEmpty else { return nil }
            components.queryItems = items
            return components.url

        case .direction:
            components.host = "dir"
            // For direction links the exist field carries the direction
            // (e.g. "north", "out"). Fall back to the noun.
            let value = exist.isEmpty ? (noun ?? "") : exist
            guard !value.isEmpty else { return nil }
            components.queryItems = [URLQueryItem(name: "value", value: value)]
            return components.url
        }
    }
}
