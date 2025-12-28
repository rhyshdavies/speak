import AVFoundation
import Foundation

/// Service for recording audio using Push-to-Talk
@MainActor
final class AudioRecorderService: NSObject, ObservableObject {
    // MARK: - Published State

    @Published private(set) var isRecording = false
    @Published private(set) var recordingURL: URL?
    @Published private(set) var audioLevel: Float = 0
    @Published private(set) var hasPermission = false

    // MARK: - Private Properties

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?

    private var recordingsDirectory: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("speak_recordings")
    }

    // MARK: - Initialization

    override init() {
        super.init()
        setupRecordingsDirectory()
        checkPermission()
    }

    private func setupRecordingsDirectory() {
        try? FileManager.default.createDirectory(
            at: recordingsDirectory,
            withIntermediateDirectories: true
        )
    }

    private func checkPermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            hasPermission = true
        case .denied:
            hasPermission = false
        case .undetermined:
            hasPermission = false
        @unknown default:
            hasPermission = false
        }
    }

    // MARK: - Permission

    /// Request microphone permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    self.hasPermission = granted
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording

    /// Start recording audio
    func startRecording() throws {
        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        // Create unique filename
        let fileName = "\(UUID().uuidString).m4a"
        let fileURL = recordingsDirectory.appendingPathComponent(fileName)

        // Recording settings (AAC format, good quality)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: AppConfig.sampleRate,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        // Create recorder
        audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        recordingURL = fileURL

        // Start level monitoring
        startLevelMonitoring()
    }

    /// Stop recording and return the file URL
    @discardableResult
    func stopRecording() -> URL? {
        stopLevelMonitoring()

        audioRecorder?.stop()
        audioRecorder = nil

        isRecording = false
        audioLevel = 0

        return recordingURL
    }

    // MARK: - Level Monitoring

    private func startLevelMonitoring() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopLevelMonitoring() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else {
            audioLevel = 0
            return
        }

        recorder.updateMeters()

        // Convert dB to linear scale (0-1)
        let averagePower = recorder.averagePower(forChannel: 0)
        let normalizedLevel = pow(10, averagePower / 20)
        audioLevel = min(max(normalizedLevel, 0), 1)
    }

    // MARK: - Cleanup

    /// Delete all recordings
    func cleanup() {
        stopRecording()
        try? FileManager.default.removeItem(at: recordingsDirectory)
        setupRecordingsDirectory()
        recordingURL = nil
    }

    /// Delete a specific recording
    func deleteRecording(at url: URL) {
        try? FileManager.default.removeItem(at: url)
        if recordingURL == url {
            recordingURL = nil
        }
    }
}
