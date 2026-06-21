import Foundation
import AVFoundation

/// Plays the bundled Piper-generated passage audio. Tiny wrapper over
/// AVAudioPlayer that exposes `isPlaying` for the UI and resets when playback
/// finishes. All audio ships in the app bundle — no network, no runtime TTS.
@Observable
final class AudioPlayer: NSObject, AVAudioPlayerDelegate {
    var isPlaying = false
    private var player: AVAudioPlayer?

    /// Toggle playback of a bundled resource like "al-bar.wav".
    func toggle(_ resource: String?) {
        guard let resource else { return }
        if isPlaying { stop() } else { play(resource) }
    }

    func play(_ resource: String) {
        let name = (resource as NSString).deletingPathExtension
        let ext = (resource as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: ext.isEmpty ? "wav" : ext) else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            p.enableRate = true            // lets us add a "slow" mode later
            player = p
            p.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    /// Play an arbitrary file URL (e.g. the learner's own shadowing recording).
    func playURL(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            player = p
            p.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
    }
}
