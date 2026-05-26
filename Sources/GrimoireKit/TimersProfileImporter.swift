import Foundation

/// Parses Lich's `Timers Profile <name>.txt` files (the `timers.lic`
/// script's persistence format) into `SpellPreset` records.
///
/// The format is line-oriented, organised in windows (Main, Cooldowns,
/// user-named windows). Each window contains spell blocks introduced
/// by `<spellId>:` and followed by `Key: Value` lines. Section headers
/// (`Window Name:`, `Window Settings`, `Default Settings`) end any
/// in-progress spell block and are otherwise ignored — we only care
/// about per-spell overrides.
///
/// When the same spell id appears in multiple windows (e.g. defined in
/// both "Main" and "Cooldowns" with different `Text Display` values),
/// the *later* occurrence wins. That matches Lich's own loader order
/// and gives the Cooldowns-specific naming priority for cooldown ids.
public enum TimersProfileImporter {

    /// The set of `Key:` lines we know how to map. Anything else
    /// (`Game Line`, `Duration`, `Priority`, `Bar Order`, `Font Family`)
    /// is silently skipped — see `SpellPreset` documentation for which
    /// timers.lic features Grimoire deliberately doesn't support.
    private static let knownKeys: Set<String> = [
        "Bar Color", "Trough Color", "Text Color",
        "Bar Height", "Font Size", "Full Bar",
        "Text Display", "Hide Bar"
    ]

    /// One named window from a profile file (e.g. "Main", "Cooldowns")
    /// with its parsed presets. Preserves the user's per-window scoping
    /// so the import UI can ask which one they want.
    public struct ParsedWindow: Equatable, Sendable {
        public let name: String
        public let presets: [SpellPreset]
    }

    /// Parse a profile file into its windows. Empty windows (no spell
    /// blocks) are dropped. Window order in the result matches the
    /// order the windows appear in the file.
    public static func parseWindows(_ content: String) -> [ParsedWindow] {
        var windows: [(name: String, bySpellId: [String: SpellPreset], order: [String])] = []
        var currentWindowIdx: Int? = nil
        var currentId: String? = nil

        @inline(__always) func ensureWindow(name: String) -> Int {
            if let idx = windows.lastIndex(where: { $0.name == name }) {
                currentWindowIdx = idx
                return idx
            }
            windows.append((name: name, bySpellId: [:], order: []))
            let idx = windows.count - 1
            currentWindowIdx = idx
            return idx
        }

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                currentId = nil
                continue
            }

            // Window header — switch to (or create) that window's bucket.
            if line.hasPrefix("Window Name:") {
                let name = String(line.dropFirst("Window Name:".count))
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { _ = ensureWindow(name: name) }
                currentId = nil
                continue
            }

            // Other section headers end the current spell block but
            // don't change the window.
            if line == "Window Settings" || line == "Default Settings" {
                currentId = nil
                continue
            }

            // Spell block header.
            if line.hasSuffix(":") {
                let candidate = String(line.dropLast()).trimmingCharacters(in: .whitespaces)
                if !candidate.isEmpty, candidate.allSatisfy({ $0.isASCII && $0.isNumber }) {
                    // Tolerate profiles that start with spell blocks
                    // before any "Window Name:" header.
                    let winIdx = currentWindowIdx ?? ensureWindow(name: "Main")
                    currentId = candidate
                    if windows[winIdx].bySpellId[candidate] == nil {
                        windows[winIdx].bySpellId[candidate] = SpellPreset(spellId: candidate)
                        windows[winIdx].order.append(candidate)
                    }
                } else {
                    currentId = nil
                }
                continue
            }

            // Property line.
            guard let winIdx = currentWindowIdx,
                  let id = currentId,
                  let colonIdx = line.firstIndex(of: ":")
            else { continue }

            let key = String(line[..<colonIdx]).trimmingCharacters(in: .whitespaces)
            let value = String(line[line.index(after: colonIdx)...])
                .trimmingCharacters(in: .whitespaces)

