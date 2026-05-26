import Foundation

/// The four Stormfront dialogs that Grimoire surfaces as timer bars.
/// Used to scope spell presets — `Buffs` and `Active Spells` are
/// commonly configured very differently from `Cooldowns` (different
/// names, different urgency colours, etc.), so each window holds its
/// own default styling + groups + per-spell overrides.
public enum DialogWindow: String, Codable, CaseIterable, Identifiable, Sendable {
    case activeSpells = "Active Spells"
    case buffs        = "Buffs"
    case cooldowns    = "Cooldowns"
    case debuffs      = "Debuffs"

    public var id: String { rawValue }

    /// Display label and Stormfront dialog id are the same string —
    /// the server's `<openDialog id='Buffs'/>` etc. matches this.
    public var displayName: String { rawValue }
    public var dialogId: String   { rawValue }
}

/// The visual overrides any one layer (per-spell, per-group, per-window
/// default) can carry. `nil` means "inherit from the next layer down".
public struct SpellStyling: Codable, Equatable, Hashable, Sendable {
    public var barColor: String?
    public var troughColor: String?
    public var textColor: String?
    public var fontSize: Double?
    public var barHeight: Double?
    public var fullBarSeconds: Int?
    /// Layer-level hide. ORed across layers at render time, so any
    /// active layer with `hidden = true` skips the bar.
    public var hidden: Bool

    public init(
        barColor: String? = nil,
        troughColor: String? = nil,
        textColor: String? = nil,
        fontSize: Double? = nil,
        barHeight: Double? = nil,
        fullBarSeconds: Int? = nil,
        hidden: Bool = false
    ) {
        self.barColor       = barColor
        self.troughColor    = troughColor
        self.textColor      = textColor
        self.fontSize       = fontSize
        self.barHeight      = barHeight
        self.fullBarSeconds = fullBarSeconds
        self.hidden         = hidden
    }

    /// True when this layer contributes nothing to the render — the
    /// resolution path can skip allocating a styled copy.
    public var hasAnyOverride: Bool {
        barColor != nil
            || troughColor != nil
            || textColor != nil
            || fontSize != nil
            || barHeight != nil
            || fullBarSeconds != nil
            || hidden
    }
}

/// Per-spell visual override. Optionally belongs to a `SpellGroup`,
/// in which case the group's styling fills in for any field this
/// preset leaves nil.
public struct SpellPreset: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    /// The server's `<progressBar id="…">` key.
    public var spellId: String
    /// Optional group membership. When set, the group's styling
    /// applies as a fallback for fields this preset doesn't override.
    public var groupId: UUID?
    /// Rename for the displayed bar text. Per-spell only — groups and
    /// default styling can't rename, since one name shouldn't blanket
    /// every member of a group.
    public var displayName: String?
    public var styling: SpellStyling
    /// Master toggle. When false, this preset's overrides are skipped
    /// without losing the saved values — group + default still apply.
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        spellId: String,
        groupId: UUID? = nil,
        displayName: String? = nil,
        styling: SpellStyling = SpellStyling(),
        enabled: Bool = true
    ) {
        self.id          = id
        self.spellId     = spellId
        self.groupId     = groupId
        self.displayName = displayName
        self.styling     = styling
        self.enabled     = enabled
    }
}

/// A named bundle of styling applied to multiple spells. Designed for
/// cases like "all Guardians of Sunfist sigils share one look" — edit
/// the group once, every member inherits.
public struct SpellGroup: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    /// User-facing label (e.g. "Sunfist Sigils"). Doesn't rename
    /// member bars — just identifies the group in the editor.
    public var name: String
    public var styling: SpellStyling
    /// Master toggle. When false, members skip the group layer and
    /// fall straight through to the window default.
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        styling: SpellStyling = SpellStyling(),
        enabled: Bool = true
    ) {
        self.id      = id
        self.name    = name
        self.styling = styling
        self.enabled = enabled
    }
}

/// Per-window configuration: a default-styling layer + zero or more
/// groups + the individual spell presets. The four windows are
/// independent — same spell id in `Buffs` vs `Cooldowns` carries
/// completely separate config.
public struct WindowConfig: Codable, Equatable, Sendable {
    public var window: DialogWindow
    public var defaultStyling: SpellStyling
    public var groups: [SpellGroup]
    public var presets: [SpellPreset]

    public init(
        window: DialogWindow,
        defaultStyling: SpellStyling = SpellStyling(),
        groups: [SpellGroup] = [],
        presets: [SpellPreset] = []
    ) {
        self.window         = window
        self.defaultStyling = defaultStyling
        self.groups         = groups
        self.presets        = presets
    }
}

/// Top-level container. Always carries one `WindowConfig` per
/// `DialogWindow` case — the editor uses `init()` to pre-populate
/// empty windows so the UI never has to handle a missing tab.
public struct SpellPresetConfig: Codable, Equatable, Sendable {
    public var windows: [WindowConfig]

