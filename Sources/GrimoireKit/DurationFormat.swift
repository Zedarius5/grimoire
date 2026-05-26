import Foundation

/// Parses and formats human-typed durations into seconds. Used both by
/// the live-bar countdown (server sends `"01:23:45"`-style strings) and
/// the editor's "Custom full bar" input (where the user types `3:30`,
/// `3m 10s`, `1h 5m`, `90s`, or plain `90`).
public enum DurationFormat {

    /// Parses a duration string into seconds. Returns nil for unparseable
    /// input. Accepts:
    ///   - `"H:MM:SS"` / `"MM:SS"`
    ///   - Unit suffix tokens in any order: `"1h 30m 10s"`, `"5m"`, `"45s"`
    ///   - Bare integer = seconds (`"90"` → 90)
    public static func parse(_ raw: String) -> Int? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Colon format takes priority — most familiar for HH:MM:SS-style.
        if trimmed.contains(":") {
            let pieces = trimmed.split(separator: ":")
            var values: [Int] = []
            values.reserveCapacity(pieces.count)
            for p in pieces {
                guard let n = Int(p.trimmingCharacters(in: .whitespaces)) else { return nil }
                values.append(n)
            }
            switch values.count {
            case 3: return values[0] * 3600 + values[1] * 60 + values[2]
            case 2: return values[0] * 60 + values[1]
            default: return nil
            }
        }

        // Unit-suffix format: "1h 30m 10s", "3m 10s", "45s", any subset.
        // Tokens can be in any order (`30m 1h` parses the same), and
        // whitespace between number+unit pairs is optional (`1h30m`).
        let lowered = trimmed.lowercased()
        var hadUnit = false
        var total = 0
        var i = lowered.startIndex
        while i < lowered.endIndex {
            // Skip whitespace.
            while i < lowered.endIndex, lowered[i].isWhitespace { i = lowered.index(after: i) }
            guard i < lowered.endIndex else { break }
            // Read a run of digits.
            let numStart = i
            while i < lowered.endIndex, lowered[i].isNumber { i = lowered.index(after: i) }
            guard numStart != i, let n = Int(lowered[numStart..<i]) else { return nil }
            // Skip whitespace before the unit letter.
            while i < lowered.endIndex, lowered[i].isWhitespace { i = lowered.index(after: i) }
            guard i < lowered.endIndex else { break }
            let unit = lowered[i]
            switch unit {
            case "h": total += n * 3600
            case "m": total += n * 60
            case "s": total += n
            default: return nil
            }
            hadUnit = true
            i = lowered.index(after: i)
        }
        if hadUnit { return total }

        // Bare integer fallback — interpret as seconds.
        return Int(trimmed)
    }

    /// Formats a seconds count into a compact, user-readable string.
    /// Round-trip-safe with `parse(_:)` for any input that uses the
    /// same conventions.
    public static func format(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        var parts: [String] = []
        if h > 0 { parts.append("\(h)h") }
        if m > 0 { parts.append("\(m)m") }
        if sec > 0 || parts.isEmpty { parts.append("\(sec)s") }
        return parts.joined(separator: " ")
    }
}
