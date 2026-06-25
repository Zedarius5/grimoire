import Foundation

/// One vital track (HP/mana/stamina/spirit).
public struct VitalValue: Equatable, Sendable {
    /// 0-100. Lich/Simu sends as integer percentage.
    public var percent: Int
    /// Display text — e.g. "health 225/225".
    public var text: String

    public init(percent: Int = 100, text: String = "") {
        self.percent = percent
        self.text = text
    }
}

/// Body parts that can carry wounds or scars. Matches the `id` attribute on
/// `<image>` widgets emitted by uberbar/injury scripts.
public enum BodyPart: String, Codable, Hashable, Sendable, CaseIterable {
    case head, neck, chest, back, abdomen
    case leftArm, rightArm
    case leftHand, rightHand
    case leftLeg, rightLeg
    case leftEye, rightEye
    case nsys
}

/// Injury and scar severity for a single body part. 0 = none, 1–3 = mild,
/// moderate, severe.
public struct WoundInfo: Equatable, Sendable {
    public var injury: Int = 0
    public var scar: Int = 0

    public init(injury: Int = 0, scar: Int = 0) {
        self.injury = injury
        self.scar = scar
    }
}

/// All current wounds & scars keyed by body part. Updated when the renderer
/// sees `<image id='leftArm' name='Injury2'/>` style widgets in dialogs.
public struct Wounds: Equatable, Sendable {
    public var parts: [BodyPart: WoundInfo] = [:]

    public init() {}

    public mutating func update(part: BodyPart, imageName: String) {
        // UberBar emits one of: "Injury{0–3}", "Scar{0–3}", "Nsys{0–3}" (for
        // the nervous system), or the bare area key (e.g. "leftArm", "head")
        // when both wound and scar are zero. Anything we don't recognise as
        // a positive injury or scar means "healed" — reset to zero.
        var info = WoundInfo()
        if imageName.hasPrefix("Injury"), let n = Int(imageName.dropFirst("Injury".count)) {
            info.injury = max(0, min(3, n))
        } else if imageName.hasPrefix("Nsys"), let n = Int(imageName.dropFirst("Nsys".count)) {
            info.injury = max(0, min(3, n))
        } else if imageName.hasPrefix("Scar"), let n = Int(imageName.dropFirst("Scar".count)) {
            info.scar = max(0, min(3, n))
        }
        parts[part] = info
    }
}

/// Aggregated character state extracted from out-of-band protocol tags.
/// Updated by `StreamRenderer` as it walks tokens; consumed by SwiftUI
/// status views via `LichClient.gameState`.
public struct GameState: Equatable, Sendable {
    public var health  = VitalValue()
    public var mana    = VitalValue()
    public var stamina = VitalValue()
    public var spirit  = VitalValue()

    public var leftHand: String = "Empty"
    public var rightHand: String = "Empty"
    public var preparedSpell: String = "None"

    /// Unix epoch seconds when current roundtime ends, or nil if none.
    public var roundtimeEnd: TimeInterval? = nil
    /// Unix epoch seconds when current cast/spell roundtime ends.
    public var castTimeEnd: TimeInterval? = nil

    /// (server clock − local clock), measured at the last `<prompt time=…>`.
    /// Roundtime timestamps are in the server's time reference, so we add this
    /// to the local clock before comparing — otherwise any skew between the
    /// game server's clock and this machine makes every RT look expired.
    /// Defaults to 0 (no correction until the first prompt arrives).
    public var serverClockOffset: TimeInterval = 0

    public var wounds = Wounds()

    /// Current `<indicator>` flags, keyed by id (e.g. `"IconSTANDING"`,
    /// `"IconHIDDEN"`, `"IconBLEEDING"`). `true` means the indicator is
    /// currently visible.
    public var indicators: [String: Bool] = [:]

    /// Direction codes (e.g. `"n"`, `"ne"`, `"up"`, `"out"`) currently
    /// available as exits in this room, derived from `<compass><dir/>` tags.
    public var exits: Set<String> = []

    /// Bracketed room name, e.g. "[Wehnimer's Landing, North Ring Road]".
    /// Sourced from `<style id='roomName'>...</style>` or the `subtitle`
    /// attribute on the main `<streamWindow>`.
    public var roomName: String = ""

    /// Room id from `<nav rm='N'/>` — Lich emits this when entering a new
    /// room. Used as the small "#12345" badge beside the room name.
    public var roomNumber: String = ""

    /// Whole seconds remaining until `end` (a server-clock timestamp),
    /// computed against the server's clock (local clock + `serverClockOffset`).
    /// 0 when `end` is nil or already past. Drives the roundtime bricks.
    public func secondsRemaining(until end: TimeInterval?,
                                 localNow: TimeInterval = Date().timeIntervalSince1970) -> Int {
        guard let end else { return 0 }
        return max(0, Int((end - (localNow + serverClockOffset)).rounded(.up)))
    }

    public init() {}
}
