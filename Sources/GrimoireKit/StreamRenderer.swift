import Foundation

/// One rendered line, tagged with the stream it belongs to.
///
/// `streamId == "main"` is the default (story) stream — everything not inside
/// a `<pushStream id='X'/>...<popStream/>` block.
public struct LineEvent: Equatable, Sendable {
    public let streamId: String
    public let line: RenderedLine

    public init(streamId: String, line: RenderedLine) {
        self.streamId = streamId
        self.line = line
    }
}

/// Walks tokens line-by-line and emits styled `LineEvent`s. Multi-line stream
/// state (push/pop, style stacks, bold depth) persists across calls.
public final class StreamRenderer {

    private var streamStack: [String] = []
    /// Stack of opened tag names whose contents we suppress from the visible
    /// feed (compDef, component, openDialog, etc.). Tracking by name — not a
    /// raw counter — means a stray close tag for one of these can't silently
    /// decrement the depth and unbalance the parser; mismatched closes are
    /// just ignored.
    private var invisibleStack: [String] = []
    private var invisibleDepth: Int { invisibleStack.count }
    private var boldDepth: Int = 0
    /// Tracks `<pushBold/>`/`<popBold/>` markers and the `monsterbold` preset
    /// separately from generic `<b>` emphasis so they can render in yellow.
    private var monsterboldDepth: Int = 0
    private var styleStack: [String] = []
    private var linkStack: [LinkRef] = []
    private var promptDepth: Int = 0

    /// When non-nil, text emissions are diverted into `stateBuffer` instead
    /// of being added to a render stream — used for paired status tags like
    /// `<right>...</right>` whose body is a status value, not visible content.
    private var stateCapture: String? = nil
    private var stateBuffer: String = ""

    /// Accumulates text emitted while `<style id='roomName'>` is on the stack
    /// so the room name lands in `gameState.roomName` when the style closes.
    private var roomNameCapture: String? = nil

    /// Out-of-band character state (vitals, hands, roundtimes, etc.). Updated
    /// in-place as tokens stream through.
    public private(set) var gameState = GameState()

    /// Script-defined dialog panels (`<openDialog>` / `<dialogData>`), keyed
    /// by dialog id (e.g. "Buffs", "UberBar", "PlayerWindow").
    public private(set) var dialogs: [String: Dialog] = [:]

    /// Server-supplied display titles for non-main stream windows, keyed by
    /// stream id. Used so the client can label auto-discovered panes the
    /// same way Wrayth/Warlock do.
    public private(set) var streamWindowTitles: [String: String] = [:]

    /// Command lookup table sent by the server via `<cmdlist><cli .../>...</cmdlist>`.
    /// Each `<a coord='X' ...>` clickable link in the feed indexes into this
    /// to find a command template (with `@`/`#` substitution chars) we send
    /// when the user clicks the link. Refreshes when the server sends
    /// `<updateverbs/>` (which we respond to by requesting a fresh list).
    public private(set) var cmdlist: [String: CmdDefinition] = [:]

    /// Server-driven context menus the client requested via `_menu #<exist> N`.
    /// Each `<menu id='X'>...<mi/>...</menu>` block arrives keyed by the
    /// `id` we sent. Consumers drain the table by id.
    public private(set) var pendingMenus: [String: ServerMenu] = [:]

    /// Incremented every time the server emits `<updateverbs/>` so consumers
    /// can detect arrivals via a monotonic counter (Equatable-friendly) and
    /// re-request the `<cmdlist>`.
    public private(set) var updateVerbsCount: Int = 0

    /// One-shot `<launchURL url='...'/>` directives the server emits in
    /// response to commands like `GOAL` or `SIMUCOIN STORE`. Drained by
    /// `LichClient` after each parse cycle and handed to the UI layer to
    /// open in the system browser.
    public private(set) var pendingLaunchURLs: [URL] = []

    /// Drains the queued launch-URL directives so consumers can dispatch
    /// them onto main and open the browser exactly once.
    public func takeLaunchURLs() -> [URL] {
        let urls = pendingLaunchURLs
        pendingLaunchURLs.removeAll()
        return urls
    }

