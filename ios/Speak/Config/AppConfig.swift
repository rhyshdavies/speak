import Foundation

/// Conversation mode - Beginner (REST) vs Advanced (WebSocket)
enum ConversationMode: String, CaseIterable, Identifiable {
    case beginner = "beginner"
    case advanced = "advanced"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .beginner: return "Beginner Mode"
        case .advanced: return "Advanced Mode"
        }
    }

    var description: String {
        switch self {
        case .beginner: return "Turn-based • ~2.6s response time"
        case .advanced: return "Real-time • Sub-500ms streaming"
        }
    }

    var icon: String {
        switch self {
        case .beginner: return "tortoise.fill"
        case .advanced: return "bolt.fill"
        }
    }
}

/// App-wide configuration
enum AppConfig {
    // MARK: - Backend URLs

    #if DEBUG
    /// Local development server (use Mac's IP for physical device testing)
    static let backendBaseURL = "http://192.168.1.147:3000"
    static let webSocketURL = "ws://192.168.1.147:8080"
    #else
    /// Production deployment
    static let backendBaseURL = "https://speak-api.vercel.app"
    static let webSocketURL = "wss://speak-api.vercel.app/ws"
    #endif

    // MARK: - Feature Flags

    /// Show transcript of user's speech
    static let showTranscript = true

    /// Show suggested responses
    static let enableSuggestions = true

    /// Show vocabulary spotlight
    static let showVocabularySpotlight = true

    /// Show corrections inline
    static let showCorrections = true

    // MARK: - Default Settings

    /// Default CEFR level for new users
    static let defaultCEFRLevel: CEFRLevel = .a1

    /// Default playback speed
    static let defaultPlaybackSpeed: Float = 1.0

    /// Available playback speeds
    static let playbackSpeeds: [Float] = [0.5, 0.75, 1.0, 1.25]

    // MARK: - Audio Settings

    /// Audio format for recording
    static let audioFormat = "m4a"

    /// Sample rate for recording
    static let sampleRate: Double = 44100

    // MARK: - Timeouts

    /// API request timeout in seconds
    static let apiTimeout: TimeInterval = 60

    /// Maximum recording duration in seconds
    static let maxRecordingDuration: TimeInterval = 60
}
