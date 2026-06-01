import Testing
import Foundation
@testable import GrimoireKit

@Suite("StreamRenderer")
struct StreamRendererTests {

    // MARK: - Basic emission

    @Test("plain text on main stream emits one event")
    func plainTextOnMain() {
        let r = StreamRenderer()
        let events = r.render(line: "You see nothing unusual.")
        #expect(events.count == 1)
        #expect(events[0].streamId == "main")
        #expect(events[0].line.plainText == "You see nothing unusual.")
        #expect(events[0].line.runs[0].style == RunStyle())
    }

    @Test("whitespace-only line emits no events")
    func whitespaceOnlyDropped() {
        let r = StreamRenderer()
        #expect(r.render(line: "   ").isEmpty)
        #expect(r.render(line: "\r\n").isEmpty)
    }

    @Test("entity refs decode in emitted text")
    func entityDecode() {
        let r = StreamRenderer()
        let events = r.render(line: "salt &amp; pepper &lt;3")
        #expect(events.first?.line.plainText == "salt & pepper <3")
    }

    // MARK: - Stream stack

    @Test("pushStream routes text to that stream, popStream returns to main")
    func streamPushPop() {
        let r = StreamRenderer()
        // Single line containing the whole push/pop is the common case.
        let events = r.render(
            line: "<pushStream id='thoughts'/>You hear someone think...<popStream/>"
        )
        #expect(events.count == 1)
        #expect(events[0].streamId == "thoughts")
        #expect(events[0].line.plainText == "You hear someone think...")
    }

    @Test("pushStream persists across render() calls until popStream")
    func streamPersistsAcrossLines() {
        let r = StreamRenderer()
        _ = r.render(line: "<pushStream id='familiar'/>")
        let events = r.render(line: "Your familiar squeaks.")
        #expect(events.first?.streamId == "familiar")
        _ = r.render(line: "<popStream/>")
        let after = r.render(line: "Back in main.")
        #expect(after.first?.streamId == "main")
    }

    @Test("empty-id pushStream is ignored (protocol noise)")
    func emptyIdPushStreamIgnored() {
        let r = StreamRenderer()
        _ = r.render(line: "<pushStream id=''/>")
        let events = r.render(line: "still in main")
        #expect(events.first?.streamId == "main")
    }

    @Test("spurious popStream on empty stack is a no-op")
    func popStreamOnEmptyStackIsNoop() {
        let r = StreamRenderer()
        _ = r.render(line: "<popStream/>")
        let events = r.render(line: "still in main")
        #expect(events.first?.streamId == "main")
    }

    // MARK: - Style stack (bold, monsterbold, presets)

    @Test("<b>...</b> marks runs as bold")
    func plainBold() {
        let r = StreamRenderer()
        let events = r.render(line: "an <b>iron longsword</b> here")
        let runs = events.first?.line.runs ?? []
        #expect(runs.contains { $0.text == "iron longsword" && $0.style.bold && !$0.style.monsterbold })
    }

    @Test("pushBold/popBold marks runs as monsterbold AND bold")
    func monsterboldFromPushBold() {
        let r = StreamRenderer()
        let events = r.render(line: "Also here: <pushBold/>a kobold<popBold/>.")
        let runs = events.first?.line.runs ?? []
        #expect(runs.contains { $0.text == "a kobold" && $0.style.bold && $0.style.monsterbold })
    }

    @Test("preset id='monsterbold' marks runs as monsterbold")
    func monsterboldFromPreset() {
        let r = StreamRenderer()
        let events = r.render(line: "<preset id='monsterbold'>a giant rat</preset> scurries by")
        let runs = events.first?.line.runs ?? []
        #expect(runs.contains { $0.text == "a giant rat" && $0.style.monsterbold })
    }

