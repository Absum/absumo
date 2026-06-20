import SwiftUI

/// Tap an Italian word, then its English match. Correct pairs lock in green.
struct MatchPairsView: View {
    let data: MatchPairs
    let onAnswered: (Bool) -> Void

    @State private var italian: [String] = []
    @State private var english: [String] = []
    @State private var selectedIt: String?
    @State private var matchedIt: Set<String> = []
    @State private var wrong: String?
    @State private var loaded = false

    private var allMatched: Bool { matchedIt.count == data.pairs.count }

    private func english(for it: String) -> String? {
        data.pairs.first { $0.it == it }?.en
    }

    private func isMatched(en: String) -> Bool {
        data.pairs.contains { matchedIt.contains($0.it) && $0.en == en }
    }

    var body: some View {
        ExerciseScaffold(
            hint: "MATCH",
            prompt: data.prompt,
            canCheck: allMatched,
            evaluate: { true },
            solution: "",
            onAnswered: onAnswered
        ) {
            HStack(alignment: .top, spacing: 14) {
                column(items: italian, isLeft: true)
                column(items: english, isLeft: false)
            }
        }
        .onAppear {
            guard !loaded else { return }
            italian = data.pairs.map(\.it).shuffled()
            english = data.pairs.map(\.en).shuffled()
            loaded = true
        }
    }

    private func column(items: [String], isLeft: Bool) -> some View {
        VStack(spacing: 12) {
            ForEach(items, id: \.self) { word in
                let matched = isLeft ? matchedIt.contains(word) : isMatched(en: word)
                let selected = isLeft && selectedIt == word
                MatchTile(text: word,
                          matched: matched,
                          selected: selected,
                          flash: wrong == word) {
                    tap(word, isLeft: isLeft)
                }
                .disabled(matched)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tap(_ word: String, isLeft: Bool) {
        Haptics.tap()
        if isLeft {
            selectedIt = word
            return
        }
        guard let chosen = selectedIt, let correct = english(for: chosen) else { return }
        if correct == word {
            matchedIt.insert(chosen)
            selectedIt = nil
            Haptics.notify(true)
        } else {
            Haptics.notify(false)
            flashWrong(word)
            selectedIt = nil
        }
    }

    private func flashWrong(_ word: String) {
        withAnimation { wrong = word }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { wrong = nil }
        }
    }
}

private struct MatchTile: View {
    let text: String
    let matched: Bool
    let selected: Bool
    let flash: Bool
    let action: () -> Void

    private var border: Color {
        if flash { return Palette.rosso }
        if selected { return Palette.terracotta }
        return Palette.hairline
    }

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(matched ? .white : Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    matched
                        ? AnyShapeStyle(Palette.olive)
                        : AnyShapeStyle(Palette.card),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(border, lineWidth: selected || flash ? 2 : 1)
                )
                .shadow(color: Palette.ink.opacity(matched ? 0 : 0.06), radius: 5, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
        .opacity(matched ? 0.9 : 1)
    }
}
