import XCTest
@testable import Absumo

/// Property-based tests for the FSRS scheduler. Rather than pinning exact magic
/// numbers (which depend on the tunable weight vector), these assert the
/// *invariants the SLA research requires* — so the suite still protects the
/// evidence-correct behaviour if the weights are later re-fit.
final class FSRSTests: XCTestCase {

    private let secondsPerDay: TimeInterval = 86_400

    private func newCard() -> Card {
        Card(id: "ciao", italian: "ciao", english: "hello", frequencyRank: 1)
    }

    // A new "good" answer schedules a review several days out (not seconds, not
    // the same session) and graduates the card to the review state.
    func testNewGoodSchedulesDaysAhead() {
        let fsrs = FSRS()
        let card = newCard()
        let now = Date()
        let o = fsrs.review(card, rating: .good, now: now)

        XCTAssertGreaterThanOrEqual(o.scheduledDays, 1, "interval must span at least a day")
        XCTAssertGreaterThan(o.due, now, "a graded card is always rescheduled into the future")
        XCTAssertEqual(o.state, .review)
        XCTAssertGreaterThan(o.stability, 0)
    }

    // Better recall → longer interval: easy > good > hard ≥ again.
    func testRatingOrderingProducesLongerIntervals() {
        let fsrs = FSRS()
        let now = Date()
        let again = fsrs.review(newCard(), rating: .again, now: now).scheduledDays
        let hard  = fsrs.review(newCard(), rating: .hard,  now: now).scheduledDays
        let good  = fsrs.review(newCard(), rating: .good,  now: now).scheduledDays
        let easy  = fsrs.review(newCard(), rating: .easy,  now: now).scheduledDays

        XCTAssertGreaterThan(easy, good)
        XCTAssertGreaterThan(good, hard)
        XCTAssertGreaterThanOrEqual(hard, again)
    }

    // The core memory-science property: keep answering "good" and stability
    // (hence the interval) grows monotonically — reviews expand across time.
    func testRepeatedGoodGrowsStabilityAndInterval() {
        let fsrs = FSRS()
        let card = newCard()
        var now = Date()
        var lastStability = 0.0
        var lastInterval = 0.0

        for i in 0..<6 {
            let log = fsrs.apply(.good, to: card, at: now)
            if i > 0 {
                XCTAssertGreaterThan(card.stability, lastStability, "stability should grow with each recall")
                XCTAssertGreaterThanOrEqual(log.scheduledDays, lastInterval, "intervals should expand")
            }
            lastStability = card.stability
            lastInterval = log.scheduledDays
            // Advance to roughly when the card next falls due.
            now = now.addingTimeInterval(log.scheduledDays * secondsPerDay)
        }
        XCTAssertGreaterThan(card.reps, 5)
    }

    // "Again" records a lapse, drops stability versus a successful recall, and
    // moves the card into relearning — but it is still rescheduled, never lost.
    func testAgainLapsesAndIsStillRescheduled() {
        let fsrs = FSRS()
        let card = newCard()
        var now = Date()

        // Build some memory first.
        for _ in 0..<3 {
            let log = fsrs.apply(.good, to: card, at: now)
            now = now.addingTimeInterval(log.scheduledDays * secondsPerDay)
        }
        let stabilityBefore = card.stability
        let lapsesBefore = card.lapses

        let log = fsrs.apply(.again, to: card, at: now)

        XCTAssertEqual(card.lapses, lapsesBefore + 1)
        XCTAssertEqual(card.state, .relearning)
        XCTAssertLessThan(card.stability, stabilityBefore, "forgetting should reduce stability")
        XCTAssertGreaterThan(card.due, now, "even a lapsed card is rescheduled, never dropped")
    }

    // Cepeda et al.: the optimal gap grows as the desired retention horizon
    // lengthens. A lower requested retention must yield a longer interval.
    func testLowerRetentionGivesLongerIntervals() {
        let now = Date()
        let strict = FSRS(requestRetention: 0.95)
        let relaxed = FSRS(requestRetention: 0.80)

        let strictInterval = strict.review(newCard(), rating: .good, now: now).scheduledDays
        let relaxedInterval = relaxed.review(newCard(), rating: .good, now: now).scheduledDays

        XCTAssertGreaterThan(relaxedInterval, strictInterval)
    }

    // Difficulty must stay within the FSRS [1, 10] band across any history.
    func testDifficultyStaysInRange() {
        let fsrs = FSRS()
        let card = newCard()
        var now = Date()
        let ratings: [Rating] = [.good, .again, .hard, .good, .easy, .again, .good, .good]

        for r in ratings {
            let log = fsrs.apply(r, to: card, at: now)
            XCTAssertGreaterThanOrEqual(card.difficulty, 1)
            XCTAssertLessThanOrEqual(card.difficulty, 10)
            now = now.addingTimeInterval(max(log.scheduledDays, 1) * secondsPerDay)
        }
    }

    // Retrievability decays from ~1 toward 0 as time passes, and equals the
    // requested retention at exactly one stability's worth of days.
    func testRetrievabilityCurve() {
        let fsrs = FSRS(requestRetention: 0.9)
        let stability = 10.0
        XCTAssertEqual(fsrs.retrievability(elapsedDays: 0, stability: stability), 1, accuracy: 0.001)
        // By definition stability is the interval where R == requestRetention.
        XCTAssertEqual(fsrs.retrievability(elapsedDays: stability, stability: stability), 0.9, accuracy: 0.01)
        let early = fsrs.retrievability(elapsedDays: 1, stability: stability)
        let late = fsrs.retrievability(elapsedDays: 30, stability: stability)
        XCTAssertGreaterThan(early, late)
    }
}
