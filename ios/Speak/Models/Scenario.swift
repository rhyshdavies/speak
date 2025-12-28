import Foundation

/// Types of scenarios available for practice
enum ScenarioType: String, Codable, CaseIterable, Identifiable {
    case airport
    case restaurant
    case greetings
    case hotel
    case shopping

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .airport: return "airplane"
        case .restaurant: return "fork.knife"
        case .greetings: return "hand.wave"
        case .hotel: return "bed.double"
        case .shopping: return "bag"
        }
    }

    var title: String {
        switch self {
        case .airport: return "At the Airport"
        case .restaurant: return "Restaurant Order"
        case .greetings: return "Introductions"
        case .hotel: return "Hotel Check-in"
        case .shopping: return "Shopping"
        }
    }

    var color: String {
        switch self {
        case .airport: return "blue"
        case .restaurant: return "orange"
        case .greetings: return "green"
        case .hotel: return "purple"
        case .shopping: return "pink"
        }
    }
}

/// Full scenario context passed to the backend
struct ScenarioContext: Codable, Identifiable, Equatable, Hashable {
    var id: String { type.rawValue }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
    }

    let type: ScenarioType
    let title: String
    let description: String
    let setting: String
    let userRole: String
    let tutorRole: String
    let objectives: [String]
}

// MARK: - Predefined Scenarios

extension ScenarioContext {
    static let airport = ScenarioContext(
        type: .airport,
        title: "At the Airport",
        description: "Practice navigating an airport in Spanish",
        setting: "International airport in Madrid",
        userRole: "A traveler going through customs and boarding",
        tutorRole: "Airport staff (customs officer, gate agent)",
        objectives: [
            "Present your passport and boarding pass",
            "Answer customs questions about your trip",
            "Ask about gate locations and boarding time"
        ]
    )

    static let restaurant = ScenarioContext(
        type: .restaurant,
        title: "Restaurant Order",
        description: "Order food and interact with restaurant staff",
        setting: "Traditional Spanish restaurant",
        userRole: "A customer dining at the restaurant",
        tutorRole: "Friendly waiter/waitress",
        objectives: [
            "Request a table and the menu",
            "Order food and drinks",
            "Handle dietary restrictions",
            "Ask for and pay the bill"
        ]
    )

    static let greetings = ScenarioContext(
        type: .greetings,
        title: "First Introductions",
        description: "Practice meeting someone new",
        setting: "A casual social gathering",
        userRole: "Someone meeting a new friend",
        tutorRole: "A friendly local who wants to chat",
        objectives: [
            "Introduce yourself",
            "Ask and answer basic questions",
            "Talk about where you're from",
            "Exchange contact information"
        ]
    )

    static let hotel = ScenarioContext(
        type: .hotel,
        title: "Hotel Check-in",
        description: "Check into a hotel and handle requests",
        setting: "Hotel lobby in Barcelona",
        userRole: "A guest checking into the hotel",
        tutorRole: "Hotel receptionist",
        objectives: [
            "Check in with your reservation",
            "Ask about room amenities",
            "Request extra services",
            "Ask about local recommendations"
        ]
    )

    static let shopping = ScenarioContext(
        type: .shopping,
        title: "Shopping Trip",
        description: "Buy items at a local store",
        setting: "Local market in Mexico City",
        userRole: "A shopper looking for items",
        tutorRole: "Shop owner/vendor",
        objectives: [
            "Ask about products and prices",
            "Negotiate or ask for discounts",
            "Describe what you're looking for",
            "Complete a purchase"
        ]
    )

    /// All available scenarios
    static let allScenarios: [ScenarioContext] = [
        .greetings,
        .airport,
        .restaurant,
        .hotel,
        .shopping
    ]
}
