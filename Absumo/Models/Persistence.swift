import Foundation
import SwiftData

/// Per-user habit + progression state. One row exists for the local user.
@Model
final class UserState {
    var xp: Int
    var streak: Int
    var hearts: Int

    init(xp: Int = 0, streak: Int = 0, hearts: Int = 5) {
        self.xp = xp
        self.streak = streak
        self.hearts = hearts
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
