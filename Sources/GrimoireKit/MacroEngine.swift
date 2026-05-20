import Foundation
import AppKit

/// Runtime macro engine. Holds the imported config, monitors NSEvent.keyDown
/// for matches against the active set (plus the default set as fallback),
/// and dispatches the matched action to either the LichClient (for text
/// commands) or the host UI (for built-in handlers and template fills).
@MainActor
public final class MacroEngine: ObservableObject {

    @Published public var config: MacroConfig = MacroConfig()

    /// Currently-active macro set. Backed by `config.activeSetId` so changes
    /// persist alongside the rest of the macro config (Preferences saves the
    /// whole `MacroConfig` blob).
    public var activeSetId: Int {
        get { config.activeSetId }
        set { config.activeSetId = newValue }
    }

    /// Set by ContentView so the engine can send commands without owning a
    /// reference to the Lich client at init time.
    public weak var client: LichClient?

    /// Called when a built-in token fires (e.g. `{RepeatLast}`, `{PageUp}`).
    public var onBuiltin: (MacroBuiltin) -> Void = { _ in }

    /// Called for `\?` template macros — the engine emits the prefix text up
    /// to (but not including) the `\?`, leaving it to the UI to fill the
    /// input field and place the cursor there.
    public var onTemplateText: (String) -> Void = { _ in }

    private var eventMonitor: Any?

    public init() {}

    // MARK: - Public API

    public func install(_ config: MacroConfig) {
        var merged = config
        // If the incoming config doesn't already remember an active set, fall
        // back to set 0 (Wrayth's default) or the first available.
        if !merged.sets.contains(where: { $0.id == merged.activeSetId }) {
            if merged.sets.contains(where: { $0.id == 0 }) {
                merged.activeSetId = 0
            } else if let firstId = merged.sets.first?.id {
                merged.activeSetId = firstId
            }
        }
        self.config = merged
    }

    public func setActive(setId: Int) {
        config.activeSetId = setId
    }

