import SwiftUI
import GrimoireKit

/// Compact horizontal strip of icons reflecting the character's current
/// `<indicator>` flags — stance/posture plus combat afflictions like bleeding,
/// poisoned, stunned, etc. Sits beside the input bar (single-row) like
/// Wrayth's status box.
///
/// Icons are game-icons.net SVGs bundled under `Resources/game-icons/` and
/// loaded via the `GameIcon` helper. Each entry's `iconName` is the SVG
/// filename without extension; alternates for any given status are kept
/// in the bundle too so the icon-browser debug view can show them all.
struct StatusBox: View {
    let state: GameState

    /// Live status flags shown in the strip. `iconName` matches the SVG
    /// file in `Resources/game-icons/`.
    static let entries: [Entry] = [
        Entry("IconSTANDING",  label: "Standing",  iconName: "person",                   color: .white.opacity(0.85)),
        Entry("IconKNEELING",  label: "Kneeling",  iconName: "kneeling",                 color: .yellow.opacity(0.85)),
        Entry("IconSITTING",   label: "Sitting",   iconName: "meditation",               color: .yellow.opacity(0.85)),
        Entry("IconPRONE",     label: "Prone",     iconName: "falling",                  color: .orange),
        Entry("IconHIDDEN",    label: "Hidden",    iconName: "hidden",                   color: .gray),
        Entry("IconINVISIBLE", label: "Invisible", iconName: "invisible",                color: .gray),
        Entry("IconJOINED",    label: "Grouped",   iconName: "backup",                   color: .blue),
        Entry("IconSTUNNED",   label: "Stunned",   iconName: "knockout",                 color: .yellow),
        Entry("IconBLEEDING",  label: "Bleeding",  iconName: "bleeding-wound",           color: .red),
        Entry("IconPOISONED",  label: "Poisoned",  iconName: "poison-bottle",            color: .green),
        Entry("IconDISEASED",  label: "Diseased",  iconName: "plague-doctor-profile",    color: .purple),
        Entry("IconWEBBED",    label: "Webbed",    iconName: "spider-web",               color: .gray),
        Entry("IconCALMED",    label: "Calm",      iconName: "peace-dove",               color: .blue),
        Entry("IconSILENCED",  label: "Silenced",  iconName: "silenced",                 color: .gray),
        Entry("IconDEAD",      label: "Dead",      iconName: "skull-crossed-bones",      color: .red),
    ]

    struct Entry: Identifiable {
        let id: String
        let label: String
        let iconName: String
        let color: Color

        init(_ id: String, label: String, iconName: String, color: Color) {
            self.id = id
            self.label = label
            self.iconName = iconName
            self.color = color
        }
    }

    private var activeIndicators: [Entry] {
        Self.entries.filter { state.indicators[$0.id] == true }
    }

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("StatusBox")
        // Single row of icons. Icon size is the smaller of the padded
        // container height and the per-icon width slice, so a few
        // indicators render large while 4+ shrink to stay on one line.
        GeometryReader { proxy in
            let count = activeIndicators.count
            let pad: CGFloat = 8
            let gap: CGFloat = 6
            // Hard cap on icon size — without it the icons fill the full
            // container height and read as oversized next to the
            // input/vitals chrome.
            let maxIconSize: CGFloat = 52
            let availW = max(0, proxy.size.width - pad * 2)
            let availH = max(0, proxy.size.height - pad * 2)
            let iconSize: CGFloat = {
                guard count > 0 else { return 0 }
                let widthBudget = (availW - CGFloat(count - 1) * gap) / CGFloat(count)
                return max(0, min(availH, widthBudget, maxIconSize))
            }()

            HStack(spacing: gap) {
                ForEach(activeIndicators) { entry in
                    GameIcon(name: entry.iconName)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundStyle(entry.color)
                        .help(entry.label)
                }
                // Pushes the icons to the leading edge when there's
                // leftover width (i.e., when icons hit the height cap
                // before consuming all the width).
                Spacer(minLength: 0)
            }
            .padding(pad)
        }
        // Fixed width; the adjacent InputBar/VitalsBar are `maxWidth:
        // .infinity` and shrink to accommodate it.
        .frame(width: 260)
        .frame(maxHeight: .infinity)
        .background(GameTheme.background)
        .overlay(
            Rectangle().frame(width: 1).foregroundStyle(Color.white.opacity(0.08)),
            alignment: .leading
        )
        .environment(\.colorScheme, .dark)
    }
}
