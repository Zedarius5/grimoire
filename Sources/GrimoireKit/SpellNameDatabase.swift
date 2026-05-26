import Foundation

/// Reads Lich's cached effect/spell database (`~/Gemstone/data/effect-list.xml`)
/// to translate Stormfront spell numbers like `709` into human-readable
/// names like `Grasp of the Dead`. Same data source the Lich runtime
/// uses for `Spell[709].name`, so any spell the user has seen in their
/// Lich install is automatically named in Grimoire — even when the game
/// isn't currently running.
///
/// Re-reads at startup; if Lich refreshes the cache while Grimoire is
/// open the user can call `reload()` (e.g. from a future "Refresh"
/// button) to pick up additions.
public final class SpellNameDatabase: @unchecked Sendable {

    /// Process-wide instance. Both `LichClient`'s stream parser (which
    /// *records* observed names) and `SpellPresetStore` (which *reads*
    /// them for editor labels) point at the same object so a freshly
    /// seen cooldown name shows up in the editor without a restart.
    public static let shared = SpellNameDatabase()

    /// Default path Lich writes to. Override for tests or non-standard
    /// installs.
    public static let defaultPath: String = ("~/Gemstone/data/effect-list.xml" as NSString)
        .expandingTildeInPath

    private let lock = NSLock()
    private var byId: [String: String] = [:]
    /// Names Grimoire has seen for ids that aren't in Lich's XML at all
    /// (7-10 digit cooldown / ability ids). Persisted via `Preferences`.
    /// Kept separate from `byId` so an XML reload doesn't drop them.
    private var observedById: [String: String] = [:]
    private let path: String
    /// `false` for test instances built with a custom path — we don't
    /// want unit tests polluting the user's persisted observed cache.
    private let persistsObserved: Bool
    /// Coalesces `record(id:name:)` writes so we don't synchronously
    /// hit `UserDefaults` (and the notification post it triggers) on
    /// every parsed `<progressBar>`. Sampling showed that path
    /// dominated the LichClient parsing thread once the user had
    /// played long enough to start seeing new cooldown ids.
    private var persistPending = false
    private let persistDelay: TimeInterval = 2.0
    private let persistQueue = DispatchQueue(
        label: "com.zedarius.Grimoire.SpellNameDatabase.persist",
        qos: .utility
    )

    public init(path: String = SpellNameDatabase.defaultPath) {
        self.path = path
        self.persistsObserved = (path == SpellNameDatabase.defaultPath)
        if persistsObserved {
            self.observedById = Preferences.loadObservedSpellNames()
        }
        reload()
    }

    /// Re-parses the on-disk effect-list. Cheap: ~230KB, parsed once
    /// into a dictionary lookup. Safe to call on app launch; no-ops
    /// when the file is absent (silently — Grimoire shouldn't fight a
    /// non-Lich install).
    public func reload() {
        guard FileManager.default.fileExists(atPath: path),
              let parser = XMLParser(contentsOf: URL(fileURLWithPath: path)) else {
            return
        }
        let delegate = ParseDelegate()
        parser.delegate = delegate
        guard parser.parse() else { return }
        lock.lock()
        byId = delegate.byId
        lock.unlock()
    }

    /// Look up a spell name by its server-supplied id. Returns nil only
    /// when neither the Lich XML nor the observed cache has a record.
    /// XML wins on collision (canonical spelling for 3-4 digit spells);
    /// the observed cache fills in everything else.
    public func name(forId id: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        if let v = byId[id] { return v }
        return observedById[id]
    }

    /// Record a name Grimoire just saw for `id` in a live `<progressBar>`.
    /// Idempotent — only schedules a persist when the value actually
    /// changed. Persistence runs on a background queue with a
    /// debounce window so a burst of progressBar updates coalesces
    /// into a single write to `UserDefaults` instead of one per
    /// parsed tag (which was costing half the parser's CPU because
    /// each write synchronously posted `NSUserDefaultsDidChange`).
    /// Refuses to record when name equals id (the server sometimes
    /// echoes the id as text for unnamed timers).
    public func record(id: String, name: String) {
        guard !id.isEmpty, !name.isEmpty, id != name else { return }
        lock.lock()
        let changed = (observedById[id] != name)
        if changed { observedById[id] = name }
        let shouldSchedule = changed && persistsObserved && !persistPending
        if shouldSchedule { persistPending = true }
        lock.unlock()
        guard shouldSchedule else { return }
        persistQueue.asyncAfter(deadline: .now() + persistDelay) { [weak self] in
            self?.flushPersist()
        }
    }

    private func flushPersist() {
        lock.lock()
        let snapshot = observedById
        persistPending = false
        lock.unlock()
        Preferences.saveObservedSpellNames(snapshot)
    }

    /// Number of (id, name) pairs currently loaded. Counts the XML cache
    /// plus any observed ids not already covered by XML. Useful as a
    /// quick "is the database populated" signal in the Options popover.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        var seen = Set(byId.keys)
        for id in observedById.keys { seen.insert(id) }
        return seen.count
    }

    // MARK: - XMLParser delegate

    private final class ParseDelegate: NSObject, XMLParserDelegate {
        var byId: [String: String] = [:]

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            // Lich's effect-list only uses `<spell>` for the
            // id-to-name records we care about; everything else
            // (`<duration>`, `<cost>`, etc.) is nested under it and
            // doesn't carry a `number` attribute.
            guard elementName == "spell" else { return }
            if let id = attributeDict["number"], !id.isEmpty,
               let name = attributeDict["name"], !name.isEmpty {
                byId[id] = name
            }
        }
    }
}
