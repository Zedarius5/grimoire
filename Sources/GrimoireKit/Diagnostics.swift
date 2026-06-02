import Foundation
import Darwin

/// Captures live signals useful for diagnosing main-thread wedges that the
/// existing reconcile/watchdog logs can't see — namely "how long has the
/// main thread been unresponsive" and "which SwiftUI panes are churning."
///
/// The heartbeat runs on a private background queue, so it keeps reporting
/// even when the main thread is fully wedged in a SwiftUI layout loop —
/// the situation where every existing log site is starved.
///
/// In addition to the original log-when-interesting path, this snapshots a
/// per-second `PerfSnapshot` accessible via `latestSnapshot()` so an
/// in-app debug window can show live counters without re-instrumenting
/// every call site.
public final class Diagnostics: @unchecked Sendable {

    public static let shared = Diagnostics()

    // MARK: - State (lock-guarded)

    private let lock = NSLock()
    /// Most recent measured dispatch-to-run latency for a heartbeat
    /// closure on the main queue, in ms. Low = responsive; high =
    /// backpressure or recent stall. Updated by each heartbeat
    /// closure when it actually runs on main.
    private var lastTickLatencyMs: Double = 0
    /// Time (CFAbsoluteTime) the most recent heartbeat closure
    /// completed on main. Used to detect ongoing wedges: if this
    /// hasn't advanced in over an interval, main IS wedged right
    /// now (the dispatched closures are stuck behind something).
    private var lastTickCompletedAt: TimeInterval = CFAbsoluteTimeGetCurrent()
    private var paneEvalCounts: [String: Int] = [:]
    /// StoryTextView reconcile durations (ms) recorded during the current
    /// rolling window. Capped to keep memory bounded under bursty traffic.
    private var reconcileSamples: [Double] = []
    /// LichClient applyBatch records (lines / queueMs / runtimeMs) during
    /// the current window.
    private var lichBatchSamples: [LichBatchSample] = []
    /// Count of "main-lag exceeded 500ms" snapshots in the trailing minute.
    /// Sliding window over recent heartbeat readings; index-zero is oldest.
    private var recentLagReadingsMs: [Int] = []
    private var latestPerfSnapshot: PerfSnapshot = .empty

    private var heartbeatTimer: DispatchSourceTimer?
    private let queue = DispatchQueue(
        label: "com.zedarius.Grimoire.Diagnostics",
        qos: .utility
    )

    /// Heartbeat / snapshot interval. 1s gives a debug window decent
    /// freshness without spinning the queue too hard.
    private static let interval: TimeInterval = 1.0

    private init() {
        startHeartbeat()
    }

    // MARK: - Public recorders

    /// Call from a SwiftUI `body` (as `let _ = Diagnostics.shared.recordPaneEval(...)`)
    /// to log that this pane's body was re-evaluated. The id is free-form;
    /// stable per pane is what matters.
    public func recordPaneEval(_ id: String) {
        lock.lock()
        paneEvalCounts[id, default: 0] += 1
        lock.unlock()
    }

    /// StoryTextView's reconcile path calls this once per completed
    /// reconcile so the perf window can track avg / max / count.
    public func recordReconcile(durationMs: Double) {
        lock.lock()
        reconcileSamples.append(durationMs)
        // Cap so a runaway loop doesn't pin memory; we only need
        // enough samples to compute interval stats.
        if reconcileSamples.count > 5000 {
            reconcileSamples.removeFirst(reconcileSamples.count - 5000)
        }
        lock.unlock()
    }

    /// LichClient's applyBatch calls this so the perf window can track
    /// ingestion rate, queue delay, and runtime cost per batch.
    public func recordLichBatch(lines: Int, queueDelayMs: Int, runtimeMs: Int) {
        lock.lock()
        lichBatchSamples.append(LichBatchSample(lines: lines, queueDelayMs: queueDelayMs, runtimeMs: runtimeMs))
        if lichBatchSamples.count > 5000 {
            lichBatchSamples.removeFirst(lichBatchSamples.count - 5000)
        }
        lock.unlock()
    }

