import SwiftUI

// MARK: - Glass surfaces (Vetro)

/// A frosted-glass surface floating over the Vetro backdrop, lit from above.
/// `raised` panels sit forward (stronger shadow + optional accent glow);
/// non-raised ones recede. Replaces the old flat "paper card".
struct GlassPanel<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var raised: Bool = true
    var glow: Color? = nil
    @ViewBuilder var content: () -> Content

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }

    var body: some View {
        content()
            .background(.ultraThinMaterial, in: shape)
            .overlay(   // top-lit edge highlight → the "glass" tell
                shape.strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.55), .white.opacity(0.05)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1)
            )
            .shadow(color: (glow ?? Palette.ink).opacity(raised ? (glow == nil ? 0.18 : 0.30) : 0.07),
                    radius: raised ? 24 : 9, y: raised ? 14 : 5)
    }
}

/// Back-compat alias — existing screens call GlassCard; now it's frosted glass.
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 28
    @ViewBuilder var content: () -> Content
    var body: some View {
        GlassPanel(cornerRadius: cornerRadius, raised: true, content: content)
    }
}

// MARK: - Buttons

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = Palette.terracotta
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title)
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Palette.gradient(tint), in: Capsule())
            .shadow(color: tint.opacity(0.30), radius: 12, y: 6)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Stats

struct StatPill: View {
    let icon: String
    let value: String
    var tint: Color = Palette.olive

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(tint)
            Text(value).fontWeight(.bold).foregroundStyle(Palette.ink)
        }
        .font(.subheadline)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Palette.cardSoft, in: Capsule())
        .overlay(Capsule().strokeBorder(tint.opacity(0.30), lineWidth: 1))
    }
}

// MARK: - Tappable chips (word bank)

struct Chip: View {
    let text: String
    var tint: Color = Palette.terracotta
    var filled: Bool = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(filled ? .white : Palette.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    filled ? AnyShapeStyle(tint) : AnyShapeStyle(Palette.card),
                    in: Capsule()
                )
                .overlay(Capsule().strokeBorder(filled ? .clear : Palette.hairline, lineWidth: 1))
                .shadow(color: Palette.ink.opacity(filled ? 0 : 0.06), radius: 5, y: 3)
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Multiple-choice row

struct ChoiceRow: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack {
                Text(text).font(.title3.weight(.semibold)).foregroundStyle(Palette.ink)
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Palette.terracotta : Palette.inkFaint)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                selected ? Palette.terracotta.opacity(0.08) : Palette.card,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(selected ? Palette.terracotta : Palette.hairline,
                                  lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Feedback bar (shown after an answer is checked)

struct FeedbackBar: View {
    let correct: Bool
    let solution: String
    let onContinue: () -> Void

    private var tint: Color { correct ? Palette.olive : Palette.rosso }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                Text(correct ? "Perfetto!" : "Not quite")
                    .font(.title3.weight(.bold))
            }
            .foregroundStyle(tint)

            if !correct && !solution.isEmpty {
                Text("Answer: \(solution)")
                    .font(.subheadline)
                    .foregroundStyle(Palette.inkSoft)
            }

            PrimaryButton(title: "Continue", tint: tint, action: onContinue)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Flow layout (wrapping rows of chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        let width = maxWidth == .infinity ? x : maxWidth
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Void) {
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y),
                       proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
