import Foundation

/// Captures live signals useful for diagnosing main-thread wedges that the
/// existing reconcile/watchdog logs can't see — namely "how long has the
/// main thread been unresponsive" and "which SwiftUI panes are churning."
///
/// The heartbeat runs on a private background queue, so it keeps reporting
/// even when the main thread is fully wedged in a SwiftUI layout loop —
/// the situation where every existing log site is starved.
public final class Diagnostics: @unchecked Sendable {

    public static let shared = Diagnostics()

    private let lock = NSLock()
    private var lastMainTick: Date = Date()
    private var paneEvalCounts: [String: Int] = [:]
    private var heartbeatTimer: DispatchSourceTimer?
    private let queue = DispatchQueue(
        label: "com.zedarius.Grimoire.Diagnostics",
        qos: .utility
    )

    private init() {
        startHeartbeat()
    }

    /// Call from a SwiftUI `body` (as `let _ = Diagnostics.shared.recordPaneEval(...)`)
    /// to log that this pane's body was re-evaluated. The id is free-form;
    /// stable per pane is what matters.
    public func recordPaneEval(_ id: String) {
        lock.lock()
        paneEvalCounts[id, default: 0] += 1
        lock.unlock()
    }

    /// Called from the heartbeat block once it lands on main, to mark "main
    /// thread was responsive at this moment." If main is wedged the block
    /// queues but never runs, so `lastMainTick` falls behind real time and
    /// the heartbeat's next firing logs the gap.
    fileprivate func recordMainTick() {
        lock.lock()
        lastMainTick = Date()
        lock.unlock()
    }

    private func startHeartbeat() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 2, repeating: 2)
        timer.setEventHandler { [weak self] in
            self?.heartbeat()
        }
        timer.resume()
        self.heartbeatTimer = timer
    }

    private func heartbeat() {
        // Queue a ping to main; it'll run as soon as main is responsive.
        DispatchQueue.main.async { [weak self] in
            self?.recordMainTick()
        }

        // Snapshot and reset eval counters for this window.
        lock.lock()
        let mainLagMs = Int(Date().timeIntervalSince(lastMainTick) * 1000)
        let evalSnapshot = paneEvalCounts
        paneEvalCounts.removeAll()
        lock.unlock()

        let topEvals = evalSnapshot
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")

        // Steady state: mainLag is tiny and panes don't churn — skip log.
        // Anything interesting (wedge, burst, suspicious churn) gets a line.
        let interesting = mainLagMs > 500 || !evalSnapshot.isEmpty
        guard interesting else { return }

        appLog(
            "Diagnostics",
            "mainLag=\(mainLagMs)ms panes=[\(topEvals)]",
            level: .info
        )
    }
}
