import Foundation

/// Types of scenarios available for practice
enum ScenarioType: String, Codable, CaseIterable, Identifiable {
    // Beginner scenarios (A1-A2)
    case greetings
    case numbers
    case directions
    case taxi
    case cafe
    case freeConversationA1

    // Elementary scenarios (A2-B1)
    case restaurant
    case hotel
    case shopping
    case pharmacy
    case airport
    case freeConversationA2

    // Intermediate scenarios (B1-B2)
    case doctor
    case apartment
    case museum
    case phoneCall
    case complaints
    case freeConversationB1

    // Advanced scenarios (B2-C1)
    case bank
    case jobInterview
    case carRental
    case legalHelp
    case networking
    case freeConversationB2

    // Mastery scenarios (C1-C2)
    case debate
    case negotiation
    case mediaInterview
    case academicPresentation
    case crisisManagement
    case freeConversationC1
    case freeConversationC2

    var id: String { rawValue }

    var icon: String {
        switch self {
        // Beginner
        case .greetings: return "hand.wave"
        case .numbers: return "number"
        case .directions: return "map"
        case .taxi: return "car"
        case .cafe: return "cup.and.saucer"
        case .freeConversationA1: return "bubble.left.and.bubble.right"
        // Elementary
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double"
        case .shopping: return "bag"
        case .pharmacy: return "cross.case"
        case .airport: return "airplane"
        case .freeConversationA2: return "bubble.left.and.bubble.right"
        // Intermediate
        case .doctor: return "stethoscope"
        case .apartment: return "house"
        case .museum: return "building.columns"
        case .phoneCall: return "phone"
        case .complaints: return "exclamationmark.bubble"
        case .freeConversationB1: return "bubble.left.and.bubble.right"
        // Advanced
        case .bank: return "banknote"
        case .jobInterview: return "briefcase"
        case .carRental: return "car.2"
        case .legalHelp: return "scale.3d"
        case .networking: return "person.3"
        case .freeConversationB2: return "bubble.left.and.bubble.right"
        // Mastery
        case .debate: return "bubble.left.and.bubble.right"
        case .negotiation: return "arrow.left.arrow.right"
        case .mediaInterview: return "mic"
        case .academicPresentation: return "graduationcap"
        case .crisisManagement: return "exclamationmark.triangle"
        case .freeConversationC1: return "bubble.left.and.bubble.right"
        case .freeConversationC2: return "bubble.left.and.bubble.right"
        }
    }

    var title: String {
        switch self {
        // Beginner
        case .greetings: return "First Introductions"
        case .numbers: return "Numbers & Time"
        case .directions: return "Asking Directions"
        case .taxi: return "Taking a Taxi"
        case .cafe: return "At the Café"
        case .freeConversationA1: return "Free Chat (A1)"
        // Elementary
        case .restaurant: return "Restaurant Order"
        case .hotel: return "Hotel Check-in"
        case .shopping: return "At the Market"
        case .pharmacy: return "At the Pharmacy"
        case .airport: return "At the Airport"
        case .freeConversationA2: return "Free Chat (A2)"
        // Intermediate
        case .doctor: return "Doctor's Visit"
        case .apartment: return "Renting an Apartment"
        case .museum: return "Museum Visit"
        case .phoneCall: return "Phone Conversation"
        case .complaints: return "Making a Complaint"
        case .freeConversationB1: return "Free Chat (B1)"
        // Advanced
        case .bank: return "At the Bank"
        case .jobInterview: return "Job Interview"
        case .carRental: return "Car Rental"
        case .legalHelp: return "Legal Consultation"
        case .networking: return "Professional Networking"
        case .freeConversationB2: return "Free Chat (B2)"
        // Mastery
        case .debate: return "Debate & Discussion"
        case .negotiation: return "Business Negotiation"
        case .mediaInterview: return "Media Interview"
        case .academicPresentation: return "Academic Presentation"
        case .crisisManagement: return "Crisis Management"
        case .freeConversationC1: return "Free Chat (C1)"
        case .freeConversationC2: return "Free Chat (C2)"
        }
    }