            guard !value.isEmpty, knownKeys.contains(key),
                  var preset = windows[winIdx].bySpellId[id]
            else { continue }

            apply(key: key, value: value, to: &preset)
            windows[winIdx].bySpellId[id] = preset
        }

        return windows.compactMap { entry in
            guard !entry.bySpellId.isEmpty else { return nil }
            let sorted = entry.bySpellId.values.sorted { lhs, rhs in
                if let a = Int(lhs.spellId), let b = Int(rhs.spellId) { return a < b }
                return lhs.spellId.localizedStandardCompare(rhs.spellId) == .orderedAscending
            }
            return ParsedWindow(name: entry.name, presets: sorted)
        }
    }

    /// Convenience: flatten every parsed window into a single deduped
    /// list of presets, with later-window values winning on collision.
    /// Kept for callers that don't care about window-level scoping.
    public static func parse(_ content: String) -> [SpellPreset] {
        let windows = parseWindows(content)
        return merge(windows)
    }

    /// Merge multiple parsed windows into a single deduped list. Later
    /// windows override earlier on shared `spellId`s; non-conflicting
    /// fields from earlier windows are preserved.
    public static func merge(_ windows: [ParsedWindow]) -> [SpellPreset] {
        var bySpellId: [String: SpellPreset] = [:]
        for window in windows {
            for preset in window.presets {
                if var existing = bySpellId[preset.spellId] {
                    if let v = preset.displayName             { existing.displayName             = v }
                    if let v = preset.styling.barColor        { existing.styling.barColor        = v }
                    if let v = preset.styling.troughColor     { existing.styling.troughColor     = v }
                    if let v = preset.styling.textColor       { existing.styling.textColor       = v }
                    if let v = preset.styling.fontSize        { existing.styling.fontSize        = v }
                    if let v = preset.styling.barHeight       { existing.styling.barHeight       = v }
                    if let v = preset.styling.fullBarSeconds  { existing.styling.fullBarSeconds  = v }
                    existing.styling.hidden = preset.styling.hidden || existing.styling.hidden
                    existing.enabled = preset.enabled
                    bySpellId[preset.spellId] = existing
                } else {
                    bySpellId[preset.spellId] = preset
                }
            }
        }
        return bySpellId.values.sorted { lhs, rhs in
            if let a = Int(lhs.spellId), let b = Int(rhs.spellId) { return a < b }
            return lhs.spellId.localizedStandardCompare(rhs.spellId) == .orderedAscending
        }
    }

    private static func apply(key: String, value: String, to preset: inout SpellPreset) {
        switch key {
        case "Bar Color":
            preset.styling.barColor = cssNameToHex(value)
        case "Trough Color":
            preset.styling.troughColor = cssNameToHex(value)
        case "Text Color":
            preset.styling.textColor = cssNameToHex(value)
        case "Bar Height":
            if let n = Double(value) { preset.styling.barHeight = n }
        case "Font Size":
            if let n = Double(value) { preset.styling.fontSize = n }
        case "Full Bar":
            // timers.lic stores Full Bar in *minutes*; our internal
            // field is `fullBarSeconds`, so multiply on the way in.
            if let n = Int(value) { preset.styling.fullBarSeconds = n * 60 }
        case "Text Display":
            preset.displayName = value
        case "Hide Bar":
            preset.styling.hidden = value.lowercased() == "yes"
        default:
            break
        }
    }

    /// Resolves a CSS3 named colour or hex string to a `#RRGGBB` value
    /// suitable for `SpellPreset.{barColor,troughColor,textColor}`.
    /// Returns nil for unrecognised values so the caller can leave the
    /// field as "inherit default" rather than apply a bad colour.
    static func cssNameToHex(_ raw: String) -> String? {
        CSSColors.resolve(raw)
    }

}