    public init(windows: [WindowConfig] = DialogWindow.allCases.map { WindowConfig(window: $0) }) {
        self.windows = windows
    }

    /// Convenience accessor that always returns a config — synthesizes
    /// an empty one if a v1-migrated config is missing a window for
    /// whatever reason.
    public func config(for window: DialogWindow) -> WindowConfig {
        windows.first(where: { $0.window == window }) ?? WindowConfig(window: window)
    }

    public mutating func update(_ window: WindowConfig) {
        if let idx = windows.firstIndex(where: { $0.window == window.window }) {
            windows[idx] = window
        } else {
            windows.append(window)
        }
    }
}

// MARK: - Resolution

/// The fully-resolved visual state for one progress bar, after spell →
/// group → window-default fall-through. Render code consumes this
/// instead of having to chain ?? across every field at the call site.
public struct ResolvedSpellStyling: Equatable, Sendable {
    public var displayName: String?
    public var barColor: String?
    public var troughColor: String?
    public var textColor: String?
    public var fontSize: Double?
    public var barHeight: Double?
    public var fullBarSeconds: Int?
    /// ORed across every active layer — any layer that wants the bar
    /// hidden wins.
    public var hidden: Bool

    public init(
        displayName: String? = nil,
        barColor: String? = nil,
        troughColor: String? = nil,
        textColor: String? = nil,
        fontSize: Double? = nil,
        barHeight: Double? = nil,
        fullBarSeconds: Int? = nil,
        hidden: Bool = false
    ) {
        self.displayName    = displayName
        self.barColor       = barColor
        self.troughColor    = troughColor
        self.textColor      = textColor
        self.fontSize       = fontSize
        self.barHeight      = barHeight
        self.fullBarSeconds = fullBarSeconds
        self.hidden         = hidden
    }

    public static let empty = ResolvedSpellStyling()
}

extension WindowConfig {
    /// Resolves the visual state for a given spell id within this
    /// window. Layer order: per-spell preset → group → window
    /// default. Each layer is only consulted when `enabled = true`.
    public func resolve(spellId: String) -> ResolvedSpellStyling {
        let preset = presets.first(where: { $0.spellId == spellId })
        let group: SpellGroup? = {
            guard let gid = preset?.groupId else { return nil }
            return groups.first(where: { $0.id == gid })
        }()

        let spellLayer:   SpellStyling? = (preset?.enabled == true) ? preset?.styling : nil
        let groupLayer:   SpellStyling? = (group?.enabled  == true) ? group?.styling  : nil
        let defaultLayer: SpellStyling  = defaultStyling

        func field<T>(_ kp: KeyPath<SpellStyling, T?>) -> T? {
            spellLayer?[keyPath: kp]
                ?? groupLayer?[keyPath: kp]
                ?? defaultLayer[keyPath: kp]
        }

        let hidden = (spellLayer?.hidden ?? false)
            || (groupLayer?.hidden ?? false)
            || defaultLayer.hidden

        return ResolvedSpellStyling(
            displayName:    (preset?.enabled == true) ? preset?.displayName : nil,
            barColor:       field(\.barColor),
            troughColor:    field(\.troughColor),
            textColor:      field(\.textColor),
            fontSize:       field(\.fontSize),
            barHeight:      field(\.barHeight),
            fullBarSeconds: field(\.fullBarSeconds),
            hidden:         hidden
        )
    }
}

// MARK: - v1 migration

/// Snapshot of the pre-window-scoped config shape. Lives only so the
/// store can read old data, lift it into the v2 layout, and re-save.
public struct LegacySpellPresetConfigV1: Codable, Sendable {
    public struct Preset: Codable, Sendable {
        public var id: UUID
        public var spellId: String
        public var displayName: String?
        public var barColor: String?
        public var troughColor: String?
        public var textColor: String?
        public var fontSize: Double?
        public var barHeight: Double?
        public var fullBarSeconds: Int?
        public var hidden: Bool
        public var enabled: Bool
    }
    public var presets: [Preset]
}

extension SpellPresetConfig {
    /// Lifts a v1 flat-list config into v2 by dropping every preset
    /// into the `Buffs` window. Buffs is the closest analog for the
    /// timers.lic "Main" window, which is where the majority of v1
    /// spell entries originated.
    public static func migrating(_ v1: LegacySpellPresetConfigV1) -> SpellPresetConfig {
        let buffsPresets: [SpellPreset] = v1.presets.map { p in
            SpellPreset(
                id: p.id,
                spellId: p.spellId,
                groupId: nil,
                displayName: p.displayName,
                styling: SpellStyling(
                    barColor: p.barColor,
                    troughColor: p.troughColor,
                    textColor: p.textColor,
                    fontSize: p.fontSize,
                    barHeight: p.barHeight,
                    fullBarSeconds: p.fullBarSeconds,
                    hidden: p.hidden
                ),
                enabled: p.enabled
            )
        }
        var config = SpellPresetConfig()
        config.update(WindowConfig(window: .buffs, presets: buffsPresets))
        return config
    }
}
