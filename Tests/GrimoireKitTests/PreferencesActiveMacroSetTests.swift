import Testing
import Foundation
import GrimoireKit

/// Per-character "last-used macro set" persistence. Sets are shared; only which
/// set is active is remembered per character. Set 0 is a valid set (Wrayth's
/// default), so "unset" must be distinguishable from "saved 0".
@Suite("Preferences active macro set")
struct PreferencesActiveMacroSetTests {

    @Test("round-trips per character; nil when unset; 0 is distinct from unset")
    func roundTrip() {
        // Unique account so the test can't collide with anything real.
        let acct = "test-\(UUID().uuidString)"
        defer {
            for ch in ["alice", "bob", "carol"] {
                UserDefaults.standard.removeObject(
                    forKey: "grimoire.activeMacroSet.\(acct.lowercased()).\(ch)")
            }
        }

        // Unset reads nil.
        #expect(Preferences.loadActiveMacroSet(account: acct, character: "alice") == nil)

        // Round-trips a non-zero id.
        Preferences.saveActiveMacroSet(3, account: acct, character: "alice")
        #expect(Preferences.loadActiveMacroSet(account: acct, character: "alice") == 3)

        // Set 0 must read back as 0, not nil.
        Preferences.saveActiveMacroSet(0, account: acct, character: "bob")
        #expect(Preferences.loadActiveMacroSet(account: acct, character: "bob") == 0)

        // Other characters are isolated.
        #expect(Preferences.loadActiveMacroSet(account: acct, character: "carol") == nil)
    }
}