    /// Internal accumulator while a `<menu>` block is being parsed.
    private var currentMenuId: String? = nil
    private var currentMenuItems: [MenuItem] = []

    /// Set of tag names we've already logged as unrecognised, so the
    /// diagnostic doesn't spam the log every time the same unknown tag
    /// arrives. Used by the temporary "log unknown tags" instrumentation
    /// that helps identify which Stormfront XML tags we still need to
    /// implement (e.g., the `GOAL`/`SIMUCOIN` browser-launch directive).
    private var loggedUnknownTags: Set<String> = []

    /// Pops a server menu from the cache (if it's arrived). Callers should
    /// keep polling or rely on the observable mirror in `LichClient`.
    public func takeMenu(id: String) -> ServerMenu? {
        guard let m = pendingMenus.removeValue(forKey: id) else { return nil }
        return m
    }

    /// Forces all volatile state back to a clean slate. Used as a watchdog
    /// from `LichClient` when other streams continue updating but `main`
    /// has gone silent — symptom of an unrecoverable stuck pushStream /
    /// invisibleStack that the prompt-boundary safety net failed to catch.
    public func forceResetVolatileState() {
        if !invisibleStack.isEmpty {
            appLog("StreamRenderer", "Watchdog reset invisibleStack=\(self.invisibleStack)", level: .info)
            invisibleStack.removeAll()
        }
        if !streamStack.isEmpty {
            appLog("StreamRenderer", "Watchdog reset streamStack=\(self.streamStack)", level: .info)
            streamStack.removeAll()
        }
        if stateCapture != nil {
            appLog("StreamRenderer", "Watchdog reset stateCapture=\(self.stateCapture ?? "?")", level: .info)
            stateCapture = nil
            stateBuffer = ""
        }
        if !styleStack.isEmpty {
            styleStack.removeAll()
        }
        if !linkStack.isEmpty {
            linkStack.removeAll()
        }
        if boldDepth != 0 {
            boldDepth = 0
        }
        if monsterboldDepth != 0 {
            monsterboldDepth = 0
        }
    }

    /// When non-nil, widget tags (`<label>`, `<progressBar>`, `<link>`) are
    /// collected as members of this dialog instead of routed normally.
    private var activeDialogId: String? = nil

    public init() {}

    /// Render a single wire-protocol line. Returns one event per stream the
    /// line wrote visible content into (often just one — the active stream).
    public func render(line: String) -> [LineEvent] {
        let tokens = Tokenizer.tokenize(line)
        var state = RenderState(currentStream: currentStreamId)

        for token in tokens {
            switch token {
            case .openTag(let name, let attrs, let selfClosing):
                processOpen(name: name, attrs: attrs, selfClosing: selfClosing)
            case .closeTag(let name):
                processClose(name: name)
            case .text(let s):
                emitText(s, into: &state)
            case .entityRef(let name):
                emitText(decodeEntity(name), into: &state)
            case .charRef(let code):
                if let scalar = Unicode.Scalar(code) {
                    emitText(String(scalar), into: &state)
                }
            }
        }
        state.flush()
        return state.events
    }

    /// Convenience for callers that only care about the main feed.
    public func renderMain(line: String) -> RenderedLine? {
        render(line: line).first(where: { $0.streamId == "main" })?.line
    }

    // MARK: - State helpers

    private var currentStreamId: String {
        streamStack.last ?? "main"
    }

