import Foundation

/// Applies a list of `Highlight` rules to a `RenderedLine`, returning a new
/// line where matched character ranges carry overridden fg/bg colors.
public enum HighlightProcessor {

    /// Returns `line` unchanged when no enabled rules match; otherwise returns
    /// a new line with runs split at match boundaries and `highlightFg/Bg`
    /// populated on the matched runs.
    public static func apply(_ rules: [Highlight], to line: RenderedLine) -> RenderedLine {
        apply(rules, to: line, useGate: true)
    }

    /// `useGate` lets the equivalence test compare the Aho-Corasick-pruned
    /// path against the brute-force all-rules path. Production always gates.
    static func apply(_ rules: [Highlight], to line: RenderedLine, useGate: Bool) -> RenderedLine {
        let allActive = rules.filter { $0.enabled && !$0.text.isEmpty }
        guard !allActive.isEmpty, !line.runs.isEmpty else { return line }

        let plain = line.plainText as NSString
        let count = plain.length
        guard count > 0 else { return line }

        // PRE-FILTER: one Aho-Corasick pass prunes to the rules that could
        // match this line, instead of substring-scanning every rule. The gate
        // over-includes (regex/non-ASCII rules always pass), so output is
        // identical to scanning all rules. Candidates keep their relative
        // order, preserving color last-write-wins.
        let active = useGate ? candidateRules(allActive, line: line.plainText) : allActive
        guard !active.isEmpty else { return line }

        // Fast path: skip the per-character override allocation and run-walk
        // below when no rule even occurs in this line (most lines match
        // nothing). The check ignores `wholeWord` (a cheap `contains`),
        // over-including and letting the slow path reject partial-word hits;
        // it never under-includes.
        var hasMatch = false
        for rule in active {
            if rule.usesPattern {
                // Regex rules participate in the fast path too: one
                // cached-regex check per rule against the line.
                if let regex = compiledRegex(for: rule),
                   regex.firstMatch(in: line.plainText, range: NSRange(location: 0, length: count)) != nil {
                    hasMatch = true
                    break
                }
            } else {
                let opts: NSString.CompareOptions = rule.caseSensitive ? [] : [.caseInsensitive]
                if plain.range(of: rule.text, options: opts).location != NSNotFound {
                    hasMatch = true
                    break
                }
            }
        }
        guard hasMatch else { return line }

        var fg = [String?](repeating: nil, count: count)
        var bg = [String?](repeating: nil, count: count)
        var traits = [TraitMask](repeating: [], count: count)
        var lineFg: String? = nil
        var lineBg: String? = nil
        var lineTraits: TraitMask = []

        for rule in active {
            let ruleTraits = traitMask(for: rule)
            if rule.usesPattern {
                applyRegexMatches(
                    rule: rule,
                    ruleTraits: ruleTraits,
                    line: line.plainText,
                    count: count,
                    fg: &fg,
                    bg: &bg,
                    traits: &traits,
                    lineFg: &lineFg,
                    lineBg: &lineBg,
                    lineTraits: &lineTraits
                )
                continue
            }
            let opts: NSString.CompareOptions = rule.caseSensitive ? [] : [.caseInsensitive]
            var search = NSRange(location: 0, length: count)
            while search.location < count {
                let match = plain.range(of: rule.text, options: opts, range: search)
                if match.location == NSNotFound { break }

                if rule.wholeWord {
                    let leftOK  = match.location == 0
                        || !isWordChar(plain.character(at: match.location - 1))
                    let rightOK = match.location + match.length == count
                        || !isWordChar(plain.character(at: match.location + match.length))
                    if !(leftOK && rightOK) {
                        search.location = match.location + 1
                        search.length = max(0, count - search.location)
                        continue
                    }
                }

                if rule.entireLine {
                    if let f = rule.fgColor { lineFg = f }
                    if let b = rule.bgColor { lineBg = b }
                    lineTraits.formUnion(ruleTraits)
                } else {
                    for i in match.location ..< (match.location + match.length) {
                        if let f = rule.fgColor { fg[i] = f }
                        if let b = rule.bgColor { bg[i] = b }
                        traits[i].formUnion(ruleTraits)
                    }
                }

                search.location = match.location + match.length
                search.length = max(0, count - search.location)
            }
        }

        // Line-wide colours / traits fill in only where no per-character
        // override exists.
        if lineFg != nil || lineBg != nil || !lineTraits.isEmpty {
            for i in 0 ..< count {
                if fg[i] == nil { fg[i] = lineFg }
                if bg[i] == nil { bg[i] = lineBg }
                traits[i].formUnion(lineTraits)
            }
        }

        // Walk the original runs and split each one wherever the overrides change.
        var output: [RenderedRun] = []
        output.reserveCapacity(line.runs.count)
        var cursor = 0
        for run in line.runs {
            let runText = run.text as NSString
            let runLen = runText.length
            guard runLen > 0 else { continue }

            var i = 0
            while i < runLen {
                let pos = cursor + i
                let curFg = fg[pos]
                let curBg = bg[pos]
                let curT  = traits[pos]
                var j = i + 1
                while j < runLen,
                      fg[cursor + j] == curFg,
                      bg[cursor + j] == curBg,
                      traits[cursor + j] == curT {
                    j += 1
                }
                let segment = runText.substring(with: NSRange(location: i, length: j - i))
                var style = run.style
                style.highlightFg = curFg
                style.highlightBg = curBg
                if curT.contains(.bold)   { style.highlightBold = true }
                if curT.contains(.italic) { style.italic = true }
                output.append(RenderedRun(text: segment, style: style))
                i = j
            }
            cursor += runLen
        }

        return RenderedLine(runs: output)
    }

