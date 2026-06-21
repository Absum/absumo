import SwiftUI
import SwiftData

/// The home hub: a calm daily-loop dashboard. Surfaces what's due, the (coming)
/// input activities, and the headline knowledge metrics — one clear next action.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var cards: [Card]
    @Query private var states: [UserState]
    @Query private var reading: [ReadingProgress]

    @State private var reviewing = false
    @State private var readingItem: GradedItem?
    @State private var listening = false
    @State private var pronouncing = false

    private var metrics: Deck.Metrics { Deck.metrics(for: cards) }
    private var session: [Card] { Deck.session(from: cards) }
    private var user: UserState? { states.first }

    /// The next graded item the learner hasn't finished, for the Read card.
    private var nextRead: GradedItem? {
        let done = Set(reading.filter(\.completed).map(\.itemID))
        return GradedLibrary.all.first { !done.contains($0.id) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                reviewCard
                readCard
                listenCard
                pronunciaCard
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $reviewing) {
            ReviewSessionView(cards: session) {}
        }
        .fullScreenCover(item: $readingItem) { ReaderView(item: $0) }
        .fullScreenCover(isPresented: $listening) {
            ListenView(items: GradedLibrary.all)
        }
        .fullScreenCover(isPresented: $pronouncing) { PronunciaView() }
    }

    private var pronunciaCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "ear.fill").foregroundStyle(Palette.terracotta)
                    Text("Pronuncia").font(.headline).foregroundStyle(Palette.ink)
                    Spacer()
                }
                Text("Train your ear")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Minimal pairs and shadowing.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                PrimaryButton(title: "Practice", systemImage: "waveform", tint: Palette.terracotta) {
                    pronouncing = true
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var listenCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "headphones").foregroundStyle(Palette.adriatic)
                    Text("Listen").font(.headline).foregroundStyle(Palette.ink)
                    Spacer()
                }
                Text("\(GradedLibrary.all.count) stories, hands-free")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Palette.ink)
                Text("Play them back-to-back — on a walk, in the car.")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
                PrimaryButton(title: "Listen", systemImage: "play.fill", tint: Palette.adriatic) {
                    listening = true
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var readCard: some View {
        GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "book.fill").foregroundStyle(Palette.olive)
                    Text("Read").font(.headline).foregroundStyle(Palette.ink)
                    Spacer()
                }
                if let next = nextRead {
                    Text(next.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.ink)
                    Text("\(next.level) · graded story — tap a word to learn it")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkSoft)
                    PrimaryButton(title: "Read", systemImage: "book", tint: Palette.olive) {
                        readingItem = next
                    }
                } else {
                    Text("You've read everything for now")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Header (greeting + knowledge metrics)

    private var header: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text(greeting)
                    .font(.serifDisplay(34, weight: .bold))
                    .foregroundStyle(Palette.ink)

                HStack(spacing: 10) {
                    Metric(value: "\(metrics.wordsKnown)", label: "words known", tint: Palette.olive)
                    Metric(value: "\(Int(metrics.retention * 100))%", label: "retention", tint: Palette.adriatic)
                    Metric(value: "\(user?.streak ?? 0)", label: "day streak", tint: Palette.terracotta)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Primary action: reviews due

    private var reviewCard: some View {
        let due = metrics.dueNow
        return GlassCard(cornerRadius: 24) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "rectangle.stack.fill").foregroundStyle(Palette.terracotta)
                    Text("Reviews").font(.headline).foregroundStyle(Palette.ink)
                    Spacer()
                }
                Text(due > 0 ? "\(due) cards ready to review" : "All caught up for now")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(due > 0 ? Palette.ink : Palette.inkSoft)

                if due > 0 {
                    PrimaryButton(title: "Start review", systemImage: "play.fill", tint: Palette.terracotta) {
                        reviewing = true
                    }
                } else {
                    Text("Come back later, or add new words by reading.")
                        .font(.subheadline)
                        .foregroundStyle(Palette.inkFaint)
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Buongiorno"
        case 12..<18: return "Buon pomeriggio"
        default:      return "Buonasera"
        }
    }
}

/// A single headline number on the Today header.
private struct Metric: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.title2.weight(.bold)).foregroundStyle(tint).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
