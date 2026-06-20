import SwiftUI

/// Celebratory end-of-lesson summary.
struct ResultsView: View {
    let correct: Int
    let total: Int
    let onContinue: () -> Void

    private var xp: Int { correct * 10 }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Palette.verde.opacity(0.18))
                    .frame(width: 180, height: 180)
                    .blur(radius: 12)
                Image(systemName: "trophy.fill")
                    .font(.system(size: 84))
                    .foregroundStyle(
                        LinearGradient(colors: [Palette.verde, Palette.bianco],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .shadow(color: Palette.verde.opacity(0.6), radius: 20)
            }

            Text("Bravo!")
                .font(.system(size: 46, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: Palette.tricolore,
                                   startPoint: .leading, endPoint: .trailing)
                )

            Text("\(correct) / \(total) correct")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                StatPill(icon: "bolt.fill", value: "+\(xp) XP", tint: Palette.verde)
                StatPill(icon: "target", value: "\(Int(Double(correct) / Double(max(total, 1)) * 100))%",
                         tint: Palette.rosso)
            }

            Spacer()

            PrimaryButton(title: "Continue", systemImage: "checkmark", tint: Palette.verde,
                          action: onContinue)
        }
        .frame(maxWidth: .infinity)
    }
}
