import SwiftUI

/// A sunlit Mediterranean wash: a warm sand mesh-gradient that drifts almost
/// imperceptibly, lit from the top like late-afternoon light, with the faintest
/// blooms of terracotta and olive. Calm and quiet — it sits behind the content,
/// never competing with it.
struct MeshBackground: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // A very slow, small drift so the light feels alive but never busy.
            let dx = Float(sin(t * 0.12)) * 0.05
            let dy = Float(cos(t * 0.09)) * 0.05

            ZStack {
                MeshGradient(
                    width: 3,
                    height: 3,
                    points: [
                        SIMD2(0, 0),               SIMD2(0.5, 0),                SIMD2(1, 0),
                        SIMD2(0, 0.5),             SIMD2(0.5 + dx, 0.5 + dy),    SIMD2(1, 0.5),
                        SIMD2(0, 1),               SIMD2(0.5, 1),                SIMD2(1, 1)
                    ],
                    // All stops must be opaque — a translucent stop lets black
                    // show through the mesh. These are sand with the faintest
                    // warm (terracotta) / cool (olive) lean baked in.
                    colors: [
                        Palette.sandTop,            Palette.sandTop,   Palette.cardSoft,
                        Color(hex: 0xF1DFC6),       Palette.sand,      Color(hex: 0xE9E6CB),
                        Palette.sand,               Palette.sandLow,   Palette.sandLow
                    ]
                )
                .ignoresSafeArea()

                // A soft "sun" highlight in the upper area.
                RadialGradient(colors: [Palette.sandTop.opacity(0.9), .clear],
                               center: .init(x: 0.5, y: 0.12),
                               startRadius: 0, endRadius: 360)
                    .ignoresSafeArea()
                    .blendMode(.screen)
            }
        }
    }
}
