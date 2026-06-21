import SwiftUI
import SwiftData
import Charts

/// The Progress tab: the real measure of progress — words known, retention,
/// deck coverage, reading, and recent review activity — all from the SRS data
/// we already record. (Named to avoid clashing with SwiftUI.ProgressView.)
struct ProgressDashboardView: View {
    @Query private var cards: [Card]
    @Query private var logs: [ReviewLog]
    @Query private var reading: [ReadingProgress]
    @Query private var states: [UserState]

    private var metrics: Deck.Metrics { Deck.metrics(for: cards) }
    private var deckSize: Int { cards.count }
    private var storiesRead: Int { reading.filter(\.completed).count }
    private var storiesTotal: Int { GradedLibrary.all.count }
    private var streak: Int { states.first?.streak ?? 0 }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Progressi")
                        .font(.serifDisplay(40, weight: .bold))
                        .foregroundStyle(Palette.ink)

                    headlineGrid
                    deckCoverage
                    weekActivity
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Headline metrics

    private var headlineGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            stat("\(metrics.wordsKnown)", "words known", "checkmark.seal.fill", Palette.olive)
            stat("\(Int(metrics.retention * 100))%", "retention", "brain.head.profile", Palette.adriatic)
            stat("\(storiesRead)/\(storiesTotal)", "stories read", "book.fill", Palette.terracotta)
            stat("\(streak)", "day streak", "flame.fill", Palette.rosso)
        }
    }

    private func stat(_ value: String, _ label: String, _ icon: String, _ tint: Color) -> some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon).foregroundStyle(tint)
                Text(value).font(.title.weight(.bold)).foregroundStyle(Palette.ink).monospacedDigit()
                Text(label).font(.caption).foregroundStyle(Palette.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Deck coverage

    private var deckCoverage: some View {
        let started = cards.filter { $0.reps > 0 }.count
        let known = metrics.wordsKnown
        let learning = max(started - known, 0)
        let fresh = max(deckSize - started, 0)
        return GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your deck").font(.headline).foregroundStyle(Palette.ink)
                Text("\(started) of \(deckSize) words started")
                    .font(.subheadline).foregroundStyle(Palette.inkSoft)

                GeometryReader { geo in
                    let total = max(deckSize, 1)
                    HStack(spacing: 2) {
                        segment(known, total, geo.size.width, Palette.olive)
                        segment(learning, total, geo.size.width, Palette.terracotta)
                        segment(fresh, total, geo.size.width, Palette.hairline)
                    }
                }
                .frame(height: 14)
                .clipShape(Capsule())

                HStack(spacing: 14) {
                    legend("known", Palette.olive)
                    legend("learning", Palette.terracotta)
                    legend("new", Palette.hairline)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func segment(_ count: Int, _ total: Int, _ width: CGFloat, _ color: Color) -> some View {
        color.frame(width: max(width * CGFloat(count) / CGFloat(total), count > 0 ? 4 : 0))
    }

    private func legend(_ text: String, _ color: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(text).font(.caption2).foregroundStyle(Palette.inkSoft)
        }
    }

    // MARK: - Weekly activity

    private struct DayCount: Identifiable { let id = UUID(); let label: String; let count: Int }

    private var lastWeek: [DayCount] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let symbols = cal.veryShortWeekdaySymbols
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today) ?? today
            let count = logs.filter { cal.isDate($0.date, inSameDayAs: day) }.count
            let wd = cal.component(.weekday, from: day) - 1
            return DayCount(label: symbols[wd], count: count)
        }
    }

    private var weekActivity: some View {
        GlassCard(cornerRadius: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Reviews this week").font(.headline).foregroundStyle(Palette.ink)
                if logs.isEmpty {
                    Text("Do your first review to start tracking.")
                        .font(.subheadline).foregroundStyle(Palette.inkFaint)
                        .padding(.vertical, 20)
                } else {
                    Chart(lastWeek) { day in
                        BarMark(x: .value("Day", day.label), y: .value("Reviews", day.count))
                            .foregroundStyle(Palette.terracotta)
                            .cornerRadius(4)
                    }
                    .frame(height: 140)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
