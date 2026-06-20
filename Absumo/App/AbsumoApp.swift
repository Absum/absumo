import SwiftUI
import SwiftData

@main
struct AbsumoApp: App {
    @State private var content = ContentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [UserState.self, LessonProgress.self, Card.self, ReviewLog.self, ReadingProgress.self])
    }
}
