import SwiftUI
import GrimoireKit

/// Live perf dashboard, opened from Debug -> Performance. Polls
/// `Diagnostics.shared.latestSnapshot()` every second and renders
/// per-section counters so you can spot main-thread wedges, ingestion
/// bursts, slow reconciles, or memory growth during normal gameplay
/// without dropping to Console.app + log filtering.
///
/// Doesn't add measurement cost when closed -- the heartbeat in
/// `Diagnostics` runs regardless; this view just reads its output.
struct PerfDebugView: View {
    @State private var snapshot: PerfSnapshot = .empty
    @State private var pollTimer: Timer?

    private let pollInterval: TimeInterval = 1.0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                Divider()
                mainThreadSection
                Divider()
                renderingSection
                Divider()
                ingestionSection
                Divider()
                processSection
                if !snapshot.paneEvals.isEmpty {
                    Divider()
                    paneEvalSection
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 460, minHeight: 480)
        .navigationTitle("Performance")
        .onAppear {
            snapshot = Diagnostics.shared.latestSnapshot()
            pollTimer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { _ in
                Task { @MainActor in
                    snapshot = Diagnostics.shared.latestSnapshot()
                }
            }
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Performance").font(.title2.bold())
            Spacer()
            Text("Updated \(snapshot.timestamp == .distantPast ? "—" : timeFormatter.string(from: snapshot.timestamp)) · interval \(String(format: "%.0f", snapshot.intervalSeconds))s")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private var mainThreadSection: some View {
        sectionVStack("Main thread") {
            row(label: "Latest main-thread lag", value: "\(snapshot.mainLagMs) ms", warn: snapshot.mainLagMs > 100)
            row(label: "Lag spikes (>100ms) in last minute", value: "\(snapshot.lagSpikesLastMinute)", warn: snapshot.lagSpikesLastMinute > 0)
            Text("Lag is dispatch-to-run latency for a heartbeat closure. > ~16ms = dropped frame, > 100ms = visible stall. If the gap grows past one interval the heartbeat is wedged behind something heavy.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var renderingSection: some View {
        sectionVStack("Story view rendering") {
            row(label: "Reconciles in last interval", value: "\(snapshot.reconcileCount)")
            row(label: "Reconciles per second", value: String(format: "%.1f", snapshot.reconcilesPerSecond))
            row(label: "Avg reconcile duration", value: String(format: "%.2f ms", snapshot.reconcileAvgMs), warn: snapshot.reconcileAvgMs > 5)
            row(label: "Max reconcile (this interval)", value: String(format: "%.2f ms", snapshot.reconcileMaxMs), warn: snapshot.reconcileMaxMs > 50)
        }
    }

    private var ingestionSection: some View {
        sectionVStack("Lich ingestion") {
            row(label: "Lines from server (last interval)", value: "\(snapshot.lichBatchTotalLines)")
            row(label: "Lines per second", value: String(format: "%.1f", snapshot.linesPerSecond))
            row(label: "Batches in last interval", value: "\(snapshot.lichBatchCount)")
            row(label: "Avg lines per batch", value: String(format: "%.1f", snapshot.lichBatchAvgLines))
            row(label: "Avg main-queue delay", value: String(format: "%.1f ms", snapshot.lichBatchAvgQueueMs), warn: snapshot.lichBatchAvgQueueMs > 50)
            row(label: "Avg apply runtime", value: String(format: "%.1f ms", snapshot.lichBatchAvgRuntimeMs), warn: snapshot.lichBatchAvgRuntimeMs > 100)
        }
    }

    private var processSection: some View {
        sectionVStack("Process") {
            row(label: "Resident memory", value: "\(snapshot.memoryRssMB) MB", warn: snapshot.memoryRssMB > 800)
        }
    }

    private var paneEvalSection: some View {
        sectionVStack("Pane re-evaluations (instrumented views)") {
            ForEach(snapshot.paneEvals) { sample in
                HStack {
                    Text(sample.id)
                        .font(.system(.body, design: .monospaced))
                    Spacer()
                    Text("\(sample.count)")
                        .font(.system(.body, design: .monospaced).monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            Text("Each row is a view that called Diagnostics.shared.recordPaneEval(...) from its body. Add the call to any view you suspect of over-rendering.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func sectionVStack<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            content()
        }
    }

    private func row(label: String, value: String, warn: Bool = false) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced).monospacedDigit())
                .foregroundStyle(warn ? Color.red : Color.primary)
        }
    }

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()
}
