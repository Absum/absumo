import SwiftUI
import SwiftData

/// Top-level container: animated background + the learning path.
/// Ensures a single `UserState` row exists on first launch.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var states: [UserState]

    var body: some View {
        ZStack {
            MeshBackground()
            HomePathView()
        }
        .task {
            if states.isEmpty {
                context.insert(UserState())
                try? context.save()
            }
        }
    }
}
