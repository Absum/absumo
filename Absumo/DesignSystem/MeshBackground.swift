import SwiftUI

/// A continuously drifting mesh-gradient backdrop in the Italian tricolore.
/// The centre control point orbits slowly, so the colours breathe and flow.
struct MeshBackground: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let dx = Float(sin(t * 0.45)) * 0.16
            let dy = Float(cos(t * 0.37)) * 0.16

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    SIMD2(0, 0),            SIMD2(0.5, 0),                 SIMD2(1, 0),
                    SIMD2(0, 0.5),          SIMD2(0.5 + dx, 0.5 + dy),     SIMD2(1, 0.5),
                    SIMD2(0, 1),            SIMD2(0.5, 1),                 SIMD2(1, 1)
                ],
                colors: [
                    Palette.ink,                       Palette.verdeDeep.opacity(0.65), Palette.ink2,
                    Palette.rossoDeep.opacity(0.55),   Palette.ink,                     Palette.verde.opacity(0.45),
                    Palette.ink2,                      Palette.rosso.opacity(0.45),     Palette.ink
                ]
            )
            .ignoresSafeArea()
            .overlay(Palette.ink.opacity(0.25).ignoresSafeArea())
        }
    }
}
