import Testing
import Foundation
@testable import GrimoireKit

@Suite("LichLocation")
struct LichLocationTests {

    @Test("isValid is true only when lich.rbw is present")
    func isValidChecksLauncher() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("lich-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }

        #expect(LichLocation.isValid(dir.path) == false)
        FileManager.default.createFile(
            atPath: dir.appendingPathComponent("lich.rbw").path, contents: Data()
        )
        #expect(LichLocation.isValid(dir.path) == true)
    }

    @Test("resolve: a still-valid stored override wins")
    func resolveStoredWins() {
        let valid: Set<String> = ["/stored", "/c1", "/c2"]
        let r = LichLocation.resolve(stored: "/stored",
                                     candidates: ["/c1", "/c2"],
                                     isValid: { valid.contains($0) })
        #expect(r == "/stored")
    }

    @Test("resolve: an invalid stored override falls through to the first valid candidate")
    func resolveFallThrough() {
        let valid: Set<String> = ["/c2"]   // stored + c1 are invalid
        let r = LichLocation.resolve(stored: "/stored",
                                     candidates: ["/c1", "/c2"],
                                     isValid: { valid.contains($0) })
        #expect(r == "/c2")
    }

    @Test("resolve: candidate order is respected")
    func resolveOrder() {
        let valid: Set<String> = ["/c1", "/c2"]
        let r = LichLocation.resolve(stored: nil,
                                     candidates: ["/c1", "/c2"],
                                     isValid: { valid.contains($0) })
        #expect(r == "/c1")
    }

    @Test("resolve: nil when nothing is valid")
    func resolveNone() {
        let r = LichLocation.resolve(stored: "/stored",
                                     candidates: ["/c1"],
                                     isValid: { _ in false })
        #expect(r == nil)
    }

    @Test("derived paths build under the root")
    func derivedPaths() {
        #expect(LichLocation.launcher(in: "/L") == "/L/lich.rbw")
        #expect(LichLocation.effectList(in: "/L") == "/L/data/effect-list.xml")
        #expect(LichLocation.logsDir(in: "/L") == "/L/logs")
    }
}
