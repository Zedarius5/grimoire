import SwiftUI
import GrimoireKit

/// Animated GRIMOIRE title shown in the story-feed area when the client
/// isn't connected. Per-character shimmer (chaotic, top-heavy intensity,
/// per-cell hue/saturation drift) plus sparkle particles that emerge from
/// the `@` glyphs themselves and drift upward.
///
/// Designed in `~/Documents/Repositories/SigilProto` and ported here once
/// the look landed. Treat the prototype as the design source of truth —
/// changes worth keeping should round-trip through it.
struct SigilView: View {
    private let startDate = Date()

    var body: some View {
        ZStack {
            GameTheme.background

            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                // Clamp to non-negative — during AppKit window-state
                // restoration at launch, SwiftUI can sample the timeline
                // before `startDate` is captured, giving a tiny negative
                // `t`. That cascades to a negative `cycleNum` in
                // `drawParticle`, then a negative `spawnIdx`, then an
                // out-of-bounds array access. Pinning to ≥ 0 fixes all
                // of it at the source.
                let t = max(0, timeline.date.timeIntervalSince(startDate))

                VStack(spacing: 22) {
                    titleSection(t: t)
                    statusText(t: t)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Title section

    /// Title art + particle overlay. The canvas extends `particleTopMargin`
    /// above the title so particles have room to fade out after rising
    /// past the top row of letters.
    @ViewBuilder
    private func titleSection(t: Double) -> some View {
        let w = CGFloat(titleRows[0].count) * cellWidth
        let titleH = CGFloat(titleRows.count) * cellHeight
        let totalH = titleH + particleTopMargin

        ZStack(alignment: .topLeading) {
            particleCanvas(t: t)
                .frame(width: w, height: totalH)
                .allowsHitTesting(false)

            titleGrid(t: t)
                .padding(.top, particleTopMargin)
        }
        .frame(width: w, height: totalH)
    }

    private func titleGrid(t: Double) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<titleRows.count, id: \.self) { rowIdx in
                HStack(spacing: 0) {
                    ForEach(0..<titleRows[rowIdx].count, id: \.self) { colIdx in
                        animatedCharCell(
                            char: titleRows[rowIdx][colIdx],
                            col: colIdx,
                            row: rowIdx,
                            t: t
                        )
                    }
                }
            }
        }
    }

    /// Standard GLSL-style hash — `sin(dot(...) * BIG) mod 1` — for
    /// per-(col, row) pseudo-random values in [0, 1). Different (a, b, c)
    /// tuples give uncorrelated channels so scale, opacity, hue, and
    /// saturation each have their own "personality" per cell.
    private func cellHash(col: Int, row: Int, a: Double, b: Double, c: Double) -> Double {
        let v = sin(Double(col) * a + Double(row) * b) * c
        return v - floor(v)
    }

    /// Three-octave sine sum — a fundamental wave plus two faster, weaker
    /// harmonics. The composite reads as irregular natural wobble rather
    /// than a clean metronomic pulse. Output roughly -1…+1.
    private func octaveNoise(t: Double, baseFreq: Double, basePhase: Double) -> Double {
        let n1 = sin(t * baseFreq + basePhase)
        let n2 = sin(t * baseFreq * 2.31 + basePhase * 1.7) * 0.45
        let n3 = sin(t * baseFreq * 4.83 + basePhase * 2.4) * 0.20
        return (n1 + n2 + n3) / 1.65
    }