    private var currentStyle: RunStyle {
        // Either `<pushBold/>` markers OR a `monsterbold` preset on the
        // style stack qualify as NPC-style monster-bold.
        let isMonsterbold = monsterboldDepth > 0
            || styleStack.contains("monsterbold")

        // Inside speech-family presets, suppress *direction*-kind links
        // (`<d>`) but keep *entity*-kind links (`<a>`). Stormfront wraps
        // speech adverbs/verbs ("squeakily", "ask") in `<d cmd="...">`
        // tags whose menus are noise — those are the suppression target.
        // Player and creature names mentioned IN the spoken text use
        // `<a noun="..." exist="...">` and should remain clickable so
        // you can target them straight from chat.
        let inSpeechFamily = styleStack.contains(where: {
            $0 == "speech" || $0 == "whisper" || $0 == "thought"
        })
        let effectiveLink: LinkRef? = {
            guard let top = linkStack.last else { return nil }
            if inSpeechFamily && top.kind == .direction { return nil }
            return top
        }()

        return RunStyle(
            bold: boldDepth > 0 || isMonsterbold,
            monsterbold: isMonsterbold,
            styleId: styleStack.last,
            link: effectiveLink,
            isPrompt: promptDepth > 0
        )
    }

    private func emitText(_ s: String, into state: inout RenderState) {
        let cleaned = s
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
        guard !cleaned.isEmpty else { return }

        // Divert text inside <right>/<left>/<spell> etc. to the state buffer.
        if stateCapture != nil {
            stateBuffer += cleaned
            return
        }

        // Snapshot the room name as it streams through the `roomName` style
        // block so we don't lose it after the closing tag clears the stack.
        if roomNameCapture != nil {
            roomNameCapture? += cleaned
        }

        guard invisibleDepth == 0 else { return }
        state.append(cleaned, style: currentStyle, stream: currentStreamId)
    }

    private func processOpen(name: String, attrs: [String: String], selfClosing: Bool) {
        switch name {
        case "pushStream":
            let id = attrs["id"] ?? ""
            // Empty-id pushes are protocol noise — leaving them on the stack
            // routes subsequent main-stream text to a phantom stream id and
            // is the leading suspect for "story window goes silent" bug.
            // Skip them.
            if !id.isEmpty {
                streamStack.append(id)
                if streamStack.count > 4 {
                    appLog("StreamRenderer", "pushStream id=\(id) -> deep stack=\(self.streamStack)", level: .info)
                }
            } else {
                appLog("StreamRenderer", "Ignoring pushStream with empty id (stack=\(self.streamStack))", level: .info)
            }
        case "popStream":
            if streamStack.isEmpty {
                appLog("StreamRenderer", "Spurious popStream (empty stack)", level: .info)
            } else {
                streamStack.removeLast()
            }
        case "pushBold":
            monsterboldDepth += 1
        case "popBold":
            if monsterboldDepth > 0 { monsterboldDepth -= 1 }
        case "b" where !selfClosing:
            boldDepth += 1
        case "style":
            let id = attrs["id"] ?? ""
            if id.isEmpty {
                if let captured = roomNameCapture {
                    gameState.roomName = captured.trimmingCharacters(in: .whitespacesAndNewlines)
                }
                roomNameCapture = nil
                styleStack.removeAll()
            } else {
                if id == "roomName" {
                    roomNameCapture = ""
                }
                styleStack.append(id)
            }

        // `<preset id='X'>...</preset>` carries Stormfront's named text presets:
        // monsterbold (hostile NPCs), speech, whisper, thought, boldedstat,
        // etc. Push the id onto the same `styleStack` we use for `<style>` so
        // the renderer can pick a colour for it.
        case "preset":
            if let id = attrs["id"], !id.isEmpty {
                if !selfClosing { styleStack.append(id) }
            }

        // Stormfront's main-window status line. The `subtitle` attribute is
        // the bracketed room title (e.g. "[Wehnimer's Landing, North Road]").
        // We fall back to it if a roomName styleId block never arrives.
        //
        // Also: every `<streamWindow>` registers a window the server intends
        // the client to expose. We stash titles for non-main ids so newly
        // emitted streams can be auto-discovered as panes.
        case "streamWindow":
            let id = attrs["id"] ?? ""
            if id == "main", let subtitle = attrs["subtitle"], !subtitle.isEmpty {
                let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "-—– "))
                if gameState.roomName.isEmpty || trimmed.contains("[") {
                    gameState.roomName = trimmed
                }
            }
            if !id.isEmpty, id != "main" {
                let title = (attrs["title"]?.isEmpty == false) ? attrs["title"]! : id
                streamWindowTitles[id] = title
            }

