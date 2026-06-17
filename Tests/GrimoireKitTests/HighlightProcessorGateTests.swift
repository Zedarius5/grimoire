import Testing
import Foundation
@testable import GrimoireKit

/// Proves the Aho-Corasick pruning gate is transparent: the gated path
/// produces byte-identical output to scanning every rule, and never
/// prunes a rule that actually matches.
@Suite("HighlightProcessor pruning gate")
struct HighlightProcessorGateTests {

    private func line(_ s: String) -> RenderedLine {
        RenderedLine(runs: [RenderedRun(text: s, style: RunStyle())])
    }

    /// A varied rule set exercising every dimension the gate has to
    /// reason about: plain literals, case-sensitive, whole-word, regex,
    /// overlapping spans, entire-line, and a non-ASCII literal.
    private func sampleRules() -> [Highlight] {
        func r(_ t: String, fg: String = "#FF0000", pattern: Bool = false,
               cs: Bool = false, ww: Bool = false, line: Bool = false) -> Highlight {
            var h = Highlight(text: t, usesPattern: pattern)
            h.fgColor = fg; h.caseSensitive = cs; h.wholeWord = ww; h.entireLine = line
            return h
        }
        return [
            r("goblin", fg: "#00FF00"),
            r("the goblin", fg: "#0000FF"),          // overlaps "goblin"
            r("Death", cs: true),                     // case-sensitive
            r("cat", ww: true),                       // whole-word
            r(#"\d+ silver"#, fg: "#FFFF00", pattern: true),
            r("danger", fg: "#FF00FF", line: true),   // entire-line
            r("café", fg: "#00FFFF"),                 // non-ASCII (ungated)
            r("DiSk", fg: "#888888"),                 // mixed case literal
        ]
    }

    private let probes = [
        "the goblin bares its fangs",
        "you face certain Death today",
        "the cat sat; a category of one",
        "you find 250 silver in the pile",
        "danger lurks in every shadow",
        "a warm café au lait, served hot",
        "one hidden DISK detected here",
        "nothing in this line matches at all",
        "GOBLIN in caps and goblin in lower",
        "deathly quiet — no capital here",
        "",
    ]

    @Test("gated output is byte-identical to ungated for every probe")
    func gateIsTransparent() {
        let rules = sampleRules()
        for s in probes {
            let gated   = HighlightProcessor.apply(rules, to: line(s), useGate: true)
            let ungated = HighlightProcessor.apply(rules, to: line(s), useGate: false)
            #expect(gated == ungated, "mismatch on \(s.debugDescription)")
        }
    }

    @Test("candidate set never drops a rule that actually matches")
    func noFalseNegativePrune() {
        let rules = sampleRules().filter { $0.enabled && !$0.text.isEmpty }
        for s in probes {
            let candidates = HighlightProcessor.candidateRules(rules, line: s)
            let candidateIds = Set(candidates.map(\.id))
            for rule in rules where HighlightProcessor.matches(rule, in: s) {
                #expect(candidateIds.contains(rule.id),
                        "gate pruned a matching rule \(rule.text.debugDescription) on \(s.debugDescription)")
            }
        }
    }

    @Test("gate actually prunes when most rules can't match")
    func gatePrunes() {
        // 200 distinct literal rules; a line that contains exactly one.
        var rules: [Highlight] = (0..<200).map { Highlight(text: "phrase number \($0) here") }
        rules.append(Highlight(text: "unmistakable sentinel token"))
        let candidates = HighlightProcessor.candidateRules(rules, line: "an unmistakable sentinel token appears")
        #expect(candidates.count < rules.count)
        #expect(candidates.contains { $0.text == "unmistakable sentinel token" })
    }

    @Test("randomized fuzz: gated == ungated across many rule sets and lines")
    func fuzz() {
        var rng = SystemRandomNumberGenerator()
        let words = ["flame","icy","blast","head","chest","goblin","silver","cat",
                     "death","disk","arm","shatters","into","mist","the","a"]
        func randomText() -> String {
            (0..<Int.random(in: 1...4, using: &rng)).map { _ in words.randomElement(using: &rng)! }
                .joined(separator: " ")
        }
        for _ in 0..<200 {
            let rules: [Highlight] = (0..<Int.random(in: 1...25, using: &rng)).map { _ in
                var h = Highlight(text: randomText(),
                                  usesPattern: Bool.random(using: &rng) && false) // keep literal for fuzz
                h.fgColor = ["#FF0000","#00FF00",nil].randomElement(using: &rng)!
                h.caseSensitive = Bool.random(using: &rng)
                h.wholeWord = Bool.random(using: &rng)
                h.entireLine = Bool.random(using: &rng)
                return h
            }
            let text = (0..<Int.random(in: 0...8, using: &rng)).map { _ in words.randomElement(using: &rng)! }
                .joined(separator: " ")
            let gated   = HighlightProcessor.apply(rules, to: line(text), useGate: true)
            let ungated = HighlightProcessor.apply(rules, to: line(text), useGate: false)
            #expect(gated == ungated, "fuzz mismatch on \(text.debugDescription)")
        }
    }
}
