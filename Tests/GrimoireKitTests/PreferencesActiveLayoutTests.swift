import Testing
import Foundation
import GrimoireKit

/// Per-character active-layout memory: the layout set is shared, but each
/// character remembers (and logs back in with) the layout it last used.
@Suite("Preferences active layout", .serialized)
struct PreferencesActiveLayoutTests {

    private func key(_ account: String, _ character: String) -> String {
        "grimoire.activeLayout.\(account.lowercased()).\(character.lowercased())"
    }

    /// Snapshot/restore the keys this suite touches so it can't disturb real prefs.
    private func withCleanStore(_ accounts: [(String, String)], _ body: () -> Void) {
        let keys = accounts.map { key($0.0, $0.1) }
        let saved = keys.map { UserDefaults.standard.string(forKey: $0) }
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        defer {
            for (k, v) in zip(keys, saved) {
                if let v { UserDefaults.standard.set(v, forKey: k) }
                else { UserDefaults.standard.removeObject(forKey: k) }
            }
        }
        body()
    }

    @Test("active layout round-trips, is per-character, and case-folds the key")
    func roundTrip() {
        withCleanStore([("acc", "Ruskos"), ("acc", "Zedarius")]) {
            #expect(Preferences.loadActiveLayout(account: "acc", character: "Ruskos") == nil)

            Preferences.saveActiveLayout("Ruskos-desktop", account: "acc", character: "Ruskos")
            Preferences.saveActiveLayout("Default", account: "acc", character: "Zedarius")

            #expect(Preferences.loadActiveLayout(account: "acc", character: "Ruskos") == "Ruskos-desktop")
            #expect(Preferences.loadActiveLayout(account: "acc", character: "Zedarius") == "Default")
            // Account/character casing doesn't matter for lookup.
            #expect(Preferences.loadActiveLayout(account: "ACC", character: "ruskos") == "Ruskos-desktop")
        }
    }
}
