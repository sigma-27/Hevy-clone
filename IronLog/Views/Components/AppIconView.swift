import SwiftUI

/// Renders the IronLog app icon programmatically.
/// To generate the 1024×1024 PNG for Xcode:
///   1. Run the app in Simulator
///   2. Navigate to Settings → About, the icon preview renders there
///   3. Screenshot and crop, or use ImageRenderer in a script.
struct AppIconView: View {
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.08, blue: 0.10),
                         Color(red: 0.14, green: 0.10, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle grid lines
            Canvas { ctx, sz in
                let step: CGFloat = sz.width / 8
                let lineColor = Color.white.opacity(0.04)
                for i in 1..<8 {
                    let x = step * CGFloat(i)
                    var vp = Path()
                    vp.move(to: CGPoint(x: x, y: 0))
                    vp.addLine(to: CGPoint(x: x, y: sz.height))
                    ctx.stroke(vp, with: .color(lineColor), lineWidth: 0.5)

                    let y = step * CGFloat(i)
                    var hp = Path()
                    hp.move(to: CGPoint(x: 0, y: y))
                    hp.addLine(to: CGPoint(x: sz.width, y: y))
                    ctx.stroke(hp, with: .color(lineColor), lineWidth: 0.5)
                }
            }

            // Glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.orange.opacity(0.30), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.45
                    )
                )
                .frame(width: size * 0.85, height: size * 0.85)

            // Barbell icon
            BarbellShape()
                .stroke(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 1, green: 0.55, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: size * 0.055, lineCap: .round, lineJoin: .round)
                )
                .frame(width: size * 0.60, height: size * 0.60)
                .shadow(color: .orange.opacity(0.6), radius: size * 0.04)

            // "IronLog" wordmark at bottom
            VStack(spacing: 0) {
                Spacer()
                Text("IRONLOG")
                    .font(.system(size: size * 0.072, weight: .black, design: .rounded))
                    .tracking(size * 0.008)
                    .foregroundStyle(
                        LinearGradient(colors: [.white, Color.white.opacity(0.7)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .padding(.bottom, size * 0.09)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.224))  // iOS icon corner radius
    }
}

/// Simple barbell shape path
private struct BarbellShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let cx = rect.midX, cy = rect.midY

        // Bar
        p.move(to: CGPoint(x: cx - w * 0.46, y: cy))
        p.addLine(to: CGPoint(x: cx + w * 0.46, y: cy))

        // Left plates (two rectangles drawn as thick strokes via two parallel lines)
        let plateX1L = cx - w * 0.38
        let plateX2L = cx - w * 0.26
        let plateH = h * 0.38
        for x in [plateX1L, plateX2L] {
            p.move(to: CGPoint(x: x, y: cy - plateH / 2))
            p.addLine(to: CGPoint(x: x, y: cy + plateH / 2))
        }

        // Right plates
        let plateX1R = cx + w * 0.26
        let plateX2R = cx + w * 0.38
        for x in [plateX1R, plateX2R] {
            p.move(to: CGPoint(x: x, y: cy - plateH / 2))
            p.addLine(to: CGPoint(x: x, y: cy + plateH / 2))
        }

        return p
    }
}

#Preview {
    AppIconView(size: 300)
        .padding()
}
