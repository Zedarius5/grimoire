import Testing
@testable import GrimoireKit

/// Parsing side of the manual-dialog feature, driven by the byte-for-byte
/// grinsawl frames (window creation + a content update). The SwiftUI placement
/// is covered by ManualDialogLayoutTests + in-app verification.
@Suite("Manual dialog positioning")
struct DialogManualPositioningTests {

    // Frame 1 — window creation (open_window, sent once).
    static let creationFrame = "<closeDialog id='Grinsawl'/><openDialog type='dynamic' id='Grinsawl' title='Grinsawl' target='Grinsawl' scroll='manual' location='main' justify='3' height='340' resident='true'><dialogData id='Grinsawl'></dialogData></openDialog>"

    // Frame 2 — a representative content update (render_window, every refresh).
    static let contentFrame = "<dialogData id='Grinsawl' clear='t' ><label id='gl_0' value='Grinsawl 0.5.13.8' justify='left' left='0' top='0' /><link id='gl_1' value='[Setup]' cmd='grinsawl view setup' echo='grinsawl view setup' justify='left' left='250' top='0' /><label id='gl_2' value='Goal: GOLD Bloody halfling cannibal' justify='left' left='0' top='18' /><link id='gl_3' value='[Clear]' cmd='grinsawl clear' echo='grinsawl clear' justify='left' left='250' top='18' /><label id='gl_4' value='Spares 0/3    Byproducts 0    vissi Tier 3' justify='left' left='0' top='36' /><label id='gl_5' value='Capture: ready     Foil: ready' justify='left' left='0' top='54' /><label id='gl_6' value='Foil goal:' justify='left' left='0' top='72' /><link id='gl_7' value=' Bronze' cmd='grinsawl min bronze' echo='grinsawl min bronze' justify='left' left='75' top='72' /><link id='gl_8' value=' Silver' cmd='grinsawl min silver' echo='grinsawl min silver' justify='left' left='145' top='72' /><link id='gl_9' value=' **Gold**' cmd='grinsawl min gold' echo='grinsawl min gold' justify='left' left='215' top='72' /><label id='gl_10' value='Target (click to set):' justify='left' left='0' top='90' /><link id='gl_11' value=' Burly goliath engineer (2 unfoiled)' cmd='grinsawl target burly goliath engineer' echo='grinsawl target burly goliath engineer' justify='left' left='12' top='108' /><label id='gl_12' value='Pausing: energywings, spellactive' justify='left' left='0' top='126' /><link id='gl_13' value='[Store foiled]' cmd='grinsawl store' echo='grinsawl store' justify='left' left='0' top='144' /><link id='gl_14' value='[Store all]' cmd='grinsawl store all' echo='grinsawl store all' justify='left' left='120' top='144' /><link id='gl_15' value='[Rescan tome]' cmd='grinsawl scan tome' echo='grinsawl scan tome' justify='left' left='0' top='162' /><link id='gl_16' value='[Organize tome]' cmd='grinsawl organize' echo='grinsawl organize' justify='left' left='120' top='162' /></dialogData>"

    @Test("openDialog scroll='manual' captures the flag + height")
    func capturesManual() {
        let r = StreamRenderer()
        _ = r.render(line: Self.creationFrame)
        let d = r.dialogs["Grinsawl"]
        #expect(d?.scrollManual == true)
        #expect(d?.height == .px(340))
    }

    @Test("non-manual openDialog leaves scrollManual false")
    func nonManual() {
        let r = StreamRenderer()
        _ = r.render(line: "<openDialog id='Foo' title='Foo'><dialogData id='Foo'></dialogData></openDialog>")
        #expect(r.dialogs["Foo"]?.scrollManual == false)
    }

    @Test("content survives the clear='t' refresh with positions intact; same-top widgets share a row")
    func positionsAndRows() {
        let r = StreamRenderer()
        _ = r.render(line: Self.creationFrame)
        _ = r.render(line: Self.contentFrame)
        let d = r.dialogs["Grinsawl"]!
        #expect(d.scrollManual == true)   // preserved across clear='t'

        func top(_ id: String) -> Length? { d.widgets.first { $0.widgetId == id }?.layout.top }
        func left(_ id: String) -> Length? { d.widgets.first { $0.widgetId == id }?.layout.left }

        // gl_0 (label) + gl_1 ([Setup] link) share top=0 → one row.
        #expect(top("gl_0") == .px(0))
        #expect(top("gl_1") == .px(0))
        #expect(left("gl_1") == .px(250))

        // Foil tiers gl_7/8/9 share top=72, ascending left → one row, three cols.
        #expect(top("gl_7") == .px(72) && top("gl_8") == .px(72) && top("gl_9") == .px(72))
        #expect(left("gl_7") == .px(75) && left("gl_8") == .px(145) && left("gl_9") == .px(215))

        // The two button rows.
        #expect(top("gl_13") == .px(144) && top("gl_14") == .px(144))
        #expect(top("gl_15") == .px(162) && top("gl_16") == .px(162))
        #expect(left("gl_14") == .px(120) && left("gl_16") == .px(120))
    }
}
