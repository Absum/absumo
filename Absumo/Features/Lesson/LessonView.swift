import SwiftUI

/// Runs a lesson as a sequence of exercises, then shows results.
struct LessonView: View {
    let lesson: Lesson
    /// Called once on completion with (correctCount, totalExercises).
    let onFinish: (Int, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0
    @State private var correctCount = 0
    @State private var finished = false

    var body: some View {
        ZStack {
            MeshBackground()

            VStack(spacing: 24) {
                topBar

                if finished {
                    ResultsView(correct: correctCount, total: lesson.exercises.count) {
                        onFinish(correctCount, lesson.exercises.count)
                        dismiss()
                    }
                    .transition(.opacity.combined(with: .scale))
                } else {
                    exerciseView(lesson.exercises[index])
                        .id(index)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.headline.bold())
                    .foregroundStyle(.white.opacity(0.7))
            }

            ProgressView(value: Double(finished ? lesson.exercises.count : index),
                         total: Double(lesson.exercises.count))
                .tint(Palette.verde)

            HStack(spacing: 4) {
                Image(systemName: "heart.fill").foregroundStyle(Palette.rosso)
                Text("5").fontWeight(.heavy)
            }
            .font(.subheadline)
            .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private func exerciseView(_ exercise: Exercise) -> some View {
        switch exercise {
        case .multipleChoice(let data):
            MultipleChoiceView(data: data, onAnswered: advance)
        case .wordBank(let data):
            WordBankView(data: data, onAnswered: advance)
        case .matchPairs(let data):
            MatchPairsView(data: data, onAnswered: advance)
        }
    }

    private func advance(correct: Bool) {
        if correct { correctCount += 1 }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if index + 1 < lesson.exercises.count {
                index += 1
            } else {
                finished = true
            }
        }
    }
}
