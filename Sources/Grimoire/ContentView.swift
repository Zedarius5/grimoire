import SwiftUI
import AppKit
import GrimoireKit

extension Notification.Name {
    static let grimoireMacroRepeatLast         = Notification.Name("grimoire.macro.repeatLast")
    static let grimoireMacroRepeatSecondToLast = Notification.Name("grimoire.macro.repeatSecondToLast")
    static let grimoireMacroReturnOrRepeatLast = Notification.Name("grimoire.macro.returnOrRepeatLast")
    static let grimoireMacroHistoryPrev        = Notification.Name("grimoire.macro.historyPrev")
    static let grimoireMacroHistoryNext        = Notification.Name("grimoire.macro.historyNext")
    static let grimoireMacroFillInput          = Notification.Name("grimoire.macro.fillInput")
}

struct ContentView: View {
    // LichClient is app-level so secondary windows (e.g. the Spell
    // Presets editor's active-bars picker) can share the same live
    // state. Ownership lives in GrimoireApp via @StateObject.
    @EnvironmentObject private var client: LichClient
    // Hoisted to GrimoireApp (app-scoped) so the AppDelegate can SIGTERM it on
    // app quit and the @StateObject's lifetime doesn't race with quit.
    @EnvironmentObject private var lich: LichProcess
    @EnvironmentObject private var macros: MacroEngine
    @EnvironmentObject private var highlights: HighlightStore
    @EnvironmentObject private var layouts: LayoutStore
    @Environment(\.openWindow) private var openWindow

    @State private var fontSize: Double = 13
    @State private var panes: [PaneSpec] = PaneSpec.defaults
    @State private var paneSizes: [String: CGFloat] = [:]
    @State private var activeProfile: (account: String, character: String)? = nil

    /// Drag/hover state for pane reordering. The ghost-source opacity and
    /// hover-target ring read from this; `PaneDragWrapper` invokes its
    /// callbacks via the state object's methods.
    @StateObject private var dragState = PaneDragState()

    // Identifiers we use as "items" inside the center-column resizable stack.
    private static let centerTopId    = "region.top"
    private static let centerFeedId   = "region.feed"
    private static let centerBottomId = "region.bottom"

    @State private var showingConnect: Bool = false
    @State private var showingWindowsMenu: Bool = false
    @State private var showingOptions: Bool = false
    @State private var showingLichLog: Bool = false
    @State private var didAutoOpenConnect: Bool = false
    @State private var showingDiscoveredPanes: Bool = false

    /// Lags `client.isActive` by `disconnectFadeDelay` on the true -> false
    /// transition. Drives the swap between the live game feed and the GRIMOIRE
    /// sigil so a brief network blip (or the QUIT roundtrip) doesn't slam the
    /// user back to the "waiting" screen. Flips back to true on reconnect.
    @State private var uiShowsActiveSession: Bool = false
    @State private var deactivationTask: Task<Void, Never>? = nil
    /// Seconds we hold on the last-seen game frame after the
    /// socket drops, before fading to the sigil. The render-state
    /// clear in `LichClient` is sized to outlast this + the
    /// 1.25s cross-fade so the GameView doesn't empty mid-fade.
    private static let disconnectFadeDelay: TimeInterval = 3.0

    @State private var launchAccount: String = ""
    @State private var launchPassword: String = ""
    @State private var launchCharacter: String = ""
    @State private var launchGameCode: String = "GS3"
    @State private var rememberCredentials: Bool = true

    // Timer-bar normalisation. The OptionsPopover edits the same five keys
    // via parallel `@AppStorage` declarations; UserDefaults is the shared
    // source of truth, so any change there reactively updates `timerConfig`
    // lookups below without explicit plumbing.
    @AppStorage("grimoire.timerBars.normalize")            private var timerBarsNormalize: Bool = true
    @AppStorage("grimoire.timerBars.window.activeSpells")  private var timerWindowActiveSpells: Int = 1800
    @AppStorage("grimoire.timerBars.window.buffs")         private var timerWindowBuffs: Int = 1800
    @AppStorage("grimoire.timerBars.window.cooldowns")     private var timerWindowCooldowns: Int = 1800
    @AppStorage("grimoire.timerBars.window.debuffs")       private var timerWindowDebuffs: Int = 180

    private let launchedPort: UInt16 = 8765

    private func panes(in region: PaneRegion) -> [PaneSpec] {
        panes.filter { $0.region == region }
    }

