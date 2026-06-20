import SwiftUI
import SwiftData

/// The main screen: stats header + a winding path of lesson nodes.
struct HomePathView: View {
    @Environment(ContentStore.self) private var content
    @Environment(\.modelContext) private var context
    @Query private var progress: [LessonProgress]
    @Query private var states: [UserState]

    @State private var activeLesson: Lesson?

    private var user: UserState? { states.first }
    private var path: [(unit: Unit, lesson: Lesson)] { content.path }

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                StatsHeader(user: user)

                ForEach(Array(path.enumerated()), id: \.element.lesson.id) { index, item in
                    PathNode(
                        title: item.lesson.title,
                        icon: item.lesson.icon,
                        accent: Palette.accent(item.unit.accent),
                        index: index,
                        state: state(at: index, lesson: item.lesson)
                    ) {
                        activeLesson = item.lesson
                    }
                }
            }
            .padding(20)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $activeLesson) { lesson in
            LessonView(lesson: lesson) { correct, total in
                finish(lesson, correct: correct, total: total)
            }
        }
    }

    // MARK: - Progression logic

    private func isCompleted(_ lessonID: String) -> Bool {
        progress.first { $0.lessonID == lessonID }?.completed ?? false
    }

    private func state(at index: Int, lesson: Lesson) -> PathNode.NodeState {
        if isCompleted(lesson.id) { return .completed }
        // Unlocked when it's the first lesson or the previous one is done.
        if index == 0 || isCompleted(path[index - 1].lesson.id) { return .current }
        return .locked
    }

    private func finish(_ lesson: Lesson, correct: Int, total: Int) {
        let record = progress.first { $0.lessonID == lesson.id } ?? {
            let new = LessonProgress(lessonID: lesson.id)
            context.insert(new)
            return new
        }()
        record.completed = true
        record.bestScore = max(record.bestScore, correct)

        if let user {
            user.xp += correct * 10
            user.streak = max(user.streak, 1)
        }
        try? context.save()
    }
}
