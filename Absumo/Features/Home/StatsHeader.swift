import SwiftUI

/// Title + daily stats, shown at the top of the learning path.
struct StatsHeader: View {
    let user: UserState?

    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Absumo")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: Palette.tricolore,
                                       startPoint: .leading, endPoint: .trailing)
                    )

                Text("io absumo l'italiano")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.65))

                HStack(spacing: 10) {
                    StatPill(icon: "flame.fill", value: "\(user?.streak ?? 0)", tint: Palette.rosso)
                    StatPill(icon: "bolt.fill", value: "\(user?.xp ?? 0)", tint: Palette.verde)
                    StatPill(icon: "heart.fill", value: "\(user?.hearts ?? 5)", tint: Palette.rosso)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
