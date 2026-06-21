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

    @Test("Bold / italic traits propagate to matched runs")
    func fontTraitsPropagate() {
        let rule = Highlight(
            text: "danger",
            fgColor: "#FF0000",
            bold: true,
            italic: true
        )
        let r = HighlightProcessor.apply([rule], to: line("the danger draws near"))
        let hit = r.runs.first { $0.text == "danger" }
        #expect(hit != nil)
        #expect(hit?.style.highlightFg == "#FF0000")
        #expect(hit?.style.highlightBold == true)
        #expect(hit?.style.italic == true)
        // Surrounding runs must NOT inherit the traits.
        let nonHit = r.runs.first { $0.text.contains("draws") }
        #expect(nonHit?.style.italic == false)
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

    @Test("matches() literal: substring hit returns true")
    func matchesLiteralHit() {
        let rule = Highlight(text: "death")
        #expect(HighlightProcessor.matches(rule, in: "the monster dies a horrible death"))
    }

    @Test("matches() literal: no hit returns false")
    func matchesLiteralMiss() {
        let rule = Highlight(text: "death")
        #expect(!HighlightProcessor.matches(rule, in: "you skip merrily through the meadow"))
    }

    @Test("matches() regex: hit returns true")
    func matchesRegexHit() {
        let rule = Highlight(text: #"\d+ silver"#, usesPattern: true)
        #expect(HighlightProcessor.matches(rule, in: "you find 250 silver in the pile"))
    }

    @Test("matches() respects case sensitivity")
    func matchesCaseSensitive() {
        let rule = Highlight(text: "Death", caseSensitive: true)
        #expect(!HighlightProcessor.matches(rule, in: "facing death"))
        #expect(HighlightProcessor.matches(rule, in: "facing Death"))
    }

    @Test("matches() respects wholeWord")
    func matchesWholeWord() {
        let rule = Highlight(text: "cat", wholeWord: true)
        #expect(HighlightProcessor.matches(rule, in: "the cat sleeps"))
        #expect(!HighlightProcessor.matches(rule, in: "category of items"))
    }

    @Test("matchedText() literal: returns the substring as-it-appeared in the line")
    func matchedTextLiteralPreservesCase() {
        // Case-insensitive literal: the result should keep the line's casing,
        // not the rule's lowercase text.
        let rule = Highlight(text: "death")
        let result = HighlightProcessor.matchedText(rule, in: "The Death of a Salesman")
        #expect(result == "Death")
    }

    @Test("matchedText() regex: returns the matched span (not the pattern)")
    func matchedTextRegexReturnsSpan() {
        let rule = Highlight(text: #"\d+ silver"#, usesPattern: true)
        let result = HighlightProcessor.matchedText(rule, in: "You get 250 silver from the pile.")
        #expect(result == "250 silver")
    }

    @Test("matchedText() entireLine: returns the whole line")
    func matchedTextEntireLineReturnsFullLine() {
        var rule = Highlight(text: "death")
        rule.entireLine = true
        let line = "Your foe collapses to the ground in death."
        let result = HighlightProcessor.matchedText(rule, in: line)
        #expect(result == line)
    }

    @Test("matchedText() wholeWord: skips partial-word hits and finds the real one")
    func matchedTextWholeWordSkipsPartial() {
        var rule = Highlight(text: "cat")
        rule.wholeWord = true
        // The "cat" inside "category" is rejected; the standalone "cat" is returned.
        let result = HighlightProcessor.matchedText(rule, in: "category contains a cat in it")
        #expect(result == "cat")
    }

    @Test("matchedText() returns nil when no match")
    func matchedTextNoMatch() {
        let rule = Highlight(text: "dragon")
        #expect(HighlightProcessor.matchedText(rule, in: "you see a small kitten") == nil)
    }

    @Test("matchedText() returns nil for disabled / empty rule")
    func matchedTextDisabledOrEmpty() {
        var disabled = Highlight(text: "x")
        disabled.enabled = false
        #expect(HighlightProcessor.matchedText(disabled, in: "xyz") == nil)
        let empty = Highlight(text: "")
        #expect(HighlightProcessor.matchedText(empty, in: "anything") == nil)
    }

    @Test("matches() returns false for disabled or empty-text rules")
    func matchesDisabledOrEmpty() {
        var disabled = Highlight(text: "x")
        disabled.enabled = false
        #expect(!HighlightProcessor.matches(disabled, in: "xyz"))

        let empty = Highlight(text: "")
        #expect(!HighlightProcessor.matches(empty, in: "anything"))
    }

    @Test("Invalid regex fails closed (no match, no crash)")
    func invalidRegexFailsClosed() {
        // `[` opens a character class that never closes: ICU fails to compile,
        // so the line passes through unchanged.
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