    @Test("speech preset suppresses <d> direction links but keeps <a> entity links")
    func speechPresetSuppressesDirectionLinksOnly() {
        let r = StreamRenderer()
        // `<d>` wraps the speech verb ("ask") -- Stormfront's menu popup
        // for these is noise, so we suppress them inside speech presets.
        // `<a>` wraps player/creature names -- we keep those clickable so
        // you can target the named NPC straight from chat.
        let events = r.render(
            line: "<preset id='speech'>You <d cmd='ask'>ask</d> <a exist='1' noun='Alice'>Alice</a>, \"hello\"</preset>"
        )
        let runs = events.first?.line.runs ?? []
        // The verb (<d>) loses its link — and since adjacent runs with
        // the same style merge, "ask" ends up inside a larger run like
        // "You ask " with style.link == nil.
        #expect(runs.contains { $0.text.contains("ask") && $0.style.link == nil })
        // The name (<a>) keeps its entity link.
        #expect(runs.contains { $0.text == "Alice" && $0.style.link?.kind == .entity })
        // Every run carries the speech styleId.
        #expect(runs.allSatisfy { $0.style.styleId == "speech" })
    }

    @Test("nested <b><b> preserves bold across one </b>")
    func nestedBoldDepth() {
        let r = StreamRenderer()
        let events = r.render(line: "<b>outer <b>inner</b> still bold</b> plain")
        let runs = events.first?.line.runs ?? []
        // The "still bold" run should be bold; the trailing " plain" should not.
        #expect(runs.contains { $0.text.contains("still bold") && $0.style.bold })
        #expect(runs.contains { $0.text.contains(" plain") && !$0.style.bold })
    }

    // MARK: - Links (<a>/<d>)

    @Test("<a> link attaches LinkRef with entity kind")
    func entityLinkAttaches() {
        let r = StreamRenderer()
        let events = r.render(
            line: "<a exist='42' noun='sword' coord='c1'>iron sword</a>"
        )
        let runs = events.first?.line.runs ?? []
        let linked = runs.first { $0.text == "iron sword" }
        #expect(linked?.style.link?.kind == .entity)
        #expect(linked?.style.link?.exist == "42")
        #expect(linked?.style.link?.coord == "c1")
    }

    @Test("<d> link attaches LinkRef with direction kind")
    func directionLinkAttaches() {
        let r = StreamRenderer()
        let events = r.render(line: "Obvious paths: <d>north</d>.")
        let runs = events.first?.line.runs ?? []
        #expect(runs.first { $0.text == "north" }?.style.link?.kind == .direction)
    }

    @Test("<d cmd='...'> link carries cmd attribute for click dispatch")
    func directionLinkPreservesCmd() {
        let r = StreamRenderer()
        let events = r.render(
            line: "Gemstone 1: <d cmd='gem equip 1'>an ovate ice blue jewel</d>"
        )
        let runs = events.first?.line.runs ?? []
        let linked = runs.first { $0.text == "an ovate ice blue jewel" }
        #expect(linked?.style.link?.cmd == "gem equip 1")
        #expect(linked?.style.link?.kind == .direction)
    }

    // MARK: - Invisible stack

    @Test("<component> contents are suppressed from the feed")
    func componentSuppresses() {
        let r = StreamRenderer()
        let events = r.render(
            line: "visible <component id='room desc'>hidden room desc</component> after"
        )
        // Two emitted segments around the suppressed middle.
        let text = events.first?.line.plainText ?? ""
        #expect(text == "visible  after")
        #expect(!text.contains("hidden room desc"))
    }

    @Test("compDef block hides all enclosed text")
    func compDefSuppresses() {
        let r = StreamRenderer()
        let events = r.render(
            line: "<compDef id='exp_bar'>some exp number</compDef>"
        )
        #expect(events.isEmpty)
    }

    @Test("mismatched </component> does not desync invisibleStack")
    func mismatchedInvisibleCloseDoesNotDrift() {
        let r = StreamRenderer()
        // Leaked </component> with nothing open — should be ignored, not
        // decrement the counter into negative territory.
        _ = r.render(line: "</component>")
        // The very next line of main text should still emit.
        let events = r.render(line: "feed is alive")
        #expect(events.first?.line.plainText == "feed is alive")
    }

    // MARK: - Prompt boundary safety net

    @Test("</prompt> resets stuck invisibleStack")
    func promptResetsInvisibleStack() {
        let r = StreamRenderer()
        // Open an invisible block that "forgets" to close.
        _ = r.render(line: "<component id='whatever'>swallowed")
        // Text after the stuck open is swallowed.
        let stuck = r.render(line: "this is swallowed")
        #expect(stuck.isEmpty)
        // Prompt arrives — safety net clears invisibleStack.
        _ = r.render(line: "<prompt time='1700000000'>&gt;</prompt>")
        // Next line should make it through.
        let after = r.render(line: "feed unstuck")
        #expect(after.first?.line.plainText == "feed unstuck")
    }

