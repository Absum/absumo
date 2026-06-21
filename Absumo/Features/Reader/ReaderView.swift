import SwiftUI
import SwiftData

/// The comprehensible-input reader: a graded Italian passage where every glossed
/// word is tappable. Tapping reveals its meaning AND its dictionary form (so a
/// beginner sees "vado → andare"), and can add the lemma to the SRS deck — this
/// is the input→retrieval loop the whole app is built around.
struct ReaderView: View {
    let item: GradedItem

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var cards: [Card]

    @State private var selected: Gloss?
    @State private var showTranslation = false
    @State private var justAdded: String?
    @State private var audio = AudioPlayer()
    @State private var showGrammar = false

    private var grammarNotes: [GrammarNote] { GrammarNotes.relevant(for: item) }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    passage
                    if showTranslation { translationBlock }
                    Spacer(minLength: 20)
                    doneButton
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .overlay(alignment: .bottom) { glossSheet }
        .sheet(isPresented: $showGrammar) {
            GrammarNotesView(notes: grammarNotes)
        }
        .onAppear { markOpened() }
        .onDisappear { audio.stop() }
    }

    // MARK: - Pieces

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline.bold()).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Text(item.level)
                .font(.caption.weight(.bold)).tracking(1)
                .foregroundStyle(Palette.terracotta)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Palette.terracotta.opacity(0.12), in: Capsule())
        }
    }

    private var passage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.title)
                    .font(.serifDisplay(34, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Spacer()
                if item.audio != nil {
                    Button { audio.toggle(item.audio) } label: {
                        Image(systemName: audio.isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(Palette.terracotta)
                    }
                }
            }

            FlowLayout(spacing: 6) {
                ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                    tokenView(token)
                }
            }

            HStack(spacing: 18) {
                Button {
                    withAnimation { showTranslation.toggle() }
                } label: {
                    Label(showTranslation ? "Hide translation" : "Show translation",
                          systemImage: "text.bubble")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.adriatic)
                }
                if !grammarNotes.isEmpty {
                    Button { showGrammar = true } label: {
                        Label("Grammar (\(grammarNotes.count))", systemImage: "text.book.closed")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Palette.olive)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private func tokenView(_ token: String) -> some View {
        let gloss = item.gloss(for: token)
        return Group {
            if let gloss {
                Text(token)
                    .foregroundStyle(Palette.ink)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Palette.terracotta.opacity(0.5))
                            .frame(height: 1.5)
                            .offset(y: 3)
                    }
                    .onTapGesture {
                        Haptics.tap()
                        selected = gloss
                    }
            } else {
                Text(token).foregroundStyle(Palette.ink)
            }
        }
        .font(.system(size: 24, design: .serif))
    }

    private var translationBlock: some View {
        Text(item.translation)
            .font(.body)
            .foregroundStyle(Palette.inkSoft)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.cardSoft, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var doneButton: some View {
        PrimaryButton(title: "Done reading", systemImage: "checkmark", tint: Palette.olive) {
            markCompleted()
            dismiss()
        }
    }

    // MARK: - Gloss sheet (tap a word)

    @ViewBuilder
    private var glossSheet: some View {
        if let gloss = selected {
            let inDeck = Deck.contains(lemma: gloss.lemma, in: cards)
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gloss.word)
                            .font(.serifDisplay(30, weight: .bold))
                            .foregroundStyle(Palette.ink)
                        if !gloss.isLemma {
                            Text("from \(gloss.lemma)")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Palette.adriatic)
                        }
                    }
                    Spacer()
                    Button { withAnimation { selected = nil } } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2).foregroundStyle(Palette.inkFaint)
                    }
                }
                Text(gloss.en).font(.title3).foregroundStyle(Palette.terracotta)

                if inDeck {
                    Label("In your deck", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Palette.olive)
                } else {
                    PrimaryButton(title: "Add “\(gloss.lemma)” to deck", systemImage: "plus", tint: Palette.terracotta) {
                        Deck.addCard(lemma: gloss.lemma, english: gloss.en,
                                     example: sentence(containing: gloss.word), into: context)
                        justAdded = gloss.lemma
                        withAnimation { selected = nil }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.hairline))
            .shadow(color: Palette.ink.opacity(0.15), radius: 20, y: 8)
            .padding(16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Helpers

    private var tokens: [String] {
        item.text.split(separator: " ").map(String.init)
    }

    /// The sentence in the passage containing `surface`, used as the card's example.
    private func sentence(containing surface: String) -> String {
        let key = Gloss.normalize(surface)
        let sentences = item.text
            .split(whereSeparator: { ".!?".contains($0) })
            .map { $0.trimmingCharacters(in: .whitespaces) }
        let match = sentences.first { s in
            s.split(separator: " ").contains { Gloss.normalize(String($0)) == key }
        }
        return match.map { $0 + "." } ?? item.text
    }

    private func markOpened() {
        upsertProgress(completed: false)
    }

    private func markCompleted() {
        upsertProgress(completed: true)
    }

    private func upsertProgress(completed: Bool) {
        let id = item.id
        let existing = try? context.fetch(
            FetchDescriptor<ReadingProgress>(predicate: #Predicate { $0.itemID == id })
        )
        if let record = existing?.first {
            record.completed = record.completed || completed
            record.lastOpened = .now
        } else {
            context.insert(ReadingProgress(itemID: id, completed: completed))
        }
        try? context.save()
    }
}
