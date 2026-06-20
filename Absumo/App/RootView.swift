import SwiftUI
import SwiftData

/// Top-level shell: the Today / Library / Progress tab bar (the lesson-tree home
/// is retired — see the "Today hub" IA decision). Seeds the frequency deck and
/// ensures a single `UserState` row on first launch.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var states: [UserState]

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }

            ComingSoonView(icon: "books.vertical.fill",
                           title: "Library",
                           phase: "PHASE 1",
                           blurb: "Graded Italian stories and dialogues to read and listen to — with a guided “Start here” track and free browsing.")
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            ComingSoonView(icon: "chart.line.uptrend.xyaxis",
                           title: "Progress",
                           phase: "PHASE 5",
                           blurb: "Your real progress: words known, share of a text you can read, listening minutes, and retention over time.")
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
        }
        .tint(Palette.terracotta)
        .task {
            Deck.seedIfNeeded(into: context)
            if states.isEmpty {
                context.insert(UserState())
                try? context.save()
            }
        }
    }
}
