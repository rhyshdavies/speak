import Foundation

/// Basic implementation of ConversationEngine that calls the backend API proxy
/// The backend handles all OpenAI API calls (Whisper, GPT-4o-mini, TTS-1)
final class OpenAIBasicEngine: ConversationEngine {
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func generateTurn(
        audioFileURL: URL,
        messages: [ChatMessage],
        context: ScenarioContext,
        cefrLevel: CEFRLevel
    ) async throws -> TurnResponse {
        // Load audio data from file
        let audioData: Data
        do {
            audioData = try Data(contentsOf: audioFileURL)
        } catch {
            throw ConversationEngineError.audioProcessingError
        }

        // Validate audio data
        guard !audioData.isEmpty else {
            throw ConversationEngineError.noAudioData
        }

        // Build request
        let requestData = ConversationTurnRequest(
            messages: messages,
            scenario: context,
            cefrLevel: cefrLevel
        )

        // Send to backend
        do {
            return try await apiClient.postConversationTurn(
                audioData: audioData,
                requestData: requestData
            )
        } catch let error as ConversationEngineError {
            throw error
        } catch {
            throw ConversationEngineError.networkError(error)
        }
    }
}
