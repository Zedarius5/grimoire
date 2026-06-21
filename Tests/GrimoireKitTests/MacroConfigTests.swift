import Testing
import Foundation
@testable import GrimoireKit

/// Cover the id-based, guarded mutation API: a deferred `.onDisappear` flush
/// can fire after its set was deleted or reordered, so mutations must resolve
/// by stable id (not a captured array index) to avoid crashing or writing
/// onto the wrong set.
@Suite("MacroConfig mutations")
struct MacroConfigTests {

    @Test("committing to a just-deleted set is a safe no-op (the crash scenario)")
    func commitToDeletedSetIsNoOp() {
        let b = MacroBinding(id: UUID(), key: "F1", action: "stance off")
        var cfg = MacroConfig(sets: [
            MacroSet(id: 0, name: "Default"),
            MacroSet(id: 5, name: "Hunting", bindings: [b]),
        ])
        // User deletes the selected set (id 5).
        cfg.sets.removeAll { $0.id == 5 }
        // Deferred flushes targeting the deleted set must be harmless no-ops.
        cfg.renameSet(id: 5, to: "STALE")
        cfg.updateBinding(inSet: 5, to: MacroBinding(id: b.id, key: "F1", action: "STALE"))
        cfg.removeBinding(fromSet: 5, bindingId: b.id)

        #expect(cfg.sets.count == 1)
        #expect(cfg.sets[0].id == 0)
        #expect(cfg.sets[0].name == "Default")   // untouched
    }

    @Test("rename/update hit the right set by id after another set is removed")
    func idBasedSurvivesReorder() {
        let b = MacroBinding(id: UUID(), key: "F2", action: "old")
        var cfg = MacroConfig(sets: [
            MacroSet(id: 0, name: "Default"),
            MacroSet(id: 5, name: "Hunting"),
            MacroSet(id: 9, name: "Town", bindings: [b]),
        ])
        // Removing id 5 shifts id 9 from index 2 -> 1. An index-based commit
        // would now land on the wrong set; an id-based one must not.
        cfg.sets.removeAll { $0.id == 5 }
        cfg.renameSet(id: 9, to: "Town2")
        cfg.updateBinding(inSet: 9, to: MacroBinding(id: b.id, key: "F2", action: "new"))

        let town = cfg.sets.first { $0.id == 9 }
        #expect(town?.name == "Town2")
        #expect(town?.bindings.first?.action == "new")
        #expect(cfg.sets.first { $0.id == 0 }?.name == "Default")   // not corrupted
    }

    @Test("add / remove binding by set id; missing set is a no-op")
    func addRemoveBindingById() {
        var cfg = MacroConfig(sets: [MacroSet(id: 0, name: "Default")])

        let newId = cfg.addBinding(toSet: 0, binding: MacroBinding(key: "F1", action: "x"))
        #expect(newId != nil)
        #expect(cfg.sets[0].bindings.count == 1)

        cfg.removeBinding(fromSet: 0, bindingId: newId!)
        #expect(cfg.sets[0].bindings.isEmpty)

        // Operations on a nonexistent set are no-ops, never crashes.
        #expect(cfg.addBinding(toSet: 99, binding: MacroBinding(key: "F2", action: "y")) == nil)
        cfg.removeBinding(fromSet: 99, bindingId: UUID())
        cfg.renameSet(id: 99, to: "ghost")
        #expect(cfg.sets.count == 1)
    }

    @Test("updateBinding only rewrites when the binding actually changed")
    func updateBindingSkipsNoOp() {
        let b = MacroBinding(id: UUID(), key: "F1", action: "a")
        var cfg = MacroConfig(sets: [MacroSet(id: 0, name: "Default", bindings: [b])])
        cfg.updateBinding(inSet: 0, to: b)            // identical -> no change
        #expect(cfg.sets[0].bindings == [b])
        cfg.updateBinding(inSet: 0, to: MacroBinding(id: b.id, key: "F1", action: "b"))
        #expect(cfg.sets[0].bindings.first?.action == "b")
    }
}
