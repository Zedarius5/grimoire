import Testing
import CoreGraphics
@testable import GrimoireKit

@Suite("ManualDialogLayout")
struct ManualDialogLayoutTests {

    @Test("layoutWidth never drops below the design width")
    func layoutWidthClamp() {
        #expect(ManualDialogLayout.layoutWidth(paneWidth: 600) == 600)
        #expect(ManualDialogLayout.layoutWidth(paneWidth: 200) == 300)
    }

    @Test("responsive X spreads columns proportionally to the pane width")
    func responsiveX() {
        let p = ManualDialogLayout.position(leftPx: 250, topPx: 0, paneWidth: 600)
        #expect(p.x == 500)   // (250/300) * 600
        #expect(p.y == 0)
    }

    @Test("Y is 1:1")
    func verticalOneToOne() {
        let p = ManualDialogLayout.position(leftPx: 0, topPx: 126, paneWidth: 600)
        #expect(p.x == 0)
        #expect(p.y == 126)
    }

    @Test("below min width, positions pin to design coords (for horizontal scroll)")
    func narrowPinsToDesign() {
        let p = ManualDialogLayout.position(leftPx: 250, topPx: 0, paneWidth: 200)
        #expect(p.x == 250)   // layoutWidth clamps to 300 -> (250/300)*300
    }

    @Test("same top -> same y, ascending left -> ascending x (columns)")
    func columns() {
        // grinsawl foil tiers: left 75/145/215 all at top 72
        let a = ManualDialogLayout.position(leftPx: 75,  topPx: 72, paneWidth: 600)
        let b = ManualDialogLayout.position(leftPx: 145, topPx: 72, paneWidth: 600)
        let c = ManualDialogLayout.position(leftPx: 215, topPx: 72, paneWidth: 600)
        #expect(a.y == b.y)
        #expect(b.y == c.y)
        #expect(a.x < b.x)
        #expect(b.x < c.x)
    }
}
