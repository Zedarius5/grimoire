import Foundation

/// One parsed log line: the styled `RenderedLine` plus the category it
/// was classified into (for the viewer's show/hide toggles).
public struct LogLine: Sendable {
    public let line: RenderedLine
    public let category: LogCategory

    public init(line: RenderedLine, category: LogCategory) {
        self.line = line
        self.category = category
    }
}

/// Turns the raw text of a saved GemStone log into `[LogLine]` ready for
/// the viewer: tags rendered through the same `StreamRenderer` the live
/// feed uses (so presets/bold look like the game), control-only lines
/// (prompts etc.) dropped, and each surviving line classified.
public enum LogParser {

    /// Parses `text` into rendered, classified lines. When the log has
    /// more than `cap` displayable lines, keeps the most recent `cap`
    /// (and reports `truncated`) so the viewer can't hang on a multi-MB
    /// file.
    public static func parse(_ text: String, cap: Int = 100_000) -> (lines: [LogLine], truncated: Bool) {
        let renderer = StreamRenderer()
        var out: [LogLine] = []
        // `\r\n` and bare `\r` both appear in captured logs; normalize so
        // empty fragments don't slip through as blank lines.
        let rawLines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
        for raw in rawLines {
            // `renderMain` returns nil for content-less control lines
            // (stream-window directives, blanks). Prompt lines DO come
            // through as their ">" content (style.isPrompt) — drop those
            // too; a wall of bare prompts is pure noise in log review.
            guard let rendered = renderer.renderMain(line: String(raw)) else { continue }
            if rendered.runs.allSatisfy({ $0.style.isPrompt }) { continue }
            let category = LogClassifier.category(of: rendered.plainText)
            out.append(LogLine(line: rendered, category: category))
        }
        applyRoomDescriptions(&out)
        return finalize(out, cap: cap)
    }

    /// Relabels room-description prose as `.room`. The description is the
    /// `.game` prose between a bracketed room title and the room's listing
    /// (`Obvious paths:` / `You also see …`). Needs surrounding context, so
    /// it runs as a pass over the classified lines rather than per-line.
    /// Budget-capped so a missing terminator can't swallow the rest.
    private static func applyRoomDescriptions(_ out: inout [LogLine]) {
        var inDesc = false
        var budget = 0
        for i in out.indices {
            let plain = out[i].line.plainText
            if LogClassifier.matchesRoomTitle(plain) {
                inDesc = true; budget = 8
                continue
            }
            guard inDesc else { continue }
            if budget <= 0
                || out[i].category == .exits
                || LogClassifier.matchesRoomDescEnd(plain) {
                inDesc = false
            } else if out[i].category == .game {
                out[i] = LogLine(line: out[i].line, category: .room)
                budget -= 1
            } else {
                inDesc = false   // interrupted by some other category
            }
        }
    }

    private static func finalize(_ out: [LogLine], cap: Int) -> (lines: [LogLine], truncated: Bool) {
        if out.count > cap {
            return (Array(out.suffix(cap)), true)
        }
        return (out, false)
    }
}
