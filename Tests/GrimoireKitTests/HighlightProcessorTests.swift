import Testing
@testable import GrimoireKit

@Suite("HighlightProcessor regex matching")
struct HighlightProcessorPatternTests {

    private func line(_ s: String) -> RenderedLine {
        RenderedLine(runs: [RenderedRun(text: s, style: RunStyle())])
    }

    private func styledText(_ result: RenderedLine, where predicate: (RenderedRun) -> Bool) -> String {
        result.runs.filter(predicate).map(\.text).joined()
    }

    @Test("Regex matches a span and applies fg/bg")
    func basicMatch() {
        let rule = Highlight(
            text: #"\(\d+ hidden disks?\)"#,
            fgColor: "#FF0000",
            usesPattern: true
        )
        let cases = [
            "You see a goblin. (1 hidden disk)",
            "You see a goblin. (256 hidden disks)",
            "You see a goblin. (42 hidden disks)",
        ]
        for input in cases {
            let result = HighlightProcessor.apply([rule], to: line(input))
            let red = styledText(result) { $0.style.highlightFg == "#FF0000" }
            #expect(red.hasPrefix("("))
            #expect(red.hasSuffix(")"))
            #expect(red.contains("hidden disk"))
        }
    }

    @Test("Optional `s` (regex `?`) matches singular and plural")
    func optionalCharacter() {
        let rule = Highlight(text: "disks?", kind: .text, usesPattern: true)
            .applying(fgColor: "#00FF00")
        let single = HighlightProcessor.apply([rule], to: line("one disk here"))
        let plural = HighlightProcessor.apply([rule], to: line("two disks here"))
        #expect(single.runs.contains(where: { $0.text == "disk" && $0.style.highlightFg == "#00FF00" }))
        #expect(plural.runs.contains(where: { $0.text == "disks" && $0.style.highlightFg == "#00FF00" }))
    }

    @Test("Alternation matches either branch")
    func alternation() {
        let rule = Highlight(text: "(goblin|orc)", usesPattern: true)
            .applying(fgColor: "#FFCC00")
        let a = HighlightProcessor.apply([rule], to: line("the goblin attacks"))
        let b = HighlightProcessor.apply([rule], to: line("the orc grunts"))
        #expect(a.runs.contains(where: { $0.text == "goblin" && $0.style.highlightFg == "#FFCC00" }))
        #expect(b.runs.contains(where: { $0.text == "orc"    && $0.style.highlightFg == "#FFCC00" }))
    }

    @Test("Pattern with no match leaves the line untouched")
    func noMatchPreservesLine() {
        let rule = Highlight(text: #"\d+ gems"#, usesPattern: true)
            .applying(fgColor: "#FF00FF")
        let input = line("the sky is blue today")
        let r = HighlightProcessor.apply([rule], to: input)
        #expect(r == input)
    }

    @Test("Disabled pattern rule is ignored")
    func disabledIgnored() {
        var rule = Highlight(text: #"\d+ things"#, usesPattern: true)
            .applying(fgColor: "#FFFFFF")
        rule.enabled = false
        let input = line("found 12 things")
        let r = HighlightProcessor.apply([rule], to: input)
        #expect(r == input)
    }

    @Test("Bold / italic / underline / strikethrough traits propagate to matched runs")
    func fontTraitsPropagate() {
        let rule = Highlight(
            text: "danger",
            fgColor: "#FF0000",
            bold: true,
            italic: true,
            underline: true,
            strikethrough: true
        )
        let r = HighlightProcessor.apply([rule], to: line("the danger draws near"))
        let hit = r.runs.first { $0.text == "danger" }
        #expect(hit != nil)
        #expect(hit?.style.highlightFg == "#FF0000")
        #expect(hit?.style.highlightBold == true)
        #expect(hit?.style.italic == true)
        #expect(hit?.style.underline == true)
        #expect(hit?.style.strikethrough == true)
        // Surrounding runs must NOT inherit the traits.
        let nonHit = r.runs.first { $0.text.contains("draws") }
        #expect(nonHit?.style.italic == false)
        #expect(nonHit?.style.underline == false)
    }

    @Test("Overlapping rules stack their traits (union, not last-wins)")
    func traitsStack() {
        let boldRule = Highlight(text: "alarm", bold: true)
        let italicRule = Highlight(text: "alarm", italic: true)
        let r = HighlightProcessor.apply([boldRule, italicRule], to: line("hear the alarm bells"))
        let hit = r.runs.first { $0.text == "alarm" }
        #expect(hit?.style.highlightBold == true)
        #expect(hit?.style.italic == true)
    }

    @Test("Invalid regex fails closed (no match, no crash)")
    func invalidRegexFailsClosed() {
        // `[` opens a character class that never closes -- ICU returns
        // a compile error, our wrapper returns nil, the line passes
        // through unchanged.
        let rule = Highlight(text: "[unclosed", usesPattern: true)
            .applying(fgColor: "#FFFFFF")
        let input = line("any text whatsoever")
        let r = HighlightProcessor.apply([rule], to: input)
        #expect(r == input)
    }
}

private extension Highlight {
    func applying(fgColor: String) -> Highlight {
        var copy = self
        copy.fgColor = fgColor
        return copy
    }
}
