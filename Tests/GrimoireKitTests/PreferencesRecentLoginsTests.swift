import Testing
import Foundation
import GrimoireKit

/// The remembered list of successfully-logged-in characters that the Play
/// dialog offers for one-click selection.
// Serialized: these tests share the single `grimoire.recentLogins.v1` key, so
// they must not run concurrently (swift-testing parallelizes by default).
@Suite("Preferences recent logins", .serialized)
struct PreferencesRecentLoginsTests {

    private let key = "grimoire.recentLogins.v1"

    /// Snapshot/restore the shared key so the test can't disturb anything real.
    private func withCleanStore(_ body: () -> Void) {
        let saved = UserDefaults.standard.data(forKey: key)
        UserDefaults.standard.removeObject(forKey: key)
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: key) }
            else { UserDefaults.standard.removeObject(forKey: key) }
        }
        body()
    }

    @Test("add fronts + de-dupes (case-insensitive); remove works; load round-trips")
    func addRemove() {
        withCleanStore {
            #expect(Preferences.loadRecentLogins().isEmpty)

            Preferences.addRecentLogin(.init(account: "acc", character: "Alice", gameCode: "GS3"))
            Preferences.addRecentLogin(.init(account: "acc", character: "Bob", gameCode: "GS3"))
            #expect(Preferences.loadRecentLogins().map(\.character) == ["Bob", "Alice"])

            // Re-adding Alice (different casing) de-dupes and moves her to front.
            Preferences.addRecentLogin(.init(account: "ACC", character: "alice", gameCode: "GS3"))
            let list = Preferences.loadRecentLogins()
            #expect(list.count == 2)
            #expect(list.first?.character == "alice")   // newest casing, fronted

            // Same name, different game = a distinct entry.
            Preferences.addRecentLogin(.init(account: "acc", character: "alice", gameCode: "GSF"))
            #expect(Preferences.loadRecentLogins().count == 3)

            Preferences.removeRecentLogin(.init(account: "acc", character: "Bob", gameCode: "GS3"))
            #expect(!Preferences.loadRecentLogins().contains { $0.character.lowercased() == "bob" })
        }
    }

    @Test("list is capped to 20 most-recent")
    func capped() {
        withCleanStore {
            for i in 0..<25 {
                Preferences.addRecentLogin(.init(account: "acc", character: "C\(i)", gameCode: "GS3"))
            }
            let list = Preferences.loadRecentLogins()
            #expect(list.count == 20)
            #expect(list.first?.character == "C24")   // most recent
            #expect(!list.contains { $0.character == "C0" })   // oldest dropped
        }
    }
}
