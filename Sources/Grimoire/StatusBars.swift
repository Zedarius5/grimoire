import SwiftUI
import GrimoireKit

// MARK: - Room header

/// Slim strip rendered at the top of the story (main game) feed showing the
/// current room name. Hides when no room name has been seen yet.
struct RoomHeader: View {
    let state: GameState

    var body: some View {
        let name = state.roomName.trimmingCharacters(in: .whitespacesAndNewlines)

        if name.isEmpty {
            EmptyView()
        } else {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundStyle(GameTheme.roomName)
                Text(name)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(GameTheme.roomName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.55))
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundStyle(GameTheme.roomName.opacity(0.55)),
                alignment: .bottom
            )
            .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Hands strip

/// Compact row showing what the character is holding plus the spell ready to
/// cast. Sits above the main game feed in the Wrayth-style layout.
struct HandsStrip: View {
    let state: GameState

    var body: some View {
        HStack(spacing: 10) {
            HandCell(icon: "hand.point.left.fill",  caption: "Left",  text: state.leftHand)
            HandCell(icon: "hand.point.right.fill", caption: "Right", text: state.rightHand)
            HandCell(icon: "sparkles",              caption: "Spell", text: state.preparedSpell)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08)),
            alignment: .bottom
        )
        .environment(\.colorScheme, .dark)
    }
}

private struct HandCell: View {
    let icon: String
    let caption: String
    let text: String

    var isEmpty: Bool {
        text == "Empty" || text == "None" || text.isEmpty
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(isEmpty ? .secondary : GameTheme.roomName)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 0) {
                Text(caption.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isEmpty ? Color.secondary : Color.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(
                    isEmpty ? Color.clear : GameTheme.roomName.opacity(0.6),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Vitals bar

struct VitalsBar: View {
    let state: GameState

    var body: some View {
        HStack(spacing: 4) {
            VitalCell(label: "Health",  value: state.health,
                      color: Color(red: 0.85, green: 0.20, blue: 0.20))
            VitalCell(label: "Mana",    value: state.mana,
                      color: Color(red: 0.30, green: 0.55, blue: 1.00))
            VitalCell(label: "Stamina", value: state.stamina,
                      color: Color(red: 0.95, green: 0.70, blue: 0.20))
            VitalCell(label: "Spirit",  value: state.spirit,
                      color: Color(red: 0.80, green: 0.80, blue: 0.80))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .overlay(
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08)),
            alignment: .top
        )
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - Roundtime bricks (inline)

/// Wrayth-style roundtime indicator: each brick = one second. Designed to
/// sit inside the input bar (no background of its own — the parent provides
/// the container). Red bricks for hard RT, blue for spell/cast RT. When both
/// are active, hard sits on top of cast (half-height each); otherwise the
/// active one fills the input bar's height.
struct RoundtimeBricks: View {
    let state: GameState

    @State private var now: Date = Date()

    private static let hardColor    = Color(red: 0.92, green: 0.16, blue: 0.16)
    private static let castColor    = Color(red: 0.26, green: 0.48, blue: 1.00)
    private static let totalHeight: CGFloat = 22   // input-bar slot height
    private static let halfHeight:  CGFloat = 10   // per-row when both active
    private static let rowSpacing:  CGFloat = 2
    private static let brickWidth:  CGFloat = 14
    private static let brickSpacing: CGFloat = 2

    private var hardRemaining: Int { remainingSeconds(until: state.roundtimeEnd) }
    private var castRemaining: Int { remainingSeconds(until: state.castTimeEnd) }
    private var bothActive: Bool { hardRemaining > 0 && castRemaining > 0 }

    var body: some View {
        contents
            .frame(height: Self.totalHeight, alignment: .leading)
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { tick in
                now = tick
            }
    }

    /// Always occupies the strip height so the input bar doesn't change size
    /// when a roundtime starts or ends — the bricks just appear/disappear in
    /// place. `Color.clear` reserves the space when no RT is active.
    @ViewBuilder
    private var contents: some View {
        if hardRemaining == 0 && castRemaining == 0 {
            Color.clear
        } else if bothActive {
            VStack(alignment: .leading, spacing: Self.rowSpacing) {
                brickRow(count: hardRemaining, color: Self.hardColor, height: Self.halfHeight)
                brickRow(count: castRemaining, color: Self.castColor, height: Self.halfHeight)
            }
        } else if hardRemaining > 0 {
            brickRow(count: hardRemaining, color: Self.hardColor, height: Self.totalHeight)
        } else {
            brickRow(count: castRemaining, color: Self.castColor, height: Self.totalHeight)
        }
    }

    private func brickRow(count: Int, color: Color, height: CGFloat) -> some View {
        HStack(spacing: Self.brickSpacing) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: Self.brickWidth, height: height)
            }
        }
    }

    private func remainingSeconds(until end: TimeInterval?) -> Int {
        guard let end else { return 0 }
        return max(0, Int(ceil(end - now.timeIntervalSince1970)))
    }
}

private struct VitalCell: View {
    let label: String
    let value: VitalValue
    let color: Color

    var body: some View {
        ZStack {
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.black.opacity(0.5))
                Rectangle()
                    .fill(color.opacity(0.75))
                    .frame(width: geo.size.width * CGFloat(value.percent) / 100.0)
            }
            Text("\(label) \(displayText)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 8)
        }
        .frame(height: 20)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private var displayText: String {
        // Server sends e.g. "health 225/225"; strip the leading label.
        guard !value.text.isEmpty else { return "—" }
        let parts = value.text.split(separator: " ", maxSplits: 1)
        return parts.count == 2 ? String(parts[1]) : value.text
    }
}