    /// One character cell. Scale and opacity each pulse on independent
    /// multi-octave noise; hue and saturation drift per-cell but stable
    /// in time. Top-heavy intensity gradient — heavy strokes at the top
    /// of each letter surge, shadow chars at the bottom just breathe.
    private func animatedCharCell(char: Character, col: Int, row: Int, t: Double) -> some View {
        let visibleRow = max(1, min(10, row))
        let topness = 1.0 - Double(visibleRow - 1) / 9.0
        let intensity = 0.3 + 0.7 * topness

        let hashS = cellHash(col: col, row: row, a: 12.9898, b: 78.233,  c: 43758.5)
        let hashO = cellHash(col: col, row: row, a:  7.4100, b: 31.700, c:  9821.3)
        let hashH = cellHash(col: col, row: row, a:  5.4100, b: 19.700, c:  7823.4)
        let hashSat = cellHash(col: col, row: row, a: 9.1300, b: 27.300, c:  6543.7)

        let hueOffset = (hashH - 0.5) * 0.06
        let satOffset = (hashSat - 0.5) * 0.18
        let cellColor = Color(
            hue: baseHue + hueOffset,
            saturation: max(0, min(1, baseSat + satOffset)),
            brightness: baseBright
        )

        let freqS = 2.5 + (hashS - 0.5) * 0.9
        let freqO = 1.8 + (hashO - 0.5) * 0.7
        let phaseS = hashS * 6.2831853
        let phaseO = hashO * 6.2831853

        let scaleAmplitude = 0.10 * intensity
        let scaleNoise = octaveNoise(t: t, baseFreq: freqS, basePhase: phaseS)
        let scale = 1.0 + scaleAmplitude * scaleNoise

        let opacityFloor = 1.0 - 0.5 * intensity
        let opacityNoise = octaveNoise(t: t, baseFreq: freqO, basePhase: phaseO)
        let bell = (opacityNoise + 1.0) / 2.0
        let opacity = opacityFloor + (1.0 - opacityFloor) * bell

        return Text(String(char))
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundStyle(cellColor)
            .frame(width: cellWidth, height: cellHeight)
            .scaleEffect(scale, anchor: .center)
            .opacity(opacity)
    }

    // MARK: - Particles

    private let numParticles = 28
    private let particleLifetime: Double = 3.8

    private func particleCanvas(t: Double) -> some View {
        Canvas { ctx, _ in
            for i in 0..<numParticles {
                drawParticle(ctx: ctx, t: t, index: i)
            }
        }
    }

    /// One particle. Spawns from a randomly-picked `@` cell each lifecycle,
    /// rises with ease-out, wobbles sideways on a per-particle sine wave
    /// whose amplitude grows with age, ages through ✦ → ✧ → ⋆ → ·, and
    /// fades. Final opacity capped at `particleMaxOpacity` so they stay
    /// a soft accent rather than competing with the title.
    private func drawParticle(ctx: GraphicsContext, t: Double, index i: Int) {
        let phase = Double(i) * (particleLifetime / Double(numParticles))
        let totalT = t + phase
        let lifeRaw = totalT.truncatingRemainder(dividingBy: particleLifetime)
        let lifeNorm = lifeRaw / particleLifetime
        let cycleNum = Int(floor(totalT / particleLifetime))

        // Swift's `%` can return a negative remainder for a negative
        // dividend. Normalise into `[0, count)` defensively so any future
        // negative `cycleNum` (e.g., a renderer-timing edge case) won't
        // index out of bounds.
        let count = atPositions.count
        let rawIdx = (i * 31) + (cycleNum * 17)
        let spawnIdx = ((rawIdx % count) + count) % count
        let spawn = atPositions[spawnIdx]
        let x0 = CGFloat(spawn.col) * cellWidth + cellWidth / 2
        let y0 = particleTopMargin + CGFloat(spawn.row) * cellHeight + cellHeight / 2

        let hashA = sin(Double(spawnIdx) * 13.7 + Double(cycleNum) * 0.9) * 0.5 + 0.5
        let hashB = sin(Double(spawnIdx) * 7.3 + Double(cycleNum) * 1.7 + 2.0) * 0.5 + 0.5

        let riseDistance: CGFloat = 110
        let easedLife = CGFloat(1 - pow(1 - lifeNorm, 1.8))
        let yPos = y0 - easedLife * riseDistance

        let baseDrift: CGFloat = CGFloat((hashB - 0.5) * 28)
        let swayAmp: CGFloat = CGFloat(lifeNorm) * 6.0 + 1.0
        let swayFreq: CGFloat = CGFloat(2.0 + hashA * 2.5)
        let swayPhase = hashA * 6.28
        let xSway = swayAmp * CGFloat(sin(lifeNorm * Double(swayFreq) * 6.28 + swayPhase))
        let xPos = x0 + baseDrift * CGFloat(lifeNorm) + xSway

        let glyph: String
        switch lifeNorm {
        case ..<0.20: glyph = "✦"
        case ..<0.45: glyph = "✧"
        case ..<0.70: glyph = "⋆"
        default:      glyph = "·"
        }

        let opacity: Double
        if lifeNorm < 0.10 {
            opacity = lifeNorm / 0.10
        } else if lifeNorm < 0.60 {
            opacity = 1.0
        } else {
            opacity = (1.0 - lifeNorm) / 0.40
        }

        let label = Text(glyph)
            .font(.system(size: 9, design: .monospaced))
            .foregroundColor(particleColor)

        var localCtx = ctx
        localCtx.opacity = opacity * particleMaxOpacity
        localCtx.draw(label, at: CGPoint(x: xPos, y: yPos))
    }

