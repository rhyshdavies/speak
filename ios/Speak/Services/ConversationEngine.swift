import Foundation

/// Protocol defining the conversation engine interface
/// This abstraction allows for different implementations:
/// - V1: OpenAIBasicEngine (REST API via backend proxy)
/// - V2: OpenAIRealtimeEngine (WebRTC/Realtime API - future)
protocol ConversationEngine {
    /// Generate a full conversation turn:
    /// 1. Send audio to backend
    /// 2. Backend transcribes with Whisper
    /// 3. Backend generates response with GPT-4o-mini
    /// 4. Backend synthesizes audio with TTS-1
    /// 5. Return full response
    func generateTurn(
        audioFileURL: URL,
        messages: [ChatMessage],
        context: ScenarioContext,
        cefrLevel: CEFRLevel
    ) async throws -> TurnResponse
}

// MARK: - Errors

enum ConversationEngineError: LocalizedError {
    case networkError(Error)
    case invalidResponse
    case audioProcessingError
    case transcriptionFailed
    case apiError(String)
    case noAudioData
    case encodingError

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .audioProcessingError:
            return "Failed to process audio"
        case .transcriptionFailed:
            return "Could not transcribe audio"
        case .apiError(let message):
            return "API error: \(message)"
        case .noAudioData:
            return "No audio data received"
        case .encodingError:
            return "Failed to encode request"
        }
    }
}
