import Testing
import Foundation
@testable import GrimoireKit

@Suite("MacroEngine.tokenize")
@MainActor
struct MacroEngineTokenizeTests {

    @Test("Plain text -> single .send")
    func plainText() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look")
        #expect(segments == [.send("look")])
    }

    @Test("\\r delimits sends")
    func cariageReturnSplits() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\rsmile")
        #expect(segments == [.send("look"), .send("smile")])
    }

    @Test("Trailing \\r is fine")
    func trailingCarriageReturn() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\r")
        #expect(segments == [.send("look")])
    }

    @Test("Leading \\r is fine")
    func leadingCarriageReturn() {
        let engine = MacroEngine()
        let segments = engine.tokenize("\\rlook")
        #expect(segments == [.send("look")])
    }

    @Test("\\p between sends emits a 1s pause")
    func pauseDefaultsTo1Second() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\r\\p\\rsmile")
        #expect(segments == [.send("look"), .pause(1.0), .send("smile")])
    }

    @Test("\\pN pauses N seconds")
    func pauseWithExplicitSeconds() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\r\\p3\\rsmile")
        #expect(segments == [.send("look"), .pause(3.0), .send("smile")])
    }

    @Test("Pause floor of 0.05s prevents zero-delay loops")
    func pauseHasFloor() {
        let engine = MacroEngine()
        let segments = engine.tokenize("a\\r\\p0\\rb")
        guard segments.count == 3, case .pause(let secs) = segments[1] else {
            Issue.record("Expected pause in middle position")
            return
        }
        #expect(secs >= 0.05)
    }

    @Test("\\x at start of a piece is stripped")
    func clearInputIsStripped() {
        let engine = MacroEngine()
        let segments = engine.tokenize("\\xlook")
        #expect(segments == [.send("look")])
    }

    @Test("Empty pieces are skipped")
    func emptyPiecesSkipped() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\r\\r\\rsmile")
        #expect(segments == [.send("look"), .send("smile")])
    }

    @Test("Whitespace-only pieces are skipped")
    func whitespaceOnlyPiecesSkipped() {
        let engine = MacroEngine()
        let segments = engine.tokenize("look\\r   \\rsmile")
        #expect(segments == [.send("look"), .send("smile")])
    }
}

@Suite("MacroEngine.canonicalKey")
@MainActor
struct MacroEngineCanonicalKeyTests {

    // NSEvent is annoying to synthesize in tests (requires the AppKit
    // event system); we can't directly cover canonicalKey here. The
    // string normalization that compares user-typed bindings to
    // canonical keys is reachable via the public `MacroEngine.install`
    // + `setActive` round-trip if needed -- left as a sketch for
    // future expansion.
}
