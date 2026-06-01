import Foundation

/// Applies a list of `Highlight` rules to a `RenderedLine`, returning a new
/// line where matched character ranges carry overridden fg/bg colors.
public enum HighlightProcessor {

    /// Returns `line` unchanged when no enabled rules match; otherwise returns
    /// a new line with runs split at match boundaries and `highlightFg/Bg`
    /// populated on the matched runs.
    public static func apply(_ rules: [Highlight], to line: RenderedLine) -> RenderedLine {
        let active = rules.filter { $0.enabled && !$0.text.isEmpty }
        guard !active.isEmpty, !line.runs.isEmpty else { return line }

        let plain = line.plainText as NSString
        let count = plain.length
        guard count > 0 else { return line }

        // Fast path: skip the expensive per-character override allocation
        // and run-walk below when no rule even *occurs* in this line.
        // Most lines in a typical session don't match any user-defined
        // rule, so this saves the bulk of the highlight-rebuild cost
        // (observed: ~770ms → expected ~80ms for ~1k lines at 5 rules).
        //
        // The check ignores `wholeWord`: a `contains` is much cheaper
        // than the full word-boundary test, so we conservatively
        // over-include and let the slow path correctly reject any
        // "test" inside "testing" cases. Never under-includes.
        var hasMatch = false
        for rule in active {
            if rule.usesPattern {
                // Regex rules participate in the fast-path too -- one
                // cached-regex check per rule against the line. ~1µs
                // per call, dwarfed by the slow-path savings on lines
                // with no matches.
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
        var lineFg: String? = nil
        var lineBg: String? = nil

        for rule in active {
            if rule.usesPattern {
                applyRegexMatches(
                    rule: rule,
                    line: line.plainText,
                    count: count,
                    fg: &fg,
                    bg: &bg,
                    lineFg: &lineFg,
                    lineBg: &lineBg
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
                } else {
                    for i in match.location ..< (match.location + match.length) {
                        if let f = rule.fgColor { fg[i] = f }
                        if let b = rule.bgColor { bg[i] = b }
                    }
                }

                search.location = match.location + match.length
                search.length = max(0, count - search.location)
            }
        }

        // Line-wide colours fill in only where no per-character override exists.
        if lineFg != nil || lineBg != nil {
            for i in 0 ..< count {
                if fg[i] == nil { fg[i] = lineFg }
                if bg[i] == nil { bg[i] = lineBg }
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
                var j = i + 1
                while j < runLen, fg[cursor + j] == curFg, bg[cursor + j] == curBg {
                    j += 1
                }
                let segment = runText.substring(with: NSRange(location: i, length: j - i))
                var style = run.style
                style.highlightFg = curFg
                style.highlightBg = curBg
                output.append(RenderedRun(text: segment, style: style))
                i = j
            }
            cursor += runLen
        }

        return RenderedLine(runs: output)
    }

    /// Walks all regex matches for `rule` against `line` and stamps the
    /// per-character fg/bg arrays (or line-wide fg/bg) just like the
    /// literal path does. Honors `entireLine`. `wholeWord` is baked into
    /// the compiled pattern via `\b` boundaries.
    private static func applyRegexMatches(
        rule: Highlight,
        line: String,
        count: Int,
        fg: inout [String?],
        bg: inout [String?],
        lineFg: inout String?,
        lineBg: inout String?
    ) {
        guard let regex = compiledRegex(for: rule) else { return }
        let range = NSRange(location: 0, length: count)
        regex.enumerateMatches(in: line, range: range) { result, _, _ in
            guard let m = result, m.range.location != NSNotFound else { return }
            if rule.entireLine {
                if let f = rule.fgColor { lineFg = f }
                if let b = rule.bgColor { lineBg = b }
            } else {
                let end = min(m.range.location + m.range.length, count)
                for i in m.range.location ..< end {
                    if let f = rule.fgColor { fg[i] = f }
                    if let b = rule.bgColor { bg[i] = b }
                }
            }
        }
    }

    /// Compile-once cache. Key includes the case-sensitivity flag so
    /// identical patterns with different casing don't collide.
    /// NSCache is documented as thread-safe (callers don't need locks
    /// around `object(forKey:)` / `setObject(_:forKey:)`), but Swift 6
    /// can't see that, so we mark this `nonisolated(unsafe)` to opt out
    /// of the strict-concurrency check on the static. Entries get
    /// evicted under memory pressure, which is fine because the
    /// shorthand-to-regex compilation is cheap.
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

    /// Translates Grimoire's pattern shorthand into a real regex string.
    /// `#`   -> `\d+` (one or more digits).
    /// `{s}` -> `s?`  (optional `s`).
    /// Everything else: escaped literally so `(`, `.`, `+`, etc. don't
    /// take on regex meanings the user didn't ask for.
    ///
    /// When `wholeWord` is true the result is wrapped in `\b...\b`.
    private static func compilePattern(_ s: String, wholeWord: Bool) -> String {
        var result = ""
        var i = s.startIndex
        while i < s.endIndex {
            let remaining = s[i...]
            if remaining.hasPrefix("#") {
                result += "\\d+"
                i = s.index(after: i)
            } else if remaining.hasPrefix("{s}") {
                result += "s?"
                i = s.index(i, offsetBy: 3)
            } else {
                let ch = String(s[i])
                result += NSRegularExpression.escapedPattern(for: ch)
                i = s.index(after: i)
            }
        }
        return wholeWord ? "\\b" + result + "\\b" : result
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
