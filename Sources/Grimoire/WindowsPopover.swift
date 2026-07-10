import SwiftUI
import GrimoireKit

/// Popover that lets the user pick which dock each pane lives in. Renders a
/// grid where every pane is one row and every region is one column — tapping
/// a cell snaps that pane to that region.
struct WindowsPopover: View {
    @Binding var panes: [PaneSpec]
    @Binding var paneSizes: [String: CGFloat]
    @Binding var showingDiscoveredPanes: Bool
    let onDone: () -> Void

    /// Visual ordering of regions in the grid — clockwise from left, with
    /// the off-screen "hidden" slot at the end.
    private static let regionGridOrder: [PaneRegion] = [.left, .top, .right, .bottom, .hidden]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Windows").font(.headline)
            Text("Pick where each window appears.")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    // Sectioned by what the window IS (game-provided vs.
                    // pushed by a Lich script), not by how the pane entered
                    // the list — auto-discovered game windows (Experience,
                    // Stance, …) belong under Standard, and script widgets
                    // (UberBar, ESP, maps) under Lich scripts even when
                    // they're part of the stock layout.
                    sectionHeader("Standard")
                    gridHeaderRow
                    ForEach($panes) { $pane in
                        if pane.source.isGameNative {
                            paneRow(pane: $pane)
                        }
                    }

                    let scriptCount = panes.filter { !$0.source.isGameNative }.count
                    if scriptCount > 0 {
                        Divider().padding(.vertical, 4)
                        DisclosureGroup(isExpanded: $showingDiscoveredPanes) {
                            gridHeaderRow
                            ForEach($panes) { $pane in
                                if !pane.source.isGameNative {
                                    paneRow(pane: $pane)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("From Lich scripts")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(0.4)
                                    .foregroundStyle(.secondary)
                                Text("(\(scriptCount))")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 460)
            Divider()
            HStack {
                Button("Reset to defaults") {
                    panes = PaneSpec.defaults
                    paneSizes = PaneSpec.defaultSizes
                }
                Spacer()
                Button("Done", action: onDone)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(14)
        .frame(width: 420)
    }

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
            .padding(.top, 2)
    }

    /// Column labels for the placement grid — small arrow glyphs above each
    /// region's column of toggle dots, the eye-slash for the hidden slot,
    /// and a final "→ main" column for stream-source panes that want to
    /// route to the story feed when hidden.
    private var gridHeaderRow: some View {
        HStack(spacing: 4) {
            Color.clear.frame(maxWidth: .infinity)  // name-column spacer
            ForEach(Self.regionGridOrder) { region in
                Image(systemName: Self.symbol(for: region))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 30, height: 18)
                    .help(region.displayName)
            }
            Image(systemName: "arrow.turn.up.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 30, height: 18)
                .help("Route to main story window when hidden (stream panes only)")
        }
    }

    @ViewBuilder
    private func paneRow(pane: Binding<PaneSpec>) -> some View {
        HStack(spacing: 4) {
            // Attributed script windows read "script: Window" so the user
            // can tell which script a pane belongs to at a glance.
            Group {
                if let script = pane.wrappedValue.source.scriptName {
                    Text("\(script): ").foregroundStyle(.secondary)
                        + Text(pane.wrappedValue.title)
                } else {
                    Text(pane.wrappedValue.title)
                }
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Self.regionGridOrder) { region in
                regionToggle(pane: pane, region: region)
            }
            fallthroughToggle(pane: pane)
        }
    }

    /// Per-pane "route to main when hidden" toggle. Only meaningful for
    /// stream-source panes — dialog panes carry widget data, not lines,
    /// so the slot stays as an empty spacer to keep columns aligned.
    @ViewBuilder
    private func fallthroughToggle(pane: Binding<PaneSpec>) -> some View {
        if case .stream = pane.wrappedValue.source {
            let isOn = pane.wrappedValue.fallthroughToMainWhenHidden
            Button {
                pane.fallthroughToMainWhenHidden.wrappedValue.toggle()
            } label: {
                Image(systemName: "arrow.turn.up.right")
                    .font(.system(size: 11, weight: isOn ? .bold : .regular))
                    .foregroundStyle(isOn ? Color.accentColor : Color.secondary)
                    .frame(width: 30, height: 24)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isOn ? Color.accentColor.opacity(0.18) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(
                                isOn ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08),
                                lineWidth: 0.5
                            )
                    )
            }
            .buttonStyle(.plain)
            .help("Route this stream's lines to the main story window when this pane is hidden")
        } else {
            Color.clear.frame(width: 30, height: 24)
        }
    }

    @ViewBuilder
    private func regionToggle(pane: Binding<PaneSpec>, region: PaneRegion) -> some View {
        let isActive = pane.wrappedValue.region == region
        Button {
            pane.region.wrappedValue = region
        } label: {
            Image(systemName: Self.symbol(for: region))
                .font(.system(size: 11, weight: isActive ? .bold : .regular))
                .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
                .frame(width: 30, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isActive ? Color.accentColor.opacity(0.18) : Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            isActive ? Color.accentColor.opacity(0.6) : Color.white.opacity(0.08),
                            lineWidth: 0.5
                        )
                )
        }
        .buttonStyle(.plain)
        .help(region.displayName)
    }

    private static func symbol(for region: PaneRegion) -> String {
        switch region {
        case .left:   return "arrow.left"
        case .top:    return "arrow.up"
        case .right:  return "arrow.right"
        case .bottom: return "arrow.down"
        case .hidden: return "eye.slash"
        }
    }
}
