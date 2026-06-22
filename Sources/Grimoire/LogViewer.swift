import SwiftUI
import AppKit
import UniformTypeIdentifiers
import GrimoireKit

// MARK: - Model

/// Loads + parses a saved GemStone log off the main thread, then exposes
/// the lines filtered by which categories are toggled on. Highlights are
/// applied downstream in `LogTextView` from the live store, so editing a
/// rule and reopening reflects it.
@MainActor
final class LogViewerModel: ObservableObject {
    let url: URL
    @Published private(set) var allLines: [LogLine] = []
    @Published private(set) var counts: [LogCategory: Int] = [:]
    @Published private(set) var loading = true
    @Published private(set) var truncated = false
    @Published private(set) var loadError: String?
    /// Toggleable categories currently shown. `.game` is always shown and
    /// is intentionally absent here.
    /// Default ON (shown): script, stance, command errors, exits, room
    /// descriptions, combat mechanics. Everything else starts hidden.
    @Published var shown: Set<LogCategory> = [.script, .stance, .commandError, .exits, .room, .combat]

    /// Categories the user can toggle, in display order.
    static let toggleable: [LogCategory] = [
        .thoughts, .experience, .info, .resource, .songs, .logon, .death,
        .disk, .stance, .commandError, .exits, .room, .combat, .script
    ]

    init(url: URL) {
        self.url = url
        load()
    }

    var visibleLines: [RenderedLine] {
        allLines.compactMap { $0.category == .game || shown.contains($0.category) ? $0.line : nil }
    }

    private func load() {
        let url = self.url
        Task.detached(priority: .userInitiated) {
            guard let data = try? Data(contentsOf: url) else {
                await MainActor.run {
                    self.loadError = "Couldn't read \(url.lastPathComponent)."
                    self.loading = false
                }
                return
            }
            // Lossy UTF-8: captured logs occasionally carry stray non-UTF8
            // bytes; we'd rather show the line than fail the whole file.
            let text = String(decoding: data, as: UTF8.self)
            let (lines, truncated) = LogParser.parse(text)
            var counts: [LogCategory: Int] = [:]
            for l in lines { counts[l.category, default: 0] += 1 }
            await MainActor.run {
                self.allLines = lines
                self.counts = counts
                self.truncated = truncated
                self.loading = false
            }
        }
    }
}

// MARK: - View

struct LogViewerView: View {
    @EnvironmentObject private var highlights: HighlightStore
    @StateObject private var model: LogViewerModel

    init(url: URL) {
        _model = StateObject(wrappedValue: LogViewerModel(url: url))
    }