        // Lich emits this when entering a room — `rm` is the map node id.
        case "nav":
            if let rm = attrs["rm"], !rm.isEmpty {
                gameState.roomNumber = rm
            }

        // Server-driven command table. Each `<cli>` row defines a template the
        // client substitutes when an `<a coord='...'>` link is clicked. We
        // capture them silently — they're not rendered as visible content.
        case "cli":
            if let coord = attrs["coord"], !coord.isEmpty {
                cmdlist[coord] = CmdDefinition(
                    coord: coord,
                    command: attrs["command"] ?? "",
                    menu: attrs["menu"] ?? "",
                    menuCategory: attrs["menu_cat"] ?? ""
                )
            }

        // The `<cmdlist>` wrapper just delimits a block of `<cli>` rows. We
        // don't need to track its state, but the close still needs to be
        // recognised so it doesn't fall into the invisibleStack catch-alls.
        case "cmdlist":
            appLog("StreamRenderer", "<cmdlist> arrived", level: .debug)
        case "updateverbs":
            updateVerbsCount += 1
            appLog("StreamRenderer", "<updateverbs/> arrived (count=\(self.updateVerbsCount))", level: .debug)

        // Server-pushed browser launch directive — used by `GOAL` (training
        // points), `SIMUCOIN STORE`, and similar play.net redirect commands.
        // Real tag name is `LaunchURL` (capital L) with a `src` attribute,
        // typically a play.net-relative path like `/gs4/play/cm/loader.asp?...`.
        // `resolveLaunchURL` rebases the relative form against play.net.
        case "LaunchURL":
            if let raw = attrs["src"], !raw.isEmpty,
               let resolved = Self.resolveLaunchURL(raw) {
                pendingLaunchURLs.append(resolved)
                appLog("StreamRenderer", "<LaunchURL> -> \(resolved.absoluteString)", level: .info)
            } else {
                appLog("StreamRenderer", "<LaunchURL> with unparseable src=\(attrs["src"] ?? "<missing>")", level: .info)
            }

        // Server-driven context menus: `<menu id='X'><mi coord='C' noun='N'
        // menu_cat='K'/>...</menu>`. The id correlates with our earlier
        // `_menu #<exist> X` request. Buffer items between open and close.
        case "menu":
            if let id = attrs["id"], !id.isEmpty {
                currentMenuId = id
                currentMenuItems = []
            }
        case "mi":
            if currentMenuId != nil, let coord = attrs["coord"], !coord.isEmpty {
                currentMenuItems.append(MenuItem(
                    coord: coord,
                    noun: attrs["noun"],
                    category: attrs["menu_cat"] ?? ""
                ))
            }
        case "a", "d":
            if !selfClosing {
                let kind: LinkKind = (name == "d") ? .direction : .entity
                linkStack.append(LinkRef(
                    exist: attrs["exist"] ?? "",
                    noun: attrs["noun"],
                    kind: kind,
                    coord: attrs["coord"],
                    href: attrs["href"],
                    cmd: attrs["cmd"]
                ))
            }
        case "prompt" where !selfClosing:
            promptDepth += 1
        case "compDef", "component",
             "menuLink", "output":
            // openDialog/closeDialog are deliberately NOT in this catch-all —
            // their specific cases below carry side-effects (set dialog title,
            // remove dialog) that the catch-all would mask by matching first.
            if !selfClosing { invisibleStack.append(name) }

        // Compass block — capture the `<dir>` children as the available exits.
        // We don't add to invisibleDepth: dir tags only carry attributes (no
        // text body) so there's nothing to suppress.
        case "compass":
            if !selfClosing { gameState.exits = [] }

        case "dir":
            if let v = attrs["value"] {
                gameState.exits.insert(v)
            }