    /// Thread-safe read of the most recent snapshot. The snapshot is
    /// refreshed once per heartbeat interval.
    public func latestSnapshot() -> PerfSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return latestPerfSnapshot
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.interval, repeating: Self.interval)
        timer.setEventHandler { [weak self] in
            self?.heartbeat()
        }
        timer.resume()
        self.heartbeatTimer = timer
    }

    private func heartbeat() {
        // Dispatch a ping to main and measure how long it actually waits
        // before running. `dispatchedAt` is captured into the closure so
        // each heartbeat measures ITS OWN latency (not a shared running
        // average that gets confused by stacked closures).
        let dispatchedAt = CFAbsoluteTimeGetCurrent()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            let completedAt = CFAbsoluteTimeGetCurrent()
            let latencyMs = (completedAt - dispatchedAt) * 1000
            self.lock.lock()
            self.lastTickLatencyMs = latencyMs
            self.lastTickCompletedAt = completedAt
            self.lock.unlock()
        }

        let memMB = currentRssMB()

        // Snapshot and reset interval counters.
        lock.lock()
        // Display value: the most recent measured dispatch-to-run
        // latency. Single-digit ms under normal operation. Bounded
        // above by the heartbeat interval -- if main is wedged
        // longer than that, the dispatched closure hasn't run yet
        // and lastTickLatencyMs reflects whatever the PREVIOUS tick
        // measured (stale).
        //
        // To surface in-progress wedges past the interval, add the
        // overage of "time since last completed tick" beyond one
        // interval. Steady state: timeSinceLastComplete ≈ interval,
        // so overage ≈ 0 and mainLag = latency. Wedge in progress:
        // overage grows without bound and dominates.
        let nowAbs = CFAbsoluteTimeGetCurrent()
        let intervalMs = Self.interval * 1000
        let timeSinceLastTickMs = (nowAbs - lastTickCompletedAt) * 1000
        let wedgeOverageMs = max(0, timeSinceLastTickMs - intervalMs)
        let mainLagMs = Int(max(lastTickLatencyMs, wedgeOverageMs))
        let evalSnapshot = paneEvalCounts
        paneEvalCounts.removeAll()
        let reconciles = reconcileSamples
        reconcileSamples.removeAll()
        let batches = lichBatchSamples
        lichBatchSamples.removeAll()
        // Trailing-60-readings sliding window so "spikes in last minute"
        // is a true rolling count regardless of heartbeat interval.
        recentLagReadingsMs.append(mainLagMs)
        let lastMinuteCount = Int(60 / Self.interval)
        if recentLagReadingsMs.count > lastMinuteCount {
            recentLagReadingsMs.removeFirst(recentLagReadingsMs.count - lastMinuteCount)
        }
        // Threshold matches the per-tick log threshold: anything over
        // 100ms is a perceptible stall worth counting.
        let lagSpikes = recentLagReadingsMs.filter { $0 > 100 }.count
        let snapshot = PerfSnapshot(
            mainLagMs: mainLagMs,
            lagSpikesLastMinute: lagSpikes,
            reconcileCount: reconciles.count,
            reconcileAvgMs: reconciles.isEmpty ? 0 : reconciles.reduce(0, +) / Double(reconciles.count),
            reconcileMaxMs: reconciles.max() ?? 0,
            lichBatchCount: batches.count,
            lichBatchAvgLines: batches.isEmpty ? 0 : Double(batches.reduce(0) { $0 + $1.lines }) / Double(batches.count),
            lichBatchTotalLines: batches.reduce(0) { $0 + $1.lines },
            lichBatchAvgQueueMs: batches.isEmpty ? 0 : Double(batches.reduce(0) { $0 + $1.queueDelayMs }) / Double(batches.count),
            lichBatchAvgRuntimeMs: batches.isEmpty ? 0 : Double(batches.reduce(0) { $0 + $1.runtimeMs }) / Double(batches.count),
            memoryRssMB: memMB,
            paneEvals: evalSnapshot
                .sorted { $0.value > $1.value }
                .prefix(12)
                .map { PaneEvalSample(id: $0.key, count: $0.value) },
            intervalSeconds: Self.interval,
            timestamp: Date()
        )
        latestPerfSnapshot = snapshot
        lock.unlock()

        // Steady state: mainLag tiny, no pane churn — skip log. Anything
        // interesting still gets a line. With the new latency-based
        // measurement, mainLag in normal operation is single-digit ms,
        // so a 100ms threshold reliably catches real backpressure.
        let topEvals = evalSnapshot
            .sorted { $0.value > $1.value }
            .prefix(6)
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
        let interesting = mainLagMs > 100 || !evalSnapshot.isEmpty
        if interesting {
            appLog(
                "Diagnostics",
                "mainLag=\(mainLagMs)ms panes=[\(topEvals)]",
                level: .info
            )
        }
    }

    /// Resident set size of the current process, in MB. Returns 0 on
    /// failure (rare; the API is stable on darwin).
    private func currentRssMB() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size)
        let kr = withUnsafeMutablePointer(to: &info) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }
        return Int(info.resident_size / (1024 * 1024))
    }
}

private struct LichBatchSample {
    let lines: Int
    let queueDelayMs: Int
    let runtimeMs: Int
}

public struct PaneEvalSample: Sendable, Identifiable {
    public let id: String
    public let count: Int
}

/// Aggregated metrics for the most recent heartbeat interval. Consumed by
/// the in-app perf debug window via `Diagnostics.shared.latestSnapshot()`.
public struct PerfSnapshot: Sendable {
    public let mainLagMs: Int
    public let lagSpikesLastMinute: Int
    public let reconcileCount: Int
    public let reconcileAvgMs: Double
    public let reconcileMaxMs: Double
    public let lichBatchCount: Int
    public let lichBatchAvgLines: Double
    public let lichBatchTotalLines: Int
    public let lichBatchAvgQueueMs: Double
    public let lichBatchAvgRuntimeMs: Double
    public let memoryRssMB: Int
    public let paneEvals: [PaneEvalSample]
    public let intervalSeconds: Double
    public let timestamp: Date

    public static let empty = PerfSnapshot(
        mainLagMs: 0, lagSpikesLastMinute: 0,
        reconcileCount: 0, reconcileAvgMs: 0, reconcileMaxMs: 0,
        lichBatchCount: 0, lichBatchAvgLines: 0, lichBatchTotalLines: 0,
        lichBatchAvgQueueMs: 0, lichBatchAvgRuntimeMs: 0,
        memoryRssMB: 0, paneEvals: [],
        intervalSeconds: 1, timestamp: .distantPast
    )

    /// Inferred ingestion rate, lines/sec, over the most recent interval.
    public var linesPerSecond: Double {
        guard intervalSeconds > 0 else { return 0 }
        return Double(lichBatchTotalLines) / intervalSeconds
    }

    public var reconcilesPerSecond: Double {
        guard intervalSeconds > 0 else { return 0 }
        return Double(reconcileCount) / intervalSeconds
    }
}
