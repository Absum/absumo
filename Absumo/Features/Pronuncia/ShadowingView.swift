import SwiftUI

/// Shadowing: listen to the model (paola), record yourself saying it, then play
/// both back to compare. No automatic scoring — the learner trains their own ear.
/// All audio stays on-device.
struct ShadowingView: View {
    let items: [GradedItem]

    @State private var audio = AudioPlayer()
    @State private var recorder = AudioRecorder()
    @State private var index = 0
    @State private var micDenied = false

    private var item: GradedItem? { items.indices.contains(index) ? items[index] : nil }

    var body: some View {
        ZStack {
            MeshBackground()
            VStack(spacing: 22) {
                if let item {
                    Text(item.level)
                        .font(.caption.weight(.bold)).tracking(2).foregroundStyle(Palette.adriatic)
                    Text(item.title)
                        .font(.serifDisplay(30, weight: .bold)).foregroundStyle(Palette.ink)
                    Text(item.text)
                        .font(.system(size: 22, design: .serif))
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)

                    Spacer()
                    steps(item)
                    Spacer()
                    nextButton
                } else {
                    Text("No audio available").foregroundStyle(Palette.inkSoft)
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.light)
        .onDisappear { audio.stop(); if recorder.isRecording { recorder.stop() } }
        .alert("Microphone access needed", isPresented: $micDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enable microphone access in Settings to record and compare your pronunciation.")
        }
    }

    private func steps(_ item: GradedItem) -> some View {
        VStack(spacing: 16) {
            // 1. Listen to the model
            bigButton(icon: "speaker.wave.2.fill", label: "Listen to the model", tint: Palette.olive) {
                if let a = item.audio { audio.stop(); audio.play(a) }
            }
            // 2. Record yourself
            bigButton(icon: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill",
                      label: recorder.isRecording ? "Stop recording" : "Record yourself",
                      tint: recorder.isRecording ? Palette.rosso : Palette.terracotta) {
                toggleRecord()
            }
            // 3. Play your recording (after one exists)
            bigButton(icon: "person.wave.2.fill", label: "Play yours", tint: Palette.adriatic,
                      enabled: recorder.hasRecording && !recorder.isRecording) {
                if let url = recorder.url { audio.stop(); audio.playURL(url) }
            }
        }
    }

    private func bigButton(icon: String, label: String, tint: Color,
                           enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.headline)
                Spacer()
            }
            .foregroundStyle(enabled ? tint : Palette.inkFaint)
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Palette.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Palette.hairline))
        }
        .buttonStyle(BouncyButtonStyle())
        .disabled(!enabled)
    }

    private var nextButton: some View {
        PrimaryButton(title: "Next phrase", systemImage: "arrow.right", tint: Palette.adriatic) {
            audio.stop()
            recorder = AudioRecorder()          // reset recording state for the next item
            index = (index + 1) % max(items.count, 1)
        }
    }

    private func toggleRecord() {
        if recorder.isRecording { recorder.stop(); return }
        recorder.requestPermission { granted in
            if granted { recorder.start() } else { micDenied = true }
        }
    }
}
