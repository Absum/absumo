import Foundation
import SwiftData

/// Per-user habit + progression state. One row exists for the local user.
@Model
final class UserState {
    var xp: Int
    var streak: Int
    var hearts: Int

    // Onboarding + preferences
    var onboarded: Bool = false
    /// Target recall probability — tunes the FSRS scheduler. Higher = more
    /// reviews but stronger retention. Set during onboarding.
    var retentionTarget: Double = 0.9
    var remindersOn: Bool = false
    /// Last day the learner studied — drives the streak.
    var lastActive: Date? = nil

    init(xp: Int = 0, streak: Int = 0, hearts: Int = 5) {
        self.xp = xp
        self.streak = streak
        self.hearts = hearts
    }

    /// Record that the learner studied today; updates the streak (gentle nudge,
    /// not the point). Idempotent within a day.
    func recordActivity(now: Date = .now) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        if let last = lastActive {
            let lastDay = cal.startOfDay(for: last)
            if cal.isDate(lastDay, inSameDayAs: today) { return }   // already counted
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)
            streak = (yesterday.map { cal.isDate(lastDay, inSameDayAs: $0) } ?? false) ? streak + 1 : 1
        } else {
            streak = 1
        }
        lastActive = today
    }
}

/// Tracks completion + best score for a single lesson.
@Model
final class LessonProgress {
    @Attribute(.unique) var lessonID: String
    var completed: Bool
    var bestScore: Int

    init(lessonID: String, completed: Bool = false, bestScore: Int = 0) {
        self.lessonID = lessonID
        self.completed = completed
        self.bestScore = bestScore
    }
}
