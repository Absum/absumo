import SwiftUI
import SwiftData

/// The home hub: a calm daily-loop dashboard. Surfaces what's due, the (coming)
/// input activities, and the headline knowledge metrics — one clear next action.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var cards: [Card]
    @Query private var states: [UserState]

    @State private var reviewing = false

    private var metrics: Deck.Metrics { Deck.metrics(for: cards) }
    private var session: [Card] { Deck.session(from: cards) }
    private var user: UserState? { states.first }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header
                reviewCard
                comingSoon(icon: "book.fill", title: "Read", subtitle: "Graded stories — Phase 1")
                comingSoon(icon: "headphones", title: "Listen", subtitle: "Hands-free audio — Phase 1")
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .fullScreenCover(isPresented: $reviewing) {
            ReviewSessionView(cards: session) {}
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

    private func comingSoon(icon: String, title: String, subtitle: String) -> some View {
        GlassCard(cornerRadius: 24) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Palette.inkFaint)
                    .frame(width: 44, height: 44)
                    .background(Palette.cardSoft, in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(Palette.ink)
                    Text(subtitle).font(.subheadline).foregroundStyle(Palette.inkFaint)
                }
                Spacer()
            }
            .padding(18)
        }
        .opacity(0.7)
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
