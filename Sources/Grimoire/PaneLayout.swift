import SwiftUI
import UniformTypeIdentifiers

/// Drag payload for reordering panes via drag-and-drop. Carries just the
/// pane id — the destination lookup uses ContentView's pane array.
struct PaneTransfer: Codable, Transferable {
    let paneId: String

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .text)
    }
}

/// Where a stream pane sits in the layout. `.hidden` keeps it configured but
/// off-screen so the user can re-enable it later without losing settings.
enum PaneRegion: String, CaseIterable, Identifiable, Codable {
    case top, left, right, bottom, hidden

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .top:    return "Top"
        case .left:   return "Left"
        case .right:  return "Right"
        case .bottom: return "Bottom"
        case .hidden: return "Hidden"
        }
    }

    /// Top/bottom regions lay panes out side-by-side; left/right stack them.
    var isHorizontal: Bool { self == .top || self == .bottom }
}

/// What a pane's contents come from. `.stream` reads from `LichClient.lines(for:)`;
/// `.dialog` looks up a script-pushed widget in `LichClient.dialogs`.
enum PaneSource: Equatable, Hashable, Codable {
    case stream(String)
    case dialog(String)
}

/// A configurable pane: what it shows and where it docks.
struct PaneSpec: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var source: PaneSource
    var region: PaneRegion
    /// When this pane is `.hidden` and this flag is on, lines that
    /// would arrive in this pane's stream are rerouted into `"main"`
    /// instead — so an Ambients window pushed off-screen doesn't
    /// swallow the messages, they just land in the story feed.
    /// Only meaningful for `.stream(...)` sources; ignored for
    /// `.dialog(...)` (those are widget data, not chat-style lines).
    var fallthroughToMainWhenHidden: Bool = false

    init(
        id: String,
        title: String,
        source: PaneSource,
        region: PaneRegion,
        fallthroughToMainWhenHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.source = source
        self.region = region
        self.fallthroughToMainWhenHidden = fallthroughToMainWhenHidden
    }

    // Custom decoder so configs persisted before `fallthroughToMainWhenHidden`
    // existed still load — missing key defaults to false (no behavior change).
    private enum CodingKeys: String, CodingKey {
        case id, title, source, region, fallthroughToMainWhenHidden
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.title = try c.decode(String.self, forKey: .title)
        self.source = try c.decode(PaneSource.self, forKey: .source)
        self.region = try c.decode(PaneRegion.self, forKey: .region)
        self.fallthroughToMainWhenHidden = try c.decodeIfPresent(
            Bool.self, forKey: .fallthroughToMainWhenHidden
        ) ?? false
    }
}

