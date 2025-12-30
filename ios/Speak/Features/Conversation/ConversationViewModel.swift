import Foundation
import Combine

/// Conversation state for Advanced mode
enum ConversationState {
    case idle      // Not started
    case active    // Actively listening
    case paused    // Paused, can resume
}

/// ViewModel for the conversation screen
/// Manages state, recording, API calls, and audio playback
@MainActor
final class ConversationViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isRecording = false
    @Published private(set) var isProcessing = false
    @Published private(set) var audioLevel: Float = 0
    @Published var errorMessage: String?
    @Published private(set) var suggestedResponses: [String]?
    @Published private(set) var scenarioProgress: ScenarioProgress = .beginning
    @Published private(set) var vocabularySpotlight: VocabularySpotlight?
    @Published var playbackSpeed: Float = AppConfig.defaultPlaybackSpeed
    @Published var showTranslations: Bool = true

    /// Live transcript for Advanced mode (shown while user speaks)
    @Published private(set) var liveTranscript: String = ""

    /// Live tutor response for Advanced mode (shown as it streams)
    @Published private(set) var liveTutorText: String = ""

    /// Conversation state for Advanced mode (idle/active/paused)
    @Published private(set) var conversationState: ConversationState = .idle

    /// Combined state lock - true when user cannot interact
    /// In Advanced mode, we don't lock during processing since it's continuous
    var isLocked: Bool {
        if mode == .advanced {
            return audioPlayer.isPlaying
        }
        return isProcessing || audioPlayer.isPlaying
    }

    // MARK: - Dependencies

    private let scenario: ScenarioContext
    private let cefrLevel: CEFRLevel
    private let mode: ConversationMode
    private let conversationEngine: ConversationEngine
    private let audioRecorder: AudioRecorderService
    private let audioPlayer: AudioPlayerService

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Session Tracking

    private let sessionStartDate = Date()
    private var turnCount: Int = 0
    private var didRecordSession: Bool = false
    private var recordedMessageIds: Set<UUID> = []  // Deduplication for SessionHistory

    // MARK: - Initialization

    init(
        scenario: ScenarioContext,
        cefrLevel: CEFRLevel,
        mode: ConversationMode = .beginner,
        conversationEngine: ConversationEngine? = nil,
        audioRecorder: AudioRecorderService? = nil,
        audioPlayer: AudioPlayerService? = nil
    ) {
        self.scenario = scenario
        self.cefrLevel = cefrLevel
        self.mode = mode

        // Select engine based on mode
        if let engine = conversationEngine {
            self.conversationEngine = engine
        } else {
            switch mode {
            case .beginner:
                self.conversationEngine = OpenAIBasicEngine()
            case .advanced:
                self.conversationEngine = RealtimeEngine()
            }
        }

        self.audioRecorder = audioRecorder ?? AudioRecorderService()
        self.audioPlayer = audioPlayer ?? AudioPlayerService()

        setupObservers()
        setupRealtimeDelegate()
        addInitialGreeting()
    }

    private func setupRealtimeDelegate() {
        // Set up delegate for Advanced mode streaming
        if let realtimeEngine = conversationEngine as? RealtimeEngine {
            realtimeEngine.delegate = self
        }
    }

    // MARK: - Setup

    private func setupObservers() {
        // Observe audio level from recorder
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)

        // Observe recording state
        audioRecorder.$isRecording
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRecording)

        // Observe playback speed
        audioPlayer.$playbackSpeed
            .receive(on: DispatchQueue.main)
            .assign(to: &$playbackSpeed)

        // Observe audio player state to trigger UI updates for isLocked
        audioPlayer.$isPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    private func addInitialGreeting() {
        let modeDescription = mode == .advanced
            ? "Using real-time mode for faster responses."
            : "Using turn-based mode."

        let greeting = ChatMessage(
            role: .assistant,
            content: "Ready to practice \(scenario.title)?",
            englishText: "Hold the button below and speak in Spanish. I'll play the role of \(scenario.tutorRole). \(modeDescription)"
        )
        messages.append(greeting)
    }

    // MARK: - Recording

    /// Start recording (called on PTT press or tap to start in Advanced mode)
    func startRecording() {
        guard !isLocked else { return }

        if mode == .advanced {
            startAdvancedModeRecording()
        } else {
            startBeginnerModeRecording()
        }
    }

    /// Stop recording and send to API (called on PTT release or tap to stop in Advanced mode)
    func stopRecordingAndSend() {
        if mode == .advanced {
            stopAdvancedModeRecording()
        } else {
            stopBeginnerModeRecording()
        }
    }

    // MARK: - Beginner Mode (Push-to-Talk)

    private func startBeginnerModeRecording() {
        Task {
            // Request permission if needed
            guard await audioRecorder.requestPermission() else {
                errorMessage = "Microphone permission is required"
                HapticManager.error()
                return
            }

            do {
                try audioRecorder.startRecording()
                HapticManager.mediumTap()
            } catch {
                errorMessage = "Failed to start recording: \(error.localizedDescription)"
                HapticManager.error()
            }
        }
    }

    private func stopBeginnerModeRecording() {
        guard isRecording else { return }

        guard let recordingURL = audioRecorder.stopRecording() else {
            return
        }

        HapticManager.lightTap()
        processRecording(at: recordingURL)
    }

    // MARK: - Advanced Mode (Continuous Streaming)

    private func startAdvancedModeRecording() {
        print("[ConversationVM] startAdvancedModeRecording called")
        guard let realtimeEngine = conversationEngine as? RealtimeEngine else {
            print("[ConversationVM] ERROR: conversationEngine is not RealtimeEngine")
            return
        }

        Task {
            do {
                print("[ConversationVM] Connecting to server...")
                // Connect to server if needed
                try await realtimeEngine.connect(scenario: scenario, cefrLevel: cefrLevel)
                print("[ConversationVM] Connected! Starting streaming...")

                // Start streaming audio
                try realtimeEngine.startStreaming()
                print("[ConversationVM] Streaming started!")
                isRecording = true
                conversationState = .active
                liveTranscript = ""
                liveTutorText = ""
                HapticManager.mediumTap()
            } catch {
                print("[ConversationVM] ERROR: \(error)")
                errorMessage = "Failed to start streaming: \(error.localizedDescription)"
                HapticManager.error()
            }
        }
    }

    private func stopAdvancedModeRecording() {
        guard let realtimeEngine = conversationEngine as? RealtimeEngine else { return }
        guard isRecording else { return }

        realtimeEngine.stopStreaming()
        isRecording = false
        HapticManager.lightTap()

        // Add the user transcript as a message if we have one
        if !liveTranscript.isEmpty {
            let userMessage = ChatMessage.userMessage(liveTranscript)
            messages.append(userMessage)
            liveTranscript = ""
        }
    }

    // MARK: - Advanced Mode Controls (Pause/Resume/Stop)

    /// Pause the conversation - stops listening but keeps connection alive
    func pauseConversation() {
        guard mode == .advanced, conversationState == .active else { return }
        guard let realtimeEngine = conversationEngine as? RealtimeEngine else { return }

        realtimeEngine.pause()  // Use pause() instead of stopStreaming() to prevent auto-resume
        isRecording = false
        conversationState = .paused
        HapticManager.lightTap()

        // Add any pending transcript as a message
        if !liveTranscript.isEmpty {
            let userMessage = ChatMessage.userMessage(liveTranscript)
            messages.append(userMessage)
            liveTranscript = ""
        }

        print("[ConversationVM] Conversation paused")
    }

    /// Resume the conversation - starts listening again
    func resumeConversation() {
        guard mode == .advanced, conversationState == .paused else { return }
        guard let realtimeEngine = conversationEngine as? RealtimeEngine else { return }

        realtimeEngine.unpause()  // Clear the pause flag first

        do {
            try realtimeEngine.startStreaming()
            isRecording = true
            conversationState = .active
            HapticManager.mediumTap()
            print("[ConversationVM] Conversation resumed")
        } catch {
            errorMessage = "Failed to resume: \(error.localizedDescription)"
            HapticManager.error()
        }
    }

    /// Stop the conversation completely - disconnects and resets
    func stopConversation() {
        guard mode == .advanced else { return }
        guard let realtimeEngine = conversationEngine as? RealtimeEngine else { return }

        // Stop streaming if active
        if isRecording {
            realtimeEngine.stopStreaming()
            isRecording = false
        }

        // Disconnect from server
        realtimeEngine.disconnect()
        conversationState = .idle

        // Clear live text
        liveTranscript = ""
        liveTutorText = ""

        HapticManager.lightTap()
        print("[ConversationVM] Conversation stopped")
    }

    // MARK: - Processing

    private func processRecording(at url: URL) {
        isProcessing = true

        Task {
            defer {
                isProcessing = false
                // Clean up recording file
                audioRecorder.deleteRecording(at: url)
            }

            do {
                let response = try await conversationEngine.generateTurn(
                    audioFileURL: url,
                    messages: messages,
                    context: scenario,
                    cefrLevel: cefrLevel
                )

                // Add user message
                let userMessage = ChatMessage.userMessage(response.userTranscript)
                messages.append(userMessage)

                // Add tutor message
                let tutorMessage = ChatMessage.tutorMessage(
                    spanish: response.tutorResponse.tutorSpanish,
                    english: response.tutorResponse.tutorEnglish,
                    correction: response.tutorResponse.correctionSpanish,
                    correctionEnglish: response.tutorResponse.correctionEnglish
                )
                messages.append(tutorMessage)

                // Increment turn count
                turnCount += 1

                // Record to SessionHistory
                recordTutorMessage(tutorMessage)
                if let correction = response.tutorResponse.correctionSpanish {
                    recordCorrection(
                        original: response.userTranscript,
                        corrected: correction,
                        english: response.tutorResponse.correctionEnglish,
                        messageId: tutorMessage.id
                    )
                }

                // Update state
                suggestedResponses = response.tutorResponse.suggestedResponses
                scenarioProgress = response.tutorResponse.scenarioProgress
                vocabularySpotlight = response.tutorResponse.vocabularySpotlight

                // Play audio response
                if let audioData = response.audioData {
                    try audioPlayer.play(data: audioData) {
                        // Audio finished playing
                    }
                }

                HapticManager.success()

            } catch {
                errorMessage = error.localizedDescription
                HapticManager.error()
            }
        }
    }

    // MARK: - Playback Speed

    func setPlaybackSpeed(_ speed: Float) {
        audioPlayer.setSpeed(speed)
    }

    func cyclePlaybackSpeed() {
        audioPlayer.cycleSpeed()
        HapticManager.selection()
    }

    // MARK: - Session End

    /// Call this when the user exits the conversation (tap Exit button)
    /// Only records the session if turnCount >= 2 (prevents "opened app, said nothing" counting)
    func endSession() {
        guard !didRecordSession else { return }  // Only record once
        didRecordSession = true

        // Only count as a session if user had at least 2 turns
        guard turnCount >= 2 else {
            print("[Session] Not recording - only \(turnCount) turns (minimum 2 required)")
            return
        }

        let durationSeconds = Int(Date().timeIntervalSince(sessionStartDate))
        StreakManager.shared.recordSession(durationSeconds: durationSeconds)
        print("[Session] Recorded session: \(turnCount) turns, \(durationSeconds)s duration")
    }

    // MARK: - Cleanup

    func cleanup() {
        // End session before cleanup (in case user force-closes)
        endSession()

        audioRecorder.cleanup()
        audioPlayer.stop()

        // Disconnect WebSocket for Advanced mode
        if let realtimeEngine = conversationEngine as? RealtimeEngine {
            realtimeEngine.disconnect()
        }
    }

    // MARK: - SessionHistory Helpers

    /// Record a tutor message to SessionHistory (with deduplication)
    private func recordTutorMessage(_ message: ChatMessage) {
        guard !recordedMessageIds.contains(message.id) else { return }
        recordedMessageIds.insert(message.id)

        SessionHistory.shared.addTutorMessage(
            spanish: message.content,
            english: message.englishText,
            scenario: scenario.title
        )
    }

    /// Record a correction to SessionHistory (with deduplication)
    private func recordCorrection(original: String, corrected: String, english: String?, messageId: UUID) {
        guard !recordedMessageIds.contains(messageId) else { return }
        // Don't insert here - correction shares ID with its message

        SessionHistory.shared.addCorrection(
            original: original,
            corrected: corrected,
            english: english,
            scenario: scenario.title
        )
    }
}

