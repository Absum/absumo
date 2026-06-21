import SwiftUI

/// Pronunciation & ear-training hub. Two activities: minimal-pairs discrimination
/// and shadowing. Reached from the Today "Pronuncia" card.
struct PronunciaView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MeshBackground()
                ScrollView {
                    VStack(spacing: 14) {
                        NavigationLink {
                            MinimalPairsView()
                        } label: {
                            row(icon: "ear.fill",
                                title: "Coppie minime",
                                subtitle: "Hear the difference: nonno vs nono",
                                tint: Palette.terracotta)
                        }
                        NavigationLink {
                            ShadowingView(items: GradedLibrary.all)
                        } label: {
                            row(icon: "waveform.badge.mic",
                                title: "Shadowing",
                                subtitle: "Listen, repeat, compare yourself",
                                tint: Palette.adriatic)
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Pronuncia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }.tint(Palette.terracotta)
                }
            }
        }
    }

    private func row(icon: String, title: String, subtitle: String, tint: Color) -> some View {
        GlassCard(cornerRadius: 20) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title2).foregroundStyle(tint)
                    .frame(width: 46, height: 46)
                    .background(tint.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(Palette.ink)
                    Text(subtitle).font(.subheadline).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Palette.inkFaint)
            }
            .padding(16)
        }
    }
}