extension PaneSpec {
    /// Stock layout for a brand-new install, baked from a curated live
    /// arrangement: Familiar/Thoughts across the top, a character-status
    /// column on the left, effect timers stacked on the right, Speech along
    /// the bottom. Everything else starts hidden — configured and listed in
    /// the Windows popover, but off-screen until wanted.
    static let defaults: [PaneSpec] = [
        // Top row
        .init(id: "familiar", title: "Familiar", source: .stream("familiar"), region: .top),
        .init(id: "thoughts", title: "Thoughts", source: .stream("thoughts"), region: .top),

        // Left column — character status, top to bottom. Wounds render as a
        // body diagram from the game's own injuries dialog, so a new user
        // gets the paperdoll with no scripts required.
        .init(id: "injuries", title: "Injuries",   source: .dialog("injuries"), region: .left),
        .init(id: "expr",     title: "Experience", source: .dialog("expr"),     region: .left),
        .init(id: "bounty",   title: "Bounty",     source: .stream("bounty"),   region: .left),
        .init(id: "reserve",  title: "Reserved Items", source: .stream("reserve"), region: .left),
        .init(id: "logons",   title: "Logons",     source: .stream("logons"),   region: .left),
        .init(id: "death",    title: "Death",      source: .stream("death"),    region: .left),

        // Right column — effect timers
        .init(id: "buffs",    title: "Buffs",    source: .dialog("Buffs"),           region: .right),
        .init(id: "actspell", title: "Active Spells", source: .dialog("Active Spells"), region: .right),
        .init(id: "debuffs",  title: "Debuffs",  source: .dialog("Debuffs"),         region: .right),
        .init(id: "cooldwn",  title: "Cooldowns", source: .dialog("Cooldowns"),      region: .right),

        // Bottom row
        .init(id: "speech",   title: "Speech",   source: .stream("speech"),   region: .bottom),

        // Hidden until the user docks them
        .init(id: "room",     title: "Room",      source: .stream("room"),    region: .hidden),
        .init(id: "inv",      title: "Inventory", source: .stream("inv"),     region: .hidden),
        .init(id: "loot",     title: "Loot",      source: .stream("loot"),    region: .hidden),
        .init(id: "society",  title: "Society",   source: .stream("society"), region: .hidden),
        .init(id: "treas",    title: "Treasure",  source: .dialog("TreasureWindow"), region: .hidden),
        .init(id: "creat",    title: "Creatures", source: .dialog("CreatureWindow"), region: .hidden),
        .init(id: "plyrs",    title: "Players",   source: .dialog("PlayerWindow"),   region: .hidden),
        .init(id: "flares",   title: "Flares",    source: .dialog("FlareWindow"),    region: .hidden),
        .init(id: "hazards",  title: "Hazards",   source: .dialog("HazardWindow"),   region: .hidden),
        // Script-driven status bar — hidden by default since a new user
        // won't have the uberbar script running.
        .init(id: "uberbar",  title: "Status",    source: .dialog("UberBar"),        region: .hidden),
        // Hidden, but its lines land in the story feed rather than
        // vanishing into an off-screen pane.
        .init(id: "ambients", title: "Ambients",  source: .stream("ambients"), region: .hidden,
              fallthroughToMainWhenHidden: true),
    ]

    /// Split sizes that pair with `defaults` (points, captured on a large
    /// window; `ResizableStack` rescales everything proportionally to the
    /// actual window, so only the ratios matter).
    static let defaultSizes: [String: CGFloat] = [
        "column.left": 273, "column.center": 1066, "column.right": 338,
        "region.top": 229, "region.feed": 766, "region.bottom": 221,
        "injuries": 200, "expr": 182, "bounty": 185,
        "reserve": 206, "logons": 132, "death": 154,
    ]
}

extension PaneSource {
    /// Window ids the game itself provides over the Wrayth protocol —
    /// they exist for every player, scripts or not. Anything outside these
    /// sets arrived from a Lich script (UberBar, ESP, map windows, …).
    /// Categorization only: it drives the Standard / Lich-scripts split in
    /// the Windows popover, nothing behavioral.
    private static let gameDialogIds: Set<String> = [
        "minivitals", "expr", "injuries", "stance", "encum", "combat",
        "quick", "quick-simu", "quick-combat",
        "Buffs", "Active Spells", "Debuffs", "Cooldowns",
    ]
    private static let gameStreamIds: Set<String> = [
        "main", "thoughts", "familiar", "speech", "whispers", "talk",
        "death", "logons", "bounty", "society", "inv", "room", "loot",
        "reserve",
    ]

    var isGameNative: Bool {
        switch self {
        case .dialog(let id): return Self.gameDialogIds.contains(id)
        case .stream(let id): return Self.gameStreamIds.contains(id)
        }
    }

    /// Which Lich script pushes this window, for ids we've been able to
    /// attribute (verified against the script sources that emit them).
    /// Display-only — shown next to the window name in the Windows popover
    /// so the user knows which script a pane belongs to. Unattributed
    /// script windows just show their window name.
    private static let scriptNamesByDialogId: [String: String] = [
        "UberBar": "uberbar", "UberBounty": "uberbounty",
        "TreasureWindow": "treasurewindow", "CreatureWindow": "creaturewindow",
        "PlayerWindow": "playerwindow", "FlareWindow": "flarewindow",
        "HazardWindow": "hazardwindow",
    ]

    /// Script attribution for this source, or nil when it's a game window
    /// or an unattributed script window.
    var scriptName: String? {
        guard case .dialog(let id) = self else { return nil }
        return Self.scriptNamesByDialogId[id]
    }
}
