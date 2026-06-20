import Foundation
import AVFoundation
import MediaPlayer

/// Hands-free playlist player for the Listen mode: plays a queue of graded-item
/// audio back-to-back, auto-advancing, with lock-screen / Control-Center
/// metadata and remote (play/pause/skip) commands. Background audio is enabled
/// via UIBackgroundModes=audio, so it keeps playing on the commute.
@Observable
final class ListenPlayer: NSObject, AVAudioPlayerDelegate {
    private(set) var queue: [GradedItem] = []
    private(set) var index = 0
    var isPlaying = false

    private var player: AVAudioPlayer?
    private var remoteConfigured = false

    var current: GradedItem? { queue.indices.contains(index) ? queue[index] : nil }

    /// Begin playing `items` (only those with audio) starting at `start`.
    func start(_ items: [GradedItem], at start: Int = 0) {
        queue = items.filter { $0.audio != nil }
        guard !queue.isEmpty else { return }
        index = min(max(start, 0), queue.count - 1)
        configureSession()
        configureRemoteCommands()
        playCurrent()
    }

    func togglePlayPause() {
        guard let player else { playCurrent(); return }
        if player.isPlaying { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
        updateNowPlaying()
    }

    func next() {
        if index < queue.count - 1 { index += 1; playCurrent() }
        else { stop() }
    }

    func previous() {
        // Restart current if we're past the first couple seconds, else go back.
        if let p = player, p.currentTime > 2 { p.currentTime = 0; updateNowPlaying() }
        else if index > 0 { index -= 1; playCurrent() }
    }

    func play(at i: Int) {
        guard queue.indices.contains(i) else { return }
        index = i
        playCurrent()
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Internals

    private func playCurrent() {
        guard let item = current, let resource = item.audio else { return }
        let name = (resource as NSString).deletingPathExtension
        let ext = (resource as NSString).pathExtension
        guard let url = Bundle.main.url(forResource: name,
                                        withExtension: ext.isEmpty ? "wav" : ext) else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.delegate = self
            player = p
            p.play()
            isPlaying = true
            updateNowPlaying()
        } catch {
            isPlaying = false
        }
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func configureRemoteCommands() {
        guard !remoteConfigured else { return }
        remoteConfigured = true
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.togglePlayPause(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
    }

    private func updateNowPlaying() {
        guard let item = current, let player else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: "Absumo · \(item.level)",
            MPMediaItemPropertyPlaybackDuration: player.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: player.currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: player.isPlaying ? 1.0 : 0.0
        ]
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        next()
    }
}