        case "indicator":
            if let id = attrs["id"] {
                gameState.indicators[id] = (attrs["visible"] == "y")
            }

        // Dialogs — register/clear/route, but also keep their text content
        // suppressed from the visible feed.
        case "dialogData":
            let id = attrs["id"] ?? ""
            if attrs["clear"] == "t" {
                if dialogs[id] != nil { dialogs[id]?.widgets = [] }
                else { dialogs[id] = Dialog(id: id) }
                // The UberBar dialog re-emits all body-part `<image>` widgets
                // each refresh. If we don't reset wounds on the clear, healed
                // body parts stay coloured because no image arrives for them.
                if id == "UberBar" {
                    gameState.wounds = Wounds()
                }
            } else if dialogs[id] == nil {
                dialogs[id] = Dialog(id: id)
            }
            if !selfClosing {
                activeDialogId = id
                invisibleStack.append("dialogData")
            }
        case "openDialog":
            let id = attrs["id"] ?? ""
            let title = attrs["title"] ?? id
            dialogs[id] = Dialog(id: id, title: title)
            if !selfClosing { invisibleStack.append("openDialog") }
        case "closeDialog":
            if let id = attrs["id"] {
                dialogs.removeValue(forKey: id)
            }

        // Inside a dialog, links/labels are captured as widgets. Widgets are
        // upserted by id — re-emitting a `<label id='exp_bar' .../>` replaces
        // the existing one in place rather than appending another row.
        case "link":
            if let dialogId = activeDialogId {
                upsertWidget(.link(
                    id: attrs["id"] ?? "",
                    text: attrs["value"] ?? "",
                    command: attrs["cmd"],
                    layout: WidgetLayout.parse(attrs)
                ), in: dialogId)
            } else if !selfClosing {
                invisibleStack.append("link")
            }
        case "label":
            if let dialogId = activeDialogId {
                upsertWidget(.label(
                    id: attrs["id"] ?? "",
                    text: attrs["value"] ?? "",
                    layout: WidgetLayout.parse(attrs)
                ), in: dialogId)
            }
        case "image":
            if let dialogId = activeDialogId {
                upsertWidget(.image(
                    id: attrs["id"] ?? "",
                    name: attrs["name"] ?? "",
                    layout: WidgetLayout.parse(attrs)
                ), in: dialogId)
            }
            // Body-part image widgets double as wound state updates. The id
            // is the body part ("leftArm", "head", ...) and the name encodes
            // severity ("Injury1"–"Injury3", "Scar1"–"Scar3").
            if let id = attrs["id"],
               let name = attrs["name"],
               let part = BodyPart(rawValue: id) {
                gameState.wounds.update(part: part, imageName: name)
            }
        case "sep":
            if let dialogId = activeDialogId {
                upsertWidget(.separator, in: dialogId)
            }

        // Paired status tags — body is a status value, not visible content.
        // Self-closing form (`<spell/>`, `<right/>`) signals an explicit clear,
        // which is how GS resets the prepared spell after a cast.
        case "right", "left", "spell":
            if selfClosing {
                let value = defaultStateValue(for: name)
                switch name {
                case "right": gameState.rightHand     = value
                case "left":  gameState.leftHand      = value
                case "spell": gameState.preparedSpell = value
                default: break
                }
            } else {
                stateCapture = name
                stateBuffer = ""
            }

