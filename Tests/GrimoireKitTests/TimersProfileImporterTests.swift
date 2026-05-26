import Testing
import Foundation
@testable import GrimoireKit

@Suite("TimersProfileImporter")
struct TimersProfileImporterTests {

    @Test("parses a basic spell block")
    func basicBlock() {
        let input = """
        Window Name: Main

        730:
        Bar Color: maroon
        Trough Color: black
        Bar Height: 50
        Full Bar: 35
        Text Color: white
        Font Size: 10
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        let p = presets[0]
        #expect(p.spellId == "730")
        #expect(p.styling.barColor    == "#800000")
        #expect(p.styling.troughColor == "#000000")
        #expect(p.styling.barHeight   == 50)
        // timers.lic stores Full Bar in minutes; the importer multiplies
        // by 60 on the way in so the rest of Grimoire's stack can keep
        // working in seconds.
        #expect(p.styling.fullBarSeconds == 35 * 60)
        #expect(p.styling.textColor   == "#FFFFFF")
        #expect(p.styling.fontSize    == 10)
        #expect(p.styling.hidden      == false)
        #expect(p.displayName == nil)
    }

    @Test("skips unknown keys")
    func unknownKeys() {
        let input = """
        414:
        Font Size: 8
        Priority: 50
        Bar Order: Spell Number
        Game Line: ignored
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        #expect(presets[0].styling.fontSize == 8)
    }

    @Test("Text Display becomes displayName")
    func textDisplay() {
        let input = """
        98214962:
        Bar Color: maroon
        Text Display: Sacrifice (Channel CD)
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets[0].displayName == "Sacrifice (Channel CD)")
    }

    @Test("Hide Bar Yes/No maps to bool")
    func hideBar() {
        let input = """
        100:
        Hide Bar: Yes

        101:
        Hide Bar: No
        """
        let presets = TimersProfileImporter.parse(input)
        let byId = Dictionary(uniqueKeysWithValues: presets.map { ($0.spellId, $0) })
        #expect(byId["100"]?.styling.hidden == true)
        #expect(byId["101"]?.styling.hidden == false)
    }

    @Test("CSS named colours map to hex")
    func namedColours() {
        #expect(TimersProfileImporter.cssNameToHex("maroon")  == "#800000")
        #expect(TimersProfileImporter.cssNameToHex("DIMGRAY") == "#696969")
        #expect(TimersProfileImporter.cssNameToHex("azure")   == "#F0FFFF")
        #expect(TimersProfileImporter.cssNameToHex("gold")    == "#FFD700")
        #expect(TimersProfileImporter.cssNameToHex("pink")    == "#FFC0CB")
        #expect(TimersProfileImporter.cssNameToHex("not-a-real-colour") == nil)
    }

    @Test("hex strings pass through unchanged")
    func hexPassthrough() {
        #expect(TimersProfileImporter.cssNameToHex("#FF8800") == "#FF8800")
    }

    @Test("blank lines end the current block")
    func blankLineTerminatesBlock() {
        // The `Font Size: 99` line should NOT attach to spell 100 because
        // the blank line ended that block. (It's also not in any block, so
        // it should be silently dropped.)
        let input = """
        100:
        Bar Color: red

        Font Size: 99
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        #expect(presets[0].styling.fontSize == nil)
    }

