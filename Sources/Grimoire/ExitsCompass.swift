import SwiftUI
import GrimoireKit

/// Compact compass widget showing available exits as lit cells. Sized to fit
/// the same row as the input bar — 3x3 cardinal grid with up/down/out
/// collapsed into the centre column.
///
/// Equatable so SwiftUI can skip the body call when the parent
/// re-renders with an unchanged exits set. The `onCommand` closure is
/// intentionally excluded from the comparison; closures don't compare
/// meaningfully across SwiftUI renders.
struct ExitsCompass: View, Equatable {
    let exits: Set<String>
    let onCommand: (String) -> Void

    nonisolated static func == (lhs: ExitsCompass, rhs: ExitsCompass) -> Bool {
        lhs.exits == rhs.exits
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("ExitsCompass")
        return HStack(spacing: 3) {
            Grid(horizontalSpacing: 1, verticalSpacing: 1) {
                GridRow {
                    cell("nw", label: "NW")
                    cell("n",  label: "N")
                    cell("ne", label: "NE")
                }
                GridRow {
                    cell("w",   label: "W")
                    cell("out", label: "OUT")
                    cell("e",   label: "E")
                }
                GridRow {
                    cell("sw", label: "SW")
                    cell("s",  label: "S")
                    cell("se", label: "SE")
                }
            }

            VStack(spacing: 1) {
                arrowCell("up",   symbol: "arrowtriangle.up.fill")
                arrowCell("down", symbol: "arrowtriangle.down.fill")
            }
            .frame(width: 26)
        }
        .padding(3)
        .frame(width: 180)
        .frame(maxHeight: .infinity)
        .background(GameTheme.background)
        .overlay(
            Rectangle().frame(width: 1).foregroundStyle(Color.white.opacity(0.08)),
            alignment: .leading
        )
        .environment(\.colorScheme, .dark)
    }

    @ViewBuilder
    private func cell(_ direction: String, label: String) -> some View {
        let lit = exits.contains(direction)
        cellChrome(lit: lit, direction: direction) {
            Text(label)
                .font(.system(size: 9, weight: lit ? .semibold : .regular, design: .monospaced))
                .foregroundStyle(litForeground(lit))
        }
    }

    @ViewBuilder
    private func arrowCell(_ direction: String, symbol: String) -> some View {
        let lit = exits.contains(direction)
        cellChrome(lit: lit, direction: direction) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(litForeground(lit))
        }
    }

    @ViewBuilder
    private func cellChrome<Content: View>(
        lit: Bool,
        direction: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        Button {
            if lit { onCommand(direction) }
        } label: {
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(lit ? Color.green.opacity(0.10) : Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(lit ? Color.green.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .buttonStyle(.plain)
        .disabled(!lit)
    }

    private func litForeground(_ lit: Bool) -> Color {
        lit ? Color(red: 0.58, green: 0.95, blue: 0.58) : Color.gray.opacity(0.32)
    }
}
