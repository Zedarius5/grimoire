import Foundation
import Network

/// A TCP client that streams the GemStone XML protocol from a Lich instance.
///
/// Reads and parses on a dedicated background queue so the main thread (UI)
/// never gates network draining. Fast scripts like go2 produce bursts of
/// traffic — if Grimoire is slow to consume from the socket, Lich's writes
/// back-pressure and that delays in-game commands (visible as type-ahead
/// errors).
public final class LichClient: ObservableObject, @unchecked Sendable {

    public enum Status: Equatable, Sendable {
        case disconnected
        case connecting
        case connected
        case failed(String)
    }

    /// Protocol the client should speak after the TCP connection is established.
    /// `.raw` is bytes-in/bytes-out (used for capture replays etc.); `.wrayth`
    /// performs the Stormfront-style handshake (game key + FE string + two
    /// `<c>` readies) and prefixes user commands with `<c>` for flow control.
    public enum Mode: Equatable, Sendable {
        case raw
        case wrayth(gameKey: String)
    }

    @Published public private(set) var status: Status = .disconnected
    @Published public private(set) var linesByStream: [String: [RenderedLine]] = [:]
    /// Monotonic per-stream counter of total lines ever appended (ignoring
    /// cap-trimming). Lets views detect "new content arrived" even when
    /// `linesByStream[id].count` is capped and unchanged — without it,
    /// at-cap streams visually freeze because `lines.count` equality
    /// short-circuits SwiftUI's body re-evaluation.
    @Published public private(set) var streamRevisions: [String: Int] = [:]
    @Published public private(set) var endpointLabel: String = ""
    @Published public private(set) var gameState: GameState = GameState()
    @Published public private(set) var dialogs: [String: Dialog] = [:]
    @Published public private(set) var streamWindowTitles: [String: String] = [:]
    @Published public private(set) var cmdlist: [String: CmdDefinition] = [:]

    /// Awaiting-response callbacks for `_menu` requests, keyed by the menu id
    /// we sent. Cleared by the response handler (or by a timeout).
    private var pendingMenuCallbacks: [String: (ServerMenu?) -> Void] = [:]

    /// Monotonic counter for menu request ids — matches warlock3's
    /// `menuCount++` (the server may reject non-numeric ids).
    private var nextMenuId: Int = 1

    /// Last `updateVerbsCount` we saw in a parse batch — used to fire
    /// `refreshVerbs()` exactly once per `<updateverbs/>` arrival.
    private var lastUpdateVerbsSeen: Int = 0

    /// Wall-clock of the last successful append to `linesByStream["main"]`
    /// and the last "any other activity" tick. The watchdog uses the gap to
    /// detect the "story window stuck" bug — protocol activity continues
    /// (dialogs, side streams, prompts) but main-stream text is silently
    /// being routed elsewhere by a wedged streamStack/invisibleStack.
    private var lastMainAppendAt: Date = Date()
    private var lastOtherActivityAt: Date = Date()

    /// Invoked on the main thread once per server-pushed `<launchURL/>`.
    /// The UI layer (which owns AppKit) sets this to call
    /// `NSWorkspace.shared.open(_:)`. Kept as a closure rather than
    /// `@Published` because launches are one-shot events, not state we
    /// want to retain across view rebuilds.
    public var onLaunchURL: ((URL) -> Void)?

    /// Owned by `workQueue`.
    private var connection: NWConnection?
    private var renderer = StreamRenderer()
    private var byteBuffer = Data()
    private var mode: Mode = .raw
    /// Stream ids whose lines should be rerouted into the `"main"`
    /// buffer instead of their own (used to keep a hidden pane's
    /// messages visible in the story feed). App layer sets this from
    /// the current pane configuration via `setStreamFallthroughIds(_:)`.
    /// Owned by `workQueue` — only read inside the parsing loop.
    private var streamFallthroughIds: Set<String> = []