    @Test("</prompt> resets stuck streamStack")
    func promptResetsStreamStack() {
        let r = StreamRenderer()
        _ = r.render(line: "<pushStream id='thoughts'/>")
        _ = r.render(line: "<prompt time='1700000000'>&gt;</prompt>")
        let after = r.render(line: "feed is back on main")
        #expect(after.first?.streamId == "main")
    }

    @Test("prompt depth counts on its run style")
    func promptDepthMarksRun() {
        let r = StreamRenderer()
        let events = r.render(line: "<prompt time='1700000000'>&gt;</prompt>")
        // The ">" itself is the visible prompt char; its run should be marked.
        let runs = events.first?.line.runs ?? []
        #expect(runs.contains { $0.style.isPrompt })
    }

    // MARK: - Watchdog reset

    @Test("forceResetVolatileState clears everything")
    func watchdogClears() {
        let r = StreamRenderer()
        _ = r.render(line: "<pushStream id='thoughts'/><component id='x'>")
        let stuck = r.render(line: "no emission")
        #expect(stuck.isEmpty)
        r.forceResetVolatileState()
        let after = r.render(line: "alive")
        #expect(after.first?.streamId == "main")
        #expect(after.first?.line.plainText == "alive")
    }

    // MARK: - State capture mode (<right>/<left>/<spell>)

    @Test("<right>...</right> body lands in gameState.rightHand")
    func rightHandCapture() {
        let r = StreamRenderer()
        _ = r.render(line: "<right>a sturdy shield</right>")
        #expect(r.gameState.rightHand == "a sturdy shield")
    }

    @Test("<left>...</left> body lands in gameState.leftHand")
    func leftHandCapture() {
        let r = StreamRenderer()
        _ = r.render(line: "<left>a longsword</left>")
        #expect(r.gameState.leftHand == "a longsword")
    }

    @Test("<spell>...</spell> body lands in gameState.preparedSpell")
    func spellCapture() {
        let r = StreamRenderer()
        _ = r.render(line: "<spell>Major Sanctuary</spell>")
        #expect(r.gameState.preparedSpell == "Major Sanctuary")
    }

    @Test("self-closing <right/> resets right hand to Empty")
    func selfClosingRightResets() {
        let r = StreamRenderer()
        _ = r.render(line: "<right>sword</right>")
        _ = r.render(line: "<right/>")
        #expect(r.gameState.rightHand == "Empty")
    }

    @Test("self-closing <spell/> resets prepared spell to None")
    func selfClosingSpellResets() {
        let r = StreamRenderer()
        _ = r.render(line: "<spell>Fireball</spell>")
        _ = r.render(line: "<spell/>")
        #expect(r.gameState.preparedSpell == "None")
    }

    @Test("state-capture body is not emitted to the feed")
    func captureBodyIsNotEmitted() {
        let r = StreamRenderer()
        let events = r.render(line: "<right>a longsword</right>")
        #expect(events.isEmpty)
    }

    // MARK: - LaunchURL

    @Test("absolute http LaunchURL is queued verbatim")
    func launchURLAbsolute() {
        let r = StreamRenderer()
        _ = r.render(line: "<LaunchURL src='https://www.play.net/gs4/login.asp'/>")
        let urls = r.takeLaunchURLs()
        #expect(urls.count == 1)
        #expect(urls[0].absoluteString == "https://www.play.net/gs4/login.asp")
        #expect(r.takeLaunchURLs().isEmpty) // drained
    }

    @Test("relative LaunchURL src is rebased against play.net")
    func launchURLRelative() {
        let r = StreamRenderer()
        _ = r.render(line: "<LaunchURL src='/gs4/play/cm/loader.asp?token=abc'/>")
        let urls = r.takeLaunchURLs()
        #expect(urls.count == 1)
        #expect(urls[0].absoluteString == "https://www.play.net/gs4/play/cm/loader.asp?token=abc")
    }

    @Test("LaunchURL with empty src is dropped")
    func launchURLEmptySrcIgnored() {
        let r = StreamRenderer()
        _ = r.render(line: "<LaunchURL src=''/>")
        #expect(r.takeLaunchURLs().isEmpty)
    }

    // MARK: - Indicators, exits, room

