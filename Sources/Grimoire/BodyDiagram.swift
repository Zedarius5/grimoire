import SwiftUI
import GrimoireKit

/// A stylized front-view body silhouette that colors each region by its
/// current wound / scar severity. Designed to sit at the top of the UberBar
/// dialog as Wrayth does, scaling to fit the available width.
struct BodyDiagram: View {
    let wounds: Wounds

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(BodyDiagramLayout.regions) { region in
                    let info = wounds.parts[region.part] ?? WoundInfo()
                    region.view(
                        in: rect(for: region, size: geo.size),
                        stroke: Color.white.opacity(0.18),
                        fill: fillColor(for: info),
                        hatched: info.injury == 0 && info.scar > 0
                    )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .aspectRatio(BodyDiagramLayout.aspect, contentMode: .fit)
        .frame(maxWidth: 110, maxHeight: 120)
        .padding(.vertical, 1)
        .help(tooltipText)
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

    private func rect(for region: BodyRegion, size: CGSize) -> CGRect {
        CGRect(
            x: (region.x - region.w / 2) * size.width,
            y: (region.y - region.h / 2) * size.height,
            width: region.w * size.width,
            height: region.h * size.height
        )
    }

    /// Injury wins over scar. Injuries use warm hues (yellow/orange/red).
    /// Scars use a cool palette (cyan/teal/violet) AND a diagonal hatch
    /// overlay — distinguishable by colour family *and* by texture so they
    /// don't blur together at a glance.
    private func fillColor(for info: WoundInfo) -> Color? {
        if info.injury > 0 {
            switch info.injury {
            case 1:  return Color(red: 1.00, green: 0.96, blue: 0.05).opacity(0.95) // bright yellow
            case 2:  return Color(red: 1.00, green: 0.48, blue: 0.05).opacity(0.95) // saturated orange
            default: return Color(red: 0.95, green: 0.10, blue: 0.10).opacity(0.95) // bright red
            }
        }
        if info.scar > 0 {
            switch info.scar {
            case 1:  return Color(red: 0.78, green: 0.64, blue: 0.45).opacity(0.85) // pale tan
            case 2:  return Color(red: 0.62, green: 0.42, blue: 0.25).opacity(0.90) // medium brown
            default: return Color(red: 0.40, green: 0.22, blue: 0.12).opacity(0.95) // dark brown
            }
        }
        return nil
    }
}

/// Diagonal hatching, drawn line-by-line so a containing `.clipShape` keeps
/// the strokes inside whatever body region they're decorating.
struct DiagonalHatch: Shape {
    var spacing: CGFloat = 4

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let diag = rect.width + rect.height
        var offset: CGFloat = -rect.height
        while offset < diag {
            path.move(to: CGPoint(x: rect.minX + offset, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + offset + rect.height,
                                     y: rect.minY + rect.height))
            offset += spacing
        }
        return path
    }
}

// MARK: - Layout

/// Normalized (0–1) layout of each body region inside the diagram. Positions
/// are eyeballed to look like a stylized front-view human figure.
private struct BodyRegion: Identifiable {
    let part: BodyPart
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat
    let kind: Kind

    var id: BodyPart { part }

    enum Kind { case circle, capsule, rounded }

    func view(in rect: CGRect, stroke: Color, fill: Color?, hatched: Bool) -> some View {
        ZStack {
            shapeOutline.stroke(stroke, lineWidth: 1)
            if let fill {
                shapeOutline.fill(fill)
                if hatched {
                    DiagonalHatch(spacing: 3)
                        .stroke(Color.white.opacity(0.55), lineWidth: 0.8)
                        .clipShape(shapeOutline)
                }
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    private var shapeOutline: AnyShape {
        switch kind {
        case .circle:  return AnyShape(Circle())
        case .capsule: return AnyShape(Capsule())
        case .rounded: return AnyShape(RoundedRectangle(cornerRadius: 3))
        }
    }
}

private enum BodyDiagramLayout {
    static let aspect: CGFloat = 100.0 / 160.0

    static let regions: [BodyRegion] = [
        // Eyes float above the head, Wrayth-style.
        BodyRegion(part: .leftEye,  x: 0.32, y: 0.05, w: 0.10, h: 0.06, kind: .circle),
        BodyRegion(part: .rightEye, x: 0.68, y: 0.05, w: 0.10, h: 0.06, kind: .circle),

        // Head & neck — small head, thin neck connecting to chest.
        BodyRegion(part: .head,     x: 0.50, y: 0.16, w: 0.18, h: 0.13, kind: .circle),
        BodyRegion(part: .neck,     x: 0.50, y: 0.255, w: 0.07, h: 0.04, kind: .rounded),

        // Torso — chest is narrower so arms clearly sit beside it.
        BodyRegion(part: .chest,    x: 0.50, y: 0.36, w: 0.22, h: 0.16, kind: .rounded),
        BodyRegion(part: .abdomen,  x: 0.50, y: 0.51, w: 0.18, h: 0.09, kind: .rounded),
        BodyRegion(part: .back,     x: 0.50, y: 0.31, w: 0.05, h: 0.025, kind: .rounded),
        BodyRegion(part: .nsys,     x: 0.50, y: 0.44, w: 0.05, h: 0.025, kind: .rounded),

        // Arms pushed outward with a clear gap from the torso.
        BodyRegion(part: .leftArm,  x: 0.20, y: 0.42, w: 0.10, h: 0.26, kind: .capsule),
        BodyRegion(part: .rightArm, x: 0.80, y: 0.42, w: 0.10, h: 0.26, kind: .capsule),
        BodyRegion(part: .leftHand,  x: 0.18, y: 0.61, w: 0.11, h: 0.07, kind: .circle),
        BodyRegion(part: .rightHand, x: 0.82, y: 0.61, w: 0.11, h: 0.07, kind: .circle),

        // Legs with a clear central gap.
        BodyRegion(part: .leftLeg,  x: 0.40, y: 0.78, w: 0.11, h: 0.32, kind: .capsule),
        BodyRegion(part: .rightLeg, x: 0.60, y: 0.78, w: 0.11, h: 0.32, kind: .capsule),
    ]
}
