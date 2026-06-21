import SwiftUI

/// "Vetro" backdrop: a warm sand base with large, soft, slowly-drifting colour
/// blooms (terracotta · olive · adriatic) that give the frosted-glass panels
/// above them real depth and a living, parallax feel. Kept low-contrast and
/// calm — the content stays the focus. (Name kept so every screen picks it up.)
struct MeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                ZStack {
                    LinearGradient(colors: [Palette.sandTop, Palette.sand, Palette.sandLow],
                                   startPoint: .top, endPoint: .bottom)

                    bloom(Palette.terracotta, w, h,
                          x: 0.22 + 0.06 * sin(t * 0.05),
                          y: 0.20 + 0.05 * cos(t * 0.04), r: 0.95, op: 0.30)
                    bloom(Palette.adriatic, w, h,
                          x: 0.82 + 0.05 * cos(t * 0.045),
                          y: 0.32 + 0.06 * sin(t * 0.05), r: 0.85, op: 0.22)
                    bloom(Palette.olive, w, h,
                          x: 0.30 + 0.07 * sin(t * 0.035),
                          y: 0.85 + 0.05 * cos(t * 0.05), r: 1.0, op: 0.22)

                    // Soft top sheen so glass panels read as lit from above.
                    LinearGradient(colors: [.white.opacity(0.35), .clear],
                                   startPoint: .top, endPoint: .center)
                        .blendMode(.softLight)
                }
                .ignoresSafeArea()
            }
            .ignoresSafeArea()
        }
    }

    private func bloom(_ color: Color, _ w: CGFloat, _ h: CGFloat,
                       x: Double, y: Double, r: Double, op: Double) -> some View {
        let size = min(w, h) * r
        return RadialGradient(colors: [color.opacity(op), .clear],
                              center: .center, startRadius: 0, endRadius: size / 2)
            .frame(width: size, height: size)
            .position(x: w * x, y: h * y)
            .blur(radius: 60)
    }
}
