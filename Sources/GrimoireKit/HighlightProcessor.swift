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
            let opts: NSString.CompareOptions = rule.caseSensitive ? [] : [.caseInsensitive]
            if plain.range(of: rule.text, options: opts).location != NSNotFound {
                hasMatch = true
                break
            }
        }
        guard hasMatch else { return line }

        var fg = [String?](repeating: nil, count: count)
        var bg = [String?](repeating: nil, count: count)
        var lineFg: String? = nil
        var lineBg: String? = nil

        for rule in active {
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

    private static func isWordChar(_ ch: unichar) -> Bool {
        // ASCII fast-path: letters, digits, and underscore.
        if ch >= 0x30 && ch <= 0x39 { return true }   // 0-9
        if ch >= 0x41 && ch <= 0x5A { return true }   // A-Z
        if ch >= 0x61 && ch <= 0x7A { return true }   // a-z
        if ch == 0x5F { return true }                  // _
        return false
    }
}
