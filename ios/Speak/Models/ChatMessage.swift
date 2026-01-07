import Foundation

/// Represents a single message in the conversation
struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    /// Spanish text for display (tutor messages)
    var spanishText: String?
    /// English translation for display
    var englishText: String?
    /// Correction if user made an error
    var correctionSpanish: String?
    var correctionEnglish: String?
    /// Explanation of why the error is wrong (grammar rule)
    var correctionExplanation: String?

    enum MessageRole: String, Codable {
        case user
        case assistant
        case system
    }

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        timestamp: Date = Date(),
        spanishText: String? = nil,
        englishText: String? = nil,
        correctionSpanish: String? = nil,
        correctionEnglish: String? = nil,
        correctionExplanation: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.spanishText = spanishText
        self.englishText = englishText
        self.correctionSpanish = correctionSpanish
        self.correctionEnglish = correctionEnglish
        self.correctionExplanation = correctionExplanation
    }

    /// Create a user message from transcript
    static func userMessage(_ transcript: String) -> ChatMessage {
        ChatMessage(
            role: .user,
            content: transcript,
            spanishText: transcript
        )
    }

    /// Create a tutor message from response
    static func tutorMessage(spanish: String, english: String, correction: String? = nil, correctionEnglish: String? = nil, correctionExplanation: String? = nil) -> ChatMessage {
        ChatMessage(
            role: .assistant,
            content: spanish,
            spanishText: spanish,
            englishText: english,
            correctionSpanish: correction,
            correctionEnglish: correctionEnglish,
            correctionExplanation: correctionExplanation
        )
    }
}
