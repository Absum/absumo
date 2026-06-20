import SwiftUI

/// Title + daily stats, shown at the top of the learning path.
struct StatsHeader: View {
    let user: UserState?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Absumo")
                    .font(.serifDisplay(46, weight: .bold))
                    .foregroundStyle(Palette.ink)

                // A quiet tricolore hairline — Italian identity, no fanfare.
                HStack(spacing: 0) {
                    ForEach(Array(Palette.tricolore.enumerated()), id: \.offset) { _, c in
                        c.frame(height: 3)
                    }
                }
                .frame(width: 96)
                .clipShape(Capsule())

                Text("io absumo l'italiano")
                    .font(.headline.weight(.regular))
                    .italic()
                    .foregroundStyle(Palette.inkSoft)

                HStack(spacing: 10) {
                    StatPill(icon: "flame.fill", value: "\(user?.streak ?? 0)", tint: Palette.terracotta)
                    StatPill(icon: "leaf.fill", value: "\(user?.xp ?? 0)", tint: Palette.olive)
                    StatPill(icon: "heart.fill", value: "\(user?.hearts ?? 5)", tint: Palette.rosso)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