    /// Updates the set of streams whose lines should be rerouted to
    /// `"main"`. Safe to call from any thread; the actual mutation
    /// hops onto `workQueue` so it doesn't race with parsing.
    public func setStreamFallthroughIds(_ ids: Set<String>) {
        workQueue.async { [weak self] in
            self?.streamFallthroughIds = ids
        }
    }

    private let workQueue = DispatchQueue(
        label: "com.zedarius.Grimoire.LichClient",
        qos: .userInteractive
    )

    public init() {
        // First reference starts the background heartbeat that reports
        // main-thread responsiveness even when main is wedged.
        _ = Diagnostics.shared
    }

    public var isActive: Bool {
        switch status {
        case .connecting, .connected: return true
        default: return false
        }
    }

    public var mainLines: [RenderedLine] { linesByStream["main"] ?? [] }

    /// Monotonic revision for a given stream — increments every time a new
    /// line is appended (counting pre-cap appends, so it changes even when
    /// the visible line count is pinned at the cap). Callers compare
    /// revisions to detect "content changed" rather than `lines.count`.
    public func revision(for stream: String) -> Int {
        streamRevisions[stream] ?? 0
    }

    public func lines(for stream: String) -> [RenderedLine] {
        linesByStream[stream] ?? []
    }

    // MARK: - Connect / disconnect

