import Foundation

/// Opt-in diagnostic that appends every raw line the game sends to a
/// timestamped file, so stream oddities (a doubled broadcast, a stuck window)
/// can be traced to their exact wire input.
///
/// Off by default. The armed state is persisted, and capture starts the moment
/// a session connects — before the first login/boot line — so early readouts
/// (House messages, MOTD) are caught too. Files land in `<lich>/grimoire_capture`.
public final class RawStreamCapture {
    public static let defaultsKey = "grimoire.debug.rawCapture"

    private let queue = DispatchQueue(label: "grimoire.rawStreamCapture")
    private var handle: FileHandle?

    public init() {}

    /// Whether capture is armed (persisted). Cheap to read per line.
    public static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: defaultsKey)
    }

    /// Persist the armed flag and start/stop right away (so toggling mid-session
    /// takes effect immediately, not just on the next connect).
    public func setEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: Self.defaultsKey)
        if on { restart() } else { stop() }
    }

    /// Begin a fresh capture file for a new session, if armed. Call at connect.
    public func startIfArmed() {
        guard Self.isEnabled else { return }
        restart()
    }

    /// Close the current file and open a new one.
    private func restart() {
        queue.async {
            try? self.handle?.close()
            self.handle = nil
            guard let url = Self.newCaptureURL() else { return }
            FileManager.default.createFile(atPath: url.path, contents: nil)
            self.handle = try? FileHandle(forWritingTo: url)
            if self.handle != nil {
                appLog("RawStreamCapture", "Capturing raw stream to \(url.path)", level: .info)
            }
        }
    }

    public func stop() {
        queue.async {
            try? self.handle?.close()
            self.handle = nil
        }
    }

    /// Append one raw line. Safe to call from the connection's receive queue;
    /// the write is serialized onto the capture queue.
    public func write(_ line: String) {
        queue.async {
            guard let h = self.handle else { return }
            if let data = (line + "\n").data(using: .utf8) {
                try? h.write(contentsOf: data)
            }
        }
    }

    private static func newCaptureURL() -> URL? {
        let base = LichLocation.resolvedRoot()
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Gemstone").path
        let dir = URL(fileURLWithPath: base).appendingPathComponent("grimoire_capture")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let stamp = stampFormatter.string(from: Date())
        return dir.appendingPathComponent("grimoire-raw-\(stamp).log")
    }

    private static let stampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
