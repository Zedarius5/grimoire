import Foundation

/// "Which build am I running?" helper. Reads the modification time of
/// the running executable -- every `swift build` updates the binary,
/// so the timestamp is a reliable proxy for "is this the latest code I
/// just built?" without needing a pre-build script to embed a git SHA.
///
/// Cached because the executable's mtime can't change while the app is
/// running, and `FileManager.attributesOfItem` is a syscall.
enum BuildInfo {

    static let label: String = computeLabel()

    private static func computeLabel() -> String {
        guard let path = Bundle.main.executablePath,
              let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let modDate = attrs[.modificationDate] as? Date
        else {
            return "build unknown"
        }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return "build " + f.string(from: modDate)
    }
}
