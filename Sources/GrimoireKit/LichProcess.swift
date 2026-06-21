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
        // LANG/LC_ALL are unset. Ruby then defaults `File.open` to US-ASCII,
        // and any `.lic` with a byte >0x7F (smart quotes, em-dash, accented
        // name) crashes at load with "invalid byte sequence in US-ASCII".
        // Forcing UTF-8 here matches a Terminal launch without touching Lich
        // core or user scripts.
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

    /// App-quit shutdown. Sends SIGTERM, then waits for Lich to *actually*
    /// exit before calling `completion` (up to `timeout`).
    ///
    /// When the launch path is OS -> front-end -> Lich proxy (how Grimoire
    /// launches Lich), tearing Ruby down too fast leaves Lich no time to save
    /// script settings and let scripts finish. So instead of `stop()`'s
    /// fire-and-forget terminate, we hold the process handle and poll its real
    /// `isRunning` until the OS reaps it. The `timeout` is a backstop so a
    /// wedged Lich can't block the app from quitting.
    public func terminateAndWait(
        timeout: TimeInterval,
        completion: @escaping @MainActor () -> Void
    ) {
        guard let proc = process, proc.isRunning else {
            completion()
            return
        }
        proc.terminate()  // SIGTERM — Lich saves + winds down scripts here
        poll(proc: proc, deadline: Date().addingTimeInterval(timeout), completion: completion)
    }

    private func poll(
        proc: Process,
        deadline: Date,
        completion: @escaping @MainActor () -> Void
    ) {
        if !proc.isRunning || Date() >= deadline {
            completion()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            MainActor.assumeIsolated {
                self.poll(proc: proc, deadline: deadline, completion: completion)
            }
        }
    }
}
