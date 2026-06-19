import Foundation
import AppKit
import SwiftUI
import GrimoireKit

// Note: `LinkRef.clickURL` moved to GrimoireKit (LinkRef+ClickURL.swift)
// so it can be unit-tested. The router below consumes the resulting
// `grimoire://` URLs.

/// Holds onto the per-menu-item command + client reference. NSMenuItem
/// targets must be reference types; we attach this to `representedObject`
/// so it's retained for the menu's lifetime.
@MainActor
private final class MenuActionTarget: NSObject {
    let command: String
    let client: LichClient

    init(command: String, client: LichClient) {
        self.command = command
        self.client = client
    }

    @objc func fire(_ sender: Any?) {
        client.echoLocal("> \(command)")
        client.send(command)
    }
}

/// Resolves a `grimoire://` link URL against the live `LichClient` cmdlist
/// and sends the resulting command. Returns `.handled` so SwiftUI doesn't
/// also try to open the URL externally.
@MainActor
struct GrimoireLinkRouter {
    let client: LichClient

    func handle(_ url: URL) -> OpenURLAction.Result {
        guard url.scheme == "grimoire" else { return .systemAction(url) }

        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params: [String: String] = Dictionary(
            uniqueKeysWithValues: comps?.queryItems?.compactMap {
                guard let v = $0.value else { return nil }
                return ($0.name, v)
            } ?? []
        )

        switch url.host {
        case "href":
            // Server-supplied external link. Guard it the same way as
            // server-pushed <LaunchURL>: confirm web links, block other
            // schemes. The href value comes from semi-trusted game data.
            if let raw = params["url"], let target = URL(string: raw) {
                SafeExternalURL.open(target)
            }
            return .handled

        case "cmd":
            // Verbatim command carried on the tag's `cmd` attribute. The
            // server already chose this string for the user; we just send it.
            if let value = params["value"], !value.isEmpty {
                client.echoLocal("> \(value)")
                client.send(value)
            }
            return .handled

        case "cli":
            // Prefer a server-driven context menu when we have an exist id —
            // that's what Wrayth pops up for entities. If we only have a
            // coord (no exist) we resolve via cmdlist directly, since that's
            // a single-action verb. As a last resort fall through to a
            // `look` fallback so naïve `<a>` tags still do something.
            if let exist = params["exist"], !exist.isEmpty {
                openContextMenu(exist: exist, noun: params["noun"])
            } else if let coord = params["coord"] {
                sendCliCommand(coord: coord, noun: params["noun"], exist: nil)
            } else {
                sendCliCommand(coord: nil, noun: params["noun"], exist: nil)
            }
            return .handled

        case "dir":
            if let dir = params["value"], !dir.isEmpty {
                client.echoLocal("> \(dir)")
                client.send(dir)
            }
            return .handled

        default:
            return .systemAction(url)
        }
    }

    /// Fires the `_menu #<exist> N` request and pops an NSMenu at the cursor
    /// when the response arrives. If the request times out or the server
    /// returns no items, falls back to a `look #<exist>` so the click isn't
    /// a no-op.
    private func openContextMenu(exist: String, noun: String?) {
        // Stash these now — by the time the response comes back NSEvent's
        // current event may have changed.
        let mouseLocation = NSEvent.mouseLocation

        client.requestMenu(forExist: exist) { [weak client] menu in
            guard let client else { return }
            guard let menu, !menu.items.isEmpty else {
                // Fallback: simple look.
                let cmd = "look #\(exist)"
                client.echoLocal("> \(cmd)")
                client.send(cmd)
                return
            }
            Self.presentNSMenu(items: menu.items,
                               at: mouseLocation,
                               noun: noun,
                               exist: exist,
                               client: client)
        }
    }

    /// Builds an NSMenu from the server-supplied items, resolving each item's
    /// `coord` against `cmdlist` for both the label and the command. Items
    /// with no `menu_cat` go at the top of the menu; items with a category
    /// nest under that category as a submenu (so e.g. all the "swear at"
    /// emote variants live under a single "Roleplaying" entry rather than
    /// 40 rows in the flat menu).
    @MainActor
    private static func presentNSMenu(
        items: [MenuItem],
        at screenPoint: NSPoint,
        noun: String?,
        exist: String,
        client: LichClient
    ) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        // Category comes from the `<cli>` definition in cmdlist — `<mi>`
        // rarely carries `menu_cat` itself. Fall back to the `<mi>` value
        // when present, otherwise the cli's.
        func rawCategory(for mi: MenuItem) -> String {
            if !mi.category.isEmpty { return mi.category }
            return client.cmdlist[mi.coord]?.menuCategory ?? ""
        }

