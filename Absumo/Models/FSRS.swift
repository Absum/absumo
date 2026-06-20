import Foundation

/// A pure implementation of the **FSRS** (Free Spaced Repetition Scheduler)
/// algorithm — the open-source successor to SM-2 used by modern Anki.
///
/// Why FSRS rather than a hand-rolled interval doubler: the research backing
/// Absumo (knowledge entry 15a5759…) is specific about the memory science —
/// retrieval practice with intervals that (a) span *days* and expand, and
/// (b) scale to a *target retention horizon* — and FSRS is the validated model
/// that does exactly this. Two evidence-driven rules are enforced here:
///
///   • A card is **never dropped** after a correct recall — every grade returns
///     a future `due` date (min one day), so items keep coming back. (Dropping
///     on first success craters long-term retention; Karpicke & Roediger 2008.)
///   • Reviews are scheduled **across days**, never within a session.
///
/// The model is a value type with no storage or UI dependencies so it can be
/// unit-tested in isolation; it reads/writes the plain fields on `Card`.
struct FSRS {

    /// Desired probability of recall at review time. Lower → longer intervals.
    /// Cepeda et al. (2008): the optimal gap grows with the retention horizon,
    /// so this is the single knob a learner's horizon maps onto.
    var requestRetention: Double = 0.9

    /// Hard cap on any interval (days) — ~100 years, effectively unlimited.
    var maximumInterval: Double = 36500

    /// FSRS-4.5 default weights. Treated as tunable constants; a later task can
    /// re-fit these from accumulated `ReviewLog` history.
    var w: [Double] = [
        0.4197, 1.1869, 3.0412, 15.2441, 7.1434, 0.6477, 1.0007, 0.0674,
        1.6597, 0.1712, 1.1178, 2.0225, 0.0904, 0.3025, 2.1214, 0.2498, 2.9466
    ]

    // Forgetting-curve constants (fixed in FSRS): R(t,S) = (1 + F·t/S)^D.
    private let decay = -0.5
    private var factor: Double { pow(0.9, 1 / decay) - 1 }   // = 19/81

    // MARK: - Public API

    /// The result of grading a card: the new memory state to persist.
    struct Outcome {
        var stability: Double
        var difficulty: Double
        var due: Date
        var state: CardState
        var reps: Int
        var lapses: Int
        /// Days since the previous review (0 on the first review).
        var elapsedDays: Double
        /// The interval just scheduled, in days.
        var scheduledDays: Double
    }

    /// Grade `card` with `rating` at `now`, returning the updated memory state.
    /// Does not mutate the card — see `apply(_:to:at:)` for that.
    func review(_ card: Card, rating: Rating, now: Date = .now) -> Outcome {
        let firstReview = card.reps == 0 || card.state == .new

        var stability: Double
        var difficulty: Double
        var lapses = card.lapses
        let elapsed: Double

        if firstReview {
            elapsed = 0
            stability = initialStability(rating)
            difficulty = initialDifficulty(rating)
            if rating == .again { lapses += 1 }
        } else {
            elapsed = max(0, daysBetween(card.lastReview ?? now, now))
            let retrievability = self.retrievability(elapsedDays: elapsed, stability: card.stability)
            difficulty = nextDifficulty(card.difficulty, rating: rating)
            if rating == .again {
                lapses += 1
                stability = nextForgetStability(difficulty: card.difficulty,
                                                stability: card.stability,
                                                retrievability: retrievability)
            } else {
                stability = nextRecallStability(difficulty: card.difficulty,
                                                stability: card.stability,
                                                retrievability: retrievability,
                                                rating: rating)
            }
        }

        // Stability can't be allowed to collapse to zero, or intervals vanish.
        stability = max(stability, 0.1)

        let interval = nextInterval(stability)
        let due = Calendar.current.date(byAdding: .day,
                                        value: Int(interval),
                                        to: Calendar.current.startOfDay(for: now)) ?? now

        let state: CardState = (rating == .again)
            ? (firstReview ? .learning : .relearning)
            : .review

        return Outcome(stability: stability,
                       difficulty: difficulty,
                       due: due,
                       state: state,
                       reps: card.reps + 1,
                       lapses: lapses,
                       elapsedDays: elapsed,
                       scheduledDays: interval)
    }

    /// Grade `card`, write the new state back onto it, and append a `ReviewLog`.
    @discardableResult
    func apply(_ rating: Rating, to card: Card, at now: Date = .now) -> ReviewLog {
        let o = review(card, rating: rating, now: now)
        card.stability = o.stability
        card.difficulty = o.difficulty
        card.due = o.due
        card.lastReview = now
        card.reps = o.reps
        card.lapses = o.lapses
        card.state = o.state
        return ReviewLog(cardID: card.id,
                         date: now,
                         rating: rating,
                         elapsedDays: o.elapsedDays,
                         scheduledDays: o.scheduledDays,
                         stabilityAfter: o.stability,
                         difficultyAfter: o.difficulty,
                         stateAfter: o.state)
    }

    /// Probability the card is still recallable after `elapsedDays`.
    func retrievability(elapsedDays: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0 }
        return pow(1 + factor * elapsedDays / stability, decay)
    }

    // MARK: - FSRS internals

    private func initialStability(_ g: Rating) -> Double {
        max(w[g.rawValue - 1], 0.1)
    }

    private func initialDifficulty(_ g: Rating) -> Double {
        clampDifficulty(w[4] - w[5] * Double(g.rawValue - 3))
    }

    private func nextDifficulty(_ d: Double, rating g: Rating) -> Double {
        let delta = d - w[6] * Double(g.rawValue - 3)
        // Mean-reversion toward the difficulty of an "easy" first answer.
        let reverted = w[7] * initialDifficulty(.easy) + (1 - w[7]) * delta
        return clampDifficulty(reverted)
    }

    private func nextRecallStability(difficulty d: Double, stability s: Double,
                                     retrievability r: Double, rating g: Rating) -> Double {
        let hardPenalty = (g == .hard) ? w[15] : 1
        let easyBonus   = (g == .easy) ? w[16] : 1
        let growth = exp(w[8]) * (11 - d) * pow(s, -w[9])
            * (exp((1 - r) * w[10]) - 1) * hardPenalty * easyBonus
        return s * (1 + growth)
    }

    private func nextForgetStability(difficulty d: Double, stability s: Double,
                                     retrievability r: Double) -> Double {
        w[11] * pow(d, -w[12]) * (pow(s + 1, w[13]) - 1) * exp((1 - r) * w[14])
    }

    /// Interval (whole days, ≥ 1) at which recall probability hits the target.
    private func nextInterval(_ stability: Double) -> Double {
        let raw = (stability / factor) * (pow(requestRetention, 1 / decay) - 1)
        return min(max(raw.rounded(), 1), maximumInterval)
    }

    private func clampDifficulty(_ d: Double) -> Double { min(max(d, 1), 10) }

    private func daysBetween(_ a: Date, _ b: Date) -> Double {
        b.timeIntervalSince(a) / 86_400
    }
}