    /// Compact per-character trait set. OptionSet so multiple matching
    /// rules with different traits stack via `formUnion` instead of
    /// last-rule-wins.
    private struct TraitMask: OptionSet, Hashable {
        let rawValue: UInt8
        static let bold   = TraitMask(rawValue: 1 << 0)
        static let italic = TraitMask(rawValue: 1 << 1)
    }

    /// Walks all regex matches for `rule` against `line` and stamps the
    /// per-character fg/bg/trait arrays (or line-wide accumulators) just
    /// like the literal path does. Honors `entireLine`. `wholeWord` is
    /// baked into the compiled pattern via `\b` boundaries.
    private static func applyRegexMatches(
        rule: Highlight,
        ruleTraits: TraitMask,
        line: String,
        count: Int,
        fg: inout [String?],
        bg: inout [String?],
        traits: inout [TraitMask],
        lineFg: inout String?,
        lineBg: inout String?,
        lineTraits: inout TraitMask
    ) {
        guard let regex = compiledRegex(for: rule) else { return }
        let range = NSRange(location: 0, length: count)
        regex.enumerateMatches(in: line, range: range) { result, _, _ in
            guard let m = result, m.range.location != NSNotFound else { return }
            if rule.entireLine {
                if let f = rule.fgColor { lineFg = f }
                if let b = rule.bgColor { lineBg = b }
                lineTraits.formUnion(ruleTraits)
            } else {
                let end = min(m.range.location + m.range.length, count)
                for i in m.range.location ..< end {
                    if let f = rule.fgColor { fg[i] = f }
                    if let b = rule.bgColor { bg[i] = b }
                    traits[i].formUnion(ruleTraits)
                }
            }
        }
    }

    /// Collapses a rule's bold/italic flags into a TraitMask we can
    /// OR per character.
    private static func traitMask(for rule: Highlight) -> TraitMask {
        var m: TraitMask = []
        if rule.bold   { m.insert(.bold) }
        if rule.italic { m.insert(.italic) }
        return m
    }

    /// Compile-once cache. Key includes the case-sensitivity flag so identical
    /// patterns with different casing don't collide. NSCache is thread-safe but
    /// Swift 6 can't prove it, hence `nonisolated(unsafe)`. Memory-pressure
    /// eviction is fine since recompiling is cheap.
    nonisolated(unsafe) private static let regexCache: NSCache<NSString, NSRegularExpression> = {
        let c = NSCache<NSString, NSRegularExpression>()
        c.countLimit = 512
        return c
    }()