        // Self-closing data tags — read attrs into game state and (if inside
        // a dialog) also into the widget list.
        case "progressBar":
            // Scripts sometimes emit fractional values (e.g. `value="80.0"`),
            // which `Int(_:)` doesn't accept. Parse via Double first so the
            // bar fill survives float-formatted attributes.
            let pctValue = Int((Double(attrs["value"] ?? "") ?? 0).rounded())
            if let id = attrs["id"], attrs["value"] != nil {
                let text = attrs["text"] ?? ""
                switch id {
                case "health":  gameState.health  = VitalValue(percent: pctValue, text: text)
                case "mana":    gameState.mana    = VitalValue(percent: pctValue, text: text)
                case "stamina": gameState.stamina = VitalValue(percent: pctValue, text: text)
                case "spirit":  gameState.spirit  = VitalValue(percent: pctValue, text: text)
                default: break
                }
            }
            if let dialogId = activeDialogId {
                let barId = attrs["id"] ?? ""
                let barText = attrs["text"] ?? ""
                // Persist a server-supplied name for this id so the
                // editor and the bar's `displayText` fallback can label
                // long-id cooldowns that Lich's `effect-list.xml`
                // doesn't carry. Cheap when unchanged (see `record`).
                SpellNameDatabase.shared.record(id: barId, name: barText)
                upsertWidget(.progressBar(
                    id: barId,
                    value: pctValue,
                    text: barText,
                    time: attrs["time"],
                    layout: WidgetLayout.parse(attrs)
                ), in: dialogId)
            }
        case "roundTime":
            if let valStr = attrs["value"], let v = TimeInterval(valStr) {
                gameState.roundtimeEnd = v
            }
        case "castTime":
            if let valStr = attrs["value"], let v = TimeInterval(valStr) {
                gameState.castTimeEnd = v
            }

