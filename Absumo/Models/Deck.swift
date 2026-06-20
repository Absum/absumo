import Foundation
import SwiftData

/// Loads the bundled frequency deck and seeds `Card`s on first launch, builds
/// the day's review queue, and computes the knowledge metrics shown on Today /
/// Progress. Kept free of UI so it stays easy to reason about.
enum Deck {

    // MARK: - Seeding

    private struct SeedFile: Decodable { let words: [SeedWord] }
    private struct SeedWord: Decodable { let it: String; let en: String; let ex: String }

    /// Insert a `Card` for every word in `frequency_it.json` that isn't already
    /// present, in frequency order, due immediately (i.e. available as "new").
    /// Idempotent — safe to call on every launch.
    static func seedIfNeeded(into context: ModelContext) {
        guard let url = Bundle.main.url(forResource: "frequency_it", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(SeedFile.self, from: data)
        else { return }

        let existing = (try? context.fetch(FetchDescriptor<Card>()))?.reduce(into: Set<String>()) {
            $0.insert($1.id)
        } ?? []

        for (index, word) in file.words.enumerated() where !existing.contains(word.it) {
            context.insert(Card(id: word.it,
                                italian: word.it,
                                english: word.en,
                                example: word.ex,
                                frequencyRank: index + 1))
        }
        try? context.save()
    }

    // MARK: - Adding words from reading

    /// Add a word encountered while reading into the SRS deck, keyed by its
    /// dictionary form so it dedupes with the frequency deck. Returns false if
    /// the lemma is already in the deck (e.g. "vado" → "andare" already there).
    @discardableResult
    static func addCard(lemma: String, english: String, example: String,
                        into context: ModelContext) -> Bool {
        let id = lemma
        let existing = try? context.fetch(
            FetchDescriptor<Card>(predicate: #Predicate { $0.id == id })
        )
        guard (existing?.isEmpty ?? true) else { return false }
        context.insert(Card(id: id, italian: lemma, english: english, example: example))
        try? context.save()
        return true
    }

    static func contains(lemma: String, in cards: [Card]) -> Bool {
        cards.contains { $0.id == lemma }
    }

    // MARK: - Daily queue

    /// How many never-seen cards to introduce per day. Caps new-word intake so
    /// the review load stays sustainable (and respects spacing across days).
    static let newCardsPerDay = 8

    /// The cards to study right now: everything due, plus up to `newCardsPerDay`
    /// fresh cards in frequency order. Due cards come first.
    static func session(from cards: [Card], now: Date = .now) -> [Card] {
        let due = cards
            .filter { $0.state != .new && $0.due <= now }
            .sorted { $0.due < $1.due }

        let fresh = cards
            .filter { $0.state == .new }
            .sorted { $0.frequencyRank < $1.frequencyRank }
            .prefix(newCardsPerDay)

        return due + Array(fresh)
    }

    static func dueCount(_ cards: [Card], now: Date = .now) -> Int {
        session(from: cards, now: now).count
    }

    // MARK: - Knowledge metrics

    /// Headline numbers for Today / Progress. These replace XP/hearts as the
    /// real measure of progress (words known, retention), per the design decision.
    struct Metrics {
        var wordsKnown: Int        // cards genuinely in long-term memory
        var inProgress: Int        // started but not yet "known"
        var dueNow: Int            // cards to review right now
        var totalSeen: Int         // any card reviewed at least once
        var retention: Double      // mean current recall probability of seen cards (0–1)
    }

    /// A card counts as "known" once it's on the review schedule with a week-plus
    /// of stability — i.e. it has actually stuck, not just been answered once.
    private static let knownStabilityDays = 7.0

    static func metrics(for cards: [Card], now: Date = .now, fsrs: FSRS = FSRS()) -> Metrics {
        let seen = cards.filter { $0.reps > 0 }
        let known = seen.filter { $0.state == .review && $0.stability >= knownStabilityDays }

        let retentions: [Double] = seen.map { card in
            let elapsed = max(0, now.timeIntervalSince(card.lastReview ?? now) / 86_400)
            return fsrs.retrievability(elapsedDays: elapsed, stability: card.stability)
        }
        let meanRetention = retentions.isEmpty ? 0 : retentions.reduce(0, +) / Double(retentions.count)

        return Metrics(wordsKnown: known.count,
                       inProgress: seen.count - known.count,
                       dueNow: dueCount(cards, now: now),
                       totalSeen: seen.count,
                       retention: meanRetention)
    }
}
