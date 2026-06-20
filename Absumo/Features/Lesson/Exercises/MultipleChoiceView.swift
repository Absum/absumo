import SwiftUI

struct MultipleChoiceView: View {
    let data: MultipleChoice
    let onAnswered: (Bool) -> Void

    @State private var selected: Int?

    var body: some View {
        ExerciseScaffold(
            hint: "CHOOSE",
            prompt: data.prompt,
            canCheck: selected != nil,
            evaluate: { selected == data.answerIndex },
            solution: data.options[data.answerIndex],
            onAnswered: onAnswered
        ) {
            VStack(spacing: 12) {
                ForEach(Array(data.options.enumerated()), id: \.offset) { index, option in
                    ChoiceRow(text: option, selected: selected == index) {
                        selected = index
                    }
                }
            }
        }
    }
}
