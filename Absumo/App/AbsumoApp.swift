import SwiftUI
import SwiftData

@main
struct AbsumoApp: App {
    @State private var content = ContentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .fontDesign(.rounded)
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: [UserState.self, LessonProgress.self])
    }
}
