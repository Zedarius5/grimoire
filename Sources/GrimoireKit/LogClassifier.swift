import Foundation

/// Categories a logged game line can fall into, for the log viewer's
/// show/hide toggles. The Lich logs carry no stream-routing tags, so
/// this is heuristic pattern-matching rather than authoritative.
public enum LogCategory: String, CaseIterable, Sendable {
    case thoughts
    case experience
    case info
    case resource
    case songs
    case logon
    case death
    case disk
    case stance
    case commandError
    case exits
    case room
    case combat
    case script
    case game

    /// Human label for the toggle UI.
    public var label: String {
        switch self {
        case .thoughts:     return "Thoughts"
        case .experience:   return "Experience"
        case .info:         return "INFO"
        case .resource:     return "Resource"
        case .songs:        return "Songs"
        case .logon:        return "Logon/off"
        case .death:        return "Death"
        case .disk:         return "Disk"
        case .stance:       return "Stance"
        case .commandError: return "Cmd errors"
        case .exits:        return "Exits"
        case .room:         return "Room desc"
        case .combat:       return "Combat mech"
        case .script:       return "Script"
        case .game:         return "Game"
        }
    }
}

/// Classifies a single log line into a `LogCategory` by shape. Pure and
/// order-sensitive: first matching rule wins. `.room` (room descriptions)
/// is NOT decided here — it needs surrounding context, so `LogParser`
/// applies it as a second pass.
public enum LogClassifier {

    // `--- …` (Lich lifecycle) and `[name]…` script output: status
    // (`[name: …]`), command echoes (`[go2]>west`), and progress
    // (`[go2 ETA: …]`). Lowercase script name only, so uppercase room
    // titles (`[Abbey, Courtyard]`) and channels (`[General]`) don't match.
    private static let scriptDashPrefix = "--- "
    private static let scriptBracket = regex(#"^\s*\[[a-z][\w-]*[\]:\s]"#)
    private static let thoughtChannel = regex(#"^\[[^\]]+\]\s+\S.*?:\s"#)

    private static let infoStat = regex(#"\((?:STR|CON|DEX|AGI|DIS|AUR|LOG|INT|WIS|INF)\)"#)
    private static let infoHeader = regex(#"^\s*Level:\s.*Fame:|Name:.*Race:.*Profession:"#)

    private static let expLabels = [
        "Experience:", "Field Exp:", "Ascension Exp:", "Total Exp:",
        "Long-Term Exp:", "Death's Sting:", "Deeds:",
        "PTPs/MTPs:", "Exp to next TP:", "Exp to next ATP:", "Exp until lvl:", "ATPs:"
    ]
    private static let expInline = regex(#"\bExp:\s*[\d,]+"#)
    // Folded into Experience: mind-saturation warnings and the Wisdom of
    // the Ages buff readout.
    private static let expExtra = regex(#"mind is .*saturated|imperative that you rest|Wisdom of the Ages"#)

    private static let resourceVitals = regex(#"^\s*Health:\s*[\d,]+/[\d,]+"#)
    private static let resourceLine = regex(#"^\s*(?:Suffused Necrotic Energy|Necrotic Energy|Covert Arts Charges|Accumulated Shadow Essence|Mana|Stamina|Spirit):\s*[\d,]+"#)

    // Bard medley spam: the "currently singing" list (spell-id lines that
    // name a Song) plus the medley/renewal prose.
    private static let songsList = regex(#"^\s*\(\d+\)\s.*\bSong\b"#)
    private static let songsProse = regex(#"currently singing|song magic remains strong|your medley (?:has recently renewed|renews)|before your medley"#, [.caseInsensitive])

    private static let stance = regex(#"^You are now in an? \w+ stance\."#)

    // Typos / object-not-found / rephrase prompts.
    private static let cmdError = regex(#"^I could not find what you were referring to\.$|^What were you (?:referring|trying)\b|^Please rephrase that command\.$|^Sorry, I could not find that verb\.$"#)

    private static let disk = regex(#"^Your disk arrives"#)
    private static let exits = regex(#"^\s*Obvious (?:paths|exits):"#)

    // Combat resolution mechanics (kept visible by default; toggle hides).
    private static let combat = regex(#"^AS: [+\-]|^CS: [+\-]|^Roundtime:\s|^Cast Roundtime\s|^\.\.\.wait \d+ seconds|^\[SMR result:"#)

    // Logon/logoff and death broadcasts, matched by catalog content (the
    // " * " prefix is overloaded). id 0 = logon, id 1 = death. Built once,
    // then only read.
    nonisolated(unsafe) private static let broadcastMatcher: AhoCorasick = {
        let ac = AhoCorasick()
        for p in LogPhraseCatalog.logon { ac.add(p.lowercased(), id: 0) }
        for p in LogPhraseCatalog.death { ac.add(p.lowercased(), id: 1) }
        ac.build()
        return ac
    }()

    public static func category(of line: String) -> LogCategory {
        if line.hasPrefix(scriptDashPrefix) || matches(scriptBracket, line) { return .script }
        if matches(thoughtChannel, line) { return .thoughts }
        let broadcast = broadcastMatcher.search(line.lowercased())
        if broadcast.contains(1) { return .death }
        if broadcast.contains(0) { return .logon }
        if matches(songsList, line) || matches(songsProse, line) { return .songs }
        if matches(resourceVitals, line) || matches(resourceLine, line) { return .resource }
        if expLabels.contains(where: line.contains) || matches(expInline, line) || matches(expExtra, line) {
            return .experience
        }
        if matches(infoHeader, line) || matches(infoStat, line) { return .info }
        if matches(stance, line) { return .stance }
        if matches(cmdError, line) { return .commandError }
        if matches(disk, line) { return .disk }
        if matches(exits, line) { return .exits }
        if matches(combat, line) { return .combat }
        return .game
    }

    /// True when `line` is a bracketed room title, e.g. `[Abbey, Courtyard]`
    /// — used by `LogParser` to start a room-description block. (Title-case
    /// bracket on its own line; lowercase brackets are script output.)
    static let roomTitle = regex(#"^\s*\[[A-Z][^\]]*\]\s*$"#)

    /// True when `line` ends a room-description block (the listing that
    /// follows the prose), so `LogParser` stops relabeling.
    static let roomDescEnd = regex(#"^(?:You also see|Also here|Also visible|Also in)"#)

    static func matchesRoomTitle(_ s: String) -> Bool { matches(roomTitle, s) }
    static func matchesRoomDescEnd(_ s: String) -> Bool { matches(roomDescEnd, s) }

    // MARK: - regex helpers (compiled once)

    private static func regex(_ pattern: String, _ opts: NSRegularExpression.Options = []) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: opts)
    }

    private static func matches(_ re: NSRegularExpression, _ s: String) -> Bool {
        re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
}