    // MARK: - Status text

    private func statusText(t: Double) -> some View {
        let dotCount = Int(t * 1.5) % 4
        let dots = String(repeating: ".", count: dotCount)
        // "Awaiting connection" stays anchored in place; the dots animate
        // in a fixed-width container after it. Without this split, the
        // VStack would re-centre the entire string each time a dot is
        // added and the text would shimmy left.
        return HStack(spacing: 0) {
            Text("Awaiting connection")
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(statusColor)
            Text(dots)
                .font(.system(size: 13, design: .monospaced))
                .foregroundStyle(statusColor)
                .frame(width: 28, alignment: .leading)  // 3 chars of SF Mono 13pt is ~24pt; pad for safety
        }
    }
}

// MARK: - File-private rendering constants

private let titleArt: [String] = [
    "                                                                          ",
    " @@@@@@@@  @@@@@@@   @@@  @@@@@@@@@@    @@@@@@   @@@  @@@@@@@   @@@@@@@@  ",
    "@@@@@@@@@  @@@@@@@@  @@@  @@@@@@@@@@@  @@@@@@@@  @@@  @@@@@@@@  @@@@@@@@  ",
    "!@@        @@!  @@@  @@!  @@! @@! @@!  @@!  @@@  @@!  @@!  @@@  @@!       ",
    "!@!        !@!  @!@  !@!  !@! !@! !@!  !@!  @!@  !@!  !@!  @!@  !@!       ",
    "!@! @!@!@  @!@!!@!   !!@  @!! !!@ @!@  @!@  !@!  !!@  @!@!!@!   @!!!:!    ",
    "!!! !!@!!  !!@!@!    !!!  !@!   ! !@!  !@!  !!!  !!!  !!@!@!    !!!!!:    ",
    ":!!   !!:  !!: :!!   !!:  !!:     !!:  !!:  !!!  !!:  !!: :!!   !!:       ",
    ":!:   !::  :!:  !:!  :!:  :!:     :!:  :!:  !:!  :!:  :!:  !:!  :!:       ",
    " ::: ::::  ::   :::   ::  :::     ::   ::::: ::   ::  ::   :::   :: ::::  ",
    " :: :: :    :   : :  :     :      :     : :  :   :     :   : :  : :: ::   ",
    "                                                                          ",
]

private let titleRows: [[Character]] = titleArt.map { Array($0) }

/// Every `@` cell in the title. Used as the spawn-position pool for
/// particles so they emerge from the letters themselves.
private let atPositions: [(col: Int, row: Int)] = {
    var positions: [(col: Int, row: Int)] = []
    for (rowIdx, row) in titleRows.enumerated() {
        for (colIdx, char) in row.enumerated() where char == "@" {
            positions.append((col: colIdx, row: rowIdx))
        }
    }
    return positions
}()

private let fontSize: CGFloat = 13
private let cellWidth: CGFloat = 7.8
private let cellHeight: CGFloat = 16

/// Vertical space above the title where particles continue to rise and
/// fade after leaving the letters.
private let particleTopMargin: CGFloat = 80

/// Base colour expressed in HSB so per-cell variation can shift hue and
/// saturation independently without leaving the "magical purple" zone.
private let baseHue: Double = 0.72
private let baseSat: Double = 0.53
private let baseBright: Double = 0.85
private let particleColor = Color(red: 0.90, green: 0.78, blue: 1.0)
private let statusColor = Color(red: 0.65, green: 0.70, blue: 0.85)

/// Particle opacity cap — keeps them a light decorative touch rather
/// than a primary visual element competing with the title.
private let particleMaxOpacity: Double = 0.4
