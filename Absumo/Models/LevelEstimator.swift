import Foundation

/// Estimates the learner's working level from how many words they actually know,
/// and recommends the next graded item to read — at their level, nudging up as
/// they grow (Krashen's i+1, treated as a heuristic, not a precise target).
enum LevelEstimator {
    static let order = ["A1", "A2", "B1"]

    /// CEFR-ish band from words genuinely known (SRS "known" count). Thresholds
    /// are tunable; they map a growing vocabulary onto rising difficulty.
    static func level(wordsKnown: Int) -> String {
        switch wordsKnown {
        case ..<40:  return "A1"
        case ..<120: return "A2"
        default:     return "B1"
        }
    }

    /// The next unread story to serve: lowest-order unread item at the learner's
    /// current level; if that level is exhausted, step up a level (i+1); finally
    /// fall back to any unread item.
    static func recommended(reading: [ReadingProgress], wordsKnown: Int) -> GradedItem? {
        let done = Set(reading.filter(\.completed).map(\.itemID))
        let current = level(wordsKnown: wordsKnown)
        let bands = Array(order.drop(while: { $0 != current }))   // current → higher
        for band in bands {
            if let item = GradedLibrary.all.first(where: { $0.level == band && !done.contains($0.id) }) {
                return item
            }
        }
        return GradedLibrary.all.first { !done.contains($0.id) }
    }
}