    public func connect(host: String, port: UInt16, mode: Mode = .raw) {
        // UI-thread state.
        status = .connecting
        endpointLabel = "\(host):\(port)"
        linesByStream = [:]
        streamRevisions = [:]
        gameState = GameState()
        dialogs = [:]
        self.mode = mode
        // Invalidate any pending render-state clear scheduled by a
        // previous disconnect. With `renderedStateClearDelay` at 4.5s,
        // it's easy to start a new session inside that window — and
        // without this bump, the stale clear fires after the new
        // session's first lines have arrived and wipes them.
        disconnectGeneration &+= 1

        workQueue.async { [weak self] in
            guard let self else { return }
            // Disown the previous connection's stateUpdateHandler BEFORE
            // cancelling so its deferred `.cancelled` (or any late `.failed`)
            // can't mutate this client's state. Without this detach, an old
            // failed-connection's late `.cancelled` arriving after a fresh
            // `connect()` would (1) revert status `.connecting` ->
            // `.disconnected` and (2) call `scheduleRenderedStateClear()`,
            // which bumps `disconnectGeneration` AFTER `connect()`'s own
            // bump — so the pending clear's gen matches the current gen and
            // fires ~4.5s into the new session, wiping the initial autostart
            // scroll. Hits hardest on the launch-then-poll-connect path
            // where the first few connect attempts fail until Lich's
            // frontend port is bound.
            if let old = self.connection {
                old.stateUpdateHandler = nil
                old.cancel()
            }
            self.connection = nil
            self.renderer = StreamRenderer()
            self.byteBuffer = Data()

            guard let nwPort = NWEndpoint.Port(rawValue: port) else {
                DispatchQueue.main.async { self.status = .failed("Invalid port") }
                return
            }

            let conn = NWConnection(
                host: NWEndpoint.Host(host),
                port: nwPort,
                using: .tcp
            )
            conn.stateUpdateHandler = { [weak self] state in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.handleState(state)
                }
            }
            conn.start(queue: self.workQueue)
            self.connection = conn
        }
    }

    public func disconnect() {
        switch status {
        case .connecting, .connected:
            status = .disconnected
        default:
            break
        }
        scheduleRenderedStateClear()

        workQueue.async { [weak self] in
            // Same handler-detach rationale as `connect()`: prevent the
            // connection's eventual `.cancelled` from firing a second
            // render-clear (or, if the user reconnects fast enough,
            // tearing down the new `.connecting` state).
            if let conn = self?.connection {
                conn.stateUpdateHandler = nil
                conn.cancel()
            }
            self?.connection = nil
        }
    }

    /// Clear all server-driven state on disconnect so every pane shows
    /// its empty/default appearance: no room name, no vitals, no
    /// dialogs, no stream lines. Reconnecting always rebuilds from
    /// scratch — the server re-sends all of this during the post-login
    /// handshake.
    private func clearRenderedState() {
        // Breadcrumb so it's obvious in the log if a clear ever fires
        // unexpectedly (e.g., during an active session — which is how
        // the "first few seconds of autostart cut off" bug presented).
        appLog(
            "LichClient",
            "clearRenderedState firing (gen=\(disconnectGeneration), mainLines=\(mainLines.count))",
            level: .info
        )
        linesByStream = [:]
        streamRevisions = [:]
        gameState = GameState()
        dialogs = [:]
    }

    /// Defer the render-state clear until after the UI has had time to
    /// fade content out gracefully. Without the delay the views would
    /// snap to their empty/default appearance (e.g., HandsStrip showing
    /// "Empty / Empty / None", vitals reading 0/0) and *then* fade out
    /// — the user would see the empty state briefly. With the delay the
    /// last-seen content stays put during the fade.
    ///
    /// The constant here covers ContentView's disconnect grace period
    /// (3s "stay on last frame") plus the sigil cross-fade (1.25s),
    /// with a small margin so state survives slightly longer than the
    /// fade — otherwise the GameView would empty out mid-fade. Keep
    /// in sync with `ContentView.disconnectFadeDelay`.
    private static let renderedStateClearDelay: TimeInterval = 4.5

    /// Increments on each disconnect so a quick reconnect cancels any
    /// pending clear-and-reconnect race.
    private var disconnectGeneration: Int = 0

    private func scheduleRenderedStateClear() {
        disconnectGeneration &+= 1
        let gen = disconnectGeneration
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Self.renderedStateClearDelay
        ) { [weak self] in
            guard let self else { return }
            // If the user reconnected (or disconnected again) before
            // the timer fired, abandon this clear — connect() already
            // wiped the slate.
            guard self.disconnectGeneration == gen else { return }
            self.clearRenderedState()
        }
    }

    /// Surface an externally-detected failure (e.g. SGE auth rejection) in the
    /// client's status indicator without touching the underlying connection.
    public func reportFailure(_ message: String) {
        status = .failed(message)
    }

    /// Reset a previous failure so the UI can return to its neutral state.
    public func clearFailure() {
        if case .failed = status { status = .disconnected }
    }

    public func send(_ command: String) {
        guard case .connected = status else { return }
        workQueue.async { [weak self] in
            guard let self, let conn = self.connection else { return }
            let prefix: String
            switch self.mode {
            case .wrayth: prefix = "<c>"
            case .raw:    prefix = ""
            }
            let payload = (prefix + command + "\r\n").data(using: .utf8) ?? Data()
            conn.send(content: payload, completion: .contentProcessed { _ in })
        }
    }

    /// Append a locally-generated line to the main feed (used to echo the
    /// user's own typed commands so they appear in-context immediately).
    public func echoLocal(_ text: String) {
        let line = RenderedLine(runs: [
            RenderedRun(
                text: text,
                style: RunStyle(isPrompt: true)
            )
        ])
        var current = linesByStream["main"] ?? []
        if let last = current.last, Self.isPromptOnly(line), Self.isPromptOnly(last) {
            return
        }
        current.append(line)
        if current.count > 5_000 {
            current.removeFirst(current.count - 5_000)
        }
        linesByStream["main"] = current
        streamRevisions["main", default: 0] += 1
    }

    // MARK: - Connection lifecycle (main thread)

    /// Fired once when an *established* connection drops (server-side
    /// `QUIT`, network kill, user-clicked Disconnect button — anything
    /// that takes us out of `.connected`). Specifically does NOT fire
    /// on `.connecting → .failed` (initial connect refused) because
    /// that's the path the user takes when Lich is still booting and
    /// hasn't bound its frontend port yet; killing Lich there would
    /// guarantee an unrecoverable refuse loop. App delegate uses this
    /// hook to SIGTERM the spawned Lich child after the game-side has
    /// closed cleanly.
    public var onDisconnect: (() -> Void)?

    private func handleState(_ state: NWConnection.State) {
        let wasConnected: Bool
        if case .connected = status { wasConnected = true } else { wasConnected = false }
        switch state {
        case .ready:
            status = .connected
            workQueue.async { [weak self] in
                self?.sendHandshakeIfNeeded()
                self?.receiveNext()
            }
        case .failed(let err):
            status = .failed(err.localizedDescription)
        case .cancelled:
            if case .failed = status { /* keep failure */ }
            else { status = .disconnected }
            // Server-side disconnect (or any external cancel) needs the
            // same render-state clear that the user-initiated path does,
            // deferred so the UI can fade content out gracefully first.
            scheduleRenderedStateClear()
        case .waiting(let err):
            status = .failed(err.localizedDescription)
        default:
            break
        }
        // Only fire on a *connected* -> inactive edge. The
        // `connecting -> failed` path stays silent so the user can
        // retry while Lich is still booting.
        if wasConnected, !isActive {
            onDisconnect?()
        }
    }

    /// Wrayth-style handshake — must run before any user input. Matches what
    /// Stormfront/Wrayth/Warlock send right after the TCP connect.
    private func sendHandshakeIfNeeded() {
        guard case .wrayth(let key) = mode, let conn = connection else { return }
        let clientString = "/FE:WRAYTH /VERSION:1.0.1.28 /P:WIN_UNKNOWN /XML"
        conn.send(content: Data((key + "\n").utf8),
                  completion: .contentProcessed { _ in })
        conn.send(content: Data((clientString + "\n").utf8),
                  completion: .contentProcessed { _ in })
        // Two "ready" pings with the same 0.3s gap Lich uses for its own login.
        workQueue.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.connection?.send(content: Data("<c>\n".utf8),
                                   completion: .contentProcessed { _ in })
        }
        workQueue.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.connection?.send(content: Data("<c>\n".utf8),
                                   completion: .contentProcessed { _ in })
        }
        // Verb/command table is *not* requested here. Per warlock3, the
        // server pushes `<updateverbs/>` once its menu subsystem is live
        // and we respond with `_menu update 1` then — proactive requests
        // are silently dropped because the server hasn't enabled the
        // subsystem yet at handshake time.
    }

    /// Reissued whenever the server emits `<updateverbs/>` so the cmdlist
    /// stays in sync after the game changes our context (room, profession,
    /// quest state, etc.).
    public func refreshVerbs() {
        guard let conn = connection else { return }
        let prefix: String
        switch mode {
        case .wrayth: prefix = "<c>"
        case .raw:    prefix = ""
        }
        conn.send(content: Data("\(prefix)_menu update 1\n".utf8),
                  completion: .contentProcessed { _ in })
    }

    // MARK: - Receive / parse (workQueue)

    private func receiveNext() {
        connection?.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65_536
        ) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                self.processIncoming(data)
            }
            if isComplete || error != nil {
                DispatchQueue.main.async {
                    self.disconnect()
                }
                return
            }
            self.receiveNext()
        }
    }

    private func processIncoming(_ data: Data) {
        byteBuffer.append(data)
        let lf: UInt8 = 0x0A

        var orderedStreams: [String] = []
        var batches: [String: [RenderedLine]] = [:]

        while let nlIndex = byteBuffer.firstIndex(of: lf) {
            let lineSlice = byteBuffer[byteBuffer.startIndex..<nlIndex]
            let lineData = Data(lineSlice)
            byteBuffer.removeSubrange(byteBuffer.startIndex...nlIndex)

            guard let raw = String(data: lineData, encoding: .utf8) else { continue }
            let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "\r"))
            guard !trimmed.isEmpty else { continue }

            for event in renderer.render(line: trimmed) {
                let target = streamFallthroughIds.contains(event.streamId)
                    ? "main"
                    : event.streamId
                if batches[target] == nil { orderedStreams.append(target) }
                batches[target, default: []].append(event.line)
            }
        }

        let stateSnapshot = renderer.gameState
        let dialogSnapshot = renderer.dialogs
        let streamTitleSnapshot = renderer.streamWindowTitles
        let cmdlistSnapshot = renderer.cmdlist
        let updateVerbsSnapshot = renderer.updateVerbsCount
        // Take ownership of any pending menus on the worker thread, then
        // hand them to main. Capturing here on the same queue that mutates
        // them avoids racing with subsequent line parses.
        let menusSnapshot = renderer.pendingMenus
        if !menusSnapshot.isEmpty {
            for id in menusSnapshot.keys { _ = renderer.takeMenu(id: id) }
        }
        let launchURLsSnapshot = renderer.takeLaunchURLs()

        let enqueuedAt = CFAbsoluteTimeGetCurrent()
        let batchLineCount = batches.reduce(0) { $0 + $1.value.count }
        let mainBatchCount = batches["main"]?.count ?? 0

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let queueDelayMs = Int((CFAbsoluteTimeGetCurrent() - enqueuedAt) * 1000)
            let runStart = CFAbsoluteTimeGetCurrent()
            if !batches.isEmpty {
                self.applyBatch(orderedStreams: orderedStreams, batches: batches)
            }
            if self.gameState != stateSnapshot {
                self.gameState = stateSnapshot
            }
            if self.dialogs != dialogSnapshot {
                self.dialogs = dialogSnapshot
            }
            if self.streamWindowTitles != streamTitleSnapshot {
                self.streamWindowTitles = streamTitleSnapshot
            }
            if self.cmdlist != cmdlistSnapshot {
                self.cmdlist = cmdlistSnapshot
            }
            // Server re-issued `<updateverbs/>` — ask for a fresh cmdlist so
            // context-menu lookups stay current.
            if updateVerbsSnapshot > self.lastUpdateVerbsSeen {
                self.lastUpdateVerbsSeen = updateVerbsSnapshot
                self.refreshVerbs()
            }
            // Fire any callbacks whose menu just arrived.
            for (id, menu) in menusSnapshot {
                if let cb = self.pendingMenuCallbacks.removeValue(forKey: id) {
                    cb(menu)
                }
            }
            // Open any server-pushed browser URLs (GOAL, SIMUCOIN STORE,
            // play.net redirects, etc.). The handler is set by the UI layer
            // — if it isn't, the URLs are silently dropped (intentional;
            // means a headless or unit-test client doesn't try to open
            // a browser).
            if !launchURLsSnapshot.isEmpty, let open = self.onLaunchURL {
                for url in launchURLsSnapshot { open(url) }
            }

            // Log slow batches or any batch that sat in the main queue for
            // more than ~50ms — backpressure on main is the leading
            // indicator of the SwiftUI layout wedge we're hunting.
            let runtimeMs = Int((CFAbsoluteTimeGetCurrent() - runStart) * 1000)
            Diagnostics.shared.recordLichBatch(
                lines: batchLineCount,
                queueDelayMs: queueDelayMs,
                runtimeMs: runtimeMs
            )
            if queueDelayMs > 50 || runtimeMs > 100 {
                let sideCount = batchLineCount - mainBatchCount
                appLog(
                    "LichClient",
                    "applyBatch queueDelay=\(queueDelayMs)ms runtime=\(runtimeMs)ms main=\(mainBatchCount) other=\(sideCount)",
                    level: .info
                )
            }
        }
    }

    /// Issues a `_menu #<exist> N` request to the server and invokes
    /// `completion` when the matching `<menu id='N'>` response arrives.
    /// Times out after 3 seconds with `nil` so a click never silently
    /// dangles.
    public func requestMenu(forExist exist: String, completion: @escaping (ServerMenu?) -> Void) {
        // Matches warlock3: numeric, monotonically increasing. The server's
        // menu subsystem is picky about non-numeric ids.
        let menuId = nextMenuId
        nextMenuId += 1
        let key = String(menuId)
        pendingMenuCallbacks[key] = completion
        send("_menu #\(exist) \(menuId)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            if let cb = self.pendingMenuCallbacks.removeValue(forKey: key) {
                cb(nil)
            }
        }
    }

    private func applyBatch(
        orderedStreams: [String],
        batches: [String: [RenderedLine]]
    ) {
        var newDict = linesByStream
        var newRevisions = streamRevisions
        var mainGrew = false
        var otherGrew = false
        for streamId in orderedStreams {
            guard let incoming = batches[streamId] else { continue }
            var current = newDict[streamId] ?? []
            var appended = 0
            for line in incoming {
                if let last = current.last, Self.isPromptOnly(line), Self.isPromptOnly(last) {
                    continue
                }
                current.append(line)
                appended += 1
            }
            // Main needs deep scrollback so the user can review history; side
            // streams (thoughts, familiar, etc.) are short-form and trigger
            // a full SwiftUI re-layout of their pane on every append, so
            // they get a much smaller cap to keep layout cost bounded.
            let cap = streamId == "main" ? 5_000 : 500
            if current.count > cap {
                current.removeFirst(current.count - cap)
            }
            newDict[streamId] = current
            // Bump revision by the number of appends *before* cap trimming.
            // This stays monotonic and lets views detect new content even
            // when `current.count` is pinned at the cap.
            if appended > 0 {
                newRevisions[streamId, default: 0] += appended
                if streamId == "main" { mainGrew = true }
                else                   { otherGrew = true }
            }
        }
        linesByStream = newDict
        streamRevisions = newRevisions

        // Watchdog timestamps.
        let now = Date()
        if mainGrew { lastMainAppendAt = now }
        if otherGrew || mainGrew { lastOtherActivityAt = now }

        // If 10s of "other things are flowing but main isn't", assume the
        // renderer wedged on a stuck pushStream / invisibleStack and force
        // a reset. The next bit of incoming text should land in main again.
        let mainSilent = now.timeIntervalSince(lastMainAppendAt)
        let otherActive = now.timeIntervalSince(lastOtherActivityAt)
        if mainSilent > 10, otherActive < 2 {
            appLog("LichClient", "Main-stream watchdog firing - main silent for \(Int(mainSilent))s, side activity \(Int(otherActive))s ago", level: .info)
            renderer.forceResetVolatileState()
            // Push the timestamp forward so we don't refire every tick while
            // the renderer recovers.
            lastMainAppendAt = now
        }
    }

    /// True for any of the server's bare-prompt variants — the alive
    /// `>`, plus state-modified prompts like `DEAD>`, `H>` (hidden),
    /// `!>` (stunned), `R>` (roundtime). We collapse consecutive
    /// prompt-only lines but keep prompt-styled lines that carry the
    /// user's own command (`echoLocal` emits `"> smile"` etc.) — those
    /// contain a space so they're excluded by the no-space guard below.
    ///
    /// Bug history: previously this only matched bare `">"`. Scripts
    /// that squelch their command output still cause the server to
    /// emit a prompt afterward, so squelched scripts in dead/hidden/etc.
    /// state would pile up dozens of identical `DEAD>` / `H>` lines in
    /// the story feed.
    private static func isPromptOnly(_ line: RenderedLine) -> Bool {
        guard !line.runs.isEmpty, line.runs.allSatisfy({ $0.style.isPrompt }) else { return false }
        let joined = line.runs.map(\.text).joined().trimmingCharacters(in: .whitespaces)
        // Short, no spaces, ends with `>`. 8 chars covers every prompt
        // variant I've seen in GS4/DR; bump if a longer one surfaces.
        return joined.hasSuffix(">")
            && !joined.contains(" ")
            && joined.count <= 8
    }
}