        default:
            // Surface unknown open tags exactly once each, with their
            // attributes, so we can identify which Stormfront XML
            // directives we haven't implemented yet. Particularly useful
            // for hunting down the browser-launch tag triggered by
            // commands like `GOAL` and `SIMUCOIN STORE`.
            if !loggedUnknownTags.contains(name) {
                loggedUnknownTags.insert(name)
                let attrPairs = attrs
                    .map { "\($0.key)=\($0.value)" }
                    .sorted()
                    .joined(separator: " ")
                appLog(
                    "StreamRenderer",
                    "unknown open tag <\(name)\(attrPairs.isEmpty ? "" : " \(attrPairs)")\(selfClosing ? "/" : "")>",
                    level: .info
                )
            }
        }
    }

    private func processClose(name: String) {
        switch name {
        case "b":
            if boldDepth > 0 { boldDepth -= 1 }
        case "preset":
            // Pop the most recently pushed preset id. Stormfront's preset
            // close tags don't carry the id back, so we trust the stack
            // ordering — if it's empty (mismatched close), no-op.
            if !styleStack.isEmpty { styleStack.removeLast() }
        case "menu":
            // Finalise a server menu we were buffering. Stash it under its
            // id so the click router can drain it after firing the request.
            if let id = currentMenuId {
                appLog("StreamRenderer", "<menu id=\(id)> closed with \(self.currentMenuItems.count) items", level: .debug)
                pendingMenus[id] = ServerMenu(id: id, items: currentMenuItems)
            }
            currentMenuId = nil
            currentMenuItems = []
        case "a", "d":
            if !linkStack.isEmpty { linkStack.removeLast() }
        case "prompt":
            if promptDepth > 0 { promptDepth -= 1 }
            // Stormfront prompts are reliable frame boundaries: by the time
            // the server emits `>`, everything inside the previous tick
            // should have closed. If state is non-empty here, something
            // unbalanced is wedged — most damagingly `invisibleDepth > 0`,
            // which silently swallows every line of main-feed text while
            // dialog widget updates keep flowing. Reset to a known-good
            // state so the story feed unsticks itself.
            if promptDepth == 0 {
                if !invisibleStack.isEmpty {
                    appLog("StreamRenderer", "Prompt safety net: dropping stuck invisibleStack=\(self.invisibleStack)", level: .info)
                    invisibleStack.removeAll()
                }
                if !streamStack.isEmpty {
                    appLog("StreamRenderer", "Prompt safety net: dropping stuck streamStack=\(self.streamStack)", level: .info)
                    streamStack.removeAll()
                }
                if stateCapture != nil {
                    appLog("StreamRenderer", "Prompt safety net: dropping stuck stateCapture=\(self.stateCapture ?? "?")", level: .info)
                    stateCapture = nil
                    stateBuffer = ""
                }
                if !styleStack.isEmpty {
                    styleStack.removeAll()
                }
                if !linkStack.isEmpty {
                    linkStack.removeAll()
                }
                if boldDepth != 0 {
                    boldDepth = 0
                }
                if monsterboldDepth != 0 {
                    monsterboldDepth = 0
                }
            }
        case "compDef", "component",
             "menuLink", "openDialog", "closeDialog",
             "output":
            // Only pop when this close matches the most recently-opened
            // suppressed tag. An unbalanced close from upstream (eloot's
            // silent-mode helpers strip XML on the way through and can leak
            // one side of a pair) used to silently decrement the counter,
            // sometimes leaving it at -1 — meaning the *next* legitimate
            // open would never bring it above zero, and *meaning* the main
            // feed went permanently silent. Name-stack avoids that whole
            // class of drift.
            if invisibleStack.last == name {
                invisibleStack.removeLast()
            }
        case "compass":
            break
        case "dialogData":
            if invisibleStack.last == "dialogData" {
                invisibleStack.removeLast()
            }
            activeDialogId = nil
        case "link":
            // Only outside-of-dialog links pushed onto invisibleStack on open.
            if activeDialogId == nil, invisibleStack.last == "link" {
                invisibleStack.removeLast()
            }
        case "right", "left", "spell":
            guard stateCapture == name else { break }
            let raw = stateBuffer.trimmingCharacters(in: .whitespacesAndNewlines)
            let value = raw.isEmpty ? defaultStateValue(for: name) : raw
            switch name {
            case "right": gameState.rightHand = value
            case "left":  gameState.leftHand  = value
            case "spell": gameState.preparedSpell = value
            default: break
            }
            stateCapture = nil
            stateBuffer = ""
        default:
            break
        }
    }

    private func defaultStateValue(for tag: String) -> String {
        switch tag {
        case "right", "left": return "Empty"
        case "spell":         return "None"
        default:              return ""
        }
    }

    /// Dictionary subscript on a struct value can't call a mutating method
    /// directly; this helper copies-mutates-stores.
    private func upsertWidget(_ widget: DialogWidget, in dialogId: String) {
        guard var dlg = dialogs[dialogId] else { return }
        dlg.upsert(widget)
        dialogs[dialogId] = dlg
    }

    private func decodeEntity(_ name: String) -> String {
        switch name {
        case "amp": return "&"
        case "lt": return "<"
        case "gt": return ">"
        case "quot": return "\""
        case "apos": return "'"
        case "nbsp": return "\u{00A0}"
        default: return "&\(name);"
        }
    }

    /// Normalises a `<launchURL url='...'/>` value. Absolute URLs pass
    /// through; play.net-relative paths (`/some/path?...`) get rebased
    /// against `https://www.play.net` so the system browser can open
    /// them. Anything that can't be parsed returns nil.
    private static func resolveLaunchURL(_ raw: String) -> URL? {
        if let u = URL(string: raw), u.scheme?.lowercased().hasPrefix("http") == true {
            return u
        }
        if raw.hasPrefix("/") {
            return URL(string: "https://www.play.net\(raw)")
        }
        return URL(string: raw)
    }
}

// MARK: - Per-line render bookkeeping

private struct RenderState {
    var events: [LineEvent] = []
    var currentStream: String
    var currentRuns: [RenderedRun] = []

    mutating func append(_ text: String, style: RunStyle, stream: String) {
        if stream != currentStream {
            flush()
            currentStream = stream
        }
        if var last = currentRuns.last, last.style == style {
            last.text += text
            currentRuns[currentRuns.count - 1] = last
        } else {
            currentRuns.append(RenderedRun(text: text, style: style))
        }
    }

    mutating func flush() {
        defer { currentRuns = [] }
        let cleaned = currentRuns.filter { !$0.text.isEmpty }
        guard !cleaned.isEmpty else { return }
        let joined = cleaned.map(\.text).joined()
        guard !joined.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        events.append(LineEvent(streamId: currentStream, line: RenderedLine(runs: cleaned)))
    }
}