    public func startMonitoring() {
        guard eventMonitor == nil else { return }
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else { return event }
            if let action = self.match(event) {
                self.execute(action)
                return nil  // consume the event so the TextField doesn't also see it
            }
            return event
        }
    }

    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Matching

    private func match(_ event: NSEvent) -> String? {
        guard let combo = canonicalCombo(for: event) else { return nil }
        // Check active set first.
        if let activeSet = config.sets.first(where: { $0.id == activeSetId }),
           let binding = activeSet.bindings.first(where: { keysEqual($0.key, combo) }) {
            return binding.action
        }
        // Fall back to default set (set 0) for shared shortcuts.
        if activeSetId != 0,
           let defaultSet = config.sets.first(where: { $0.id == 0 }),
           let binding = defaultSet.bindings.first(where: { keysEqual($0.key, combo) }) {
            return binding.action
        }
        return nil
    }

    /// Normalizes Wrayth-style key strings ("Alt-Ctrl-E", "Shift-Page Up") so
    /// they can be compared with what we generate from NSEvent. Lowercases,
    /// strips spaces, sorts modifier tokens alphabetically.
    private func keysEqual(_ a: String, _ b: String) -> Bool {
        normalize(a) == normalize(b)
    }

    private func normalize(_ s: String) -> String {
        let lower = s.lowercased().replacingOccurrences(of: " ", with: "")
        // Split on '-', collect modifiers vs key
        let parts = lower.split(separator: "-").map(String.init)
        guard !parts.isEmpty else { return lower }
        let modifierTokens: Set<String> = ["shift", "ctrl", "control", "alt", "option", "cmd", "command"]
        var mods: [String] = []
        var keyParts: [String] = []
        for p in parts {
            if modifierTokens.contains(p) {
                // Canonicalize alt/option, ctrl/control, cmd/command
                switch p {
                case "option": mods.append("alt")
                case "control": mods.append("ctrl")
                case "command": mods.append("cmd")
                default: mods.append(p)
                }
            } else {
                keyParts.append(p)
            }
        }
        let sortedMods = mods.sorted()
        let key = keyParts.joined(separator: "-")
        return (sortedMods + [key]).joined(separator: "-")
    }

    private func canonicalCombo(for event: NSEvent) -> String? {
        var parts: [String] = []
        let mods = event.modifierFlags
        if mods.contains(.shift)   { parts.append("Shift") }
        if mods.contains(.control) { parts.append("Ctrl") }
        if mods.contains(.option)  { parts.append("Alt") }
        if mods.contains(.command) { parts.append("Cmd") }

        guard let keyName = keyName(for: event) else { return nil }
        parts.append(keyName)
        return parts.joined(separator: "-")
    }

    /// Maps NSEvent's keyCode (and falls back to characters) to a name string
    /// matching Wrayth's XML conventions.
    private func keyName(for event: NSEvent) -> String? {
        let kc = Int(event.keyCode)
        let isKeypad = event.modifierFlags.contains(.numericPad)
        // Function keys
        switch kc {
        case 122: return "F1"
        case 120: return "F2"
        case 99:  return "F3"
        case 118: return "F4"
        case 96:  return "F5"
        case 97:  return "F6"
        case 98:  return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        case 105: return "F13"
        case 107: return "F14"
        case 113: return "F15"
        // Arrows
        case 123: return "LEFT"
        case 124: return "RIGHT"
        case 125: return "DOWN"
        case 126: return "UP"
        // Editing
        case 36:  return "Enter"
        case 76:  return "Keypad Enter"
        case 48:  return "Tab"
        case 49:  return "Space"
        case 51:  return "Backspace"
        case 53:  return "Esc"
        case 117: return "Delete"
        case 116: return "Page Up"
        case 121: return "Page Down"
        case 115: return "Home"
        case 119: return "End"
        case 114: return "Insert"
        // Numeric keypad
        case 82: return isKeypad ? "Keypad 0" : "0"
        case 83: return isKeypad ? "Keypad 1" : "1"
        case 84: return isKeypad ? "Keypad 2" : "2"
        case 85: return isKeypad ? "Keypad 3" : "3"
        case 86: return isKeypad ? "Keypad 4" : "4"
        case 87: return isKeypad ? "Keypad 5" : "5"
        case 88: return isKeypad ? "Keypad 6" : "6"
        case 89: return isKeypad ? "Keypad 7" : "7"
        case 91: return isKeypad ? "Keypad 8" : "8"
        case 92: return isKeypad ? "Keypad 9" : "9"
        case 65: return "Keypad ."
        case 67: return "Keypad *"
        case 69: return "Keypad +"
        case 75: return "Keypad /"
        case 78: return "Keypad -"
        default:
            // Fall back to character (handles letters, digits, punctuation).
            if let chars = event.charactersIgnoringModifiers?.uppercased(),
               !chars.isEmpty, chars.first?.isLetter == true || chars.first?.isNumber == true {
                return chars
            }
            return nil
        }
    }

    // MARK: - Execution

    private func execute(_ action: String) {
        // Built-in token form: {Token} or {Token}arg
        if action.hasPrefix("{"), let close = action.firstIndex(of: "}") {
            let token = String(action[action.index(after: action.startIndex)..<close])
            let rest = String(action[action.index(after: close)...])
            executeBuiltin(token: token, rest: rest)
            return
        }

        // Template fill: contains `\?` somewhere — emit prefix text, let the
        // input field take over.
        if action.contains("\\?") {
            var text = action
            text = text.replacingOccurrences(of: "\\x", with: "")
            if let qRange = text.range(of: "\\?") {
                let prefix = String(text[..<qRange.lowerBound])
                onTemplateText(prefix)
                return
            }
        }

        // Otherwise parse \r-separated commands and send each.
        let commands = parseCommands(action)
        guard let client else { return }
        for cmd in commands where !cmd.isEmpty {
            client.echoLocal("> \(cmd)")
            client.send(cmd)
        }
    }

    private func parseCommands(_ action: String) -> [String] {
        action
            .components(separatedBy: "\\r")
            .map { piece in
                var s = piece
                if s.hasPrefix("\\x") { s = String(s.dropFirst(2)) }
                // Treat any other backslash escapes as literal removal for now.
                return s.trimmingCharacters(in: .whitespaces)
            }
            .filter { !$0.isEmpty }
    }

    private func executeBuiltin(token: String, rest: String) {
        switch token {
        case "RepeatLast":          onBuiltin(.repeatLast)
        case "RepeatSecondToLast":  onBuiltin(.repeatSecondToLast)
        case "ReturnOrRepeatLast":  onBuiltin(.returnOrRepeatLast)
        case "HistoryPrev":         onBuiltin(.historyPrev)
        case "HistoryNext":         onBuiltin(.historyNext)
        case "PauseScript":         onBuiltin(.pauseScript)
        case "BufferTop":           onBuiltin(.bufferTop)
        case "BufferBottom":        onBuiltin(.bufferBottom)
        case "PageUp":              onBuiltin(.pageUp)
        case "PageDown":            onBuiltin(.pageDown)
        case "LineUp":              onBuiltin(.lineUp)
        case "LineDown":            onBuiltin(.lineDown)
        case "SelectAll":           onBuiltin(.selectAll)
        case "Copy":                onBuiltin(.copy)
        case "Cut":                 onBuiltin(.cut)
        case "Paste":               onBuiltin(.paste)
        case "MacroSet":
            if let id = Int(rest.trimmingCharacters(in: .whitespaces)) {
                activeSetId = id
            }
        default:
            // Wrayth-specific dialogs / unsupported tokens — silently ignore.
            break
        }
    }
}
