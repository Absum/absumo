import SwiftUI
import SwiftData

/// First-launch onboarding: sets the retention target (which tunes the SRS) and
/// an optional gentle daily reminder. Short and calm — no hype.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var states: [UserState]

    @State private var retention = 0.9
    @State private var reminders = false

    private let options: [(label: String, sub: String, value: Double)] = [
        ("Casual", "Fewer reviews, lighter touch", 0.85),
        ("Balanced", "The recommended default", 0.90),
        ("Thorough", "More reviews, stronger memory", 0.95)
    ]

    var body: some View {
        ZStack {
            MeshBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Benvenuto")
                            .font(.serifDisplay(40, weight: .bold))
                            .foregroundStyle(Palette.ink)
                        Text("Absumo helps you actually learn Italian — read and listen to real Italian, and the words you meet come back for review right before you'd forget them.")
                            .font(.body).foregroundStyle(Palette.inkSoft)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How thoroughly do you want to remember?")
                            .font(.headline).foregroundStyle(Palette.ink)
                        ForEach(options, id: \.value) { opt in
                            choice(opt)
                        }
                        Text("This sets how often words come back. You can't really get this wrong — it just balances review load against retention.")
                            .font(.caption).foregroundStyle(Palette.inkFaint)
                    }

                    Toggle(isOn: $reminders) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Gentle daily reminder").font(.headline).foregroundStyle(Palette.ink)
                            Text("One quiet nudge a day. Off by default.").font(.caption).foregroundStyle(Palette.inkSoft)
                        }
                    }
                    .tint(Palette.olive)
                    .padding(16)
                    .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.hairline))

                    PrimaryButton(title: "Inizia", systemImage: "arrow.right", tint: Palette.terracotta) {
                        finish()
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.light)
        .interactiveDismissDisabled()
    }

    private func choice(_ opt: (label: String, sub: String, value: Double)) -> some View {
        let selected = abs(retention - opt.value) < 0.001
        return Button { retention = opt.value } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(opt.label).font(.headline).foregroundStyle(Palette.ink)
                    Text(opt.sub).font(.caption).foregroundStyle(Palette.inkSoft)
                }
                Spacer()
                Image(systemName: selected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(selected ? Palette.terracotta : Palette.inkFaint)
            }
            .padding(16)
            .background(selected ? Palette.terracotta.opacity(0.08) : Palette.card,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(selected ? Palette.terracotta : Palette.hairline, lineWidth: selected ? 2 : 1))
        }
        .buttonStyle(BouncyButtonStyle())
    }

    private func finish() {
        let user = states.first ?? {
            let u = UserState(); context.insert(u); return u
        }()
        user.retentionTarget = retention
        user.remindersOn = reminders
        user.onboarded = true
        try? context.save()
        if reminders { Reminders.enable() } else { Reminders.disable() }
        dismiss()
    }
}