    /// Stream ids that should reroute to `"main"` because their pane
    /// is hidden and the user opted in to fallthrough. Dialog-source
    /// panes are skipped — those carry widget data, not chat lines.
    private func streamFallthroughIds(in panes: [PaneSpec]) -> Set<String> {
        var ids: Set<String> = []
        for pane in panes where pane.region == .hidden && pane.fallthroughToMainWhenHidden {
            if case .stream(let id) = pane.source { ids.insert(id) }
        }
        return ids
    }

    /// Looks up the timer-bar window (in seconds) for a given dialog id.
    /// Falls back to the Active Spells window for unrecognised dialogs.
    private func timerConfig(for dialogId: String) -> TimerBarConfig {
        let window: Int
        switch dialogId {
        case "Debuffs":       window = timerWindowDebuffs
        case "Buffs":         window = timerWindowBuffs
        case "Cooldowns":     window = timerWindowCooldowns
        case "Active Spells": window = timerWindowActiveSpells
        default:              window = timerWindowActiveSpells
        }
        return TimerBarConfig(normalize: timerBarsNormalize, windowSeconds: window)
    }

    /// Appends any `PaneSpec.defaults` entries whose *source* is missing from
    /// the saved layout — keeps a user's existing arrangement intact but makes
    /// newly-added default panes (e.g. Debuffs) show up in the Windows
    /// popover so the user can reveal them. Matching on source rather than id
    /// matters for panes a user discovered before they were promoted into the
    /// defaults (an existing `auto.dialog.expr` is the same window as the
    /// default `expr` — don't add a duplicate). New panes default to `.hidden`
    /// so they don't pop into the layout unexpectedly.
    private func mergeWithDefaults(saved: [PaneSpec]) -> [PaneSpec] {
        var merged = saved
        let savedSources = Set(saved.map(\.source))
        for spec in PaneSpec.defaults where !savedSources.contains(spec.source) {
            var addition = spec
            addition.region = .hidden
            merged.append(addition)
        }
        return merged
    }

    /// Mirror the active named layout into the live arrangement. Called on
    /// launch and whenever the user switches layouts. Merging with defaults
    /// keeps any newly-added default panes available (as hidden).
    private func applyActiveLayout() {
        panes = mergeWithDefaults(saved: layouts.activePanes)
        paneSizes = layouts.activeSizes
    }

    private var activeMacroSetName: String? {
        guard !macros.config.sets.isEmpty else { return nil }
        return macros.config.sets.first(where: { $0.id == macros.config.activeSetId })?.name
    }

