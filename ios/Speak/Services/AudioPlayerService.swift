import AVFoundation
import Foundation

/// Service for playing TTS audio responses
@MainActor
final class AudioPlayerService: NSObject, ObservableObject {
    // MARK: - Published State

    @Published private(set) var isPlaying = false
    @Published var playbackSpeed: Float = AppConfig.defaultPlaybackSpeed

    // MARK: - Private Properties

    private var audioPlayer: AVAudioPlayer?
    private var completionHandler: (() -> Void)?

    // MARK: - Playback

    /// Play audio from Data
    func play(data: Data, completion: (() -> Void)? = nil) throws {
        stop()

        // Configure audio session for playback
        // Use .playAndRecord to be compatible with Advanced mode streaming
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        // Create player
        audioPlayer = try AVAudioPlayer(data: data)
        audioPlayer?.delegate = self
        audioPlayer?.enableRate = true
        audioPlayer?.rate = playbackSpeed
        audioPlayer?.prepareToPlay()

        completionHandler = completion
        audioPlayer?.play()
        isPlaying = true
    }

    /// Play audio from URL
    func play(url: URL, completion: (() -> Void)? = nil) throws {
        let data = try Data(contentsOf: url)
        try play(data: data, completion: completion)
    }

    /// Stop playback
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        completionHandler = nil
    }

    /// Pause playback
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    /// Resume playback
    func resume() {
        audioPlayer?.play()
        isPlaying = audioPlayer?.isPlaying ?? false
    }

    // MARK: - Speed Control

    /// Set playback speed
    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
        audioPlayer?.rate = speed
    }

    /// Cycle through available speeds
    func cycleSpeed() {
        let speeds = AppConfig.playbackSpeeds
        if let currentIndex = speeds.firstIndex(of: playbackSpeed) {
            let nextIndex = (currentIndex + 1) % speeds.count
            setSpeed(speeds[nextIndex])
        } else {
            setSpeed(speeds[0])
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayerService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.completionHandler?()
            self.completionHandler = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            self.isPlaying = false
            self.completionHandler = nil
        }
    }
}
