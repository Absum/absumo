import SwiftUI

/// The app's living signature: a softly breathing orb whose ring shows current
/// retention and whose centre shows words known. Replaces the row of stat pills
/// — knowledge made visible, the calm anti-XP motivator.
struct KnowledgeOrb: View {
    let wordsKnown: Int
    let retention: Double   // 0…1

    private let ring = LinearGradient(colors: [Palette.terracotta, Palette.adriatic],
                                      startPoint: .topLeading, endPoint: .bottomTrailing)

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let breath = 1 + 0.015 * sin(t * 1.1)            // gentle pulse
            ZStack {
                Circle()                                      // ambient glow
                    .fill(RadialGradient(colors: [Palette.terracotta.opacity(0.35), .clear],
                                         center: .center, startRadius: 0, endRadius: 130))
                    .blur(radius: 18)

                Circle()                                      // track
                    .stroke(Palette.ink.opacity(0.08), lineWidth: 12)

                if retention > 0.01 {
                    Circle()                                  // retention arc
                        .trim(from: 0, to: min(retention, 1))
                        .stroke(ring, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .shadow(color: Palette.terracotta.opacity(0.4), radius: 6)
                }

                VStack(spacing: 2) {
                    Text("\(wordsKnown)")
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.ink)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                    Text("parole")
                        .font(.caption.weight(.medium))
                        .tracking(2)
                        .foregroundStyle(Palette.inkSoft)
                    if retention > 0 {
                        Text("\(Int(retention * 100))% memoria")
                            .font(.caption2)
                            .foregroundStyle(Palette.adriatic)
                            .padding(.top, 2)
                    }
                }
            }
            .frame(width: 200, height: 200)
            .scaleEffect(breath)
        }
    }
}
