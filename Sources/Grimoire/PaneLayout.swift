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
}

extension PaneSpec {
    /// Default Wrayth-style layout. Stream panes are pre-routed; dialog panes
    /// light up only when the Lich script that emits them runs (and after
    /// the user has it docked in a non-hidden region).
    static let defaults: [PaneSpec] = [
        // Stream-based panes (chat-style)
        .init(id: "thoughts", title: "Thoughts", source: .stream("thoughts"), region: .top),
        .init(id: "familiar", title: "Familiar", source: .stream("familiar"), region: .top),
        .init(id: "death",    title: "Death",    source: .stream("death"),    region: .right),
        .init(id: "logons",   title: "Logons",   source: .stream("logons"),   region: .right),
        .init(id: "speech",   title: "Speech",   source: .stream("speech"),   region: .bottom),
        .init(id: "room",     title: "Room",     source: .stream("room"),     region: .hidden),
        .init(id: "bounty",   title: "Bounty",   source: .stream("bounty"),   region: .hidden),
        .init(id: "inv",      title: "Inventory", source: .stream("inv"),     region: .hidden),
        .init(id: "loot",     title: "Loot",     source: .stream("loot"),     region: .hidden),
        .init(id: "society",  title: "Society",  source: .stream("society"),  region: .hidden),

        // Dialog-based panes (Lich-script-pushed widgets)
        .init(id: "uberbar",  title: "Status",   source: .dialog("UberBar"),         region: .left),
        .init(id: "buffs",    title: "Buffs",    source: .dialog("Buffs"),           region: .right),
        .init(id: "actspell", title: "Active Spells", source: .dialog("Active Spells"), region: .right),
        .init(id: "debuffs",  title: "Debuffs",  source: .dialog("Debuffs"),         region: .right),
        .init(id: "cooldwn",  title: "Cooldowns", source: .dialog("Cooldowns"),      region: .right),
        .init(id: "treas",    title: "Treasure",  source: .dialog("TreasureWindow"), region: .right),
        .init(id: "creat",    title: "Creatures", source: .dialog("CreatureWindow"), region: .bottom),
        .init(id: "plyrs",    title: "Players",   source: .dialog("PlayerWindow"),   region: .bottom),
        .init(id: "flares",   title: "Flares",    source: .dialog("FlareWindow"),    region: .hidden),
        .init(id: "hazards",  title: "Hazards",   source: .dialog("HazardWindow"),   region: .hidden),
    ]
}
