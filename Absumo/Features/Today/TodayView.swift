import SwiftUI
import SwiftData

/// The Today hub, Vetro style: a living knowledge orb, ONE clear hero action,
/// and quiet recessed glass tiles for the rest. Depth, not a card stack.
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
    private var due: Int { metrics.dueNow }
    private var level: String { LevelEstimator.level(wordsKnown: metrics.wordsKnown) }
    private var nextRead: GradedItem? {
        LevelEstimator.recommended(reading: reading, wordsKnown: metrics.wordsKnown)
    }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(spacing: 26) {
                    topBar
                    KnowledgeOrb(wordsKnown: metrics.wordsKnown, retention: metrics.retention)
                        .padding(.top, 6)
                    hero
                    secondaryRow
                }
                .padding(.horizontal, 22)
                .padding(.top, 4)
                .padding(.bottom, 44)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(isPresented: $reviewing) { ReviewSessionView(cards: session) {} }
        .fullScreenCover(item: $readingItem) { ReaderView(item: $0) }
        .fullScreenCover(isPresented: $listening) { ListenView(items: GradedLibrary.all) }
        .fullScreenCover(isPresented: $pronouncing) { PronunciaView() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.serifDisplay(30, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text("io absumo l'italiano")
                    .font(.footnote).italic()
                    .foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Text("Livello \(level)")
                .font(.caption.weight(.bold)).tracking(1)
                .foregroundStyle(Palette.olive)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1))
        }
    }

    // MARK: - Hero action (one clear next step)

    @ViewBuilder
    private var hero: some View {
        if due > 0 {
            heroPanel(icon: "rectangle.stack.fill", kicker: "DA RIVEDERE",
                      title: "\(due) parole pronte", cta: "Inizia",
                      tint: Palette.terracotta) { reviewing = true }
        } else if let next = nextRead {
            heroPanel(icon: "book.fill", kicker: "DA LEGGERE",
                      title: next.title, cta: "Leggi · \(next.level)",
                      tint: Palette.olive) { readingItem = next }
        } else {
            heroPanel(icon: "checkmark.seal.fill", kicker: "OGGI",
                      title: "Tutto fatto. Bravo!", cta: "Ascolta ancora",
                      tint: Palette.adriatic) { listening = true }
        }
    }

    private func heroPanel(icon: String, kicker: String, title: String, cta: String,
                           tint: Color, action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            GlassPanel(cornerRadius: 30, raised: true, glow: tint) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: icon).foregroundStyle(tint)
                        Text(kicker).font(.caption.weight(.bold)).tracking(2).foregroundStyle(Palette.inkSoft)
                        Spacer()
                    }
                    Text(title)
                        .font(.serifDisplay(30, weight: .bold))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text(cta).fontWeight(.bold)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20).padding(.vertical, 13)
                    .background(Palette.gradient(tint), in: Capsule())
                    .shadow(color: tint.opacity(0.4), radius: 10, y: 5)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }

    // MARK: - Secondary actions (recessed glass tiles)

    private var secondaryRow: some View {
        HStack(spacing: 12) {
            if due > 0 {
                tile("book.fill", "Leggi", Palette.olive, enabled: nextRead != nil) {
                    if let n = nextRead { readingItem = n }
                }
            } else {
                tile("rectangle.stack.fill", "Rivedi", Palette.terracotta, enabled: false) {}
            }
            tile("headphones", "Ascolta", Palette.adriatic) { listening = true }
            tile("waveform", "Pronuncia", Palette.rosso) { pronouncing = true }
        }
    }

    private func tile(_ icon: String, _ label: String, _ tint: Color,
                      enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button { Haptics.tap(); action() } label: {
            GlassPanel(cornerRadius: 22, raised: false) {
                VStack(spacing: 9) {
                    Image(systemName: icon).font(.title2).foregroundStyle(enabled ? tint : Palette.inkFaint)
                    Text(label).font(.subheadline.weight(.semibold))
                        .foregroundStyle(enabled ? Palette.ink : Palette.inkFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.55)
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
