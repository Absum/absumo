import SwiftUI

/// A single lesson "stone" on the winding path.
struct PathNode: View {
    enum NodeState { case completed, current, locked }

    let title: String
    let icon: String
    let accent: Color
    let index: Int
    let state: NodeState
    let action: () -> Void

    /// Horizontal sway gives the trail its gentle winding shape.
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
                    // Current lesson sits in a soft halo ring.
                    if state == .current {
                        Circle()
                            .strokeBorder(accent.opacity(0.35), lineWidth: 3)
                            .frame(width: 104, height: 104)
                    }

                    Circle()
                        .fill(fillStyle)
                        .frame(width: 88, height: 88)
                        .overlay(Circle().strokeBorder(strokeColor, lineWidth: 1))
                        .shadow(color: shadowColor, radius: state == .locked ? 6 : 14,
                                y: state == .locked ? 3 : 8)

                    Image(systemName: symbol)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(state == .locked ? Palette.inkFaint : Palette.ink)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(state == .locked)
        .offset(x: sway)
    }

    private var fillStyle: AnyShapeStyle {
        switch state {
        case .locked:
            return AnyShapeStyle(Palette.cardSoft)
        case .completed, .current:
            return AnyShapeStyle(Palette.gradient(accent))
        }
    }

    private var strokeColor: Color {
        state == .locked ? Palette.hairline : .white.opacity(0.35)
    }

    private var iconColor: Color {
        state == .locked ? Palette.inkFaint : .white
    }

    private var shadowColor: Color {
        switch state {
        case .locked:              return Palette.ink.opacity(0.08)
        case .completed, .current: return accent.opacity(0.30)
        }
    }
}
