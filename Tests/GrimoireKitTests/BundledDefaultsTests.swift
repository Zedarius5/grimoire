import Testing
import Foundation
@testable import GrimoireKit

/// Guards the starter config JSONs bundled with the app (loaded by
/// HighlightStore / SpellPresetStore on a first run with no saved
/// settings). They're hand-curated exports, so decode them against the
/// real model types here — a silent decode failure in the app would just
/// mean "new users get an empty editor" with nothing to flag it.
@Suite("Bundled starter configs")
struct BundledDefaultsTests {

    /// The JSONs live in the app target's resources, which this test
    /// target can't see via Bundle — resolve them relative to this file.
    private func resourceData(_ name: String) throws -> Data {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // GrimoireKitTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("Sources/Grimoire/Resources/\(name)")
        return try Data(contentsOf: url)
    }

    @Test("default-highlights.json decodes with the curated group states")
    func highlightsDecode() throws {
        let config = try JSONDecoder().decode(
            HighlightConfig.self, from: resourceData("default-highlights.json"))
        #expect(!config.groups.isEmpty)
        #expect(!config.highlights.isEmpty)

        // Fatal groups ship on; the (very colourful) damage tints ship off.
        for group in config.groups where group.name.hasSuffix(" fatal") {
            #expect(group.enabled, "\(group.name) should default on")
        }
        for group in config.groups where group.name.hasSuffix(" damage") {
            #expect(!group.enabled, "\(group.name) should default off")
        }

        // Every rule's group reference resolves to a shipped group.
        let groupIds = Set(config.groups.map(\.id))
        for rule in config.highlights {
            if let gid = rule.groupId {
                #expect(groupIds.contains(gid))
            }
        }
    }

    @Test("default-spell-presets.json decodes and group refs resolve")
    func spellPresetsDecode() throws {
        let config = try JSONDecoder().decode(
            SpellPresetConfig.self, from: resourceData("default-spell-presets.json"))
        #expect(!config.windows.isEmpty)
        #expect(config.windows.contains { !$0.presets.isEmpty })

        for window in config.windows {
            let groupIds = Set(window.groups.map(\.id))
            for preset in window.presets {
                if let gid = preset.groupId {
                    #expect(groupIds.contains(gid))
                }
            }
        }
    }
}
