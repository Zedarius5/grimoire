import Foundation

/// Game-server credentials returned by SGE auth (host, port, character key).
public struct GameCredentials: Equatable, Sendable {
    public let host: String
    public let port: UInt16
    public let key: String

    public init(host: String, port: UInt16, key: String) {
        self.host = host
        self.port = port
        self.key = key
    }
}

public enum SgeAuthError: Error, LocalizedError {
    case rejected(String)
    case scriptFailed(String)
    case parseFailed
    case ioError(String)

    public var errorDescription: String? {
        switch self {
        case .rejected(let msg):     return "Login rejected: \(msg)"
        case .scriptFailed(let msg): return msg.isEmpty ? "Auth script failed" : msg
        case .parseFailed:           return "Couldn't parse auth response"
        case .ioError(let msg):      return msg
        }
    }
}

/// Runs `scripts/sge_auth.rb` (which wraps Lich's existing `EAccess` module)
/// and returns the game-server credentials needed to connect through Lich.
public enum SgeAuth {

    public static func authenticate(
        rubyPath: String,
        scriptPath: String,
        lichDir: String,
        account: String,
        password: String,
        character: String,
        gameCode: String
    ) async throws -> GameCredentials {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: rubyPath)
        proc.arguments = [scriptPath, account, password, character, gameCode]

        var env = ProcessInfo.processInfo.environment
        env["LICH_DIR"] = lichDir
        proc.environment = env

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        do {
            try proc.run()
        } catch {
            throw SgeAuthError.ioError("Couldn't launch ruby: \(error.localizedDescription)")
        }

        return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<GameCredentials, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                proc.waitUntilExit()
                let stdoutData = outPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = errPipe.fileHandleForReading.readDataToEndOfFile()
                let stderr = String(data: stderrData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                switch proc.terminationStatus {
                case 0:
                    guard
                        let dict = try? JSONSerialization.jsonObject(with: stdoutData) as? [String: Any],
                        let host = dict["host"] as? String,
                        let key  = dict["key"] as? String,
                        let port = (dict["port"] as? NSNumber).flatMap({ UInt16(exactly: $0.intValue) })
                    else {
                        cont.resume(throwing: SgeAuthError.parseFailed)
                        return
                    }
                    cont.resume(returning: GameCredentials(host: host, port: port, key: key))
                case 2:
                    cont.resume(throwing: SgeAuthError.rejected(Self.friendlyRejection(stderr)))
                default:
                    cont.resume(throwing: SgeAuthError.scriptFailed(stderr))
                }
            }
        }
    }

    private static func friendlyRejection(_ stderr: String) -> String {
        // sge_auth.rb prints "auth: <CODE>" for known rejections.
        let payload = stderr.replacingOccurrences(of: "auth: ", with: "")
        switch payload {
        case "PASSWORD":          return "wrong password"
        case "NORECORD":          return "no such account"
        case "REJECT":            return "account rejected"
        case "CHARACTER_NOT_FOUND": return "character not found on this account"
        default:                  return payload
        }
    }
}