    /// Bottom region — matches Wrayth's layout:
    /// Left column (flex): input + vitals stacked vertically.
    /// Right side: status box + exits compass spanning both rows (double-height).
    private var bottomBar: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                InputBar(
                    isActive: client.isActive,
                    gameState: client.gameState,
                    onSend: { cmd in
                        client.echoLocal("> \(cmd)")
                        client.send(cmd)
                    }
                )
                VitalsBar(state: client.gameState)
            }
            .frame(maxWidth: .infinity)

            StatusBox(state: client.gameState)
                .frame(maxHeight: .infinity)
            ExitsCompass(exits: client.gameState.exits) { dir in
                client.echoLocal("> \(dir)")
                client.send(dir)
            }
            .equatable()
            .frame(maxHeight: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(GameTheme.background)
    }

    // MARK: - Body

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("ContentView")
        return VStack(spacing: 0) {
            toolbar
            Divider()
            mainSplit
            bottomBar
        }
        .frame(minWidth: 1000, minHeight: 600)
        .navigationTitle("Grimoire · \(BuildInfo.label)")
        .environment(\.fontSize, fontSize)
        .environment(\.highlights, highlights.effectiveHighlights)
        .environment(\.openURL, OpenURLAction { url in
            GrimoireLinkRouter(client: client).handle(url)
        })
        .onAppear {
            applyActiveLayout()
            restoreLastLoginIntoForm()
            setupMacros()
            if !didAutoOpenConnect, !client.isActive {
                didAutoOpenConnect = true
                showingConnect = true
            }
            // Wire up server-pushed browser launches (`GOAL`, `SIMUCOIN
            // STORE`, etc.). The client emits these on the main thread
            // already. Route through SafeExternalURL so the user confirms
            // web links (and non-web schemes are blocked + explained) —
            // the game stream is only semi-trusted.
            client.onLaunchURL = { url in
                MainActor.assumeIsolated {
                    SafeExternalURL.open(url)
                }
            }
            // Notification dispatch: scan every newly-appended line
            // against the user's `notify`-flagged highlight rules and
            // post a macOS notification for each match. Uses the
            // resolved (group-merged) rule set so a member of a
            // notify-on-match group fires the same as if its own
            // `notify` were on. Lives here (vs. inside LichClient)
            // because the rule set is a Grimoire concern, not a
            // protocol concern.
            client.onLinesAppended = { [highlights] lines, _streamId in
                let rules = highlights.effectiveHighlights.filter { $0.enabled && $0.notify }
                guard !rules.isEmpty else { return }
                // Build a one-shot id -> name map so each per-line
                // scan doesn't re-linear-scan the groups array.
                let groupNames = Dictionary(
                    uniqueKeysWithValues: highlights.groups.map { ($0.id, $0.name) }
                )
                for line in lines {
                    let text = line.plainText
                    for rule in rules {
                        guard let matched = HighlightProcessor.matchedText(rule, in: text) else { continue }
                        let groupName = rule.groupId.flatMap { groupNames[$0] }
                        NotificationManager.shared.notify(
                            rule: rule,
                            matchedText: matched,
                            groupName: groupName
                        )
                    }
                }
            }
            // Seed the stream-fallthrough list on launch so panes that
            // were hidden + flagged in the persisted config take effect
            // immediately, without waiting for the next `panes` mutation.
            client.setStreamFallthroughIds(streamFallthroughIds(in: panes))
        }
        .onChange(of: panes) { _, newValue in
            // Window layouts are global (per-monitor), not per-character: fold
            // live edits into the active named layout.
            layouts.updateActive(panes: newValue)
            client.setStreamFallthroughIds(streamFallthroughIds(in: newValue))
        }
        .onChange(of: paneSizes) { _, newValue in
            layouts.updateActive(sizes: newValue)
        }
        // The active layout changed (user switched in Options, or login
        // restored a character's layout) — load it, and remember it as this
        // character's choice (per-character, like the active macro set).
        .onChange(of: layouts.activeName) { _, newName in
            applyActiveLayout()
            if let profile = activeProfile {
                Preferences.saveActiveLayout(newName, account: profile.account, character: profile.character)
            }
        }
        .onChange(of: macros.config) { _, newValue in
            Preferences.saveMacros(newValue)
        }
        .onChange(of: macros.activeSetId) { _, newSet in
            // Remember the active set for the logged-in character.
            if let profile = activeProfile {
                Preferences.saveActiveMacroSet(newSet, account: profile.account, character: profile.character)
            }
        }
        // Auto-discover new dialog windows and stream windows the moment the
        // server / a Lich script first emits them. The new pane goes in as
        // `.hidden` so it shows up in the Windows popover without barging
        // into the visible layout.
        .onChange(of: client.dialogs.count) { _, _ in
            syncDiscoveredPanes()
        }
        .onChange(of: client.linesByStream.count) { _, _ in
            syncDiscoveredPanes()
        }
        .onChange(of: client.streamWindowTitles) { _, _ in
            syncDiscoveredPanes()
        }
        // Drive the sigil/gameFeed swap off `uiShowsActiveSession`,
        // which lags the false transition. Reconnect (false -> true)
        // is immediate. Disconnect (true -> false) waits the grace
        // period before flipping, and is cancelled by a quick
        // reconnect inside that window.
        .onChange(of: client.isActive) { _, isActive in
            deactivationTask?.cancel()
            if isActive {
                uiShowsActiveSession = true
            } else {
                deactivationTask = Task { @MainActor in
                    try? await Task.sleep(
                        nanoseconds: UInt64(Self.disconnectFadeDelay * 1_000_000_000)
                    )
                    guard !Task.isCancelled, !client.isActive else { return }
                    uiShowsActiveSession = false
                }
            }
        }
    }

    /// Walks the client's live dialog / stream registries and adds a hidden
    /// `PaneSpec` for anything we don't already have. Default-known panes
    /// (in `PaneSpec.defaults`) take precedence over the auto-generated
    /// versions — those stay in whatever region the user assigned.
    private func syncDiscoveredPanes() {
        var current = panes
        let existingDialogSources: Set<String> = Set(panes.compactMap {
            if case .dialog(let id) = $0.source { return id }
            return nil
        })
        let existingStreamSources: Set<String> = Set(panes.compactMap {
            if case .stream(let id) = $0.source { return id }
            return nil
        })

        for (id, dlg) in client.dialogs where !existingDialogSources.contains(id) {
            let raw = dlg.title.isEmpty ? id : dlg.title
            current.append(PaneSpec(
                id: "auto.dialog.\(id)",
                title: Self.prettify(rawName: raw),
                source: .dialog(id),
                region: .hidden
            ))
        }

        for id in client.linesByStream.keys where id != "main" && !existingStreamSources.contains(id) {
            let raw = client.streamWindowTitles[id] ?? humanize(streamId: id)
            current.append(PaneSpec(
                id: "auto.stream.\(id)",
                title: Self.prettify(rawName: raw),
                source: .stream(id),
                region: .hidden
            ))
        }

        if current.count != panes.count {
            panes = current
        }
    }

    /// Fallback display name when the server hasn't sent a `<streamWindow>`
    /// title yet — strip the conventional Wrayth "s" prefix and title-case.
    private func humanize(streamId: String) -> String {
        var s = streamId
        if s.hasPrefix("s"), s.count > 1, s.dropFirst().first?.isLowercase == true {
            s.removeFirst()
        }
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    /// Title-cases an auto-discovered raw name. Splits camelCase boundaries,
    /// replaces underscores/hyphens with spaces, and capitalises each word.
    /// Used so the Windows popover renders "Map Master" instead of
    /// "mapMaster", "Uber Bounty" instead of "UberBounty", etc.
    private static func prettify(rawName: String) -> String {
        guard !rawName.isEmpty else { return rawName }
        var spaced = ""
        for (i, char) in rawName.enumerated() {
            if char == "_" || char == "-" {
                spaced.append(" ")
            } else if char.isUppercase, i > 0,
                      let prev = spaced.last, prev.isLowercase || prev.isNumber {
                spaced.append(" ")
                spaced.append(char)
            } else {
                spaced.append(char)
            }
        }
        return spaced
            .split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            connectControl

            Spacer()

            if let setName = activeMacroSetName {
                HStack(spacing: 4) {
                    Image(systemName: "keyboard")
                        .foregroundStyle(.secondary)
                    Text(setName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule().fill(Color.white.opacity(0.06))
                )
                .help("Active macro set — change in Options")
            }

            Button {
                showingWindowsMenu = true
            } label: {
                Label("Windows", systemImage: "rectangle.3.group")
            }
            .popover(isPresented: $showingWindowsMenu, arrowEdge: .bottom) {
                WindowsPopover(
                    panes: $panes,
                    paneSizes: $paneSizes,
                    showingDiscoveredPanes: $showingDiscoveredPanes,
                    onDone: { showingWindowsMenu = false }
                )
            }

            Button {
                showingOptions = true
            } label: {
                Label("Options", systemImage: "gearshape")
            }
            .popover(isPresented: $showingOptions, arrowEdge: .bottom) {
                OptionsPopover(
                    fontSize: $fontSize,
                    showingOptions: $showingOptions
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private var connectControl: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)

            if client.isActive || lich.isRunning {
                Button {
                    disconnect()
                } label: {
                    Label("Disconnect", systemImage: "bolt.slash")
                }
                Text(statusLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Button {
                    showingConnect = true
                } label: {
                    Label("Play...", systemImage: "play.fill")
                }
                .popover(isPresented: $showingConnect, arrowEdge: .bottom) {
                    ConnectView(
                        client: client,
                        showingConnect: $showingConnect,
                        launchAccount: $launchAccount,
                        launchPassword: $launchPassword,
                        launchCharacter: $launchCharacter,
                        launchGameCode: $launchGameCode,
                        rememberCredentials: $rememberCredentials,
                        onAuthenticated: handleAuthenticated
                    )
                }

                if let errorText = currentErrorText {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(errorText, forType: .string)
                    } label: {
                        Text(errorText)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(.plain)
                    .help("\(errorText)\n\nClick to copy.")
                }

                if !lich.logTail.isEmpty {
                    Button {
                        showingLichLog = true
                    } label: {
                        Image(systemName: "text.alignleft")
                    }
                    .help("View Lich launch logs")
                    .popover(isPresented: $showingLichLog, arrowEdge: .bottom) {
                        lichLogPopover
                    }
                }
            }
        }
    }

    private var currentErrorText: String? {
        if case .failed(let message) = client.status { return message }
        if case .failed(let message) = lich.status { return message }
        if case .exited(let code) = lich.status, code != 0 {
            return "Lich exited (code \(code)). View logs for details."
        }
        return nil
    }

    private var statusLabel: String {
        if case .connected = client.status {
            return "\(client.endpointLabel)  ·  \(client.mainLines.count) lines"
        }
        if case .connecting = client.status {
            return "connecting to \(client.endpointLabel)..."
        }
        if lich.isRunning {
            return "Lich starting..."
        }
        return ""
    }

    private var statusColor: Color {
        if case .connected = client.status { return .green }
        if case .connecting = client.status { return .yellow }
        if lich.isRunning { return .yellow }
        if case .failed = client.status { return .red }
        if case .failed = lich.status { return .red }
        return Color.gray.opacity(0.6)
    }

    // MARK: - Popovers

    private var lichLogPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Lich output").font(.headline)
                Spacer()
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(lich.logTail.joined(separator: "\n"), forType: .string)
                }
            }
            ScrollView {
                Text(lich.logTail.joined(separator: "\n"))
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 520, height: 280)
            .padding(8)
            .background(Color.black.opacity(0.85))
            .foregroundStyle(.white)
            .cornerRadius(6)
        }
        .padding(12)
    }

    // MARK: - Layout

    /// Left | Center column (top row, feed, bottom row) | Right.
    /// Each column / region is a ResizableStack so the user can drag the
    /// dividers; sizes persist in `paneSizes`.
    @ViewBuilder
    private var mainSplit: some View {
        let columns = visibleColumns()
        HStack(spacing: 0) {
            if dropZoneVisible(for: .left) {
                EmptyRegionDropZone(label: "Left dock") { sourceId in
                    moveIntoEmptyRegion(sourceId: sourceId, region: .left)
                }
                .frame(width: 140)
                .padding(.vertical, 4)
                .padding(.leading, 4)
            }
            ResizableStack(axis: .horizontal, items: columns, sizes: $paneSizes, minSize: 220) { id in
                columnView(for: id)
            }
            if dropZoneVisible(for: .right) {
                EmptyRegionDropZone(label: "Right dock") { sourceId in
                    moveIntoEmptyRegion(sourceId: sourceId, region: .right)
                }
                .frame(width: 140)
                .padding(.vertical, 4)
                .padding(.trailing, 4)
            }
        }
        .background(GameTheme.background)
        .animation(.easeInOut(duration: 0.22), value: panes)
    }

    /// A drop zone is shown only while a pane is actively being dragged and
    /// the target region is currently empty. Outside of drags or for
    /// already-populated regions the zone stays hidden so it doesn't reserve
    /// dead pixels.
    private func dropZoneVisible(for region: PaneRegion) -> Bool {
        dragState.draggingPaneId != nil && panes(in: region).isEmpty
    }

    /// Drop handler for empty regions — simply reassigns the source pane's
    /// region. The pane keeps its position in the global `panes` array,
    /// which is fine: the region filter is what places it visually.
    private func moveIntoEmptyRegion(sourceId: String, region: PaneRegion) -> Bool {
        guard let idx = panes.firstIndex(where: { $0.id == sourceId }) else { return true }
        panes[idx].region = region
        dragState.endDrag()
        return true
    }

    /// Returns the column ids that should appear in the main split, in order.
    /// Left/right are omitted when they have no panes.
    private func visibleColumns() -> [String] {
        var ids: [String] = []
        if !panes(in: .left).isEmpty   { ids.append("column.left") }
        ids.append("column.center")
        if !panes(in: .right).isEmpty  { ids.append("column.right") }
        return ids
    }

    @ViewBuilder
    private func columnView(for id: String) -> some View {
        switch id {
        case "column.left":
            regionColumn(panes: panes(in: .left))
        case "column.right":
            regionColumn(panes: panes(in: .right))
        default:
            centerColumn
        }
    }

    /// Vertical layout: hands strip (above the story feed) | top row |
    /// game feed | bottom row. The hands strip is intentionally scoped to
    /// the center column so the left and right docks can run all the way to
    /// the top of the window instead of being clipped under it.
    @ViewBuilder
    private var centerColumn: some View {
        let items = centerItems()
        VStack(spacing: 0) {
            HandsStrip(state: client.gameState)
            if dropZoneVisible(for: .top) {
                EmptyRegionDropZone(label: "Top row") { sourceId in
                    moveIntoEmptyRegion(sourceId: sourceId, region: .top)
                }
                .frame(height: 80)
                .padding(.horizontal, 4)
                .padding(.top, 4)
            }
            ResizableStack(axis: .vertical, items: items, sizes: $paneSizes, minSize: 80) { id in
                centerItemView(id: id)
            }
            if dropZoneVisible(for: .bottom) {
                EmptyRegionDropZone(label: "Bottom row") { sourceId in
                    moveIntoEmptyRegion(sourceId: sourceId, region: .bottom)
                }
                .frame(height: 80)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
    }

    private func centerItems() -> [String] {
        var ids: [String] = []
        if !panes(in: .top).isEmpty    { ids.append(Self.centerTopId) }
        ids.append(Self.centerFeedId)
        if !panes(in: .bottom).isEmpty { ids.append(Self.centerBottomId) }
        return ids
    }

    @ViewBuilder
    private func centerItemView(id: String) -> some View {
        switch id {
        case Self.centerTopId:
            regionRow(panes: panes(in: .top))
        case Self.centerBottomId:
            regionRow(panes: panes(in: .bottom))
        default:
            gameFeed
        }
    }

    @ViewBuilder
    private var gameFeed: some View {
        VStack(spacing: 0) {
            RoomHeader(state: client.gameState)
            Group {
                // The empty-state placeholder is OVERLAID via ZStack rather
                // than swapped via if/else: swapping unmounts GameView,
                // destroying the underlying NSTextView, so the next content
                // would mount a fresh NSTextView at scroll y=0. The overlay
                // keeps the NSView alive across brief empty moments (reconnect
                // wipe, stale-clear race) so the story feed doesn't jump to top.
                if uiShowsActiveSession {
                    ZStack {
                        GameView(
                            lines: client.mainLines,
                            revision: client.revision(for: "main"),
                            onLinkClick: { url in
                                _ = GrimoireLinkRouter(client: client).handle(url)
                            }
                        )
                        .equatable()
                        if client.mainLines.isEmpty {
                            emptyGamePlaceholder
                        }
                    }
                } else {
                    SigilView()
                }
            }
            // Cross-fade duration. The TIMING of the false transition
            // is governed by `disconnectFadeDelay` (see .onChange below);
            // 1.25s here is just how long the cross-fade itself runs.
            .animation(.easeInOut(duration: 1.25), value: uiShowsActiveSession)
        }
    }

    private var emptyGamePlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: client.isActive ? "ellipsis.circle" : "play.circle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
            Text(lich.isRunning
                 ? "Lich is starting — connecting once the port is ready..."
                 : client.isActive
                   ? "Connected — waiting for game data..."
                   : "Click Play to log in.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GameTheme.background)
        .environment(\.colorScheme, .dark)
    }

    private func regionRow(panes rowPanes: [PaneSpec]) -> some View {
        ResizableStack(axis: .horizontal, items: rowPanes.map { $0.id }, sizes: $paneSizes, minSize: 140) { id in
            if let pane = rowPanes.first(where: { $0.id == id }) {
                paneView(for: pane)
            } else {
                Color.clear
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
        .background(GameTheme.background)
    }

    private func regionColumn(panes columnPanes: [PaneSpec]) -> some View {
        ResizableStack(axis: .vertical, items: columnPanes.map { $0.id }, sizes: $paneSizes, minSize: 80) { id in
            if let pane = columnPanes.first(where: { $0.id == id }) {
                paneView(for: pane)
            } else {
                Color.clear
            }
        }
        .padding(4)
        .background(GameTheme.background)
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func paneView(for spec: PaneSpec) -> some View {
        let isSource = spec.id == dragState.draggingPaneId
        let isHoverTarget = !isSource
            && dragState.draggingPaneId != nil
            && spec.id == dragState.hoverTargetId

        // AppKit-backed wrapper handles the drag and drop primitives directly,
        // avoiding the SwiftUI `.draggable` / `.dropDestination` reliability
        // issues (missed drops, sporadic isTargeted callbacks). Visual
        // feedback stays in SwiftUI, driven by the wrapper's callbacks.
        PaneDragWrapper(
            paneId: spec.id,
            onDragBegin: { id in dragState.beginDrag(id: id) },
            onDragEnd: { dragState.endDrag() },
            onHoverChange: { hovering in
                dragState.hoverChanged(id: spec.id, hovering: hovering)
            },
            onDrop: { sourceId in
                let ok = applyPaneDrop(sourceId: sourceId, target: spec)
                dragState.endDrag()
                return ok
            }
        ) {
            paneContent(for: spec)
                .opacity(isSource ? 0.35 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isHoverTarget ? Color.accentColor : Color.clear,
                            lineWidth: 3
                        )
                        .padding(1)
                        .animation(.easeInOut(duration: 0.12), value: isHoverTarget)
                )
        }
    }

    /// AppKit-side drop handler. Captures the target's *original* index before
    /// removing the source so the insertion lands at the right slot regardless
    /// of drag direction; re-finding the target after removal would shift it by
    /// one for forward moves and snap the drop back to the source's old slot.
    private func applyPaneDrop(sourceId: String, target: PaneSpec) -> Bool {
        guard sourceId != target.id else { return true }
        guard let srcIdx = panes.firstIndex(where: { $0.id == sourceId }),
              let originalDstIdx = panes.firstIndex(where: { $0.id == target.id })
        else { return true }

        panes[srcIdx].region = target.region
        let moved = panes.remove(at: srcIdx)
        // Inserting at the original dst index lands the source at the target's
        // old slot for both forward and backward moves.
        let insertAt = min(originalDstIdx, panes.count)
        panes.insert(moved, at: insertAt)
        return true
    }

    @ViewBuilder
    private func paneContent(for spec: PaneSpec) -> some View {
        // `isActive` lets each pane fade its *content* (scroll area) while
        // keeping its title header visible. LichClient defers its render-state
        // clear so the last-seen content stays rendered during the fade.
        switch spec.source {
        case .stream(let streamId):
            StreamPane(
                title: spec.title,
                lines: client.lines(for: streamId),
                revision: client.revision(for: streamId),
                isActive: client.isActive,
                onLinkClick: { url in
                    _ = GrimoireLinkRouter(client: client).handle(url)
                }
            )
            .equatable()
        case .dialog(let dialogId):
            if let dlg = client.dialogs[dialogId] {
                DialogPane(
                    dialog: dlg,
                    onCommand: { client.send($0) },
                    timerConfig: timerConfig(for: dialogId),
                    // Both the game's own injuries dialog and the uberbar
                    // script's UberBar emit per-body-part <image> widgets;
                    // either renders the wound diagram.
                    wounds: (dialogId == "UberBar" || dialogId == "injuries")
                        ? client.gameState.wounds : nil,
                    isActive: client.isActive
                )
                // Intentionally not `.equatable()` — that optimization breaks
                // the per-second @State ticker that drives the bar countdowns.
            } else {
                StreamPane(
                    title: "\(spec.title) (waiting)",
                    lines: [],
                    revision: 0,
                    isActive: client.isActive
                )
            }
        }
    }

    /// Moves a dragged pane to the dropped-on target's slot. Cross-region
    /// drops also reassign the source pane to the target's region.
    private func handlePaneDrop(items: [PaneTransfer], target: PaneSpec) -> Bool {
        guard let source = items.first, source.paneId != target.id else { return false }
        guard let srcIdx = panes.firstIndex(where: { $0.id == source.paneId }) else { return false }

        // Reassign region in case this was a cross-region drop.
        panes[srcIdx].region = target.region

        let moved = panes.remove(at: srcIdx)
        if let destIdx = panes.firstIndex(where: { $0.id == target.id }) {
            panes.insert(moved, at: destIdx)
        } else {
            panes.append(moved)
        }
        return true
    }

    // MARK: - Connect / disconnect

    /// Post-auth handler invoked by `ConnectView` once SGE has returned game
    /// credentials. Persists last-login + keychain, loads the per-character
    /// pane layout, spawns lich, then polls until the TCP socket comes up.
    private func handleAuthenticated(_ result: ConnectAuthResult) {
        Preferences.saveLastLogin(.init(
            account: result.account,
            character: result.character,
            gameCode: result.gameCode
        ))
        // Remember this (successful) character for the Play dialog's recent list.
        Preferences.addRecentLogin(.init(
            account: result.account,
            character: result.character,
            gameCode: result.gameCode
        ))
        if result.rememberCredentials {
            Keychain.save(password: result.password, account: result.account)
        } else {
            Keychain.deletePassword(account: result.account)
        }

        activeProfile = (account: result.account, character: result.character)
        // Restore this character's last-used macro set (the sets are shared;
        // only the active choice is per-character). Only if that set still
        // exists — a since-deleted id leaves the current default in place.
        if let savedSet = Preferences.loadActiveMacroSet(account: result.account, character: result.character),
           macros.config.sets.contains(where: { $0.id == savedSet }) {
            macros.setActive(setId: savedSet)
        }
        // Restore this character's last-active window layout. Layouts are
        // shared; only the active choice is per-character — so each character
        // logs back in with the layout they last used (selecting it reloads
        // the panes via the activeName onChange). A since-deleted layout
        // leaves the current one in place.
        if let savedLayout = Preferences.loadActiveLayout(account: result.account, character: result.character),
           layouts.names.contains(savedLayout) {
            layouts.select(savedLayout)
        }

        let lichPath = LichLocation.launcher(in: result.lichRoot)
        let creds = result.serverCreds

        lich.launch(
            rubyPath: result.rubyPath,
            lichPath: lichPath,
            args: [
                "-g", "\(creds.host):\(creds.port)",
                "--stormfront",
                "--gemstone",
                "--gtk"
            ]
        )
        // The Lich folder is now known — (re)read the effect-list so spell
        // timers show names instead of bare ids on a freshly-set-up install.
        SpellNameDatabase.shared.reload()

        Task {
            for _ in 0..<120 {
                try? await Task.sleep(for: .milliseconds(500))
                if !lich.isRunning { return }
                switch client.status {
                case .connected:
                    return
                case .connecting:
                    continue
                case .disconnected, .failed:
                    client.connect(
                        host: "127.0.0.1",
                        port: creds.port,
                        mode: .wrayth(gameKey: creds.key)
                    )
                }
            }
        }
    }

    private func disconnect() {
        client.disconnect()
        if lich.isRunning {
            lich.stop()
        }
    }

    // MARK: - Macros

    private func setupMacros() {
        macros.client = client
        macros.onBuiltin = { [weak client] action in
            switch action {
            case .repeatLast:         NotificationCenter.default.post(name: .grimoireMacroRepeatLast, object: nil)
            case .repeatSecondToLast: NotificationCenter.default.post(name: .grimoireMacroRepeatSecondToLast, object: nil)
            case .returnOrRepeatLast: NotificationCenter.default.post(name: .grimoireMacroReturnOrRepeatLast, object: nil)
            case .historyPrev:        NotificationCenter.default.post(name: .grimoireMacroHistoryPrev, object: nil)
            case .historyNext:        NotificationCenter.default.post(name: .grimoireMacroHistoryNext, object: nil)
            default: break
            }
            _ = client
        }
        macros.onTemplateText = { text in
            NotificationCenter.default.post(name: .grimoireMacroFillInput, object: text)
        }
        // `\?` macros open a small always-on-top panel that gathers the
        // user's value, then re-enters the engine with the substituted
        // action so `\r`/`\p` semantics still apply.
        macros.onPromptForInput = { [weak macros] action in
            MacroPromptPanel.shared.show(action: action) { substituted in
                macros?.executeAction(substituted)
            }
        }
        macros.startMonitoring()

        // Prefer the user's last edited-and-saved macro config over a fresh
        // re-parse of the XML — otherwise edits made in the macro editor
        // would be wiped on every launch.
        if let saved = Preferences.loadMacros() {
            macros.install(saved)
        } else if let xmlPath = UserDefaults.standard.string(forKey: "grimoire.macroFile"),
                  let url = URL(string: xmlPath),
                  let config = try? MacroParser.parse(file: url) {
            macros.install(config)
            Preferences.saveMacros(config)
        }
    }

    private func restoreLastLoginIntoForm() {
        let last = Preferences.loadLastLogin()
        if launchAccount.isEmpty   { launchAccount = last.account }
        if launchCharacter.isEmpty { launchCharacter = last.character }
        launchGameCode = last.gameCode.isEmpty ? "GS3" : last.gameCode
        if !last.account.isEmpty, launchPassword.isEmpty,
           let stored = Keychain.loadPassword(account: last.account) {
            launchPassword = stored
        }
        // Panes/sizes come from the active named layout (loaded on launch),
        // not per-character storage.
    }
}

/// Small chip rendered as the drag preview while a pane is being moved.
/// Sized smaller than the source pane so the cursor + chip don't obscure the
/// underlying layout shift the user is trying to read.
private struct DragPreviewChip: View {
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "rectangle.dashed")
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(GameTheme.paneHeader)
        .overlay(
            RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .foregroundStyle(.white)
    }
}

#Preview {
    ContentView()
}
