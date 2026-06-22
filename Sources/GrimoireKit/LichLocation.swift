import Foundation

/// Resolves the user's Lich install folder and derives every Lich path from it
/// (launcher, effect-list, logs, the `LICH_DIR` value). Single source of truth
/// so the app isn't tied to one install location.
public enum LichLocation {

    /// Auto-detect candidates, in priority order (tilde-expanded at use). Per
    /// the gswiki Lich install docs the macOS default is `~/Lich5`; `~/Gemstone`
    /// is the location Grimoire historically assumed and existing installs use.
    static let candidatePaths = ["~/Lich5", "~/Gemstone"]

    /// A folder is a Lich install if it contains the `lich.rbw` launcher.
    public static func isValid(_ root: String) -> Bool {
        FileManager.default.fileExists(atPath: launcher(in: root))
    }

    /// Persisted user override (nil if unset).
    public static func storedRoot() -> String? { Preferences.loadLichDir() }
    public static func setRoot(_ path: String) { Preferences.saveLichDir(path) }

    /// First candidate present on disk, or nil.
    public static func autodetect() -> String? {
        expandedCandidates().first(where: isValid)
    }

    /// The Lich root to use: a still-valid stored override, else the first
    /// valid candidate, else nil (the caller should prompt the user to locate
    /// their install).
    public static func resolvedRoot() -> String? {
        resolve(stored: storedRoot(), candidates: expandedCandidates(), isValid: isValid)
    }

    /// Pure precedence logic, injectable for tests: stored-if-valid → first
    /// valid candidate → nil.
    static func resolve(stored: String?, candidates: [String], isValid: (String) -> Bool) -> String? {
        if let stored, isValid(stored) { return stored }
        return candidates.first(where: isValid)
    }

    private static func expandedCandidates() -> [String] {
        candidatePaths.map { ($0 as NSString).expandingTildeInPath }
    }

    // Derived paths from a known-good root.
    public static func launcher(in root: String) -> String { "\(root)/lich.rbw" }
    public static func effectList(in root: String) -> String { "\(root)/data/effect-list.xml" }
    public static func logsDir(in root: String) -> String { "\(root)/logs" }
}
