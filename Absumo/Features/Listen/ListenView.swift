import SwiftUI

/// Hands-free listening: a now-playing screen over a queue of graded stories.
/// Audio auto-advances and keeps playing in the background / on the lock screen.
struct ListenView: View {
    let items: [GradedItem]
    var startIndex: Int = 0

    @Environment(\.dismiss) private var dismiss
    @State private var player = ListenPlayer()

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 0) {
                header
                Spacer()
                nowPlaying
                Spacer()
                controls
                Spacer()
                queueList
            }
            .padding(20)
        }
        .preferredColorScheme(.light)
        .onAppear { if player.queue.isEmpty { player.start(items, at: startIndex) } }
        .onDisappear { player.stop() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.headline.bold()).foregroundStyle(Palette.inkSoft)
            }
            Spacer()
            Text("Ascolta").font(.caption.weight(.bold)).tracking(2).foregroundStyle(Palette.terracotta)
            Spacer()
            Image(systemName: "chevron.down").font(.headline.bold()).foregroundStyle(.clear)
        }
    }

    private var nowPlaying: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(Palette.terracotta.opacity(0.12)).frame(width: 200, height: 200)
                Image(systemName: player.isPlaying ? "waveform" : "headphones")
                    .font(.system(size: 80))
                    .foregroundStyle(Palette.terracotta)
                    .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
            }
            Text(player.current?.title ?? "—")
                .font(.serifDisplay(32, weight: .bold))
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
            Text(player.current.map { "\($0.level) · graded story" } ?? "")
                .font(.subheadline).foregroundStyle(Palette.inkSoft)
        }
    }

    private var controls: some View {
        HStack(spacing: 40) {
            Button { player.previous() } label: {
                Image(systemName: "backward.fill").font(.title)
            }
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            Button { player.next() } label: {
                Image(systemName: "forward.fill").font(.title)
            }
        }
        .foregroundStyle(Palette.terracotta)
    }

    private var queueList: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(Array(player.queue.enumerated()), id: \.element.id) { i, item in
                    Button { player.play(at: i) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: i == player.index
                                  ? (player.isPlaying ? "speaker.wave.2.fill" : "speaker.fill")
                                  : "circle")
                                .font(.footnote)
                                .foregroundStyle(i == player.index ? Palette.terracotta : Palette.inkFaint)
                                .frame(width: 22)
                            Text(item.title)
                                .font(.subheadline.weight(i == player.index ? .bold : .regular))
                                .foregroundStyle(i == player.index ? Palette.ink : Palette.inkSoft)
                            Spacer()
                            Text(item.level).font(.caption2).foregroundStyle(Palette.inkFaint)
                        }
                        .padding(.vertical, 10).padding(.horizontal, 14)
                        .background(i == player.index ? Palette.cardSoft : .clear,
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: 220)
        .scrollIndicators(.hidden)
    }
}
