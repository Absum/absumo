import SwiftUI

/// Tap words from the bank to build the translation; tap them back to remove.
struct WordBankView: View {
    let data: WordBank
    let onAnswered: (Bool) -> Void

    @State private var chosen: [String] = []
    @State private var bank: [String] = []
    @State private var loaded = false

    var body: some View {
        ExerciseScaffold(
            hint: "TRANSLATE",
            prompt: data.prompt,
            canCheck: !chosen.isEmpty,
            evaluate: { chosen == data.answer },
            solution: data.answer.joined(separator: " "),
            onAnswered: onAnswered
        ) {
            VStack(spacing: 18) {
                // Answer line
                FlowLayout {
                    ForEach(Array(chosen.enumerated()), id: \.offset) { index, word in
                        Chip(text: word, tint: Palette.terracotta, filled: true) {
                            chosen.remove(at: index)
                            bank.append(word)
                        }
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 56, alignment: .topLeading)
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(Palette.hairline).frame(height: 1)
                }

                // Word bank
                FlowLayout {
                    ForEach(Array(bank.enumerated()), id: \.offset) { index, word in
                        Chip(text: word) {
                            bank.remove(at: index)
                            chosen.append(word)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .onAppear {
            guard !loaded else { return }
            bank = (data.answer + data.distractors).shuffled()
            loaded = true
        }
    }
}
