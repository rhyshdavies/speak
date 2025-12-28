import Foundation
import AVFoundation

/// Delegate for receiving real-time updates from RealtimeEngine
protocol RealtimeEngineDelegate: AnyObject {
    func realtimeEngine(_ engine: RealtimeEngine, didReceiveTranscript text: String, isFinal: Bool)
    func realtimeEngine(_ engine: RealtimeEngine, didReceiveTutorText text: String)
    func realtimeEngine(_ engine: RealtimeEngine, didReceiveAudioData data: Data)
    func realtimeEngineDidFinishResponse(_ engine: RealtimeEngine, response: TurnResponse)
    func realtimeEngine(_ engine: RealtimeEngine, didEncounterError error: Error)
}

/// WebSocket-based real-time conversation engine
/// Uses ElevenLabs Scribe STT → Groq Llama 3.3 70B → Cartesia TTS pipeline
/// Features: Sentence-level TTS streaming, streaming audio playback, event-driven connection
/// Target latency: sub-300ms (vs ~2.6s for REST-based beginner mode)
final class RealtimeEngine: NSObject, ConversationEngine {
    // MARK: - Properties

    weak var delegate: RealtimeEngineDelegate?

    private var webSocket: URLSessionWebSocketTask?
    private var urlSession: URLSession!
    private var isConnected = false
    private var scenario: ScenarioContext?
    private var cefrLevel: CEFRLevel = .a1

    // Audio streaming (mic input)
    private var audioEngine: AVAudioEngine?
    private var isStreaming = false
    private var isTTSPlaying = false  // Pause mic input during TTS to prevent echo