// MARK: - RealtimeEngineDelegate

extension ConversationViewModel: RealtimeEngineDelegate {
    nonisolated func realtimeEngine(_ engine: RealtimeEngine, didReceiveTranscript text: String, isFinal: Bool) {
        Task { @MainActor in
            liveTranscript = text
        }
    }

    nonisolated func realtimeEngine(_ engine: RealtimeEngine, didReceiveTutorText text: String) {
        Task { @MainActor in
            liveTutorText = text
        }
    }

    nonisolated func realtimeEngine(_ engine: RealtimeEngine, didReceiveAudioData data: Data) {
        // Audio chunks are accumulated in the engine and played when complete
    }

    nonisolated func realtimeEngineDidFinishResponse(_ engine: RealtimeEngine, response: TurnResponse) {
        Task { @MainActor in
            // Add user message first (if we have a transcript)
            if !response.userTranscript.isEmpty {
                let userMessage = ChatMessage.userMessage(response.userTranscript)
                messages.append(userMessage)
            }

            // Add tutor message (only if there's content)
            if !response.tutorResponse.tutorSpanish.isEmpty {
                let tutorMessage = ChatMessage.tutorMessage(
                    spanish: response.tutorResponse.tutorSpanish,
                    english: response.tutorResponse.tutorEnglish,
                    correction: response.tutorResponse.correctionSpanish,
                    correctionEnglish: response.tutorResponse.correctionEnglish
                )
                messages.append(tutorMessage)

                // Increment turn count
                turnCount += 1

                // Record to SessionHistory
                recordTutorMessage(tutorMessage)
                if let correction = response.tutorResponse.correctionSpanish {
                    recordCorrection(
                        original: response.userTranscript,
                        corrected: correction,
                        english: response.tutorResponse.correctionEnglish,
                        messageId: tutorMessage.id
                    )
                }
            }

            // Clear live text
            liveTranscript = ""
            liveTutorText = ""

            // Update state
            suggestedResponses = response.tutorResponse.suggestedResponses
            scenarioProgress = response.tutorResponse.scenarioProgress
            vocabularySpotlight = response.tutorResponse.vocabularySpotlight

            // NOTE: Audio was already played via streaming (AVAudioPlayerNode) in RealtimeEngine.
            // The RealtimeEngine automatically calls resumeAfterPlayback() when all audio buffers finish.
            // No need to do anything here for audio playback.

            HapticManager.success()
        }
    }

    nonisolated func realtimeEngine(_ engine: RealtimeEngine, didEncounterError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
            HapticManager.error()
        }
    }
}
