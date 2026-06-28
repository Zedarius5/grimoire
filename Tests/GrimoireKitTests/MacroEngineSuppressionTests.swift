import Testing
@testable import GrimoireKit

/// While the macro editor is capturing a key, the runtime engine must NOT fire
/// the matching macro — otherwise pressing a key to bind it leaks the existing
/// macro's command to the game (and the keystroke never reaches the capture
/// field). The set-0 fallback means even a brand-new empty set leaks.
@MainActor
@Suite("MacroEngine key suppression")
struct MacroEngineSuppressionTests {

    private func engine(active: Int, _ sets: [MacroSet]) -> MacroEngine {
        let e = MacroEngine()
        e.install(MacroConfig(sets: sets, activeSetId: active))
        return e
    }

    @Test("a bound key fires normally")
    func firesNormally() {
        let e = engine(active: 0, [MacroSet(id: 0, name: "Default",
            bindings: [MacroBinding(key: "F1", action: "stance off")])])
        #expect(e.actionToFire(forCombo: "F1") == "stance off")
    }

    @Test("no macro fires while the editor is capturing a key (the bug)")
    func suppressedDuringCapture() {
        let e = engine(active: 0, [MacroSet(id: 0, name: "Default",
            bindings: [MacroBinding(key: "F1", action: "stance off")])])
        e.beginKeyCapture()
        #expect(e.actionToFire(forCombo: "F1") == nil)
        e.endKeyCapture()
        #expect(e.actionToFire(forCombo: "F1") == "stance off")
    }

    @Test("a new empty set still leaks via the set-0 fallback — also suppressed during capture")
    func setZeroFallbackSuppressed() {
        let e = engine(active: 5, [
            MacroSet(id: 0, name: "Default", bindings: [MacroBinding(key: "F2", action: "stomp")]),
            MacroSet(id: 5, name: "New", bindings: []),
        ])
        #expect(e.actionToFire(forCombo: "F2") == "stomp")   // set-0 fallback fires
        e.beginKeyCapture()
        #expect(e.actionToFire(forCombo: "F2") == nil)       // suppressed (this was the leak)
        e.endKeyCapture()
    }

    @Test("nested capture begin/end stays balanced")
    func balanced() {
        let e = engine(active: 0, [MacroSet(id: 0, name: "D",
            bindings: [MacroBinding(key: "F1", action: "x")])])
        e.beginKeyCapture(); e.beginKeyCapture()
        #expect(e.actionToFire(forCombo: "F1") == nil)
        e.endKeyCapture()
        #expect(e.actionToFire(forCombo: "F1") == nil)   // still suppressed (depth 1)
        e.endKeyCapture()
        #expect(e.actionToFire(forCombo: "F1") == "x")   // resumed
    }
}
