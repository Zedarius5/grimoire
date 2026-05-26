import Testing
import Foundation
@testable import GrimoireKit

@Suite("SpellNameDatabase")
struct SpellNameDatabaseTests {

    /// Writes a minimal effect-list.xml to a temp path and confirms
    /// the parser pulls (number → name) pairs from `<spell>` tags.
    @Test("parses effect-list entries")
    func parsesEntries() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("effect-list-\(UUID()).xml")
        defer { try? FileManager.default.removeItem(at: tmp) }

        let xml = """
        <?xml version='1.0' ?>
        <list>
           <spell availability='all' name='Spirit Warding I' number='101' type='defense'>
              <duration>120</duration>
           </spell>
           <spell name='Grasp of the Dead' number='709' type='offense'>
              <duration>30</duration>
           </spell>
           <spell number='730' name='Major Sanctuary' type='defense'>
              <duration>1200</duration>
           </spell>
        </list>
        """
        try xml.write(to: tmp, atomically: true, encoding: .utf8)

        let db = SpellNameDatabase(path: tmp.path)
        #expect(db.count == 3)
        #expect(db.name(forId: "101") == "Spirit Warding I")
        #expect(db.name(forId: "709") == "Grasp of the Dead")
        #expect(db.name(forId: "730") == "Major Sanctuary")
        #expect(db.name(forId: "99999") == nil)
    }

    @Test("missing file is silently tolerated")
    func missingFile() {
        let db = SpellNameDatabase(path: "/var/folders/definitely/does/not/exist.xml")
        #expect(db.count == 0)
        #expect(db.name(forId: "709") == nil)
    }
}
