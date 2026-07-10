import Testing
import Foundation
@testable import GrimoireKit

private struct Stub: Named, Equatable, Codable {
    var name: String
    var payload: Int = 0
}

@Suite("NamedSet")
struct NamedSetTests {

    private func set(_ names: [String], active: String? = nil) -> NamedSet<Stub> {
        NamedSet(items: names.map { Stub(name: $0) }, activeName: active)
    }

    @Test("active defaults to first; resolves the active item")
    func activeDefaults() {
        let s = set(["A", "B"])
        #expect(s.activeName == "A")
        #expect(s.active?.name == "A")
    }

    @Test("invalid active falls back to first")
    func invalidActive() {
        let s = set(["A", "B"], active: "ghost")
        #expect(s.activeName == "A")
    }

    @Test("select switches active only to an existing name")
    func select() {
        var s = set(["A", "B"])
        s.select("B"); #expect(s.activeName == "B")
        s.select("nope"); #expect(s.activeName == "B")   // unchanged
    }

    @Test("upsert replaces by name (case-insensitive) and activates")
    func upsert() {
        var s = set(["A", "B"])
        s.upsert(Stub(name: "C", payload: 1))
        #expect(s.items.count == 3)
        #expect(s.activeName == "C")
        s.upsert(Stub(name: "a", payload: 9))            // replaces "A"
        #expect(s.items.count == 3)
        #expect(s.items.first { $0.name.lowercased() == "a" }?.payload == 9)
        #expect(s.activeName == "a")
    }

    @Test("updateActive mutates the active item in place")
    func updateActive() {
        var s = set(["A", "B"], active: "B")
        s.updateActive { $0.payload = 42 }
        #expect(s.active?.payload == 42)
        #expect(s.items.first { $0.name == "A" }?.payload == 0)   // untouched
    }

    @Test("rename updates active item + pointer; no-op on empty or collision")
    func rename() {
        var s = set(["A", "B"], active: "A")
        s.rename(to: "Big")
        #expect(s.activeName == "Big")
        #expect(s.active?.name == "Big")
        s.rename(to: "   ")          // empty -> no-op
        #expect(s.activeName == "Big")
        s.rename(to: "B")            // collides with the other item -> no-op
        #expect(s.activeName == "Big")
    }

    @Test("deleteActive removes + repoints; refuses to delete the last one")
    func deleteActive() {
        var s = set(["A", "B"], active: "A")
        s.deleteActive()
        #expect(s.items.map(\.name) == ["B"])
        #expect(s.activeName == "B")
        s.deleteActive()             // last one -> no-op
        #expect(s.items.map(\.name) == ["B"])
    }

    @Test("round-trips through Codable")
    func codable() throws {
        let s = set(["A", "B"], active: "B")
        let data = try JSONEncoder().encode(s)
        let back = try JSONDecoder().decode(NamedSet<Stub>.self, from: data)
        #expect(back == s)
    }
}
