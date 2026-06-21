import Foundation
import os

/// Writes a single line to both `os.Logger` (visible via Console.app or
/// `log show --predicate 'subsystem == "com.zedarius.Grimoire"'`) AND to
/// `~/Library/Logs/Grimoire.log` (so the user can `tail -f` it from
/// Terminal without dealing with Console filtering).
///
/// Use it from anywhere in the app or framework — non-isolated, safe from
/// any thread, all file I/O serialised on a background queue.
public func appLog(
    _ category: String,
    _ message: String,
    level: OSLogType = .default
) {
    AppLogger.shared.write(category: category, message: message, level: level)
}

private final class AppLogger: @unchecked Sendable {

    static let shared = AppLogger()

    private let logger = Logger(subsystem: "com.zedarius.Grimoire", category: "Grimoire")
    private let queue = DispatchQueue(label: "com.zedarius.Grimoire.AppLog")
    private let logURL: URL

    /// Roll the log over once it passes this size. Keeps one previous
    /// generation (`Grimoire.log.1`), so on-disk usage is bounded at ~2x this
    /// rather than growing without limit.
    private static let maxBytes: UInt64 = 5 * 1024 * 1024

    private static let timestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    init() {
        let lib = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
        let dir = lib.appendingPathComponent("Logs", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.logURL = dir.appendingPathComponent("Grimoire.log")
        // Header at startup so the user can tell distinct sessions apart.
        let header = "\n=== Grimoire session start \(Self.timestamp.string(from: Date())) ===\n"
        queue.async { [logURL] in
            Self.rotateIfNeeded(logURL)
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let h = try? FileHandle(forWritingTo: logURL) {
                    defer { try? h.close() }
                    _ = try? h.seekToEnd()
                    try? h.write(contentsOf: Data(header.utf8))
                }
            } else {
                try? Data(header.utf8).write(to: logURL)
            }
        }
    }

    /// If the log has grown past `maxBytes`, move it aside to
    /// `Grimoire.log.1` (replacing any prior backup) so a fresh, empty
    /// log starts. Runs once per session on the log queue, before the
    /// header write. Cheap: a single stat + rename.
    private static func rotateIfNeeded(_ url: URL) {
        let fm = FileManager.default
        guard let attrs = try? fm.attributesOfItem(atPath: url.path),
              let size = (attrs[.size] as? NSNumber)?.uint64Value,
              size > maxBytes
        else { return }
        let backup = url.appendingPathExtension("1")  // Grimoire.log.1
        try? fm.removeItem(at: backup)
        try? fm.moveItem(at: url, to: backup)
    }

    func write(category: String, message: String, level: OSLogType) {
        logger.log(level: level, "\(category, privacy: .public): \(message, privacy: .public)")
        queue.async { [logURL] in
            let line = "\(Self.timestamp.string(from: Date())) [\(category)] \(message)\n"
            guard let data = line.data(using: .utf8) else { return }
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let h = try? FileHandle(forWritingTo: logURL) {
                    defer { try? h.close() }
                    _ = try? h.seekToEnd()
                    try? h.write(contentsOf: data)
                }
            } else {
                try? data.write(to: logURL)
            }
        }
    }
}
