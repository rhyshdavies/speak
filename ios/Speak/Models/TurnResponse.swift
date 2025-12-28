import Foundation

/// Response from the backend for a single conversation turn
struct TurnResponse: Codable {
    let userTranscript: String
    let tutorResponse: TutorResponseJSON
    let audioBase64: String
    let audioMimeType: String

    /// Decode audio from base64
    var audioData: Data? {
        Data(base64Encoded: audioBase64)
    }
}

/// Structured JSON response from GPT-4o-mini
struct TutorResponseJSON: Codable {
    let tutorSpanish: String
    let tutorEnglish: String
    let correctionSpanish: String?
    let correctionEnglish: String?
    let hint: String?
    let vocabularySpotlight: VocabularySpotlight?
    let scenarioProgress: ScenarioProgress
    let suggestedResponses: [String]?
}

/// Vocabulary word highlight
struct VocabularySpotlight: Codable {
    let word: String
    let translation: String
    let usage: String
}

/// Progress through the scenario
enum ScenarioProgress: String, Codable {
    case beginning
    case middle
    case ending
    case complete

    var isComplete: Bool {
        self == .complete
    }

    var progressPercentage: Double {
        switch self {
        case .beginning: return 0.25
        case .middle: return 0.5
        case .ending: return 0.75
        case .complete: return 1.0
        }
    }
}

/// Request body sent to the backend
struct ConversationTurnRequest: Codable {
    let messages: [ChatMessage]
    let scenario: ScenarioContext
    let cefrLevel: CEFRLevel
    let playbackSpeed: Double?

    init(messages: [ChatMessage], scenario: ScenarioContext, cefrLevel: CEFRLevel, playbackSpeed: Double? = nil) {
        self.messages = messages
        self.scenario = scenario
        self.cefrLevel = cefrLevel
        self.playbackSpeed = playbackSpeed
    }
}

/// API error response
struct APIErrorResponse: Codable {
    let error: String
    let details: String?
}
