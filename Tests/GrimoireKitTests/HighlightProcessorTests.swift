import Testing
@testable import GrimoireKit

@Suite("HighlightProcessor pattern matching")
struct HighlightProcessorPatternTests {

    private func line(_ s: String) -> RenderedLine {
        RenderedLine(runs: [RenderedRun(text: s, style: RunStyle())])
    }

    private func styledText(_ result: RenderedLine, where predicate: (RenderedRun) -> Bool) -> String {
        result.runs.filter(predicate).map(\.text).joined()
    }

    @Test("`#` shorthand matches one-or-more digits")
    func hashMatchesDigits() {
        let rule = Highlight(
            text: "(# hidden disk{s})",
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
            // The matched span must include the `(` opening and the
            // trailing `)`, so the user gets the whole `(N hidden disk(s))`
            // bracket highlighted.
            #expect(red.hasPrefix("("))
            #expect(red.hasSuffix(")"))
            #expect(red.contains("hidden disk"))
        }
    }

    @Test("`{s}` is optional")
    func optionalSuffix() {
        let rule = Highlight(text: "disk{s}", kind: .text, usesPattern: true)
            .applying(fgColor: "#00FF00")
        let single = HighlightProcessor.apply([rule], to: line("one disk here"))
        let plural = HighlightProcessor.apply([rule], to: line("two disks here"))
        #expect(single.runs.contains(where: { $0.text == "disk" && $0.style.highlightFg == "#00FF00" }))
        #expect(plural.runs.contains(where: { $0.text == "disks" && $0.style.highlightFg == "#00FF00" }))
    }

    @Test("non-shorthand characters are taken literally")
    func literalsAreEscaped() {
        // A user-typed `(` would explode a real regex; the shorthand
        // compiler must escape it so the rule still works as expected.
        let rule = Highlight(text: "(# silver)", usesPattern: true)
            .applying(fgColor: "#FFCC00")
        let r = HighlightProcessor.apply([rule], to: line("You get (50 silver) from the pile."))
        let yellow = styledText(r) { $0.style.highlightFg == "#FFCC00" }
        #expect(yellow == "(50 silver)")
    }

    @Test("pattern rule with no match leaves the line untouched")
    func noMatchPreservesLine() {
        let rule = Highlight(text: "# gems", usesPattern: true)
            .applying(fgColor: "#FF00FF")
        let input = line("the sky is blue today")
        let r = HighlightProcessor.apply([rule], to: input)
        #expect(r == input)
    }

    @Test("disabled pattern rule is ignored")
    func disabledIgnored() {
        var rule = Highlight(text: "# things", usesPattern: true)
            .applying(fgColor: "#FFFFFF")
        rule.enabled = false
        let input = line("found 12 things")
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
