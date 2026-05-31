import Foundation

/// Manages a child Lich process spawned by Grimoire.
///
/// Captures stdout/stderr so launch failures (missing gem, bad ruby path,
/// auth failure) are surfaced rather than vanishing.
@MainActor
public final class LichProcess: ObservableObject {

    public enum Status: Equatable, Sendable {
        case stopped
        case starting
        case running
        case exited(Int32)
        case failed(String)
    }

    @Published public private(set) var status: Status = .stopped
    @Published public private(set) var logTail: [String] = []

    private var process: Process?

    public init() {}

    public var isRunning: Bool {
        switch status {
        case .running, .starting: return true
        default: return false
        }
    }

    public func launch(rubyPath: String, lichPath: String, args: [String]) {
        stop()
        logTail = []

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: rubyPath)
        proc.arguments = [lichPath] + args

        // GUI-launched macOS apps don't inherit a shell environment, so
        // LANG/LC_ALL are unset when we spawn Lich. Ruby then defaults
        // `File.open` to US-ASCII, and any `.lic` containing a byte >0x7F
        // (smart quotes, em-dash, accented name) crashes at script load
        // with "invalid byte sequence in US-ASCII". From a Terminal these
        // same scripts work because the shell injects LANG=en_US.UTF-8.
        // Forcing UTF-8 here makes the spawn behave the same as a Terminal
        // launch without touching Lich core or any user scripts.
        var env = ProcessInfo.processInfo.environment
        env["LANG"] = "en_US.UTF-8"
        env["LC_ALL"] = "en_US.UTF-8"
        proc.environment = env

        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = outPipe

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                let lines = text
                    .split(separator: "\n", omittingEmptySubsequences: false)
                    .map(String.init)
                self.logTail.append(contentsOf: lines)
                if self.logTail.count > 300 {
                    self.logTail.removeFirst(self.logTail.count - 300)
                }
            }
        }

        proc.terminationHandler = { [weak self] p in
            Task { @MainActor in
                guard let self else { return }
                outPipe.fileHandleForReading.readabilityHandler = nil
                self.status = .exited(p.terminationStatus)
                self.process = nil
            }
        }

        status = .starting
        do {
            try proc.run()
            self.process = proc
            status = .running
        } catch {
            status = .failed("Failed to launch: \(error.localizedDescription)")
        }
    }

    public func stop() {
        process?.terminate()
        process = nil
        if isRunning {
            status = .stopped
        }
    }
}
