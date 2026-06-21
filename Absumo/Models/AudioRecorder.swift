import Foundation
import AVFoundation

/// Records the learner's voice to a temporary file for shadowing self-comparison.
/// Everything stays on-device — nothing is uploaded.
@Observable
final class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var isRecording = false
    var hasRecording = false
    private(set) var url: URL?
    private var recorder: AVAudioRecorder?

    /// Ask for mic permission (iOS 17+ API).
    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    func toggle() { isRecording ? stop() : start() }

    func start() {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("shadow-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default,
                                                            options: [.defaultToSpeaker, .allowBluetooth])
            try AVAudioSession.sharedInstance().setActive(true)
            let r = try AVAudioRecorder(url: dest, settings: settings)
            r.delegate = self
            r.record()
            recorder = r
            url = dest
            isRecording = true
        } catch {
            isRecording = false
        }
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        hasRecording = true
    }
}
