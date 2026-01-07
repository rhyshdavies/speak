import Foundation

/// CEFR (Common European Framework of Reference) proficiency levels
enum CEFRLevel: String, Codable, CaseIterable, Identifiable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .a1: return "Beginner (A1)"
        case .a2: return "Elementary (A2)"
        case .b1: return "Intermediate (B1)"
        case .b2: return "Upper Intermediate (B2)"
        case .c1: return "Advanced (C1)"
        case .c2: return "Mastery (C2)"
        }
    }

    var description: String {
        switch self {
        case .a1: return "Basic phrases and simple sentences"
        case .a2: return "Routine tasks and direct exchanges"
        case .b1: return "Main points on familiar matters"
        case .b2: return "Complex texts and spontaneous interaction"
        case .c1: return "Fluent expression for social and professional use"
        case .c2: return "Near-native precision and nuance"
        }
    }

    var icon: String {
        switch self {
        case .a1: return "1.circle.fill"
        case .a2: return "2.circle.fill"
        case .b1: return "3.circle.fill"
        case .b2: return "4.circle.fill"
        case .c1: return "5.circle.fill"
        case .c2: return "6.circle.fill"
        }
    }

    /// B2+ levels require premium subscription
    var requiresPremium: Bool {
        switch self {
        case .a1, .a2, .b1:
            return false
        case .b2, .c1, .c2:
            return true
        }
    }
}
