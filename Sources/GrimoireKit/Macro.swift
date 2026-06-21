import Foundation

/// One key binding within a macro set.
public struct MacroBinding: Codable, Equatable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var key: String       // raw Wrayth key string, e.g. "F1", "Alt-Ctrl-E", "Keypad 1"
    public var action: String    // raw Wrayth action string, may contain \r, \x, \?, {Token}
    public init(id: UUID = UUID(), key: String, action: String) {
        self.id = id
        self.key = key
        self.action = action
    }
}

/// A named macro set (Wrayth supports 10: id 0 = default, 1-9 = user-named).
public struct MacroSet: Codable, Equatable, Identifiable, Sendable {
    public var id: Int
    public var name: String
    public var bindings: [MacroBinding]
    public init(id: Int, name: String, bindings: [MacroBinding] = []) {
        self.id = id
        self.name = name
        self.bindings = bindings
    }
}

public struct MacroConfig: Codable, Equatable, Sendable {
    public var sets: [MacroSet] = []
    public var activeSetId: Int = 0
    public init(sets: [MacroSet] = [], activeSetId: Int = 0) {
        self.sets = sets
        self.activeSetId = activeSetId
    }

    // MARK: - Set/binding mutations (id-keyed, guarded)
    //
    // Resolve the target set by its stable `id` at call time, never by a
    // captured index: the editor's deferred `.onDisappear` flushes can fire
    // after a set is deleted or reordered, so an index-based mutation would
    // crash or write onto the wrong set. Resolving by id + guarding makes a
    // stale flush a harmless no-op.

    /// Renames the set with `id`, if it still exists.
    public mutating func renameSet(id: Int, to name: String) {
        guard let i = sets.firstIndex(where: { $0.id == id }) else { return }
        if sets[i].name != name { sets[i].name = name }
    }

    /// Appends `binding` to the set with `id`; returns its id, or nil if the
    /// set no longer exists.
    @discardableResult
    public mutating func addBinding(toSet id: Int, binding: MacroBinding) -> MacroBinding.ID? {
        guard let i = sets.firstIndex(where: { $0.id == id }) else { return nil }
        sets[i].bindings.append(binding)
        return binding.id
    }

    /// Removes the binding `bindingId` from the set with `id`. No-op if either
    /// is gone.
    public mutating func removeBinding(fromSet id: Int, bindingId: MacroBinding.ID) {
        guard let i = sets.firstIndex(where: { $0.id == id }) else { return }
        sets[i].bindings.removeAll { $0.id == bindingId }
    }

    /// Replaces the binding matching `updated.id` inside the set with `id`,
    /// only when something actually changed. No-op if the set or the binding
    /// no longer exists.
    public mutating func updateBinding(inSet id: Int, to updated: MacroBinding) {
        guard let si = sets.firstIndex(where: { $0.id == id }),
              let bi = sets[si].bindings.firstIndex(where: { $0.id == updated.id })
        else { return }
        if sets[si].bindings[bi] != updated { sets[si].bindings[bi] = updated }
    }
}

/// Built-in macro actions Grimoire knows how to perform itself. Most other
/// Wrayth `{Foo}` tokens (UI dialogs, image toggles, etc.) have no Grimoire
/// equivalent and are ignored.
public enum MacroBuiltin: Equatable, Sendable {
    case repeatLast
    case repeatSecondToLast
    case returnOrRepeatLast
    case historyPrev
    case historyNext
    case pauseScript
    case bufferTop
    case bufferBottom
    case pageUp
    case pageDown
    case lineUp
    case lineDown
    case selectAll
    case copy
    case cut
    case paste
}
