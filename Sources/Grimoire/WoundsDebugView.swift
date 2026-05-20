import SwiftUI
import GrimoireKit

/// Debug-only harness for the BodyDiagram. Lets you dial each body part's
/// injury and scar severity by hand, plus four quick presets, so visual
/// polish work doesn't require waiting to take damage in a real session.
///
/// Opened from the Debug menu (⌥⌘W). Owns its own `Wounds` state — does
/// NOT touch `LichClient.gameState`, so it's safe to leave open during
/// real play.
struct WoundsDebugView: View {
    @State private var wounds = Wounds()

    /// Display ordering for the per-part picker list. Roughly head-down
    /// so it scans like the silhouette itself.
    private let orderedParts: [BodyPart] = [
        .head, .leftEye, .rightEye, .neck,
        .chest, .back, .abdomen, .nsys,
        .leftArm, .rightArm, .leftHand, .rightHand,
        .leftLeg, .rightLeg,
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            // Live preview pinned in a dark-themed pane so it matches
            // how the widget actually appears inside the UberBar dialog.
            VStack(spacing: 8) {
                Text("Preview")
                    .font(.headline)
                BodyDiagram(wounds: wounds)
                    .padding(12)
                    .background(GameTheme.background)
                    .overlay(
                        Rectangle().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .environment(\.colorScheme, .dark)
                Spacer()
            }
            .frame(width: 200)

            VStack(alignment: .leading, spacing: 10) {
                presetRow
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        header
                        ForEach(orderedParts, id: \.self) { part in
                            partRow(part)
                        }
                    }
                    .padding(.trailing, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(16)
        .frame(minWidth: 660, minHeight: 480)
    }

    // MARK: - Presets

    private var presetRow: some View {
        HStack(spacing: 8) {
            Button("All Injuries 3") { setAll(injury: 3, scar: 0) }
            Button("All Scars 3")    { setAll(injury: 0, scar: 3) }
            Button("Random")         { randomize() }
            Button("Clear")          { wounds = Wounds() }
            Spacer()
        }
    }

    private var header: some View {
        HStack {
            Text("Part").frame(width: 90, alignment: .leading)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("Injury").frame(width: 160, alignment: .center)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
            Text("Scar").frame(width: 160, alignment: .center)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
        .padding(.bottom, 2)
    }

    @ViewBuilder
    private func partRow(_ part: BodyPart) -> some View {
        let info = wounds.parts[part] ?? WoundInfo()
        HStack {
            Text(part.rawValue)
                .frame(width: 90, alignment: .leading)
                .font(.system(.body, design: .monospaced))
            severityPicker(value: info.injury) { newVal in
                update(part: part, injury: newVal, scar: info.scar)
            }
            severityPicker(value: info.scar) { newVal in
                update(part: part, injury: info.injury, scar: newVal)
            }
        }
    }

    private func severityPicker(
        value: Int,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        Picker("", selection: Binding(
            get: { value },
            set: { onChange($0) }
        )) {
            ForEach(0...3, id: \.self) { rank in
                Text("\(rank)").tag(rank)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 160)
    }

    // MARK: - Mutation

    private func update(part: BodyPart, injury: Int, scar: Int) {
        if injury == 0 && scar == 0 {
            wounds.parts.removeValue(forKey: part)
        } else {
            wounds.parts[part] = WoundInfo(injury: injury, scar: scar)
        }
    }

    private func setAll(injury: Int, scar: Int) {
        var w = Wounds()
        for part in BodyPart.allCases {
            if injury > 0 || scar > 0 {
                w.parts[part] = WoundInfo(injury: injury, scar: scar)
            }
        }
        wounds = w
    }

    private func randomize() {
        var w = Wounds()
        for part in BodyPart.allCases {
            // Bias toward "no wound" so the random distribution looks
            // like a plausible mid-fight state rather than a meat grinder.
            let roll = Int.random(in: 0...4)
            if roll == 0 { continue }
            // Mix of injuries and scars; injury wins when both > 0,
            // so weight toward injuries when the part is "active."
            let isInjury = Int.random(in: 0...2) > 0
            let rank = Int.random(in: 1...3)
            w.parts[part] = isInjury
                ? WoundInfo(injury: rank, scar: 0)
                : WoundInfo(injury: 0, scar: rank)
        }
        wounds = w
    }
}