    var body: some View {
        VStack(spacing: 0) {
            toggleBar
            Divider()
            content
            if model.truncated {
                Text("Large file — showing the most recent 100,000 lines.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(.yellow.opacity(0.12))
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .navigationTitle(model.url.lastPathComponent)
    }

    private var toggleBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("BETA")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 5).padding(.vertical, 1)
                    .background(Capsule().fill(.orange))
                    .foregroundStyle(.white)
                Text("Log Viewer is new — line categories may be imperfect.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 165), alignment: .leading)],
                alignment: .leading, spacing: 3
            ) {
                ForEach(LogViewerModel.toggleable, id: \.self) { cat in
                    Toggle(isOn: Binding(
                        get: { model.shown.contains(cat) },
                        set: { on in if on { model.shown.insert(cat) } else { model.shown.remove(cat) } }
                    )) {
                        Text("\(cat.label) (\(model.counts[cat, default: 0]))")
                            .font(.system(size: 11, design: .monospaced))
                            .lineLimit(1)
                    }
                    .toggleStyle(.checkbox)
                }
            }
            Text("Game text always shown · ⌘F to find")
                .font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
    }

    @ViewBuilder
    private var content: some View {
        if model.loading {
            ProgressView("Loading \(model.url.lastPathComponent)…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = model.loadError {
            Text(err).foregroundStyle(.red)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if model.visibleLines.isEmpty {
            Text("No lines in the shown categories.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            LogTextView(lines: model.visibleLines,
                        highlights: highlights.effectiveHighlights,
                        fontSize: 13)
            .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Read-only highlighted text view

/// Read-only `NSTextView` that renders the (already category-filtered)
/// log lines with the user's highlights applied. Static document: it
/// rebuilds the whole attributed string when the inputs change rather
/// than doing the live feed's incremental reconcile. Starts at the top
/// and enables the native Find bar.
struct LogTextView: NSViewRepresentable {
    let lines: [RenderedLine]
    let highlights: [Highlight]
    let fontSize: CGFloat

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = true
        scroll.backgroundColor = NSColor(GameTheme.background)

        // TextKit 1 — large logs lay out far faster than TextKit 2 (same
        // reasoning as the live story feed).
        let tv = NSTextView(usingTextLayoutManager: false)
        tv.isEditable = false
        tv.isSelectable = true
        tv.drawsBackground = true
        tv.backgroundColor = NSColor(GameTheme.background)
        tv.textContainerInset = NSSize(width: 12, height: 10)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.textContainer?.widthTracksTextView = true
        tv.usesFindBar = true
        tv.isIncrementalSearchingEnabled = true
        tv.linkTextAttributes = [:]  // links aren't clickable here (no live client)

        scroll.documentView = tv
        context.coordinator.textView = tv
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        let sig = signature
        guard context.coordinator.appliedSignature != sig,
              let tv = context.coordinator.textView,
              let storage = tv.textStorage else { return }
        storage.setAttributedString(
            LogAttributedBuilder.build(lines, fontSize: fontSize, highlights: highlights)
        )
        context.coordinator.appliedSignature = sig
        // Anchor at the top after a content swap (a filter toggle, say).
        tv.scrollRangeToVisible(NSRange(location: 0, length: 0))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor final class Coordinator {
        weak var textView: NSTextView?
        var appliedSignature: Int = -1
    }

    /// Cheap change-detector so we don't rebuild the (potentially huge)
    /// attributed string on every SwiftUI update — only when the visible
    /// lines, highlight set, or font actually change.
    private var signature: Int {
        var h = Hasher()
        h.combine(lines.count)
        h.combine(fontSize)
        h.combine(highlights.count)
        h.combine(lines.first?.plainText)
        h.combine(lines.last?.plainText)
        return h.finalize()
    }
}

// MARK: - Attributed-string builder

/// Builds the dark-themed attributed string for the log viewer, applying
/// highlights per line. Mirrors the live feed's run→attribute mapping but
/// stays self-contained so it can't perturb `StoryTextView`'s tuned
/// reconcile path.
private enum LogAttributedBuilder {
    @MainActor
    static func build(_ lines: [RenderedLine], fontSize: CGFloat, highlights: [Highlight]) -> NSAttributedString {
        let out = NSMutableAttributedString()
        for line in lines {
            let processed = highlights.isEmpty ? line : HighlightProcessor.apply(highlights, to: line)
            for run in processed.runs where !run.text.isEmpty {
                let s = run.style
                let bold = s.bold || s.monsterbold || s.highlightBold || s.styleId == "roomName"
                let base = NSFont.monospacedSystemFont(ofSize: fontSize, weight: bold ? .bold : .regular)
                var attrs: [NSAttributedString.Key: Any] = [:]
                if s.italic {
                    let d = base.fontDescriptor.withSymbolicTraits(.italic)
                    attrs[.font] = NSFont(descriptor: d, size: fontSize) ?? base
                } else {
                    attrs[.font] = base
                }
                let fg = foreground(for: s)
                attrs[.foregroundColor] = fg
                if let hex = s.highlightBg, let c = NSColor(hexString: hex) {
                    attrs[.backgroundColor] = c
                }
                if s.link != nil {
                    // Visual cue only; not clickable in the viewer.
                    attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
                    attrs[.underlineColor] = fg
                }
                out.append(NSAttributedString(string: run.text, attributes: attrs))
            }
            out.append(NSAttributedString(string: "\n"))
        }
        return out
    }

    @MainActor
    private static func foreground(for s: RunStyle) -> NSColor {
        if let hex = s.highlightFg, let c = NSColor(hexString: hex) { return c }
        if s.monsterbold { return NSColor(GameTheme.monsterbold) }
        if s.isPrompt { return NSColor(GameTheme.prompt) }
        switch s.styleId {
        case "roomName": return NSColor(GameTheme.roomName)
        case "speech":   return NSColor(GameTheme.speech)
        case "whisper":  return NSColor(GameTheme.whisper)
        case "thought":  return NSColor(GameTheme.thought)
        case "roomDesc": return NSColor(GameTheme.roomDesc)
        default: break
        }
        if let link = s.link {
            return link.kind == .direction
                ? NSColor(GameTheme.directionLink)
                : NSColor(GameTheme.entityLink)
        }
        return NSColor(GameTheme.foreground)
    }
}

// MARK: - Menu item

/// `File ▸ Open Log…` — picks a `.log` and opens a viewer window for it.
/// Lives as a view so it can use the `openWindow` environment value.
struct OpenLogMenuItem: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("Open Log (Beta)…") {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = false
            panel.canChooseDirectories = false
            var types: [UTType] = [.plainText, .text]
            if let logType = UTType(filenameExtension: "log") { types.insert(logType, at: 0) }
            panel.allowedContentTypes = types
            panel.allowsOtherFileTypes = true
            if let root = LichLocation.resolvedRoot() {
                let logs = URL(fileURLWithPath: LichLocation.logsDir(in: root))
                if FileManager.default.fileExists(atPath: logs.path) { panel.directoryURL = logs }
            }
            if panel.runModal() == .OK, let url = panel.url {
                openWindow(value: url)
            }
        }
        .keyboardShortcut("o", modifiers: [.command])
    }
}
