import SwiftUI

/// Ear-training: play one word, the learner picks which of the minimal pair they
/// heard. Trains the geminate-consonant and stress contrasts Italian relies on.
struct MinimalPairsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var audio = AudioPlayer()

    @State private var pairs: [MinimalPair] = MinimalPairs.all.shuffled()
    @State private var index = 0
    @State private var targetIsB = false        // which word is actually playing
    @State private var answeredCorrect: Bool?   // nil = not answered yet
    @State private var score = 0

    private var pair: MinimalPair? { pairs.indices.contains(index) ? pairs[index] : nil }
    private var target: PairWord? { pair.map { targetIsB ? $0.b : $0.a } }
    private var finished: Bool { index >= pairs.count }

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 24) {
                topBar
                if let pair {
                    Spacer()
                    Text("Which word do you hear?")
                        .font(.headline).foregroundStyle(Palette.inkSoft)
                    playButton
                    Spacer()
                    options(pair)
                    feedback(pair)
                    Spacer(minLength: 8)
                } else {
                    Spacer(); summary; Spacer()
                }
            }
            .padding(20)
        }
        .preferredColorScheme(.light)
        .onAppear { if pair != nil { targetIsB = Bool.random(); playCurrent() } }
        .onDisappear { audio.stop() }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline.bold()).foregroundStyle(Palette.inkSoft)
            }
            ProgressView(value: Double(index), total: Double(max(pairs.count, 1))).tint(Palette.terracotta)
            Text("\(min(index + 1, pairs.count))/\(pairs.count)")
                .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.inkSoft).monospacedDigit()
        }
    }

    private var playButton: some View {
        Button { playCurrent() } label: {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 88))
                .foregroundStyle(Palette.terracotta)
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func options(_ pair: MinimalPair) -> some View {
        HStack(spacing: 14) {
            optionButton(pair.a, isB: false)
            optionButton(pair.b, isB: true)
        }
    }

    private func optionButton(_ word: PairWord, isB: Bool) -> some View {
        let answered = answeredCorrect != nil
        let isTarget = (isB == targetIsB)
        // After answering, highlight the correct word green, a wrong pick red.
        let border: Color = answered && isTarget ? Palette.olive : Palette.hairline
        return Button {
            guard !answered else { return }
            choose(isB: isB)
        } label: {
            Text(word.it)
                .font(.serifDisplay(28, weight: .semibold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(answered && isTarget ? Palette.olive.opacity(0.12) : Palette.card,
                            in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(border, lineWidth: answered && isTarget ? 2 : 1))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(answered)
    }

    @ViewBuilder
    private func feedback(_ pair: MinimalPair) -> some View {
        if let correct = answeredCorrect, let target {
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    Text(correct ? "Esatto!" : "You heard: \(target.it)")
                        .fontWeight(.bold)
                }
                .font(.title3)
                .foregroundStyle(correct ? Palette.olive : Palette.rosso)

                Text("\(pair.a.it) = \(pair.a.en) · \(pair.b.it) = \(pair.b.en)")
                    .font(.subheadline).foregroundStyle(Palette.inkSoft)
                Text(pair.hint).font(.caption).foregroundStyle(Palette.inkFaint)

                PrimaryButton(title: "Continue", tint: Palette.terracotta) { advance() }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Palette.cardSoft, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .transition(.opacity)
        }
    }

    private var summary: some View {
        VStack(spacing: 18) {
            Image(systemName: "ear.fill").font(.system(size: 64)).foregroundStyle(Palette.terracotta)
            Text("\(score) / \(pairs.count)")
                .font(.serifDisplay(46, weight: .bold)).foregroundStyle(Palette.ink)
            Text("pairs heard correctly").font(.title3).foregroundStyle(Palette.inkSoft)
            PrimaryButton(title: "Done", systemImage: "checkmark", tint: Palette.terracotta) { dismiss() }
        }
    }

    // MARK: - Logic

    private func playCurrent() {
        guard let target else { return }
        audio.stop()
        audio.play(target.file)
    }

    private func choose(isB: Bool) {
        let correct = (isB == targetIsB)
        if correct { score += 1 }
        Haptics.notify(correct)
        withAnimation { answeredCorrect = correct }
    }

    private func advance() {
        withAnimation {
            index += 1
            answeredCorrect = nil
            targetIsB = Bool.random()
        }
        if pair != nil { playCurrent() }
    }
}