    // Streaming audio playback (TTS output)
    private var playbackEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let playbackFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000, channels: 1, interleaved: true)!
    private var pendingBufferCount = 0  // Track how many buffers are queued for playback

    // Response accumulation
    private var currentTranscript = ""
    private var tutorSpanishText = ""
    private var tutorEnglishText = ""
    private var suggestedResponses: [String]? = nil
    private var audioChunks: [Data] = []  // Still accumulate for final response
    private var responseCompletion: ((Result<TurnResponse, Error>) -> Void)?
    private var isWaitingForResponse = false

    // Connection state for event-driven setup
    private var connectionContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Initialization

    override init() {
        super.init()
        self.urlSession = URLSession(
            configuration: .default,
            delegate: self,
            delegateQueue: OperationQueue()
        )
    }

    // MARK: - Connection Management

    func connect(scenario: ScenarioContext, cefrLevel: CEFRLevel) async throws {
        self.scenario = scenario
        self.cefrLevel = cefrLevel

        print("[RealtimeEngine] Connecting to: \(AppConfig.webSocketURL)")

        guard let url = URL(string: AppConfig.webSocketURL) else {
            print("[RealtimeEngine] ERROR: Invalid URL")
            throw ConversationEngineError.networkError(URLError(.badURL))
        }

        webSocket = urlSession.webSocketTask(with: url)
        webSocket?.resume()
        print("[RealtimeEngine] WebSocket resumed")

        // Start listening for messages immediately so we can receive 'ready'
        startListening()

        // Wait for connection using event-driven approach (no fixed delay!)
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.connectionContinuation = continuation

            // Timeout after 10 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
                if let cont = self?.connectionContinuation {
                    self?.connectionContinuation = nil
                    cont.resume(throwing: ConversationEngineError.networkError(URLError(.timedOut)))
                }
            }
        }
    }

    func disconnect() {
        stopStreaming()
        stopPlaybackEngine()
        webSocket?.cancel(with: .goingAway, reason: nil)
        isConnected = false
    }

    // MARK: - Audio Streaming

    /// Start streaming audio to the server (for Advanced mode continuous listening)
    func startStreaming() throws {
        print("[RealtimeEngine] startStreaming called, isConnected: \(isConnected)")
        guard isConnected else {
            print("[RealtimeEngine] ERROR: Not connected!")
            throw ConversationEngineError.networkError(URLError(.notConnectedToInternet))
        }
        guard !isStreaming else {
            print("[RealtimeEngine] Already streaming")
            return
        }

        // Configure audio session
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)

        // Setup audio engine
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Convert to 16kHz mono PCM for Deepgram
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)!

        // Create converter
        guard let converter = AVAudioConverter(from: inputFormat, to: targetFormat) else {
            throw ConversationEngineError.audioProcessingError
        }

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer, converter: converter, targetFormat: targetFormat)
        }

        try audioEngine.start()
        isStreaming = true

        // Reset state for new conversation turn
        currentTranscript = ""
        tutorSpanishText = ""
        tutorEnglishText = ""
        suggestedResponses = nil
        audioChunks = []
        pendingBufferCount = 0
    }

    /// Stop streaming audio
    func stopStreaming() {
        guard isStreaming else { return }

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isStreaming = false
    }

    /// Resume mic input after TTS playback finishes (call from ViewModel after audio player completes)
    func resumeAfterPlayback() {
        isTTSPlaying = false
        print("[RealtimeEngine] Playback complete, resuming mic input")

        // Also send resume to server
        guard let webSocket = webSocket, isConnected else { return }
        let message = ["type": "resume"]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let str = String(data: data, encoding: .utf8) {
            webSocket.send(.string(str)) { error in
                if let error = error {
                    print("[RealtimeEngine] Error sending resume: \(error)")
                } else {
                    print("[RealtimeEngine] Sent resume to server")
                }
            }
        }
    }

    /// Legacy method - use resumeAfterPlayback() instead
    func sendResume() {
        resumeAfterPlayback()
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, converter: AVAudioConverter, targetFormat: AVAudioFormat) {
        // Create output buffer
        let frameCount = AVAudioFrameCount(Double(buffer.frameLength) * targetFormat.sampleRate / buffer.format.sampleRate)
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCount) else { return }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, error == nil else { return }

        // Convert to Data and send via WebSocket
        if let channelData = outputBuffer.int16ChannelData {
            let data = Data(bytes: channelData[0], count: Int(outputBuffer.frameLength) * 2)
            sendAudioChunk(data)
        }
    }

    private func sendAudioChunk(_ data: Data) {
        // Don't send audio while TTS is playing to prevent echo
        guard !isTTSPlaying else { return }
        guard let webSocket = webSocket, isConnected else { return }
        webSocket.send(.data(data)) { error in
            if let error = error {
                print("[RealtimeEngine] Error sending audio: \(error)")
            }
        }
    }

    private func sendSetup(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let scenario = scenario else {
            completion(.failure(ConversationEngineError.invalidResponse))
            return
        }

        let setupMessage: [String: Any] = [
            "type": "setup",
            "scenario": [
                "type": scenario.type.rawValue,
                "title": scenario.title,
                "setting": scenario.setting,
                "tutorRole": scenario.tutorRole,
                "objectives": scenario.objectives
            ],
            "cefrLevel": cefrLevel.rawValue
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: setupMessage) else {
            completion(.failure(ConversationEngineError.encodingError))
            return
        }

        webSocket?.send(.string(String(data: data, encoding: .utf8)!)) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // MARK: - ConversationEngine Protocol

    func generateTurn(
        audioFileURL: URL,
        messages: [ChatMessage],
        context: ScenarioContext,
        cefrLevel: CEFRLevel
    ) async throws -> TurnResponse {
        // Connect if not already connected
        if !isConnected {
            try await connect(scenario: context, cefrLevel: cefrLevel)
        }

        // Reset state for new turn
        currentTranscript = ""
        tutorSpanishText = ""
        tutorEnglishText = ""
        suggestedResponses = nil
        audioChunks = []
        isWaitingForResponse = true

        // Read and send audio data
        let audioData = try Data(contentsOf: audioFileURL)
        try await sendAudio(audioData)

        // Wait for response
        return try await withCheckedThrowingContinuation { continuation in
            self.responseCompletion = { result in
                continuation.resume(with: result)
            }

            // Timeout after 30 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                if self?.isWaitingForResponse == true {
                    self?.isWaitingForResponse = false
                    continuation.resume(throwing: ConversationEngineError.networkError(URLError(.timedOut)))
                }
            }
        }
    }

    private func sendAudio(_ data: Data) async throws {
        guard let webSocket = webSocket else {
            throw ConversationEngineError.networkError(URLError(.notConnectedToInternet))
        }

        // Send audio as binary data
        try await webSocket.send(.data(data))
    }

    // MARK: - Message Handling

    private func startListening() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                // Continue listening
                self?.startListening()
            case .failure(let error):
                print("[RealtimeEngine] WebSocket error: \(error)")
                self?.isConnected = false
            }
        }
    }

    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            handleJSONMessage(text)
        case .data(let data):
            // Binary audio data
            audioChunks.append(data)
        @unknown default:
            break
        }
    }

    private func handleJSONMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "ready":
            print("[RealtimeEngine] Server ready")
            // Resume connection continuation - server is ready!
            isConnected = true
            if let cont = connectionContinuation {
                connectionContinuation = nil
                cont.resume()
            }

        case "transcript":
            // Interim or final transcript from Deepgram
            if let transcript = json["text"] as? String {
                let isFinal = json["isFinal"] as? Bool ?? false
                currentTranscript = transcript
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.realtimeEngine(self, didReceiveTranscript: transcript, isFinal: isFinal)
                }
            }

        case "tutor_text":
            // Streaming text from Gemini
            if let fullText = json["fullText"] as? String {
                tutorSpanishText = fullText
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.realtimeEngine(self, didReceiveTutorText: fullText)
                }
            }

        case "tutor_response":
            // Full response with all metadata
            if let response = json["response"] as? [String: Any] {
                tutorSpanishText = response["tutorSpanish"] as? String ?? tutorSpanishText
                tutorEnglishText = response["tutorEnglish"] as? String ?? ""
                suggestedResponses = response["suggestedResponses"] as? [String]
            }

        case "audio":
            // Base64 audio chunk from Cartesia - play immediately!
            isTTSPlaying = true
            if let base64Data = json["data"] as? String,
               let audioData = Data(base64Encoded: base64Data) {
                audioChunks.append(audioData)  // Still accumulate for final response
                // Play chunk immediately for streaming playback
                playAudioChunk(audioData)
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.realtimeEngine(self, didReceiveAudioData: audioData)
                }
            }

        case "audio_done":
            // Audio streaming complete - but DON'T resume mic yet!
            // Mic will resume after audio playback finishes via resumeAfterPlayback()
            print("[RealtimeEngine] Audio chunks received, finalizing response")
            finalizeResponse()

        case "error":
            if let errorMessage = json["message"] as? String {
                let error = ConversationEngineError.apiError(errorMessage)
                responseCompletion?(.failure(error))
                isWaitingForResponse = false
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.realtimeEngine(self, didEncounterError: error)
                }
            }

        case "stt_disconnected":
            // Speech recognition disconnected - notify user
            let error = ConversationEngineError.apiError("Speech recognition disconnected. Please restart.")
            isConnected = false
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.realtimeEngine(self, didEncounterError: error)
            }

        default:
            break
        }
    }

    private func finalizeResponse() {
        // Combine audio chunks (for response metadata - audio was already streamed)
        var combinedAudio = Data()
        for chunk in audioChunks {
            combinedAudio.append(chunk)
        }
        print("[RealtimeEngine] Finalizing response: \(audioChunks.count) chunks, \(combinedAudio.count) bytes total, \(pendingBufferCount) buffers still playing")

        // Check if we have any meaningful content
        let hasAudio = !combinedAudio.isEmpty
        let hasText = !tutorSpanishText.isEmpty

        // If no content, just reset and don't notify (empty response from server)
        if !hasAudio && !hasText {
            print("[RealtimeEngine] Empty response - skipping notification")
            currentTranscript = ""
            tutorSpanishText = ""
            tutorEnglishText = ""
            suggestedResponses = nil
            audioChunks = []
            // If no audio was streamed, resume mic immediately
            if pendingBufferCount == 0 {
                resumeAfterPlayback()
            }
            return
        }

        // If no audio was received, resume mic immediately
        if !hasAudio && pendingBufferCount == 0 {
            resumeAfterPlayback()
        }
        // Otherwise, resumeAfterPlayback will be called when last audio buffer finishes

        // Convert PCM to WAV format for response metadata (not for playback - already streamed)
        let audioData = hasAudio ? createWAVFromPCM(combinedAudio, sampleRate: 24000, channels: 1) : Data()
        print("[RealtimeEngine] Created WAV: \(audioData.count) bytes")
        let audioBase64 = audioData.base64EncodedString()

        let tutorResponse = TutorResponseJSON(
            tutorSpanish: tutorSpanishText,
            tutorEnglish: tutorEnglishText,
            correctionSpanish: nil,
            correctionEnglish: nil,
            hint: nil,
            vocabularySpotlight: nil,
            scenarioProgress: .middle,
            suggestedResponses: suggestedResponses
        )

        let response = TurnResponse(
            userTranscript: currentTranscript,
            tutorResponse: tutorResponse,
            audioBase64: audioBase64,
            audioMimeType: "audio/wav"
        )

        // Notify via completion handler (for generateTurn compatibility)
        if isWaitingForResponse {
            isWaitingForResponse = false
            responseCompletion?(.success(response))
        }

        // Notify delegate for streaming mode
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.realtimeEngineDidFinishResponse(self, response: response)
        }

        // Reset for next turn
        currentTranscript = ""
        tutorSpanishText = ""
        tutorEnglishText = ""
        suggestedResponses = nil
        audioChunks = []
    }

    // MARK: - Streaming Audio Playback

    /// Setup playback engine for streaming TTS audio
    private func setupPlaybackEngine() {
        guard playbackEngine == nil else { return }

        playbackEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        guard let engine = playbackEngine, let player = playerNode else { return }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: playbackFormat)

        do {
            try engine.start()
            player.play()
            print("[RealtimeEngine] Playback engine started")
        } catch {
            print("[RealtimeEngine] Failed to start playback engine: \(error)")
        }
    }

    /// Play an audio chunk immediately (streaming playback)
    private func playAudioChunk(_ data: Data) {
        setupPlaybackEngine()

        guard let player = playerNode, let engine = playbackEngine, engine.isRunning else {
            print("[RealtimeEngine] Playback engine not ready")
            return
        }

        // Convert Data to AVAudioPCMBuffer
        let frameCount = UInt32(data.count / 2)  // 2 bytes per Int16 sample
        guard let buffer = AVAudioPCMBuffer(pcmFormat: playbackFormat, frameCapacity: frameCount) else {
            print("[RealtimeEngine] Failed to create audio buffer")
            return
        }
        buffer.frameLength = frameCount

        // Copy data into buffer
        data.withUnsafeBytes { rawBuffer in
            if let src = rawBuffer.baseAddress {
                memcpy(buffer.int16ChannelData![0], src, data.count)
            }
        }

        // Track pending buffers
        pendingBufferCount += 1

        // Schedule buffer for immediate playback with completion handler
        player.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                self?.pendingBufferCount -= 1
                // When last buffer finishes, resume mic input
                if self?.pendingBufferCount == 0 {
                    self?.resumeAfterPlayback()
                }
            }
        }
    }

    /// Stop playback engine
    private func stopPlaybackEngine() {
        playerNode?.stop()
        playbackEngine?.stop()
        playbackEngine = nil
        playerNode = nil
    }

    // MARK: - Audio Conversion

    /// Creates a WAV file from raw PCM 16-bit signed integer data
    private func createWAVFromPCM(_ pcmData: Data, sampleRate: Int, channels: Int) -> Data {
        var header = Data()

        // RIFF header
        header.append(contentsOf: "RIFF".utf8)
        let fileSize = UInt32(36 + pcmData.count)
        header.append(contentsOf: withUnsafeBytes(of: fileSize.littleEndian) { Array($0) })
        header.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        header.append(contentsOf: "fmt ".utf8)
        let fmtSize = UInt32(16)
        header.append(contentsOf: withUnsafeBytes(of: fmtSize.littleEndian) { Array($0) })
        let audioFormat = UInt16(1) // PCM (not IEEE float)
        header.append(contentsOf: withUnsafeBytes(of: audioFormat.littleEndian) { Array($0) })
        let channelCount = UInt16(channels)
        header.append(contentsOf: withUnsafeBytes(of: channelCount.littleEndian) { Array($0) })
        let sampleRateValue = UInt32(sampleRate)
        header.append(contentsOf: withUnsafeBytes(of: sampleRateValue.littleEndian) { Array($0) })
        let byteRate = UInt32(sampleRate * channels * 2) // 2 bytes per sample (int16)
        header.append(contentsOf: withUnsafeBytes(of: byteRate.littleEndian) { Array($0) })
        let blockAlign = UInt16(channels * 2)
        header.append(contentsOf: withUnsafeBytes(of: blockAlign.littleEndian) { Array($0) })
        let bitsPerSample = UInt16(16)
        header.append(contentsOf: withUnsafeBytes(of: bitsPerSample.littleEndian) { Array($0) })

        // data chunk
        header.append(contentsOf: "data".utf8)
        let dataSize = UInt32(pcmData.count)
        header.append(contentsOf: withUnsafeBytes(of: dataSize.littleEndian) { Array($0) })

        // Combine header and PCM data
        var wavData = header
        wavData.append(pcmData)

        return wavData
    }
}

// MARK: - URLSessionWebSocketDelegate

extension RealtimeEngine: URLSessionWebSocketDelegate {
    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        print("[RealtimeEngine] WebSocket connected - sending setup immediately")
        // Send setup message immediately when connection opens (no delay!)
        sendSetup { [weak self] result in
            switch result {
            case .success:
                print("[RealtimeEngine] Setup sent, waiting for 'ready' from server")
                // Don't resume continuation here - wait for 'ready' message
            case .failure(let error):
                print("[RealtimeEngine] Setup failed: \(error)")
                if let cont = self?.connectionContinuation {
                    self?.connectionContinuation = nil
                    cont.resume(throwing: error)
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        print("[RealtimeEngine] WebSocket closed: \(closeCode)")
        isConnected = false
        // If we were waiting for connection, fail it
        if let cont = connectionContinuation {
            connectionContinuation = nil
            cont.resume(throwing: ConversationEngineError.networkError(URLError(.networkConnectionLost)))
        }
    }
}
