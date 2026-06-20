import SwiftUI

/// End-of-lesson summary — warm and quietly congratulatory.
struct ResultsView: View {
    let correct: Int
    let total: Int
    let onContinue: () -> Void

    private var xp: Int { correct * 10 }
    private var pct: Int { Int(Double(correct) / Double(max(total, 1)) * 100) }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Palette.terracotta.opacity(0.12))
                    .frame(width: 180, height: 180)
                Image(systemName: "laurel.leading")
                    .font(.system(size: 96))
                    .foregroundStyle(Palette.olive)
                    .overlay(
                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 96))
                            .foregroundStyle(Palette.olive)
                    )
                Image(systemName: "star.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Palette.terracotta)
            }

            Text("Bravo!")
                .font(.serifDisplay(48, weight: .bold))
                .foregroundStyle(Palette.ink)

            Text("\(correct) / \(total) correct")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)

            HStack(spacing: 12) {
                StatPill(icon: "leaf.fill", value: "+\(xp) XP", tint: Palette.olive)
                StatPill(icon: "target", value: "\(pct)%", tint: Palette.terracotta)
            }

            Spacer()

            PrimaryButton(title: "Continue", systemImage: "checkmark", tint: Palette.terracotta,
                          action: onContinue)
        }
        .frame(maxWidth: .infinity)
    }
}