    var color: String {
        switch self {
        // Beginner - greens
        case .greetings: return "green"
        case .numbers: return "mint"
        case .directions: return "teal"
        case .taxi: return "green"
        case .cafe: return "mint"
        case .freeConversationA1: return "green"
        // Elementary - blues
        case .restaurant: return "orange"
        case .hotel: return "purple"
        case .shopping: return "pink"
        case .pharmacy: return "blue"
        case .airport: return "blue"
        case .freeConversationA2: return "teal"
        // Intermediate - oranges
        case .doctor: return "red"
        case .apartment: return "orange"
        case .museum: return "brown"
        case .phoneCall: return "indigo"
        case .complaints: return "orange"
        case .freeConversationB1: return "yellow"
        // Advanced - purples
        case .bank: return "indigo"
        case .jobInterview: return "purple"
        case .carRental: return "cyan"
        case .legalHelp: return "gray"
        case .networking: return "purple"
        case .freeConversationB2: return "purple"
        // Mastery - reds
        case .debate: return "red"
        case .negotiation: return "brown"
        case .mediaInterview: return "pink"
        case .academicPresentation: return "indigo"
        case .crisisManagement: return "red"
        case .freeConversationC1: return "orange"
        case .freeConversationC2: return "red"
        }
    }

    var minimumLevel: CEFRLevel {
        switch self {
        // Beginner (A1)
        case .greetings, .numbers, .directions, .taxi, .cafe, .freeConversationA1:
            return .a1
        // Elementary (A2)
        case .restaurant, .hotel, .shopping, .pharmacy, .airport, .freeConversationA2:
            return .a2
        // Intermediate (B1)
        case .doctor, .apartment, .museum, .phoneCall, .complaints, .freeConversationB1:
            return .b1
        // Advanced (B2)
        case .bank, .jobInterview, .carRental, .legalHelp, .networking, .freeConversationB2:
            return .b2
        // Mastery (C1)
        case .debate, .negotiation, .mediaInterview, .academicPresentation, .crisisManagement, .freeConversationC1:
            return .c1
        // Mastery (C2)
        case .freeConversationC2:
            return .c2
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
    // MARK: - Beginner Scenarios (A1)

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

    static let numbers = ScenarioContext(
        type: .numbers,
        title: "Numbers & Time",
        description: "Practice numbers, prices, and telling time",
        setting: "Various everyday situations",
        userRole: "A tourist needing to understand numbers",
        tutorRole: "Helpful local explaining numbers and time",
        objectives: [
            "Count and understand numbers 1-100",
            "Ask and tell the time",
            "Understand prices",
            "Talk about dates and schedules"
        ]
    )

    static let directions = ScenarioContext(
        type: .directions,
        title: "Asking Directions",
        description: "Learn to ask for and understand directions",
        setting: "A busy street in Seville",
        userRole: "A lost tourist looking for landmarks",
        tutorRole: "Helpful pedestrian giving directions",
        objectives: [
            "Ask where places are located",
            "Understand basic directions (left, right, straight)",
            "Ask about distances",
            "Thank someone for their help"
        ]
    )

    static let taxi = ScenarioContext(
        type: .taxi,
        title: "Taking a Taxi",
        description: "Practice getting around by taxi",
        setting: "Taxi stand in Buenos Aires",
        userRole: "A passenger needing a ride",
        tutorRole: "Taxi driver",
        objectives: [
            "Tell the driver your destination",
            "Ask about the fare",
            "Give simple directions",
            "Pay and say goodbye"
        ]
    )

    static let cafe = ScenarioContext(
        type: .cafe,
        title: "At the Café",
        description: "Order coffee and snacks",
        setting: "A cozy café in Madrid",
        userRole: "A customer wanting a coffee",
        tutorRole: "Friendly barista",
        objectives: [
            "Order a drink",
            "Ask about pastries",
            "Request the check",
            "Make simple small talk"
        ]
    )

    static let freeConversationA1 = ScenarioContext(
        type: .freeConversationA1,
        title: "Free Chat (A1)",
        description: "Open conversation practice with basic vocabulary",
        setting: "Casual chat with a friendly Spanish speaker",
        userRole: "A beginner learner practicing basic conversation",
        tutorRole: "A patient, friendly conversation partner who speaks slowly and simply",
        objectives: [
            "Practice basic greetings and farewells",
            "Talk about yourself, family, and daily routines",
            "Ask and answer simple questions",
            "Use basic vocabulary about colors, numbers, weather"
        ]
    )

    // MARK: - Elementary Scenarios (A2)

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
        title: "At the Market",
        description: "Buy items at a local market",
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

    static let pharmacy = ScenarioContext(
        type: .pharmacy,
        title: "At the Pharmacy",
        description: "Get medicine and health products",
        setting: "Neighborhood pharmacy in Lima",
        userRole: "Someone feeling unwell",
        tutorRole: "Helpful pharmacist",
        objectives: [
            "Describe simple symptoms",
            "Ask for medicine recommendations",
            "Understand dosage instructions",
            "Ask about prices"
        ]
    )

    static let airport = ScenarioContext(
        type: .airport,
        title: "At the Airport",
        description: "Navigate an airport in Spanish",
        setting: "International airport in Madrid",
        userRole: "A traveler going through customs and boarding",
        tutorRole: "Airport staff (customs officer, gate agent)",
        objectives: [
            "Present your passport and boarding pass",
            "Answer customs questions about your trip",
            "Ask about gate locations and boarding time"
        ]
    )

    static let freeConversationA2 = ScenarioContext(
        type: .freeConversationA2,
        title: "Free Chat (A2)",
        description: "Open conversation about everyday topics",
        setting: "Casual chat with a Spanish-speaking friend",
        userRole: "An elementary learner building conversational skills",
        tutorRole: "A friendly conversation partner who encourages you to speak",
        objectives: [
            "Discuss hobbies, likes, and dislikes",
            "Talk about past experiences using simple past tense",
            "Make plans and talk about the future",
            "Express simple opinions and preferences"
        ]
    )

    // MARK: - Intermediate Scenarios (B1)

    static let doctor = ScenarioContext(
        type: .doctor,
        title: "Doctor's Visit",
        description: "Describe symptoms and understand medical advice",
        setting: "Medical clinic in Santiago",
        userRole: "A patient with health concerns",
        tutorRole: "Doctor conducting a consultation",
        objectives: [
            "Describe your symptoms in detail",
            "Answer questions about medical history",
            "Understand diagnosis and treatment",
            "Ask questions about medication"
        ]
    )

    static let apartment = ScenarioContext(
        type: .apartment,
        title: "Renting an Apartment",
        description: "View and negotiate an apartment rental",
        setting: "Apartment viewing in Valencia",
        userRole: "Someone looking for a place to rent",
        tutorRole: "Landlord or real estate agent",
        objectives: [
            "Ask about the apartment features",
            "Discuss rental terms and conditions",
            "Negotiate price or included services",
            "Ask about the neighborhood"
        ]
    )

    static let museum = ScenarioContext(
        type: .museum,
        title: "Museum Visit",
        description: "Discuss art and culture at a museum",
        setting: "Prado Museum in Madrid",
        userRole: "An interested visitor",
        tutorRole: "Museum guide",
        objectives: [
            "Ask about artworks and history",
            "Express opinions about art",
            "Ask for recommendations",
            "Discuss cultural significance"
        ]
    )

    static let phoneCall = ScenarioContext(
        type: .phoneCall,
        title: "Phone Conversation",
        description: "Handle phone calls for appointments and services",
        setting: "Making calls to various businesses",
        userRole: "Someone making phone inquiries",
        tutorRole: "Receptionist or customer service representative",
        objectives: [
            "Make an appointment",
            "Ask for information over the phone",
            "Leave a message",
            "Handle being put on hold"
        ]
    )

    static let complaints = ScenarioContext(
        type: .complaints,
        title: "Making a Complaint",
        description: "Express dissatisfaction and seek resolution",
        setting: "Customer service desk",
        userRole: "A dissatisfied customer",
        tutorRole: "Customer service manager",
        objectives: [
            "Explain the problem clearly",
            "Express dissatisfaction politely",
            "Request a specific solution",
            "Negotiate a resolution"
        ]
    )

    static let freeConversationB1 = ScenarioContext(
        type: .freeConversationB1,
        title: "Free Chat (B1)",
        description: "Discuss a variety of topics with more depth",
        setting: "Coffee with a Spanish-speaking colleague",
        userRole: "An intermediate learner expanding conversational range",
        tutorRole: "An engaging conversation partner who challenges you to express more complex ideas",
        objectives: [
            "Discuss current events and news",
            "Share experiences and tell stories",
            "Express and justify opinions",
            "Use conditional and subjunctive in common expressions"
        ]
    )

    // MARK: - Advanced Scenarios (B2)

    static let bank = ScenarioContext(
        type: .bank,
        title: "At the Bank",
        description: "Handle complex banking transactions",
        setting: "Bank branch in Mexico City",
        userRole: "A customer with financial needs",
        tutorRole: "Bank officer",
        objectives: [
            "Open an account or request services",
            "Discuss loan or credit options",
            "Resolve account issues",
            "Understand financial terminology"
        ]
    )

    static let jobInterview = ScenarioContext(
        type: .jobInterview,
        title: "Job Interview",
        description: "Practice professional interview skills",
        setting: "Corporate office in Madrid",
        userRole: "A job candidate",
        tutorRole: "Hiring manager conducting the interview",
        objectives: [
            "Present your qualifications professionally",
            "Answer behavioral questions",
            "Discuss salary expectations",
            "Ask thoughtful questions about the role"
        ]
    )

    static let carRental = ScenarioContext(
        type: .carRental,
        title: "Car Rental",
        description: "Rent a car and handle related issues",
        setting: "Car rental agency in Costa Rica",
        userRole: "A customer renting a vehicle",
        tutorRole: "Rental agent",
        objectives: [
            "Choose the right vehicle",
            "Understand insurance options",
            "Discuss rental terms",
            "Handle return procedures"
        ]
    )

    static let legalHelp = ScenarioContext(
        type: .legalHelp,
        title: "Legal Consultation",
        description: "Discuss legal matters with a professional",
        setting: "Law office in Buenos Aires",
        userRole: "Someone seeking legal advice",
        tutorRole: "Lawyer providing consultation",
        objectives: [
            "Explain your legal situation",
            "Ask about your rights and options",
            "Understand legal procedures",
            "Discuss costs and next steps"
        ]
    )

    static let networking = ScenarioContext(
        type: .networking,
        title: "Professional Networking",
        description: "Build professional relationships",
        setting: "Business conference in Barcelona",
        userRole: "A professional meeting new contacts",
        tutorRole: "Fellow professional at the event",
        objectives: [
            "Introduce yourself professionally",
            "Discuss your industry and work",
            "Exchange ideas and opinions",
            "Arrange follow-up meetings"
        ]
    )

    static let freeConversationB2 = ScenarioContext(
        type: .freeConversationB2,
        title: "Free Chat (B2)",
        description: "In-depth discussion on complex topics",
        setting: "Dinner party with educated Spanish speakers",
        userRole: "An upper-intermediate learner engaging in sophisticated conversation",
        tutorRole: "An intellectually curious conversation partner who enjoys substantive discussions",
        objectives: [
            "Discuss abstract concepts and hypotheticals",
            "Debate different perspectives respectfully",
            "Use idiomatic expressions naturally",
            "Navigate formal and informal registers"
        ]
    )

    // MARK: - Mastery Scenarios (C1-C2)

    static let debate = ScenarioContext(
        type: .debate,
        title: "Debate & Discussion",
        description: "Engage in complex discussions on current events",
        setting: "University seminar room",
        userRole: "A participant in an intellectual debate",
        tutorRole: "Fellow debater with opposing views",
        objectives: [
            "Present nuanced arguments",
            "Respond to counterarguments",
            "Use rhetorical devices effectively",
            "Conclude with a compelling summary"
        ]
    )

    static let negotiation = ScenarioContext(
        type: .negotiation,
        title: "Business Negotiation",
        description: "Negotiate complex business deals",
        setting: "Boardroom in a multinational company",
        userRole: "A business representative negotiating terms",
        tutorRole: "Opposing party in negotiation",
        objectives: [
            "Present your position persuasively",
            "Identify mutual interests",
            "Handle objections diplomatically",
            "Reach a mutually beneficial agreement"
        ]
    )

    static let mediaInterview = ScenarioContext(
        type: .mediaInterview,
        title: "Media Interview",
        description: "Handle press and media questions",
        setting: "Television studio",
        userRole: "A public figure being interviewed",
        tutorRole: "Journalist asking probing questions",
        objectives: [
            "Stay composed under pressure",
            "Deliver key messages clearly",
            "Handle difficult questions",
            "Speak in quotable soundbites"
        ]
    )

    static let academicPresentation = ScenarioContext(
        type: .academicPresentation,
        title: "Academic Presentation",
        description: "Present and defend academic research",
        setting: "University conference hall",
        userRole: "A researcher presenting findings",
        tutorRole: "Academic audience asking questions",
        objectives: [
            "Present complex ideas clearly",
            "Use academic register appropriately",
            "Respond to challenging questions",
            "Acknowledge limitations and future directions"
        ]
    )

    static let crisisManagement = ScenarioContext(
        type: .crisisManagement,
        title: "Crisis Management",
        description: "Handle urgent situations with authority",
        setting: "Emergency response center",
        userRole: "A leader managing a crisis",
        tutorRole: "Team member and stakeholders",
        objectives: [
            "Communicate urgently but calmly",
            "Give clear instructions",
            "Coordinate multiple parties",
            "Make decisions under pressure"
        ]
    )

    static let freeConversationC1 = ScenarioContext(
        type: .freeConversationC1,
        title: "Free Chat (C1)",
        description: "Fluent conversation on any topic",
        setting: "Intellectual salon with native Spanish speakers",
        userRole: "An advanced speaker participating as an equal",
        tutorRole: "A cultured native speaker who expects fluent, nuanced conversation",
        objectives: [
            "Discuss literature, philosophy, or current affairs in depth",
            "Use sophisticated vocabulary and complex grammatical structures",
            "Understand and use cultural references and humor",
            "Express subtle shades of meaning and implication"
        ]
    )

    static let freeConversationC2 = ScenarioContext(
        type: .freeConversationC2,
        title: "Free Chat (C2)",
        description: "Native-level conversation without limits",
        setting: "Any context - you're indistinguishable from a native speaker",
        userRole: "A near-native speaker with full command of the language",
        tutorRole: "A native speaker who treats you as a fellow native, using all registers and styles",
        objectives: [
            "Engage with wordplay, irony, and rhetorical flourishes",
            "Discuss specialized topics with technical precision",
            "Navigate regional dialects and sociolects",
            "Express yourself with complete stylistic flexibility"
        ]
    )

    /// All available scenarios grouped by level
    static let allScenarios: [ScenarioContext] = [
        // Beginner (A1)
        .greetings, .numbers, .directions, .taxi, .cafe, .freeConversationA1,
        // Elementary (A2)
        .restaurant, .hotel, .shopping, .pharmacy, .airport, .freeConversationA2,
        // Intermediate (B1)
        .doctor, .apartment, .museum, .phoneCall, .complaints, .freeConversationB1,
        // Advanced (B2)
        .bank, .jobInterview, .carRental, .legalHelp, .networking, .freeConversationB2,
        // Mastery (C1-C2)
        .debate, .negotiation, .mediaInterview, .academicPresentation, .crisisManagement,
        .freeConversationC1, .freeConversationC2
    ]

    /// Get scenarios appropriate for a given CEFR level
    static func scenarios(for level: CEFRLevel) -> [ScenarioContext] {
        allScenarios.filter { scenario in
            scenario.type.minimumLevel <= level
        }
    }
}

// MARK: - CEFRLevel Comparable

extension CEFRLevel: Comparable {
    private var sortOrder: Int {
        switch self {
        case .a1: return 0
        case .a2: return 1
        case .b1: return 2
        case .b2: return 3
        case .c1: return 4
        case .c2: return 5
        }
    }

    static func < (lhs: CEFRLevel, rhs: CEFRLevel) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