    @Test("<indicator visible='y'> updates gameState.indicators true")
    func indicatorVisibleTrue() {
        let r = StreamRenderer()
        _ = r.render(line: "<indicator id='IconSTANDING' visible='y'/>")
        #expect(r.gameState.indicators["IconSTANDING"] == true)
    }

    @Test("<indicator visible='n'> updates gameState.indicators false")
    func indicatorVisibleFalse() {
        let r = StreamRenderer()
        _ = r.render(line: "<indicator id='IconHIDDEN' visible='n'/>")
        #expect(r.gameState.indicators["IconHIDDEN"] == false)
    }

    @Test("<compass><dir>...</dir></compass> populates gameState.exits")
    func compassExits() {
        let r = StreamRenderer()
        _ = r.render(line: "<compass><dir value='n'/><dir value='se'/><dir value='out'/></compass>")
        #expect(r.gameState.exits == ["n", "se", "out"])
    }

    @Test("compass open resets prior exits before populating")
    func compassResets() {
        let r = StreamRenderer()
        _ = r.render(line: "<compass><dir value='n'/></compass>")
        _ = r.render(line: "<compass><dir value='s'/></compass>")
        #expect(r.gameState.exits == ["s"])
    }

    @Test("<nav rm='123'/> updates gameState.roomNumber")
    func navUpdatesRoomNumber() {
        let r = StreamRenderer()
        _ = r.render(line: "<nav rm='12345'/>")
        #expect(r.gameState.roomNumber == "12345")
    }

    @Test("<style id='roomName'>...</style id=''/> captures room name to gameState")
    func roomNameCapture() {
        let r = StreamRenderer()
        _ = r.render(
            line: "<style id='roomName'/>[Wehnimer's Landing, North Ring Road]<style id=''/>"
        )
        #expect(r.gameState.roomName == "[Wehnimer's Landing, North Ring Road]")
    }

    @Test("<streamWindow id='main' subtitle='[Town Square]'> sets roomName fallback")
    func streamWindowSubtitleFallback() {
        let r = StreamRenderer()
        _ = r.render(line: "<streamWindow id='main' subtitle=' - [Town Square]'/>")
        #expect(r.gameState.roomName.contains("[Town Square]"))
    }

    @Test("<streamWindow id='X' title='Y'> records side-window title")
    func streamWindowTitleRecorded() {
        let r = StreamRenderer()
        _ = r.render(line: "<streamWindow id='thoughts' title='Thoughts'/>")
        #expect(r.streamWindowTitles["thoughts"] == "Thoughts")
    }

    // MARK: - Vitals via <progressBar>

    @Test("<progressBar id='health' value='80'> updates gameState.health")
    func healthProgressBar() {
        let r = StreamRenderer()
        _ = r.render(line: "<progressBar id='health' value='80' text='health 200/250'/>")
        #expect(r.gameState.health.percent == 80)
        #expect(r.gameState.health.text == "health 200/250")
    }

    @Test("<progressBar value='80.0'> tolerates fractional values")
    func progressBarFractional() {
        let r = StreamRenderer()
        _ = r.render(line: "<progressBar id='mana' value='80.0' text='mana'/>")
        #expect(r.gameState.mana.percent == 80)
    }

    // MARK: - Round/cast time

    @Test("<roundTime value='1700000005'/> sets roundtimeEnd")
    func roundTimeRecorded() {
        let r = StreamRenderer()
        _ = r.render(line: "<roundTime value='1700000005'/>")
        #expect(r.gameState.roundtimeEnd == 1_700_000_005)
    }

    @Test("<castTime value='1700000010'/> sets castTimeEnd")
    func castTimeRecorded() {
        let r = StreamRenderer()
        _ = r.render(line: "<castTime value='1700000010'/>")
        #expect(r.gameState.castTimeEnd == 1_700_000_010)
    }

    // MARK: - Dialogs

    @Test("openDialog creates a Dialog entry")
    func openDialogCreates() {
        let r = StreamRenderer()
        _ = r.render(line: "<openDialog id='Buffs' title='Active Spells'/>")
        #expect(r.dialogs["Buffs"]?.title == "Active Spells")
    }

