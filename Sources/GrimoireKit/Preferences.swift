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

    public struct LastLogin: Codable, Equatable, Hashable, Identifiable {
        public var account: String
        public var character: String
        public var gameCode: String

        /// Stable id for SwiftUI lists (account+character+game, case-folded).
        /// Computed, so it isn't part of the Codable form.
        public var id: String { "\(account.lowercased()):\(character.lowercased()):\(gameCode)" }

        public init(account: String, character: String, gameCode: String) {
            self.account = account
            self.character = character
            self.gameCode = gameCode
        }

        /// De-dupe match: same account+character (case-insensitive) and game.
        public func matches(_ other: LastLogin) -> Bool {
            account.lowercased() == other.account.lowercased()
                && character.lowercased() == other.character.lowercased()
                && gameCode == other.gameCode
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

    // MARK: - Recent logins (successful)

    private static let kRecentLogins = "grimoire.recentLogins.v1"
    private static let recentLoginsCap = 20

    /// Successfully-logged-in characters, most-recent first.
    public static func loadRecentLogins() -> [LastLogin] {
        guard let data = defaults.data(forKey: kRecentLogins),
              let list = try? JSONDecoder().decode([LastLogin].self, from: data)
        else { return [] }
        return list
    }

    /// Records a successful login at the front — de-duped (case-insensitive on
    /// account+character, exact game) and capped at `recentLoginsCap`.
    public static func addRecentLogin(_ login: LastLogin) {
        var list = loadRecentLogins().filter { !$0.matches(login) }
        list.insert(login, at: 0)
        if list.count > recentLoginsCap { list = Array(list.prefix(recentLoginsCap)) }
        persistRecentLogins(list)
    }

    public static func removeRecentLogin(_ login: LastLogin) {
        persistRecentLogins(loadRecentLogins().filter { !$0.matches(login) })
    }

    private static func persistRecentLogins(_ list: [LastLogin]) {
        if let data = try? JSONEncoder().encode(list) {
            defaults.set(data, forKey: kRecentLogins)
        }
    }

    // MARK: - Lich install folder

    private static let kLichDir = "grimoire.lichDir"

    /// User-chosen Lich root, or nil if never set (auto-detect applies).
    public static func loadLichDir() -> String? { defaults.string(forKey: kLichDir) }
    public static func saveLichDir(_ path: String) { defaults.set(path, forKey: kLichDir) }

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

    // MARK: - Per-character active macro set

    /// Which macro set a character last had active. The sets themselves are
    /// shared (see `saveMacros`); only the active *choice* is per-character.
    private static func activeMacroSetKey(account: String, character: String) -> String {
        "grimoire.activeMacroSet.\(account.lowercased()).\(character.lowercased())"
    }

    /// The character's last-active set id, or nil if never saved. Uses
    /// `object(forKey:)` so "unset" is distinguishable from a saved 0 (set 0 is
    /// a valid default set).
    public static func loadActiveMacroSet(account: String, character: String) -> Int? {
        let key = activeMacroSetKey(account: account, character: character)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.integer(forKey: key)
    }

    public static func saveActiveMacroSet(_ setId: Int, account: String, character: String) {
        defaults.set(setId, forKey: activeMacroSetKey(account: account, character: character))
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
