import Foundation

/// Supported languages for practice
enum Language: String, CaseIterable, Identifiable, Codable {
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case japanese = "ja"
    case korean = "ko"
    case mandarin = "zh"
    case arabic = "ar"

    var id: String { rawValue }

    /// Display name in English
    var displayName: String {
        switch self {
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .mandarin: return "Mandarin"
        case .arabic: return "Arabic"
        }
    }

    /// Native name
    var nativeName: String {
        switch self {
        case .spanish: return "Español"
        case .french: return "Français"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .mandarin: return "中文"
        case .arabic: return "العربية"
        }
    }

    /// Flag emoji
    var flag: String {
        switch self {
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇧🇷"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .mandarin: return "🇨🇳"
        case .arabic: return "🇸🇦"
        }
    }

    /// Greeting for home screen
    var greeting: (morning: String, afternoon: String, evening: String) {
        switch self {
        case .spanish:
            return ("Buenos días", "Buenas tardes", "Buenas noches")
        case .french:
            return ("Bonjour", "Bon après-midi", "Bonsoir")
        case .german:
            return ("Guten Morgen", "Guten Tag", "Guten Abend")
        case .italian:
            return ("Buongiorno", "Buon pomeriggio", "Buonasera")
        case .portuguese:
            return ("Bom dia", "Boa tarde", "Boa noite")
        case .japanese:
            return ("おはようございます", "こんにちは", "こんばんは")
        case .korean:
            return ("좋은 아침이에요", "안녕하세요", "안녕하세요")
        case .mandarin:
            return ("早上好", "下午好", "晚上好")
        case .arabic:
            return ("صباح الخير", "مساء الخير", "مساء الخير")
        }
    }

    /// Whether this language uses RTL (right-to-left) text direction
    var isRTL: Bool {
        self == .arabic
    }

    /// Short code for display (2 letters uppercase)
    var shortCode: String {
        rawValue.uppercased()
    }
}