    @Test("closeDialog removes the Dialog entry")
    func closeDialogRemoves() {
        let r = StreamRenderer()
        _ = r.render(line: "<openDialog id='Buffs' title='Active Spells'/>")
        _ = r.render(line: "<closeDialog id='Buffs'/>")
        #expect(r.dialogs["Buffs"] == nil)
    }

    @Test("dialogData with label upserts widget")
    func dialogDataLabelUpsert() {
        let r = StreamRenderer()
        _ = r.render(line: "<dialogData id='Buffs'><label id='spell_1' value='Sanctuary'/></dialogData>")
        let widgets = r.dialogs["Buffs"]?.widgets ?? []
        #expect(widgets.contains {
            if case let .label(id, text, _) = $0 { return id == "spell_1" && text == "Sanctuary" }
            return false
        })
    }

    @Test("dialogData re-emission upserts by widget id (no duplicates)")
    func dialogWidgetUpsertReplaces() {
        let r = StreamRenderer()
        _ = r.render(line: "<dialogData id='Buffs'><label id='spell_1' value='Sanctuary'/></dialogData>")
        _ = r.render(line: "<dialogData id='Buffs'><label id='spell_1' value='Sanctuary 12'/></dialogData>")
        let widgets = r.dialogs["Buffs"]?.widgets ?? []
        // Only one widget with id=spell_1, carrying the updated value.
        let matching = widgets.compactMap { (w: DialogWidget) -> String? in
            if case let .label(id, text, _) = w, id == "spell_1" { return text }
            return nil
        }
        #expect(matching == ["Sanctuary 12"])
    }

    @Test("dialogData with clear='t' empties existing widgets")
    func dialogDataClearWipesWidgets() {
        let r = StreamRenderer()
        _ = r.render(line: "<dialogData id='Buffs'><label id='spell_1' value='Sanctuary'/></dialogData>")
        _ = r.render(line: "<dialogData id='Buffs' clear='t'/>")
        #expect(r.dialogs["Buffs"]?.widgets.isEmpty == true)
    }

    @Test("UberBar wound image updates gameState.wounds")
    func woundImageUpdatesGameState() {
        let r = StreamRenderer()
        _ = r.render(
            line: "<dialogData id='UberBar'><image id='leftArm' name='Injury2'/></dialogData>"
        )
        #expect(r.gameState.wounds.parts[.leftArm]?.injury == 2)
    }

    // MARK: - Menus

    @Test("<menu><mi/></menu> buffers a ServerMenu under its id")
    func menuBuffered() {
        let r = StreamRenderer()
        _ = r.render(line: "<menu id='m1'><mi coord='c1' noun='sword' menu_cat='Weapon'/><mi coord='c2' noun='sword' menu_cat='Item'/></menu>")
        let menu = r.takeMenu(id: "m1")
        #expect(menu?.items.count == 2)
        #expect(menu?.items[0].coord == "c1")
        #expect(r.takeMenu(id: "m1") == nil) // drained
    }

    // MARK: - cmdlist

    @Test("<cli coord='X' command='Y'/> populates cmdlist")
    func cmdlistPopulated() {
        let r = StreamRenderer()
        _ = r.render(line: "<cmdlist><cli coord='C1' command='look #' menu='Look' menu_cat='Default'/></cmdlist>")
        #expect(r.cmdlist["C1"]?.command == "look #")
        #expect(r.cmdlist["C1"]?.menu == "Look")
    }

    @Test("<updateverbs/> bumps the monotonic counter")
    func updateVerbsCounter() {
        let r = StreamRenderer()
        let before = r.updateVerbsCount
        _ = r.render(line: "<updateverbs/>")
        _ = r.render(line: "<updateverbs/>")
        #expect(r.updateVerbsCount == before + 2)
    }

    // MARK: - Realistic mixed line

    @Test("realistic main-line with bold inventory + plain text")
    func realisticBoldInventory() {
        let r = StreamRenderer()
        let events = r.render(
            line: "You see a <b>steel longsword</b> and <pushBold/>a kobold<popBold/> here."
        )
        let runs = events.first?.line.runs ?? []
        #expect(runs.contains { $0.text == "steel longsword" && $0.style.bold && !$0.style.monsterbold })
        #expect(runs.contains { $0.text == "a kobold" && $0.style.monsterbold })
        // The trailing " here." should be plain.
        #expect(runs.contains { $0.text.contains("here.") && !$0.style.bold && !$0.style.monsterbold })
    }
}
