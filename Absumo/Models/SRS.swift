import Foundation
import SwiftData

/// How well the learner recalled a card. Raw values 1–4 feed the scheduler.
enum Rating: Int, Codable, CaseIterable {
    case again = 1   // forgot
    case hard  = 2
    case good  = 3
    case easy  = 4
}

/// Where a card sits in its learning lifecycle.
enum CardState: Int, Codable {
    case new        // never reviewed
    case learning   // first successful reviews
    case review     // graduated; on the long-interval schedule
    case relearning // lapsed and being rebuilt
}

/// A single vocabulary item and its spaced-repetition memory state.
///
/// The scheduling fields (`stability`, `difficulty`, `due`, …) are owned by the
/// FSRS scheduler — see `FSRS.swift`. They are plain stored properties so the
/// scheduler stays a pure, testable value type and this model is just storage.
@Model
final class Card {
    // Content
    @Attribute(.unique) var id: String     // stable key, e.g. the lemma
    var italian: String                    // front (prompt)
    var english: String                    // back (answer)
    var example: String                    // a sentence giving context
    var frequencyRank: Int                 // 1 = most frequent; drives intake order

    // FSRS memory state
    var stability: Double                  // days until recall prob. falls to target
    var difficulty: Double                 // 1…10, intrinsic hardness
    var due: Date                          // next review date
    var lastReview: Date?                  // when it was last graded
    var reps: Int                          // total reviews
    var lapses: Int                        // times rated `again`
    var stateRaw: Int                      // CardState

    var state: CardState {
        get { CardState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    init(id: String,
         italian: String,
         english: String,
         example: String = "",
         frequencyRank: Int = 0,
         due: Date = .now) {
        self.id = id
        self.italian = italian
        self.english = english
        self.example = example
        self.frequencyRank = frequencyRank
        self.stability = 0
        self.difficulty = 0
        self.due = due
        self.lastReview = nil
        self.reps = 0
        self.lapses = 0
        self.stateRaw = CardState.new.rawValue
    }
}

/// An immutable record of one grading event — the raw history the scheduler can
/// be re-tuned against later, and the source for retention/throughput metrics.
@Model
final class ReviewLog {
    var cardID: String
    var date: Date
    var ratingRaw: Int
    var elapsedDays: Double      // days since the previous review (0 if first)
    var scheduledDays: Double    // interval that had been scheduled
    var stabilityAfter: Double
    var difficultyAfter: Double
    var stateAfterRaw: Int

    var rating: Rating { Rating(rawValue: ratingRaw) ?? .good }

    init(cardID: String,
         date: Date,
         rating: Rating,
         elapsedDays: Double,
         scheduledDays: Double,
         stabilityAfter: Double,
         difficultyAfter: Double,
         stateAfter: CardState) {
        self.cardID = cardID
        self.date = date
        self.ratingRaw = rating.rawValue
        self.elapsedDays = elapsedDays
        self.scheduledDays = scheduledDays
        self.stabilityAfter = stabilityAfter
        self.difficultyAfter = difficultyAfter
        self.stateAfterRaw = stateAfter.rawValue
    }
}
