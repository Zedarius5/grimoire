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
