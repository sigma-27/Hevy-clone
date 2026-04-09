import SwiftUI

/// A front/back body map that highlights primary and secondary muscles.
struct MuscleDiagramView: View {
    var primaryMuscles: [String]
    var secondaryMuscles: [String]
    @State private var isFront = true

    var body: some View {
        VStack(spacing: 10) {
            Picker("Side", selection: $isFront) {
                Text("Front").tag(true)
                Text("Back").tag(false)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Canvas { ctx, size in
                let scale = min(size.width / 200, size.height / 420)
                let ox = (size.width - 200 * scale) / 2
                let oy = (size.height - 420 * scale) / 2
                ctx.translateBy(x: ox, y: oy)
                ctx.scaleBy(x: scale, y: scale)
                drawBackground(in: &ctx)
                let regions = isFront ? frontRegions : backRegions
                for r in regions {
                    let isPrimary = primaryMuscles.contains(r.muscle)
                    let isSecondary = !isPrimary && secondaryMuscles.contains(r.muscle)
                    if isPrimary {
                        ctx.fill(r.path, with: .color(.red.opacity(0.80)))
                        ctx.stroke(r.path, with: .color(.red), lineWidth: 0.8)
                    } else if isSecondary {
                        ctx.fill(r.path, with: .color(.orange.opacity(0.70)))
                        ctx.stroke(r.path, with: .color(.orange), lineWidth: 0.8)
                    }
                }
            }
            .frame(height: 300)
            .animation(.easeInOut(duration: 0.2), value: isFront)

            HStack(spacing: 20) {
                Label("Primary", systemImage: "circle.fill").foregroundStyle(.red)
                Label("Secondary", systemImage: "circle.fill").foregroundStyle(.orange)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Muscle Regions

    struct Region {
        let muscle: String
        let path: Path
    }

    private var frontRegions: [Region] {
        [
            // Neck
            .init(muscle: "neck",        path: rect(88, 52, 24, 16, 4)),
            // Chest
            .init(muscle: "chest",       path: rect(74, 92, 52, 38, 8)),
            // Front delt / shoulders
            .init(muscle: "front_delt",  path: ellipse(48, 76, 28, 22)),
            .init(muscle: "front_delt",  path: ellipse(124, 76, 28, 22)),
            .init(muscle: "shoulders",   path: ellipse(48, 76, 28, 22)),
            .init(muscle: "shoulders",   path: ellipse(124, 76, 28, 22)),
            // Biceps
            .init(muscle: "biceps",      path: rect(37, 102, 20, 52, 9)),
            .init(muscle: "biceps",      path: rect(143, 102, 20, 52, 9)),
            // Forearms
            .init(muscle: "forearms",    path: rect(35, 157, 17, 54, 7)),
            .init(muscle: "forearms",    path: rect(148, 157, 17, 54, 7)),
            // Abs / Core
            .init(muscle: "abs",         path: rect(80, 132, 40, 54, 6)),
            .init(muscle: "core",        path: rect(80, 132, 40, 54, 6)),
            // Obliques
            .init(muscle: "obliques",    path: rect(67, 138, 13, 42, 5)),
            .init(muscle: "obliques",    path: rect(120, 138, 13, 42, 5)),
            // Hip flexors
            .init(muscle: "hip_flexors", path: rect(70, 188, 28, 18, 5)),
            .init(muscle: "hip_flexors", path: rect(102, 188, 28, 18, 5)),
            // Quads
            .init(muscle: "quads",       path: rect(68, 210, 30, 88, 12)),
            .init(muscle: "quads",       path: rect(102, 210, 30, 88, 12)),
            // Adductors
            .init(muscle: "adductors",   path: rect(88, 228, 14, 62, 6)),
            // Abductors
            .init(muscle: "abductors",   path: rect(62, 214, 10, 60, 5)),
            .init(muscle: "abductors",   path: rect(128, 214, 10, 60, 5)),
            // Calves (tibialis)
            .init(muscle: "calves",      path: rect(70, 305, 24, 58, 9)),
            .init(muscle: "calves",      path: rect(106, 305, 24, 58, 9)),
        ]
    }

    private var backRegions: [Region] {
        [
            // Neck
            .init(muscle: "neck",        path: rect(88, 52, 24, 16, 4)),
            // Traps
            .init(muscle: "traps",       path: trapezoid(76, 68, 48, 80, 36, 32)),
            // Rear delt / shoulders
            .init(muscle: "rear_delt",   path: ellipse(48, 76, 28, 22)),
            .init(muscle: "rear_delt",   path: ellipse(124, 76, 28, 22)),
            .init(muscle: "shoulders",   path: ellipse(48, 76, 28, 22)),
            .init(muscle: "shoulders",   path: ellipse(124, 76, 28, 22)),
            // Lats
            .init(muscle: "lats",        path: latShape(left: true)),
            .init(muscle: "lats",        path: latShape(left: false)),
            // Upper / mid back
            .init(muscle: "back",        path: rect(80, 100, 40, 66, 6)),
            .init(muscle: "mid_back",    path: rect(82, 118, 36, 40, 5)),
            .init(muscle: "rhomboids",   path: rect(82, 100, 36, 24, 5)),
            // Lower back
            .init(muscle: "lower_back",  path: rect(82, 168, 36, 22, 5)),
            // Triceps
            .init(muscle: "triceps",     path: rect(37, 102, 20, 52, 9)),
            .init(muscle: "triceps",     path: rect(143, 102, 20, 52, 9)),
            // Forearms
            .init(muscle: "forearms",    path: rect(35, 157, 17, 54, 7)),
            .init(muscle: "forearms",    path: rect(148, 157, 17, 54, 7)),
            // Glutes
            .init(muscle: "glutes",      path: rect(70, 193, 28, 26, 10)),
            .init(muscle: "glutes",      path: rect(102, 193, 28, 26, 10)),
            // Hamstrings
            .init(muscle: "hamstrings",  path: rect(68, 218, 30, 82, 12)),
            .init(muscle: "hamstrings",  path: rect(102, 218, 30, 82, 12)),
            // Calves
            .init(muscle: "calves",      path: rect(70, 305, 24, 58, 9)),
            .init(muscle: "calves",      path: rect(106, 305, 24, 58, 9)),
        ]
    }

    // MARK: - Path Helpers

    private func ellipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
    }

    private func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: r)
    }

    private func trapezoid(_ x: CGFloat, _ y: CGFloat,
                           _ topW: CGFloat, _ botW: CGFloat,
                           _ cx: CGFloat, _ h: CGFloat) -> Path {
        var p = Path()
        let left1 = cx - topW / 2
        let right1 = cx - topW / 2 + topW
        let left2 = cx - botW / 2
        let right2 = cx - botW / 2 + botW
        p.move(to: CGPoint(x: x + left1, y: y))
        p.addLine(to: CGPoint(x: x + right1, y: y))
        p.addLine(to: CGPoint(x: x + right2, y: y + h))
        p.addLine(to: CGPoint(x: x + left2, y: y + h))
        p.closeSubpath()
        return p
    }

    private func latShape(left: Bool) -> Path {
        var p = Path()
        if left {
            p.move(to: CGPoint(x: 70, y: 100))
            p.addLine(to: CGPoint(x: 80, y: 100))
            p.addLine(to: CGPoint(x: 82, y: 170))
            p.addLine(to: CGPoint(x: 68, y: 192))
            p.addCurve(to: CGPoint(x: 70, y: 100),
                       control1: CGPoint(x: 50, y: 165),
                       control2: CGPoint(x: 52, y: 125))
        } else {
            p.move(to: CGPoint(x: 130, y: 100))
            p.addLine(to: CGPoint(x: 120, y: 100))
            p.addLine(to: CGPoint(x: 118, y: 170))
            p.addLine(to: CGPoint(x: 132, y: 192))
            p.addCurve(to: CGPoint(x: 130, y: 100),
                       control1: CGPoint(x: 150, y: 165),
                       control2: CGPoint(x: 148, y: 125))
        }
        p.closeSubpath()
        return p
    }

    // MARK: - Body Outline

    private func drawBackground(in ctx: inout GraphicsContext) {
        let fill = Color(.systemGray5)
        let stroke = Color(.systemGray3)

        func draw(_ path: Path) {
            ctx.fill(path, with: .color(fill))
            ctx.stroke(path, with: .color(stroke), lineWidth: 1)
        }

        // Head
        draw(ellipse(78, 8, 44, 50))
        // Neck
        draw(rect(90, 56, 20, 18, 3))
        // Shoulders
        draw(ellipse(44, 74, 32, 24))
        draw(ellipse(124, 74, 32, 24))
        // Torso
        draw(rect(70, 72, 60, 126, 8))
        // Upper arms
        draw(rect(36, 82, 22, 76, 10))
        draw(rect(142, 82, 22, 76, 10))
        // Forearms
        draw(rect(34, 160, 18, 60, 8))
        draw(rect(148, 160, 18, 60, 8))
        // Hands
        draw(ellipse(34, 218, 18, 14))
        draw(ellipse(148, 218, 18, 14))
        // Hips
        draw(rect(66, 195, 68, 22, 6))
        // Thighs
        draw(rect(66, 212, 32, 96, 12))
        draw(rect(102, 212, 32, 96, 12))
        // Lower legs
        draw(rect(68, 310, 28, 68, 10))
        draw(rect(104, 310, 28, 68, 10))
        // Feet
        draw(ellipse(58, 376, 42, 16))
        draw(ellipse(100, 376, 42, 16))
    }
}

// MARK: - Preview

#Preview {
    MuscleDiagramView(
        primaryMuscles: ["chest", "front_delt"],
        secondaryMuscles: ["triceps", "shoulders"]
    )
    .padding()
}
