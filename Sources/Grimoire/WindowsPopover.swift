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
                    sectionHeader("Standard")
                    gridHeaderRow
                    ForEach($panes) { $pane in
                        if !pane.id.hasPrefix("auto.") {
                            paneRow(pane: $pane)
                        }
                    }

                    let discoveredCount = panes.filter { $0.id.hasPrefix("auto.") }.count
                    if discoveredCount > 0 {
                        Divider().padding(.vertical, 4)
                        DisclosureGroup(isExpanded: $showingDiscoveredPanes) {
                            gridHeaderRow
                            ForEach($panes) { $pane in
                                if pane.id.hasPrefix("auto.") {
                                    paneRow(pane: $pane)
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text("Discovered by scripts")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(0.4)
                                    .foregroundStyle(.secondary)
                                Text("(\(discoveredCount))")
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
                    paneSizes = [:]
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
    /// region's column of toggle dots, plus the eye-slash for the hidden slot.
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
        }
    }

    @ViewBuilder
    private func paneRow(pane: Binding<PaneSpec>) -> some View {
        HStack(spacing: 4) {
            Text(pane.wrappedValue.title)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(Self.regionGridOrder) { region in
                regionToggle(pane: pane, region: region)
            }
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
