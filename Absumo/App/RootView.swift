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

            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical.fill") }

            ProgressDashboardView()
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