        // Items whose category is empty, or whose category is a pure-numeric
        // sort key like "0"/"1"/"4" with no display name, get rolled up to
        // the top level — they're effectively "uncategorised" verbs.
        func displayCategory(for mi: MenuItem) -> String {
            Self.prettyCategory(rawCategory(for: mi))
        }

        let topLevel = items.filter { displayCategory(for: $0).isEmpty }
        let categorized = items.filter { !displayCategory(for: $0).isEmpty }
        // Preserve numeric prefix sort order by grouping on the *raw*
        // category, then sorting groups by their raw key (so "5_roleplay"
        // still appears between the items that were `4` and `9`).
        let grouped = Dictionary(grouping: categorized, by: { rawCategory(for: $0) })

        // Render top-level (no-category) items first.
        for mi in topLevel {
            if let nsItem = makeMenuItem(mi, noun: noun, exist: exist, client: client) {
                menu.addItem(nsItem)
            }
        }

        // Separator only when we actually have both kinds of content.
        if !topLevel.isEmpty && !grouped.isEmpty {
            menu.addItem(.separator())
        }

        // Categorised items get a submenu per category, in the order the
        // server intended (numeric-prefix sort on the raw key).
        for rawKey in grouped.keys.sorted() {
            let title = Self.prettyCategory(rawKey)
            guard !title.isEmpty else { continue }
            let submenu = NSMenu(title: title)
            submenu.autoenablesItems = false
            for mi in grouped[rawKey] ?? [] {
                if let child = makeMenuItem(mi, noun: noun, exist: exist, client: client) {
                    submenu.addItem(child)
                }
            }
            guard !submenu.items.isEmpty else { continue }
            let parent = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            parent.submenu = submenu
            menu.addItem(parent)
        }

        guard !menu.items.isEmpty else {
            // Server returned items but none mapped to a known cmdlist coord.
            let cmd = "look #\(exist)"
            client.echoLocal("> \(cmd)")
            client.send(cmd)
            return
        }

        menu.popUp(positioning: nil, at: screenPoint, in: nil)
    }

    /// Turns the server's raw category key (e.g. `"5_roleplay-swear"` or
    /// `"4"`) into a human label (`"Roleplay › Swear"`). Returns an empty
    /// string for purely-numeric keys — those items roll up to the top of
    /// the menu rather than living in a submenu with a meaningless title.
    private static func prettyCategory(_ raw: String) -> String {
        // Strip leading `N_` (numeric sort prefix), if any.
        var body = raw
        if let underscore = body.firstIndex(of: "_"),
           body[..<underscore].allSatisfy(\.isNumber) {
            body = String(body[body.index(after: underscore)...])
        } else if body.allSatisfy(\.isNumber) {
            return ""
        }
        guard !body.isEmpty else { return "" }
        // Hyphen splits sub-categories; render as a › separator.
        return body.split(separator: "-").map(titleCase).joined(separator: " › ")
    }

    /// Replaces underscores with spaces and capitalises each word.
    private static func titleCase(_ part: Substring) -> String {
        part.replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }

    /// Wires up one resolved `<mi>` row as an NSMenuItem. Returns nil when
    /// the row references a coord we don't have in our cmdlist cache yet.
    @MainActor
    private static func makeMenuItem(
        _ mi: MenuItem,
        noun: String?,
        exist: String,
        client: LichClient
    ) -> NSMenuItem? {
        guard let def = client.cmdlist[mi.coord] else { return nil }
        let label = def.resolvedLabel(noun: noun, exist: exist, menuItemNoun: mi.noun)
        let command = def.resolve(noun: noun, exist: exist, menuItemNoun: mi.noun)
        let item = NSMenuItem(
            title: label,
            action: #selector(MenuActionTarget.fire(_:)),
            keyEquivalent: ""
        )
        let target = MenuActionTarget(command: command, client: client)
        item.target = target
        item.representedObject = target  // retain
        return item
    }

    /// Resolves the click via the server's cmdlist (preferred — matches what
    /// Wrayth/Warlock do). Falls back to a simple `look #<exist>` or
    /// `look <noun>` when no template is available, so naïve `<a>` tags
    /// without a coord still do something useful.
    private func sendCliCommand(coord: String?, noun: String?, exist: String?) {
        if let coord, let def = client.cmdlist[coord] {
            let cmd = def.resolve(noun: noun, exist: exist)
            if !cmd.isEmpty {
                client.echoLocal("> \(cmd)")
                client.send(cmd)
                return
            }
        }
        // Fallback. Prefer `#<exist>` (Lich-friendly object id) when present.
        let fallback: String
        if let exist, !exist.isEmpty {
            fallback = "look #\(exist)"
        } else if let noun, !noun.isEmpty {
            fallback = "look \(noun)"
        } else {
            return
        }
        client.echoLocal("> \(fallback)")
        client.send(fallback)
    }
}
