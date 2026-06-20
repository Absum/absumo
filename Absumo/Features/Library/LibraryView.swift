import SwiftUI
import SwiftData

/// The Library tab: a guided "Start here" track for beginners plus free browsing
/// of all graded content. Reading any item opens the Reader.
struct LibraryView: View {
    @Query private var progress: [ReadingProgress]
    @State private var reading: GradedItem?

    private var items: [GradedItem] { GradedLibrary.all }

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Library")
                        .font(.serifDisplay(40, weight: .bold))
                        .foregroundStyle(Palette.ink)

                    section(title: "★ Start here", subtitle: "A guided path for beginners") {
                        ForEach(items) { item in
                            row(item)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
        }
        .fullScreenCover(item: $reading) { ReaderView(item: $0) }
    }

    private func section<Content: View>(title: String, subtitle: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Palette.ink)
                Text(subtitle).font(.subheadline).foregroundStyle(Palette.inkSoft)
            }
            content()
        }
    }

    private func row(_ item: GradedItem) -> some View {
        let done = isCompleted(item.id)
        return Button {
            reading = item
        } label: {
            GlassCard(cornerRadius: 20) {
                HStack(spacing: 14) {
                    Image(systemName: done ? "checkmark.circle.fill" : "book.fill")
                        .font(.title3)
                        .foregroundStyle(done ? Palette.olive : Palette.terracotta)
                        .frame(width: 40, height: 40)
                        .background(Palette.cardSoft, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.title).font(.headline).foregroundStyle(Palette.ink)
                        Text("\(item.level) · \(item.glossary.count) words")
                            .font(.caption).foregroundStyle(Palette.inkSoft)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(Palette.inkFaint)
                }
                .padding(16)
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func isCompleted(_ id: String) -> Bool {
        progress.first { $0.itemID == id }?.completed ?? false
    }
}
