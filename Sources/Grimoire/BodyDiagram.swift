import SwiftUI
import GrimoireKit

/// Wounds widget for the UberBar dialog. A simple front-view paperdoll
/// silhouette with numbered "pip" overlays at each affected body part:
/// red for injuries, tan for scars, with the rank (1/2/3) printed inside.
///
/// Severity reads from both colour *and* number so it stays scannable at a
/// glance and remains accessible regardless of colour perception.
///
/// Parts without a natural front-view position render in the silhouette's
/// own dead-space zones rather than getting squeezed onto the body:
/// - **Eyes**: in the gap between the head and the shoulders (one per
///   side, with the pair pulled out wide so each pip is fully visible).
/// - **Back / Nrvs**: in the empty space beside the legs, under the
///   arms, with short labels below each pip so the user can tell which
///   is which.
struct BodyDiagram: View {
    let wounds: Wounds

    /// Total widget footprint. Tracked by `DialogPane.bodyDiagramWidth`
    /// and `bodyDiagramHeight` — keep both in sync if changed.
    static let totalSize = CGSize(width: 110, height: 150)

    var body: some View {
        let _ = Diagnostics.shared.recordPaneEval("BodyDiagram")
        return GeometryReader { geo in
            ZStack {
                SilhouetteShape()
                    .stroke(Color.white.opacity(0.28), lineWidth: 1)

                // Front-visible body parts.
                ForEach(PipAnchor.frontVisible) { anchor in
                    if let info = wounds.parts[anchor.part],
                       let kind = pipKind(for: info) {
                        WoundPip(
                            kind: kind,
                            rank: kind == .injury ? info.injury : info.scar,
                            size: anchor.size
                        )
                        .position(
                            x: anchor.x * geo.size.width,
                            y: anchor.y * geo.size.height
                        )
                    }
                }

                // Off-body parts — labeled pip+label vertical stacks in the
                // dead space outside the silhouette. Eyes sit above the
                // shoulders (one each side); back/nerves below, beside the
                // legs.
                ForEach(OffBodyAnchor.all) { anchor in
                    if let info = wounds.parts[anchor.part],
                       let kind = pipKind(for: info) {
                        VStack(spacing: 1) {
                            WoundPip(
                                kind: kind,
                                rank: kind == .injury ? info.injury : info.scar,
                                size: anchor.size
                            )
                            Text(anchor.label)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                                .fixedSize()
                        }
                        .position(
                            x: anchor.x * geo.size.width,
                            y: anchor.y * geo.size.height
                        )
                    }
                }
            }
        }
        .frame(width: Self.totalSize.width, height: Self.totalSize.height)
        .help(tooltipText)
    }

    private func pipKind(for info: WoundInfo) -> WoundPip.Kind? {
        if info.injury > 0 { return .injury }
        if info.scar > 0   { return .scar }
        return nil
    }

    private var tooltipText: String {
        let active = wounds.parts.filter { $0.value.injury > 0 || $0.value.scar > 0 }
        if active.isEmpty { return "No wounds or scars" }
        return active.map { part, info in
            var bits: [String] = []
            if info.injury > 0 { bits.append("injury \(info.injury)") }
            if info.scar   > 0 { bits.append("scar \(info.scar)") }
            return "\(part.rawValue): \(bits.joined(separator: ", "))"
        }.joined(separator: "\n")
    }
}

// MARK: - Pip

/// One numbered severity badge — red for injury, tan for scar, with the
/// rank (1/2/3) printed in the middle.
///
/// Uses the `N.circle.fill` SF Symbol family so the number is
/// type-set-centered by Apple's typography (rather than fighting with
/// `Text` baseline metrics, which leave the glyph visibly low inside
/// the circle). `.palette` rendering colours the digit as the primary
/// foreground and the circle as the secondary.
struct WoundPip: View {
    enum Kind { case injury, scar }

    let kind: Kind
    let rank: Int
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "\(rank).circle.fill")
            .resizable()
            .symbolRenderingMode(.palette)
            .foregroundStyle(
                kind == .injury
                    ? Color.white
                    : Color(red: 0.18, green: 0.09, blue: 0.04),
                kind == .injury
                    ? GameTheme.woundInjury
                    : GameTheme.woundScar
            )
            .frame(width: size, height: size)
    }
}

// MARK: - Silhouette shape

