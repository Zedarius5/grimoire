import Foundation

/// "Which build am I running?" helper. Composes a title-bar label
/// from the current git short SHA (read from `.git/HEAD` near the
/// executable) and the executable's modification time, so the user
/// can speak the same `commit-hash` language as the repo AND spot
/// a "SHA shows the new pull but I haven't rebuilt yet" mismatch
/// (the timestamp would be older than the latest commit's date).
///
/// Cached because none of this can change at runtime and the syscalls
/// shouldn't repeat per body re-eval.
enum BuildInfo {

    static let label: String = computeLabel()

    private static func computeLabel() -> String {
        var parts: [String] = []
        if let sha = embeddedGitSHA() ?? gitShortSHA() {
            parts.append(sha)
        }
        if let stamp = buildTimestamp() { parts.append(stamp) }
        return parts.isEmpty ? "build unknown" : parts.joined(separator: " · ")
    }

    /// Build-time SHA embedded in Info.plist by the `build-app.sh`
    /// bundling script. Available in proper .app bundles; nil for
    /// raw `swift build` runs from `.build/`. Preferred over the
    /// .git walk-up because it survives the .app being moved out of
    /// the build tree (e.g., copied to /Applications).
    private static func embeddedGitSHA() -> String? {
        guard let sha = Bundle.main.object(forInfoDictionaryKey: "GrimoireGitSHA") as? String,
              !sha.isEmpty,
              sha != "unknown"
        else { return nil }
        return sha
    }

    private static func buildTimestamp() -> String? {
        guard let path = Bundle.main.executablePath,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date
        else { return nil }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f.string(from: modDate)
    }

    /// Walks up from the executable looking for a `.git` directory,
    /// then resolves HEAD to a short SHA. Returns nil for distributed
    /// builds (no .git in scope) -- caller falls back to timestamp.
    private static func gitShortSHA() -> String? {
        guard let exec = Bundle.main.executableURL else { return nil }
        var dir = exec.deletingLastPathComponent()
        for _ in 0..<10 {
            let candidate = dir.appendingPathComponent(".git")
            if FileManager.default.fileExists(atPath: candidate.path) {
                return resolveHead(in: candidate)
            }
            let parent = dir.deletingLastPathComponent()
            if parent == dir { return nil }  // reached filesystem root
            dir = parent
        }
        return nil
    }

    /// Reads `.git/HEAD`. If it's a symbolic ref ("ref: refs/heads/main"),
    /// reads the actual SHA from the referenced file. Otherwise the
    /// HEAD contents IS the SHA (detached state). Packed refs aren't
    /// handled -- uncommon for an active workspace.
    private static func resolveHead(in gitDir: URL) -> String? {
        let headURL = gitDir.appendingPathComponent("HEAD")
        guard let head = try? String(contentsOf: headURL, encoding: .utf8) else { return nil }
        let trimmed = head.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("ref: ") {
            let refPath = String(trimmed.dropFirst("ref: ".count))
            let refURL = gitDir.appendingPathComponent(refPath)
            guard let sha = try? String(contentsOf: refURL, encoding: .utf8) else { return nil }
            return String(sha.trimmingCharacters(in: .whitespacesAndNewlines).prefix(7))
        }
        return String(trimmed.prefix(7))
    }
}
