import SwiftUI

/// Shared chrome for every exercise: a hint label, the prompt, the interactive
/// content, and a Check → feedback → Continue state machine.
struct ExerciseScaffold<Content: View>: View {
    let hint: String
    let prompt: String
    let canCheck: Bool
    /// Evaluated when the learner taps Check; returns whether they were correct.
    let evaluate: () -> Bool
    /// Shown in the feedback bar when the answer is wrong.
    let solution: String
    let onAnswered: (Bool) -> Void
    @ViewBuilder var content: () -> Content

    private enum Phase: Equatable { case answering, checked(Bool) }
    @State private var phase: Phase = .answering

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(hint)
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(Palette.terracotta)

            Text(prompt)
                .font(.serifDisplay(28, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            content()
                .disabled(phase != .answering)

            Spacer(minLength: 12)

            footer
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch phase {
        case .answering:
            PrimaryButton(title: "Check", tint: Palette.terracotta) {
                let correct = evaluate()
                Haptics.notify(correct)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    phase = .checked(correct)
                }
            }
            .opacity(canCheck ? 1 : 0.4)
            .disabled(!canCheck)

        case .checked(let correct):
            FeedbackBar(correct: correct, solution: solution) {
                onAnswered(correct)
            }
        }
    }
}