/// A stylized front-view human paperdoll outline drawn as a single Shape.
/// All sub-figures (head, neck, torso, arms, hands, legs) are added to one
/// `Path` so a single stroke renders the whole silhouette without seams.
///
/// Proportions are normalized to the shape's `rect` and tuned by eye to
/// look like a recognisable standing figure. Legs are intentionally
/// stopped well above the bottom edge so the off-body Back/Nrvs labels
/// have room to sit beside the lower body without colliding with feet.
struct SilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()

        // Head — slightly taller than wide.
        path.addEllipse(in: CGRect(
            x: 0.40 * w, y: 0.02 * h,
            width: 0.20 * w, height: 0.16 * h
        ))

        // Neck — short rounded rect bridging head to chest.
        path.addRoundedRect(
            in: CGRect(x: 0.45 * w, y: 0.17 * h, width: 0.10 * w, height: 0.06 * h),
            cornerSize: CGSize(width: 2, height: 2)
        )

        // Torso — trapezoidal subpath, shoulders wider than waist.
        var torso = Path()
        torso.move(to:   CGPoint(x: 0.31 * w, y: 0.23 * h))   // top-left shoulder
        torso.addLine(to: CGPoint(x: 0.69 * w, y: 0.23 * h))   // top-right shoulder
        torso.addLine(to: CGPoint(x: 0.63 * w, y: 0.58 * h))   // right hip
        torso.addLine(to: CGPoint(x: 0.37 * w, y: 0.58 * h))   // left hip
        torso.closeSubpath()
        path.addPath(torso)

        // Arms — capsules hanging at sides, just outside the shoulders.
        // Shortened so the figure's proportions read less spider-like
        // and so there's room for the eye labels above the shoulders.
        path.addRoundedRect(
            in: CGRect(x: 0.16 * w, y: 0.24 * h, width: 0.10 * w, height: 0.28 * h),
            cornerSize: CGSize(width: 5, height: 5)
        )
        path.addRoundedRect(
            in: CGRect(x: 0.74 * w, y: 0.24 * h, width: 0.10 * w, height: 0.28 * h),
            cornerSize: CGSize(width: 5, height: 5)
        )

        // Hands — ellipses at the bottom of each (shortened) arm. Same
        // size as before, shifted up to follow the arm endpoints.
        path.addEllipse(in: CGRect(
            x: 0.14 * w, y: 0.52 * h,
            width: 0.14 * w, height: 0.08 * h
        ))
        path.addEllipse(in: CGRect(
            x: 0.72 * w, y: 0.52 * h,
            width: 0.14 * w, height: 0.08 * h
        ))

        // Legs — capsules with a clear gap between them. Shortened
        // (was 0.58→0.98) so the Back/Nrvs labels can sit beside the
        // lower body without overlapping feet.
        path.addRoundedRect(
            in: CGRect(x: 0.36 * w, y: 0.58 * h, width: 0.12 * w, height: 0.32 * h),
            cornerSize: CGSize(width: 5, height: 5)
        )
        path.addRoundedRect(
            in: CGRect(x: 0.52 * w, y: 0.58 * h, width: 0.12 * w, height: 0.32 * h),
            cornerSize: CGSize(width: 5, height: 5)
        )

        return path
    }
}

// MARK: - Pip anchors

/// Where each front-visible body part's pip lands on the silhouette,
/// in normalized 0–1 coordinates. Back and nsys live in `OffBodyAnchor`
/// because they don't sit on the silhouette itself.
private struct PipAnchor: Identifiable {
    let part: BodyPart
    let x: CGFloat
    let y: CGFloat
    var size: CGFloat = 18

    var id: BodyPart { part }

    // Almost every pip is the standard 18pt — keeps the visual rhythm
    // even. Neck is the exception (14pt) because the neck band itself
    // is so narrow that a full-size pip would overflow into both the
    // head ellipse and the shoulder line at once.
    static let frontVisible: [PipAnchor] = [
        PipAnchor(part: .head,      x: 0.50, y: 0.10,  size: 18),
        PipAnchor(part: .neck,      x: 0.50, y: 0.20,  size: 14),

        // Torso.
        PipAnchor(part: .chest,     x: 0.50, y: 0.32,  size: 18),
        PipAnchor(part: .abdomen,   x: 0.50, y: 0.52,  size: 18),

        // Arms — capsule centers shifted up with the shorter arm length.
        PipAnchor(part: .leftArm,   x: 0.21, y: 0.37,  size: 18),
        PipAnchor(part: .rightArm,  x: 0.79, y: 0.37,  size: 18),

        // Hands sit at the wrist end of the (shortened) arms.
        PipAnchor(part: .leftHand,  x: 0.21, y: 0.56,  size: 18),
        PipAnchor(part: .rightHand, x: 0.79, y: 0.56,  size: 18),

        // Legs.
        PipAnchor(part: .leftLeg,   x: 0.42, y: 0.75,  size: 18),
        PipAnchor(part: .rightLeg,  x: 0.58, y: 0.75,  size: 18),
    ]
}

/// Body parts that have no natural pip-on-the-silhouette position.
/// Rendered as a labeled vertical pip+text stack in the dead space
/// outside the silhouette — eyes above the shoulders, back/nerves
/// below, beside the legs.
///
/// Labels are tuned for column-width balance: `L.Eye` / `R.Eye` for the
/// upper pair and `Back` / `Nrvs` for the lower pair so each side reads
/// at the same visual weight.
private struct OffBodyAnchor: Identifiable {
    let part: BodyPart
    let label: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat

    var id: BodyPart { part }

    static let all: [OffBodyAnchor] = [
        OffBodyAnchor(part: .leftEye,  label: "L.Eye", x: 0.16, y: 0.11, size: 18),
        OffBodyAnchor(part: .rightEye, label: "R.Eye", x: 0.84, y: 0.11, size: 18),
        OffBodyAnchor(part: .back,     label: "Back",  x: 0.16, y: 0.82, size: 18),
        OffBodyAnchor(part: .nsys,     label: "Nrvs",  x: 0.84, y: 0.82, size: 18),
    ]
}
