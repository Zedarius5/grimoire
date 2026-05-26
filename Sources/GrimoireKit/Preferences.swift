import Foundation
import CoreGraphics

/// User-defaults-backed preferences for Grimoire. Stores the last login (so
/// Connect... is pre-filled) and per-character pane layouts (so window setup
/// persists across launches). Passwords live in the Keychain, not here.
public enum Preferences {

    private static var defaults: UserDefaults { UserDefaults.standard }

    // MARK: - Last login

    private static let kLastAccount   = "grimoire.lastAccount"
    private static let kLastCharacter = "grimoire.lastCharacter"
    private static let kLastGameCode  = "grimoire.lastGameCode"

    public struct LastLogin {
        public var account: String
        public var character: String
        public var gameCode: String

        public init(account: String, character: String, gameCode: String) {
            self.account = account
            self.character = character
            self.gameCode = gameCode
        }
    }

    public static func loadLastLogin() -> LastLogin {
        LastLogin(
            account:   defaults.string(forKey: kLastAccount)   ?? "",
            character: defaults.string(forKey: kLastCharacter) ?? "",
            gameCode:  defaults.string(forKey: kLastGameCode)  ?? "GS3"
        )
    }

    public static func saveLastLogin(_ login: LastLogin) {
        defaults.set(login.account,   forKey: kLastAccount)
        defaults.set(login.character, forKey: kLastCharacter)
        defaults.set(login.gameCode,  forKey: kLastGameCode)
    }

    // MARK: - Per-character window layout

    /// Stores `Codable` panes keyed by `<account>:<character>`.
    public static func savePanes<T: Encodable>(_ panes: T, account: String, character: String) {
        guard let data = try? JSONEncoder().encode(panes) else { return }
        defaults.set(data, forKey: panesKey(account: account, character: character))
    }

    public static func loadPanes<T: Decodable>(
        as type: T.Type,
        account: String,
        character: String
    ) -> T? {
        let key = panesKey(account: account, character: character)
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func panesKey(account: String, character: String) -> String {
        "grimoire.panes.\(account.lowercased()).\(character.lowercased())"
    }

    // MARK: - Per-character split sizes

    public static func saveSizes(_ sizes: [String: CGFloat], account: String, character: String) {
        guard let data = try? JSONEncoder().encode(sizes) else { return }
        defaults.set(data, forKey: sizesKey(account: account, character: character))
    }

    public static func loadSizes(account: String, character: String) -> [String: CGFloat]? {
        let key = sizesKey(account: account, character: character)
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([String: CGFloat].self, from: data)
    }

    private static func sizesKey(account: String, character: String) -> String {
        "grimoire.sizes.\(account.lowercased()).\(character.lowercased())"
    }

    // MARK: - Macros

    private static let kMacros = "grimoire.macros.v1"

    public static func saveMacros(_ config: MacroConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: kMacros)
    }

    public static func loadMacros() -> MacroConfig? {
        guard let data = defaults.data(forKey: kMacros) else { return nil }
        return try? JSONDecoder().decode(MacroConfig.self, from: data)
    }

    // MARK: - Highlights

    private static let kHighlights = "grimoire.highlights.v1"

    public static func saveHighlights(_ config: HighlightConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: kHighlights)
    }

    public static func loadHighlights() -> HighlightConfig? {
        guard let data = defaults.data(forKey: kHighlights) else { return nil }
        return try? JSONDecoder().decode(HighlightConfig.self, from: data)
    }

    // MARK: - Spell presets

    private static let kSpellPresetsV1 = "grimoire.spellPresets.v1"
    private static let kSpellPresetsV2 = "grimoire.spellPresets.v2"

    public static func saveSpellPresets(_ config: SpellPresetConfig) {
        guard let data = try? JSONEncoder().encode(config) else { return }
        defaults.set(data, forKey: kSpellPresetsV2)
    }

    /// Loads v2 if present, falls back to migrating v1 (presets land in
    /// the Buffs window — see `SpellPresetConfig.migrating(_:)`), and
    /// finally returns nil if nothing's saved at all.
    public static func loadSpellPresets() -> SpellPresetConfig? {
        if let data = defaults.data(forKey: kSpellPresetsV2),
           let v2 = try? JSONDecoder().decode(SpellPresetConfig.self, from: data) {
            return v2
        }
        if let data = defaults.data(forKey: kSpellPresetsV1),
           let v1 = try? JSONDecoder().decode(LegacySpellPresetConfigV1.self, from: data) {
            let migrated = SpellPresetConfig.migrating(v1)
            // Persist immediately as v2 so we don't keep paying the
            // migration cost on every launch.
            if let data = try? JSONEncoder().encode(migrated) {
                defaults.set(data, forKey: kSpellPresetsV2)
            }
            return migrated
        }
        return nil
    }

    // MARK: - Observed spell names

    private static let kObservedSpellNames = "grimoire.observedSpellNames.v1"

    /// Names Grimoire has seen for spell ids in live `<progressBar>` widgets.
    /// Populated by the stream parser; consumed by the editor and bar render
    /// to label cooldowns / ability timers that Lich's `effect-list.xml`
    /// doesn't cover (7-10 digit ids).
    public static func loadObservedSpellNames() -> [String: String] {
        guard let data = defaults.data(forKey: kObservedSpellNames),
              let map = try? JSONDecoder().decode([String: String].self, from: data)
        else { return [:] }
        return map
    }

    public static func saveObservedSpellNames(_ map: [String: String]) {
        guard let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: kObservedSpellNames)
    }
}
