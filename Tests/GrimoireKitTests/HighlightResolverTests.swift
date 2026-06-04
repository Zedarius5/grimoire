import Testing
import Foundation
@testable import GrimoireKit

@Suite("HighlightResolver")
struct HighlightResolverTests {

    @Test("Rule without group passes through unchanged")
    func ungroupedPassthrough() {
        let rule = Highlight(text: "alpha", fgColor: "#FF0000")
        let result = HighlightResolver.resolve([rule], groups: [])
        #expect(result == [rule])
    }

    @Test("Rule with nil group fields inherits from group")
    func inheritColorAndTraits() {
        let group = HighlightGroup(
            id: UUID(),
            name: "g",
            fgColor: "#00FF00",
            bgColor: "#000088",
            bold: true,
            italic: true
        )
        let rule = Highlight(text: "beta", groupId: group.id)
        let resolved = HighlightResolver.resolve([rule], groups: [group]).first!
        #expect(resolved.fgColor == "#00FF00")
        #expect(resolved.bgColor == "#000088")
        #expect(resolved.bold == true)
        #expect(resolved.italic == true)
    }

    @Test("Rule's own color overrides group default")
    func ruleColorWinsOverGroup() {
        let group = HighlightGroup(id: UUID(), name: "g", fgColor: "#00FF00")
        let rule = Highlight(text: "gamma", fgColor: "#FF00FF", groupId: group.id)
        let resolved = HighlightResolver.resolve([rule], groups: [group]).first!
        #expect(resolved.fgColor == "#FF00FF")
    }

    @Test("Bold and italic OR across rule and group (no un-bolding)")
    func boldOrsAcrossLayers() {
        let group = HighlightGroup(id: UUID(), name: "g", bold: true, italic: false)
        let rule = Highlight(text: "d", bold: false, italic: true, groupId: group.id)
        let resolved = HighlightResolver.resolve([rule], groups: [group]).first!
        #expect(resolved.bold == true)
        #expect(resolved.italic == true)
    }

    @Test("entireLine / caseSensitive / wholeWord OR across rule and group")
    func matchFlagsOrAcrossLayers() {
        let group = HighlightGroup(
            id: UUID(),
            name: "g",
            entireLine: true,
            caseSensitive: false,
            wholeWord: true
        )
        let rule = Highlight(
            text: "x",
            entireLine: false,
            caseSensitive: true,
            wholeWord: false,
            groupId: group.id
        )
        let r = HighlightResolver.resolve([rule], groups: [group]).first!
        #expect(r.entireLine    == true)   // group provides
        #expect(r.caseSensitive == true)   // rule provides
        #expect(r.wholeWord     == true)   // group provides
    }

    @Test("Disabled group disables all members in effective view")
    func disabledGroupCascades() {
        let group = HighlightGroup(id: UUID(), name: "g", enabled: false)
        let onRule  = Highlight(text: "x", enabled: true, groupId: group.id)
        let offRule = Highlight(text: "y", enabled: false, groupId: group.id)
        let resolved = HighlightResolver.resolve([onRule, offRule], groups: [group])
        #expect(resolved[0].enabled == false)
        #expect(resolved[1].enabled == false)
    }

    @Test("Orphan groupId (group deleted out from under) is harmless")
    func orphanGroupIdPasses() {
        let rule = Highlight(text: "z", groupId: UUID())
        let result = HighlightResolver.resolve([rule], groups: [])
        #expect(result == [rule])
    }

    @Test("notify ORs across rule and group")
    func notifyOrsAcrossLayers() {
        let g1 = HighlightGroup(id: UUID(), name: "notify-group", notify: true)
        let g2 = HighlightGroup(id: UUID(), name: "quiet-group", notify: false)
        // Rule with notify=false in a notify-on group: effective notify true.
        let r1 = Highlight(text: "a", notify: false)
        let r1WithGroup = { var r = r1; r.groupId = g1.id; return r }()
        // Rule with notify=true in a quiet group: effective notify true.
        let r2 = Highlight(text: "b", notify: true)
        let r2WithGroup = { var r = r2; r.groupId = g2.id; return r }()
        // Rule with notify=false, no group: effective notify false.
        let r3 = Highlight(text: "c", notify: false)
        let resolved = HighlightResolver.resolve([r1WithGroup, r2WithGroup, r3], groups: [g1, g2])
        #expect(resolved[0].notify == true)
        #expect(resolved[1].notify == true)
        #expect(resolved[2].notify == false)
    }
}
