import SwiftUI
import SwiftData

/// A recall-first SRS session: the learner sees the prompt, *attempts to recall*
/// the answer, reveals it, then self-grades. Grading drives the FSRS scheduler.
/// This is deliberately active recall — not passive multiple-choice — per the
/// retrieval-practice evidence.
struct ReviewSessionView: View {
    let cards: [Card]
    var onFinish: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    private let fsrs = FSRS()

    @State private var index = 0
    @State private var revealed = false
    @State private var reviewed = 0

    private var current: Card? { index < cards.count ? cards[index] : nil }
    private var finished: Bool { index >= cards.count }

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 24) {
                topBar
                if let card = current {
                    Spacer()
                    prompt(card)
                    Spacer()
                    footer(card)
                } else {
                    Spacer()
                    summary
                    Spacer()
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Pieces

    private var topBar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(Palette.inkSoft)
            }
            ProgressView(value: Double(index), total: Double(max(cards.count, 1)))
                .tint(Palette.terracotta)
            Text("\(min(index + 1, cards.count))/\(cards.count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
                .monospacedDigit()
        }
    }

    private func prompt(_ card: Card) -> some View {
        VStack(spacing: 18) {
            Text(card.italian)
                .font(.serifDisplay(44, weight: .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)

            if revealed {
                VStack(spacing: 12) {
                    Text(card.english)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Palette.terracotta)
                    if !card.example.isEmpty {
                        Text(card.example)
                            .font(.body)
                            .italic()
                            .foregroundStyle(Palette.inkSoft)
                            .multilineTextAlignment(.center)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Text("Recall the meaning…")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkFaint)
            }
        }
    }

    @ViewBuilder
    private func footer(_ card: Card) -> some View {
        if revealed {
            HStack(spacing: 10) {
                gradeButton(.again, "Again", Palette.rosso, card)
                gradeButton(.hard,  "Hard",  Palette.terracotta, card)
                gradeButton(.good,  "Good",  Palette.olive, card)
                gradeButton(.easy,  "Easy",  Palette.adriatic, card)
            }
        } else {
            PrimaryButton(title: "Show answer", tint: Palette.terracotta) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { revealed = true }
            }
        }
    }

    private func gradeButton(_ rating: Rating, _ title: String, _ tint: Color, _ card: Card) -> some View {
        let days = fsrs.review(card, rating: rating).scheduledDays
        return Button {
            grade(rating, card)
        } label: {
            VStack(spacing: 4) {
                Text(title).font(.subheadline.weight(.bold))
                Text(intervalLabel(days)).font(.caption2).monospacedDigit().opacity(0.9)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Palette.gradient(tint), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private var summary: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundStyle(Palette.olive)
            Text("Fatto!")
                .font(.serifDisplay(40, weight: .bold))
                .foregroundStyle(Palette.ink)
            Text("\(reviewed) cards reviewed")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Palette.inkSoft)
            PrimaryButton(title: "Done", systemImage: "checkmark", tint: Palette.terracotta) {
                onFinish()
                dismiss()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Logic

    private func grade(_ rating: Rating, _ card: Card) {
        Haptics.notify(rating != .again)
        let log = fsrs.apply(rating, to: card, at: .now)
        context.insert(log)
        try? context.save()
        reviewed += 1
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            revealed = false
            index += 1
        }
    }

    private func intervalLabel(_ days: Double) -> String {
        switch days {
        case ..<1:    return "<1d"
        case ..<30:   return "\(Int(days))d"
        case ..<365:  return "\(Int((days / 30).rounded()))mo"
        default:      return "\(Int((days / 365).rounded()))y"
        }
    }
}
