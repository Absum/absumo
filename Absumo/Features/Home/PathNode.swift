import SwiftUI

/// A single lesson "bubble" on the winding path.
struct PathNode: View {
    enum NodeState { case completed, current, locked }

    let title: String
    let icon: String
    let accent: Color
    let index: Int
    let state: NodeState
    let action: () -> Void

    /// Horizontal sway gives the trail its playful winding shape.
    private var sway: CGFloat { CGFloat(sin(Double(index) * 0.9)) * 64 }

    private var symbol: String {
        switch state {
        case .locked:    return "lock.fill"
        case .completed: return "checkmark"
        case .current:   return icon
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(fillStyle)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().strokeBorder(.white.opacity(0.18), lineWidth: 1))
                        .shadow(color: glowColor, radius: state == .current ? 22 : 0)

                    if state == .current {
                        Circle()
                            .strokeBorder(accent.opacity(0.5), lineWidth: 3)
                            .frame(width: 104, height: 104)
                    }

                    Image(systemName: symbol)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(state == .locked ? .white.opacity(0.5) : Palette.ink)
                }

                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(state == .locked ? 0.4 : 0.95))
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(state == .locked)
        .offset(x: sway)
    }

    private var fillStyle: AnyShapeStyle {
        switch state {
        case .locked:
            return AnyShapeStyle(.ultraThinMaterial)
        case .completed, .current:
            return AnyShapeStyle(
                LinearGradient(colors: [accent, accent.opacity(0.7)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
        }
    }

    private var glowColor: Color {
        state == .current ? accent.opacity(0.6) : .clear
    }
}
