import Testing
@testable import GrimoireKit

@Suite("LogParser")
struct LogParserTests {

    @Test("renders tags, decodes entities, drops control-only lines")
    func basics() {
        let text = [
            #"<preset id="speech">Exp: </preset>12,078,173              <preset id="speech">Field: </preset>1,593/1,434"#,
            "A grim gigas skald swings at you &amp; misses.",
            #"<prompt time="123">></prompt>"#,           // control-only -> dropped
            "[Abbey, Courtyard]",
        ].joined(separator: "\n")
        let (lines, truncated) = LogParser.parse(text)
        #expect(!truncated)
        let plains = lines.map(\.line.plainText)
        // prompt line dropped
        #expect(!plains.contains(where: { $0.contains(">") && $0.count < 3 }))
        // preset tags stripped to their text content, classified experience
        #expect(lines.contains { $0.category == .experience && $0.line.plainText.contains("Exp:") })
        // entity decoded
        #expect(plains.contains { $0.contains("&") && $0.contains("misses") })
        // room name kept as game
        #expect(lines.contains { $0.category == .game && $0.line.plainText == "[Abbey, Courtyard]" })
    }

    @Test("blank lines produce no output")
    func blanks() {
        let (lines, _) = LogParser.parse("\n\n   \n")
        #expect(lines.allSatisfy { !$0.line.plainText.trimmingCharacters(in: .whitespaces).isEmpty })
    }

    @Test("room descriptions: prose between title and listing → .room")
    func roomDescriptions() {
        let text = [
            "[Abbey, Courtyard]",
            "A wide flagstone courtyard opens before you, its edges softened by moss.",
            "Ivy climbs the weathered stone walls toward a leaden sky.",
            "You also see a stone fountain.",          // ends the desc block
            "Obvious paths: north, south.",
        ].joined(separator: "\n")
        let (lines, _) = LogParser.parse(text)
        func cat(_ needle: String) -> LogCategory? {
            lines.first { $0.line.plainText.contains(needle) }?.category
        }
        #expect(cat("flagstone courtyard") == .room)
        #expect(cat("Ivy climbs") == .room)
        #expect(cat("Abbey, Courtyard") == .game)        // title stays game
        #expect(cat("You also see") == .game)            // listing, not desc
        #expect(cat("Obvious paths") == .exits)
    }

    @Test("cap keeps the most recent lines and flags truncation")
    func cap() {
        let text = (0..<50).map { "line number \($0) of fifty here" }.joined(separator: "\n")
        let (lines, truncated) = LogParser.parse(text, cap: 10)
        #expect(truncated)
        #expect(lines.count == 10)
        #expect(lines.last?.line.plainText == "line number 49 of fifty here")
    }
}
