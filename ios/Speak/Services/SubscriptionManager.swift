import Foundation
import Combine

/// Subscription tier for freemium model
enum SubscriptionTier: String, Codable {
    case free
    case premium
}

/// Daily practice state for scenario pinning
struct DailyPracticeState: Codable {
    var date: Date  // Start of day
    var scenarioID: String
}

/// Manages subscription state, practice limits, and daily scenario pinning
/// Use via @EnvironmentObject - inject at root with .environmentObject(SubscriptionManager.shared)
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // MARK: - Published State

    @Published private(set) var tier: SubscriptionTier = .free
    @Published private(set) var practicesToday: Int = 0
    @Published private(set) var dailyPracticeState: DailyPracticeState?
    @Published private(set) var isLoading: Bool = false

    // MARK: - Dependencies

    private let revenueCat = RevenueCatService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let practicesToday = "subscription_practicesToday"
        static let lastPracticeDate = "subscription_lastPracticeDate"
        static let dailyPracticeState = "subscription_dailyPracticeState"
    }

    private let calendar = Calendar.current
    private var lastPracticeDate: Date?

    // MARK: - Initialization

    private init() {
        loadFromDefaults()
        resetDailyCountIfNeeded()
        setupRevenueCatObserver()
    }

    /// Configure RevenueCat - call at app launch
    func configure() {
        revenueCat.configure()
    }

    // MARK: - RevenueCat Integration

    private func setupRevenueCatObserver() {
        // Observe RevenueCat premium status changes
        revenueCat.$isPremium
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPremium in
                self?.tier = isPremium ? .premium : .free
            }
            .store(in: &cancellables)
    }

    /// Refresh subscription status from RevenueCat
    @MainActor
    func refreshSubscriptionStatus() async {
        isLoading = true
        await revenueCat.refreshCustomerInfo()
        isLoading = false
    }

    /// Get available packages for purchase
    var availablePackages: [Any] {
        revenueCat.availablePackages
    }

    /// Purchase the monthly subscription
    @MainActor
    func purchaseMonthly() async throws -> Bool {
        guard let package = revenueCat.monthlyPackage else {
            throw SubscriptionError.packageNotFound
        }
        isLoading = true
        defer { isLoading = false }
        return try await revenueCat.purchase(package)
    }

    /// Purchase the yearly subscription
    @MainActor
    func purchaseYearly() async throws -> Bool {
        guard let package = revenueCat.annualPackage else {
            throw SubscriptionError.packageNotFound
        }
        isLoading = true
        defer { isLoading = false }
        return try await revenueCat.purchase(package)
    }

    /// Restore previous purchases
    @MainActor
    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }
        try await revenueCat.restorePurchases()
    }

    // MARK: - Practice Limits

    /// Free tier: 1 practice per day. Premium: unlimited.
    var practiceLimit: Int? {
        switch tier {
        case .free: return 1
        case .premium: return nil
        }
    }

    /// Check if user can start another practice session
    func canStartPractice() -> Bool {
        resetDailyCountIfNeeded()
        guard let limit = practiceLimit else { return true }
        return practicesToday < limit
    }

    /// Record that a practice session was completed
    func recordPractice() {
        resetDailyCountIfNeeded()
        practicesToday += 1
        lastPracticeDate = Date()
        saveToDefaults()
    }

    /// Reset count at midnight (local timezone)
    private func resetDailyCountIfNeeded() {
        let todayStart = calendar.startOfDay(for: Date())

        if let lastDate = lastPracticeDate {
            let lastDayStart = calendar.startOfDay(for: lastDate)
            if lastDayStart != todayStart {
                practicesToday = 0
            }
        }
    }

    // MARK: - Daily Scenario Pinning

    /// Get the pinned scenario for today, or pin a new one
    /// - Parameter level: User's current CEFR level
    /// - Returns: The scenario for today's practice
    func pinnedScenario(for level: CEFRLevel) -> ScenarioContext {
        let todayStart = calendar.startOfDay(for: Date())

        // Check if we have a pinned scenario for today
        if let state = dailyPracticeState,
           calendar.startOfDay(for: state.date) == todayStart,
           let scenario = ScenarioContext.allScenarios.first(where: { $0.id == state.scenarioID }),
           scenario.type.minimumLevel <= level {
            return scenario
        }

        // New day or level changed - select and pin a new scenario
        let scenario = selectNewScenario(for: level)
        pinScenario(scenario)
        return scenario
    }

    /// Pin a specific scenario for today
    private func pinScenario(_ scenario: ScenarioContext) {
        dailyPracticeState = DailyPracticeState(
            date: calendar.startOfDay(for: Date()),
            scenarioID: scenario.id
        )
        saveToDefaults()
    }

    /// Select a new scenario, avoiding yesterday's if possible
    private func selectNewScenario(for level: CEFRLevel) -> ScenarioContext {
        let scenarios = ScenarioContext.scenarios(for: level)

        guard !scenarios.isEmpty else {
            return .greetings
        }

        // Try to avoid yesterday's scenario
        if let lastState = dailyPracticeState {
            let candidates = scenarios.filter { $0.id != lastState.scenarioID }
            if let selected = candidates.randomElement() {
                return selected
            }
        }

        // Fallback: random from available
        return scenarios.randomElement() ?? .greetings
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        practicesToday = UserDefaults.standard.integer(forKey: Keys.practicesToday)
        lastPracticeDate = UserDefaults.standard.object(forKey: Keys.lastPracticeDate) as? Date

        if let data = UserDefaults.standard.data(forKey: Keys.dailyPracticeState),
           let state = try? JSONDecoder().decode(DailyPracticeState.self, from: data) {
            dailyPracticeState = state
        }
    }

    private func saveToDefaults() {
        UserDefaults.standard.set(practicesToday, forKey: Keys.practicesToday)
        UserDefaults.standard.set(lastPracticeDate, forKey: Keys.lastPracticeDate)

        if let state = dailyPracticeState,
           let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Keys.dailyPracticeState)
        }
    }

    // MARK: - Debug / Mock Toggle

    #if DEBUG
    /// Mock tier toggle for testing (DEBUG only)
    func setTier(_ newTier: SubscriptionTier) {
        tier = newTier
    }

    /// Reset practice count for testing (DEBUG only)
    func resetPracticeCount() {
        practicesToday = 0
        lastPracticeDate = nil
        saveToDefaults()
    }
    #endif
}

// MARK: - Errors

enum SubscriptionError: LocalizedError {
    case packageNotFound
    case purchaseFailed(String)

    var errorDescription: String? {
        switch self {
        case .packageNotFound:
            return "Subscription package not available. Please try again later."
        case .purchaseFailed(let message):
            return message
        }
    }
}
