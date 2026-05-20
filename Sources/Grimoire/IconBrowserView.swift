import SwiftUI

/// Debug view that displays every bundled game-icons SVG grouped by the
/// status flag it corresponds to. Useful for comparing the chosen icon
/// against the alternates — open it via "Debug > Icon Browser" in the
/// menu bar, or `⌥⌘I`.
///
/// Each row covers one status; within the row the *chosen* icon is the
/// first cell and is marked with a star, with the remaining cells being
/// alternates we keep on disk in case we want to swap later.
struct IconBrowserView: View {
    /// Per-status group: which icons exist, which one's currently wired
    /// into `StatusBox`, and what colour the live UI tints it.
    private static let groups: [Group] = [
        Group(label: "Standing",  color: .white.opacity(0.85),
              chosen: "person",            alternates: []),
        Group(label: "Kneeling",  color: .yellow.opacity(0.85),
              chosen: "kneeling",          alternates: []),
        Group(label: "Sitting",   color: .yellow.opacity(0.85),
              chosen: "meditation",        alternates: ["stone-throne", "wooden-chair"]),
        Group(label: "Prone",     color: .orange,
              chosen: "falling",           alternates: ["fall-down"]),
        Group(label: "Hidden",    color: .gray,
              chosen: "hidden",            alternates: ["hooded-figure", "hood", "hooded-assassin"]),
        Group(label: "Invisible", color: .gray,
              chosen: "invisible",         alternates: ["ghost", "floating-ghost"]),
        Group(label: "Grouped",   color: .blue,
              chosen: "backup",            alternates: ["meeple-group"]),
        Group(label: "Stunned",   color: .yellow,
              chosen: "knockout",          alternates: ["knocked-out-stars"]),
        Group(label: "Bleeding",  color: .red,
              chosen: "bleeding-wound",    alternates: ["dripping-blade", "blood"]),
        Group(label: "Poisoned",  color: .green,
              chosen: "poison-bottle",     alternates: ["poison", "poison-cloud"]),
        Group(label: "Diseased",  color: .purple,
              chosen: "plague-doctor-profile", alternates: ["virus"]),
        Group(label: "Webbed",    color: .gray,
              chosen: "spider-web",        alternates: ["cobweb"]),
        Group(label: "Calmed",    color: .blue,
              chosen: "peace-dove",        alternates: ["lotus", "lotus-flower"]),
        Group(label: "Silenced",  color: .gray,
              chosen: "silenced",          alternates: ["silence", "mute"]),
        Group(label: "Dead",      color: .red,
              chosen: "skull-crossed-bones", alternates: ["tombstone", "coffin"]),
    ]

    struct Group {
        let label: String
        let color: Color
        let chosen: String
        let alternates: [String]
        var allNames: [String] { [chosen] + alternates }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                ForEach(Self.groups, id: \.label) { group in
                    row(for: group)
                }
            }
            .padding(20)
        }
        .frame(minWidth: 720, minHeight: 480)
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func row(for group: Group) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(group.color)
                    .frame(width: 4, height: 16)
                Text(group.label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            }
            HStack(alignment: .top, spacing: 14) {
                ForEach(group.allNames, id: \.self) { name in
                    cell(name: name, color: group.color, isChosen: name == group.chosen)
                }
                Spacer(minLength: 0)
            }
        }
    }

    @ViewBuilder
    private func cell(name: String, color: Color, isChosen: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                GameIcon(name: name)
                    .frame(width: 48, height: 48)
                    .foregroundStyle(color)
                    .padding(8)
                    .background(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isChosen ? color.opacity(0.9) : Color.white.opacity(0.08),
                                lineWidth: isChosen ? 1.5 : 1
                            )
                    )
                    .cornerRadius(6)

                if isChosen {
                    Image(systemName: "star.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(color)
                        .padding(3)
                }
            }
            Text(name)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .frame(width: 88)
    }
}
