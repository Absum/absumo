import SwiftUI

/// Placeholder for tabs whose features land in later phases. Keeps the shell
/// honest about where we are in the roadmap rather than faking content.
struct ComingSoonView: View {
    let icon: String
    let title: String
    let phase: String
    let blurb: String

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56))
                    .foregroundStyle(Palette.terracotta)
                Text(title)
                    .font(.serifDisplay(34, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(phase)
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(Palette.terracotta)
                Text(blurb)
                    .font(.body)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding()
        }
    }
}