    @Test("merge: later window overrides earlier for same spell id")
    func multiWindowOverride() {
        // The user's profile has 730 in Main (Animate at Bar Color maroon)
        // and again in Cooldowns (Text Display Animate, Bar Height 40,
        // Font Size 14, Trough maroon). The later occurrence wins.
        let input = """
        Window Name: Main

        730:
        Bar Color: maroon
        Font Size: 10

        Window Name: Cooldowns

        730:
        Text Display: Animate
        Bar Height: 40
        Font Size: 14
        Trough Color: maroon
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        let p = presets[0]
        // Later window's values win for shared keys:
        #expect(p.styling.fontSize == 14)
        // Later window contributes new keys too:
        #expect(p.displayName == "Animate")
        #expect(p.styling.barHeight == 40)
        #expect(p.styling.troughColor == "#800000")
        // Bar Color was only set in Main — should be preserved by merge.
        #expect(p.styling.barColor == "#800000")
    }

    @Test("parseWindows: each window stays separate")
    func parseWindowsSeparate() {
        let input = """
        Window Name: Main

        730:
        Bar Color: maroon
        Font Size: 10

        5315:
        Bar Color: yellow

        Window Name: Cooldowns

        730:
        Text Display: Animate
        Font Size: 14

        102:
        Hide Bar: Yes
        """
        let windows = TimersProfileImporter.parseWindows(input)
        #expect(windows.count == 2)
        #expect(windows[0].name == "Main")
        #expect(windows[1].name == "Cooldowns")

        // Each window holds its own copy of 730 with that window's
        // values — no cross-window merging at this stage.
        let main = windows[0].presets
        #expect(main.count == 2)
        let main730 = main.first(where: { $0.spellId == "730" })
        #expect(main730?.styling.fontSize == 10)
        #expect(main730?.styling.barColor == "#800000")
        #expect(main730?.displayName == nil)

        let cd = windows[1].presets
        #expect(cd.count == 2)
        let cd730 = cd.first(where: { $0.spellId == "730" })
        #expect(cd730?.styling.fontSize == 14)
        #expect(cd730?.displayName == "Animate")
        #expect(cd730?.styling.barColor == nil)  // wasn't set in Cooldowns
    }

    @Test("parseWindows: windows preserve file order")
    func parseWindowsOrder() {
        let input = """
        Window Name: Foo

        100:
        Font Size: 8

        Window Name: Bar

        200:
        Font Size: 9

        Window Name: Baz

        300:
        Font Size: 10
        """
        let windows = TimersProfileImporter.parseWindows(input)
        #expect(windows.map(\.name) == ["Foo", "Bar", "Baz"])
    }

    @Test("layered resolution: spell overrides group overrides default")
    func resolution() {
        var window = WindowConfig(window: .buffs)
        window.defaultStyling = SpellStyling(barColor: "#111111", fontSize: 10)
        let group = SpellGroup(name: "Sigils", styling: SpellStyling(barColor: "#222222", textColor: "#FFFFFF"))
        window.groups = [group]
        let preset = SpellPreset(
            spellId: "9999",
            groupId: group.id,
            styling: SpellStyling(barColor: "#333333")
        )
        window.presets = [preset]

        let resolved = window.resolve(spellId: "9999")
        // Spell wins for barColor.
        #expect(resolved.barColor == "#333333")
        // Group fills in textColor (spell has none).
        #expect(resolved.textColor == "#FFFFFF")
        // Default fills in fontSize (neither spell nor group sets it).
        #expect(resolved.fontSize == 10)
    }

    @Test("layered resolution: unmanaged spell falls through to defaults")
    func resolutionUnmanaged() {
        var window = WindowConfig(window: .buffs)
        window.defaultStyling = SpellStyling(barColor: "#AABBCC")
        let resolved = window.resolve(spellId: "no-such-spell")
        // No preset matches → only the default layer contributes.
        #expect(resolved.barColor == "#AABBCC")
        #expect(resolved.textColor == nil)
        #expect(resolved.displayName == nil)
    }

    @Test("layered resolution: disabling preset/group skips that layer")
    func resolutionDisabling() {
        var window = WindowConfig(window: .buffs)
        let group = SpellGroup(name: "G", styling: SpellStyling(barColor: "#222222"), enabled: false)
        window.groups = [group]
        let preset = SpellPreset(
            spellId: "9999",
            groupId: group.id,
            styling: SpellStyling(barColor: "#333333"),
            enabled: false
        )
        window.presets = [preset]
        window.defaultStyling = SpellStyling(barColor: "#111111")

        // Both upper layers disabled — default wins.
        let resolved = window.resolve(spellId: "9999")
        #expect(resolved.barColor == "#111111")
    }

    @Test("v1 migration drops all presets into Buffs window")
    func v1Migration() {
        let v1 = LegacySpellPresetConfigV1(presets: [
            .init(
                id: UUID(),
                spellId: "730",
                displayName: "Animate",
                barColor: "#800000",
                troughColor: nil,
                textColor: nil,
                fontSize: nil,
                barHeight: nil,
                fullBarSeconds: nil,
                hidden: false,
                enabled: true
            )
        ])
        let migrated = SpellPresetConfig.migrating(v1)
        // All four windows exist after migration.
        #expect(migrated.windows.count == 4)
        // Buffs window carries the migrated preset; others are empty.
        let buffs = migrated.config(for: DialogWindow.buffs)
        #expect(buffs.presets.count == 1)
        #expect(buffs.presets[0].spellId == "730")
        #expect(buffs.presets[0].styling.barColor == "#800000")
        #expect(buffs.presets[0].displayName == "Animate")
        #expect(migrated.config(for: DialogWindow.cooldowns).presets.isEmpty)
        #expect(migrated.config(for: DialogWindow.activeSpells).presets.isEmpty)
        #expect(migrated.config(for: DialogWindow.debuffs).presets.isEmpty)
    }

    @Test("parseWindows: drops empty windows")
    func parseWindowsDropsEmpty() {
        let input = """
        Window Name: Main

        Window Settings
        Window Position: [100, 100]

        Window Name: Cooldowns

        100:
        Font Size: 8
        """
        let windows = TimersProfileImporter.parseWindows(input)
        // "Main" has no spell entries — dropped.
        #expect(windows.count == 1)
        #expect(windows[0].name == "Cooldowns")
    }

    @Test("parseWindows: spell blocks before any Window header land in Main")
    func parseWindowsFallbackToMain() {
        let input = """
        100:
        Font Size: 8
        """
        let windows = TimersProfileImporter.parseWindows(input)
        #expect(windows.count == 1)
        #expect(windows[0].name == "Main")
        #expect(windows[0].presets.first?.spellId == "100")
    }

    @Test("section headers without trailing values don't crash parsing")
    func sectionHeaders() {
        let input = """
        Window Settings
        Window Position: [100, 100]

        Default Settings
        Bar Order: Expires First

        100:
        Font Size: 8
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        #expect(presets[0].spellId == "100")
        #expect(presets[0].styling.fontSize == 8)
    }

    @Test("non-numeric spell ids are skipped")
    func nonNumericIds() {
        // Defensive — timers.lic ids should always be integers, but if
        // something slipped in (a stray "abc:") we shouldn't crash or
        // emit a bogus preset.
        let input = """
        abc:
        Font Size: 8

        730:
        Font Size: 9
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.count == 1)
        #expect(presets[0].spellId == "730")
    }

    @Test("output is sorted numerically by spell id")
    func sortedNumerically() {
        let input = """
        200:
        Font Size: 1

        20:
        Font Size: 1

        3:
        Font Size: 1
        """
        let presets = TimersProfileImporter.parse(input)
        #expect(presets.map(\.spellId) == ["3", "20", "200"])
    }
}
