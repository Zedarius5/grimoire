import Testing
import Foundation
@testable import GrimoireKit

/// Perf guard for the dialog "chip" highlight rendering. The rule-count cost
/// lives in `HighlightProcessor.apply` (unchanged by the chip change); the chip
/// rendering only adds a thin per-run view wrapper, so the thing that could
/// scale badly is (a) apply time with many rules and (b) the number of runs a
/// label splits into (= number of chip segments). Both are measured here.
@Suite("DialogHighlight perf")
struct DialogHighlightPerfTests {

    private func line(_ s: String) -> RenderedLine {
        RenderedLine(runs: [RenderedRun(text: s, style: RunStyle())])
    }

    private func ms(_ d: Duration) -> Double {
        Double(d.components.seconds) * 1000 + Double(d.components.attoseconds) / 1e15
    }

    /// 4 foil regexes (case-sensitive) + literal creature-name rules + a few
    /// regex rules, padded to `count`.
    private func makeRules(count: Int) -> [Highlight] {
        var rules: [Highlight] = []
        for letter in ["G", "S", "B", "W"] {
            rules.append(Highlight(text: "(?<=[(|])\\d{1,2}\(letter)(?=[|)])",
                                   bgColor: "#FFD700", caseSensitive: true,
                                   kind: .text, usesPattern: true))
        }
        let creatures = ["gigas skald", "battle mastodon", "hobgoblin", "hinterboar",
                         "kobold", "rabid squirrel", "cold wyrm", "grub", "reptilian mutant",
                         "gigas berserker", "goliath", "goblin", "orc", "troll", "shaman",
                         "frost giant", "wraith", "golem", "skeleton", "zombie"]
        for c in creatures where rules.count < count {
            rules.append(Highlight(text: c, fgColor: "#88CCFF"))
        }
        let dirs = ["north", "south", "east", "west", "up", "down", "out"]
        var i = 0
        while rules.count < count {
            rules.append(Highlight(text: "\\b\(dirs[i % dirs.count])\\b",
                                   fgColor: "#AAFFAA", kind: .text, usesPattern: true))
            i += 1
        }
        return rules
    }

    // A creature-window's worth of labels (from the live screenshot).
    private let labels: [String] = [
        "Grim gigas skald (1W)", "Heavily armored battle mastodon (1G)", "Hobgoblin (1G)",
        "Immense gold-bristled hinterboar (1W)", "Kobold (1G)", "Rabid squirrel (1G)",
        "Rolton (1G)", "Silver-scaled cold wyrm (1W)", "Slimy little grub (1G)",
        "Squamous reptilian mutant (2W)", "Tattooed gigas berserker (1W)",
        "Creatures: 0  CLAIM: False", "Dead Creatures: 0", "Retrieve cards:",
    ]

    @Test("chip-segment count per label stays small even with a large rule set")
    func chipSegmentsBounded() {
        let lines = labels.map(line)
        let rules900 = makeRules(count: 900)

        // The real guard: a label must not split into many chip segments
        // regardless of rule count — that's what keeps the view layer bounded.
        // (The per-rule MATCHER cost lives in HighlightProcessor.apply and is
        // unchanged by the chip rendering.)
        let maxRuns = lines.map { HighlightProcessor.apply(rules900, to: $0).runs.count }.max() ?? 0

        // Printed readout for a "tens of rules" pass (not asserted — wall-clock
        // is machine-dependent). Measured in release: ~0.4 ms/full-pass at 50
        // rules, scaling ~linearly with rule count (0.09/0.41/1.98/9.19 ms at
        // 4/50/200/900) — pre-existing matcher cost, not added by the chips.
        let rules50 = makeRules(count: 50)
        for l in lines { _ = HighlightProcessor.apply(rules50, to: l) }   // warm
        let passes = 200
        let elapsed = ContinuousClock().measure {
            for _ in 0..<passes { for l in lines { _ = HighlightProcessor.apply(rules50, to: l) } }
        }
        print(String(format: "PERF dialog highlight (%d labels): 50 rules = %.3f ms/full-pass; max chip-segments per label (900 rules) = %d",
                     lines.count, ms(elapsed) / Double(passes), maxRuns))

        #expect(maxRuns <= 6)
    }
}