    /// Returns the compiled regex for `rule`, using its `text` field as
    /// a shorthand pattern (see `compilePattern`). Returns nil if the
    /// translated pattern fails to compile.
    private static func compiledRegex(for rule: Highlight) -> NSRegularExpression? {
        let pattern = compilePattern(rule.text, wholeWord: rule.wholeWord)
        let prefix = rule.caseSensitive ? "s:" : "i:"
        let key = NSString(string: prefix + pattern)
        if let cached = regexCache.object(forKey: key) { return cached }
        let opts: NSRegularExpression.Options = rule.caseSensitive ? [] : [.caseInsensitive]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: opts) else {
            return nil
        }
        regexCache.setObject(regex, forKey: key)
        return regex
    }

    /// Returns the user's pattern as-is (this is ICU regex syntax --
    /// `\d`, `\w`, `[abc]`, `(a|b)`, `+`, `*`, `?`, anchors, etc.).
    /// When `wholeWord` is true the pattern is wrapped in `\b...\b`
    /// boundaries so existing literal-rule semantics carry over.
    private static func compilePattern(_ s: String, wholeWord: Bool) -> String {
        wholeWord ? "\\b" + s + "\\b" : s
    }

    // MARK: - Aho-Corasick pruning gate

    /// A built gate for one rule set: the automaton over ASCII literal needles
    /// (keyed by index in `active`), plus the indices of rules that bypass it.
    /// Regex rules bypass (the automaton is literal-only), as do non-ASCII
    /// literals, where Swift vs Foundation case-folding could diverge; ungating
    /// them keeps the "never drop a possible match" invariant airtight.
    private struct Gate {
        let automaton: AhoCorasick
        let ungatedIndices: [Int]
    }

    nonisolated(unsafe) private static var cachedGate: Gate?
    nonisolated(unsafe) private static var cachedGateKey: Int = 0
    private static let gateLock = NSLock()

    /// Subset of `active` that could match `line`, in the same relative order
    /// (preserving last-write-wins color precedence). A literal rule is included
    /// iff its text occurs case-insensitively; ungated rules always are. This is
    /// a superset of the actually-matching rules, so the exact matcher yields
    /// identical output to scanning every rule.
    static func candidateRules(_ active: [Highlight], line: String) -> [Highlight] {
        let gate = gateFor(active)
        var idx = gate.automaton.search(line.lowercased())
        idx.formUnion(gate.ungatedIndices)
        guard idx.count < active.count else { return active }
        return idx.sorted().map { active[$0] }
    }

    /// Builds (or returns a cached) gate for `active`. Keyed by a content hash
    /// of the rules' text + pattern flag, so the automaton is rebuilt only when
    /// the rule set changes; the per-line cost is then one hash + one
    /// O(lineLength) search rather than a substring scan per rule.
    private static func gateFor(_ active: [Highlight]) -> Gate {
        var hasher = Hasher()
        for r in active {
            hasher.combine(r.text)
            hasher.combine(r.usesPattern)
        }
        let key = hasher.finalize()

        gateLock.lock()
        defer { gateLock.unlock() }
        if let g = cachedGate, cachedGateKey == key { return g }

        let ac = AhoCorasick()
        var ungated: [Int] = []
        for (i, r) in active.enumerated() {
            if r.usesPattern || !r.text.allSatisfy(\.isASCII) {
                ungated.append(i)
            } else {
                ac.add(r.text.lowercased(), id: i)
            }
        }
        ac.build()
        let gate = Gate(automaton: ac, ungatedIndices: ungated)
        cachedGate = gate
        cachedGateKey = key
        return gate
    }

    /// Returns the exact substring of `text` that `rule` matched, or nil. The
    /// notification body uses this so the user sees what actually hit, not the
    /// rule's pattern (or a literal that differs in case from what's on screen).
    /// `entireLine` rules return the whole `text`.
    public static func matchedText(_ rule: Highlight, in text: String) -> String? {
        guard rule.enabled, !rule.text.isEmpty, !text.isEmpty else { return nil }
        if rule.entireLine, matches(rule, in: text) {
            return text
        }
        let plain = text as NSString
        if rule.usesPattern {
            guard let regex = compiledRegex(for: rule) else { return nil }
            let range = NSRange(location: 0, length: plain.length)
            guard let m = regex.firstMatch(in: text, range: range) else { return nil }
            return plain.substring(with: m.range)
        }
        let opts: NSString.CompareOptions = rule.caseSensitive ? [] : [.caseInsensitive]
        let count = plain.length
        var search = NSRange(location: 0, length: count)
        while search.location < count {
            let m = plain.range(of: rule.text, options: opts, range: search)
            if m.location == NSNotFound { return nil }
            if rule.wholeWord {
                let leftOK  = m.location == 0
                    || !isWordChar(plain.character(at: m.location - 1))
                let rightOK = m.location + m.length == count
                    || !isWordChar(plain.character(at: m.location + m.length))
                if !(leftOK && rightOK) {
                    search.location = m.location + 1
                    search.length = max(0, count - search.location)
                    continue
                }
            }
            return plain.substring(with: m)
        }
        return nil
    }

    /// True iff `rule` matches anywhere in `text`, with the same semantics as
    /// `apply(_:to:)` (regex/literal, caseSensitive, wholeWord). The
    /// notification scanner uses this to check for a match without the full
    /// per-character styling rebuild.
    public static func matches(_ rule: Highlight, in text: String) -> Bool {
        guard rule.enabled, !rule.text.isEmpty, !text.isEmpty else { return false }
        if rule.usesPattern {
            guard let regex = compiledRegex(for: rule) else { return false }
            let range = NSRange(location: 0, length: (text as NSString).length)
            return regex.firstMatch(in: text, range: range) != nil
        }
        let plain = text as NSString
        let opts: NSString.CompareOptions = rule.caseSensitive ? [] : [.caseInsensitive]
        if !rule.wholeWord {
            return plain.range(of: rule.text, options: opts).location != NSNotFound
        }
        // wholeWord: scan and verify boundaries on each candidate.
        let count = plain.length
        var search = NSRange(location: 0, length: count)
        while search.location < count {
            let m = plain.range(of: rule.text, options: opts, range: search)
            if m.location == NSNotFound { return false }
            let leftOK  = m.location == 0
                || !isWordChar(plain.character(at: m.location - 1))
            let rightOK = m.location + m.length == count
                || !isWordChar(plain.character(at: m.location + m.length))
            if leftOK && rightOK { return true }
            search.location = m.location + 1
            search.length = max(0, count - search.location)
        }
        return false
    }

    private static func isWordChar(_ ch: unichar) -> Bool {
        // ASCII fast-path: letters, digits, and underscore.
        if ch >= 0x30 && ch <= 0x39 { return true }   // 0-9
        if ch >= 0x41 && ch <= 0x5A { return true }   // A-Z
        if ch >= 0x61 && ch <= 0x7A { return true }   // a-z
        if ch == 0x5F { return true }                  // _
        return false
    }
}
