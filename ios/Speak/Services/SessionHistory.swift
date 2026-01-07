import Foundation

/// Stores recent session data for review
final class SessionHistory: ObservableObject {
    static let shared = SessionHistory()

    // MARK: - Published State

    @Published private(set) var recentCorrections: [SavedCorrection] = []
    @Published private(set) var recentTutorMessages: [SavedTutorMessage] = []
    @Published private(set) var savedPhrases: [SavedPhrase] = []

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let corrections = "history_corrections"
        static let tutorMessages = "history_tutorMessages"
        static let savedPhrases = "history_savedPhrases"
    }

    private let maxItems = 20

    // MARK: - Initialization

    private init() {
        loadFromDefaults()
    }

    // MARK: - Public Methods

    /// Add a correction from a session
    func addCorrection(original: String, corrected: String, english: String?, explanation: String?, scenario: String) {
        let correction = SavedCorrection(
            original: original,
            corrected: corrected,
            english: english,
            explanation: explanation,
            scenario: scenario,
            date: Date()
        )
        recentCorrections.insert(correction, at: 0)
        if recentCorrections.count > maxItems {
            recentCorrections = Array(recentCorrections.prefix(maxItems))
        }
        saveToDefaults()
    }

    /// Add a tutor message from a session
    func addTutorMessage(spanish: String, english: String?, scenario: String) {
        let message = SavedTutorMessage(
            spanish: spanish,
            english: english,
            scenario: scenario,
            date: Date()
        )
        recentTutorMessages.insert(message, at: 0)
        if recentTutorMessages.count > maxItems {
            recentTutorMessages = Array(recentTutorMessages.prefix(maxItems))
        }
        saveToDefaults()
    }

    /// Save a phrase for later review
    func savePhrase(spanish: String, english: String) {
        // Don't duplicate
        guard !savedPhrases.contains(where: { $0.spanish == spanish }) else { return }

        let phrase = SavedPhrase(
            spanish: spanish,
            english: english,
            date: Date()
        )
        savedPhrases.insert(phrase, at: 0)
        if savedPhrases.count > maxItems {
            savedPhrases = Array(savedPhrases.prefix(maxItems))
        }
        saveToDefaults()
    }

    /// Remove a saved phrase
    func removePhrase(_ phrase: SavedPhrase) {
        savedPhrases.removeAll { $0.id == phrase.id }
        saveToDefaults()
    }

    /// Clear all history
    func clearAll() {
        recentCorrections = []
        recentTutorMessages = []
        savedPhrases = []
        saveToDefaults()
    }

    /// Get unique recent scenario titles (from tutor messages)
    var recentScenarioTitles: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for message in recentTutorMessages {
            if !seen.contains(message.scenario) {
                seen.insert(message.scenario)
                result.append(message.scenario)
            }
            if result.count >= 5 { break }
        }
        return result
    }

    // MARK: - Private Methods

    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: Keys.corrections),
           let decoded = try? JSONDecoder().decode([SavedCorrection].self, from: data) {
            recentCorrections = decoded
        }

        if let data = UserDefaults.standard.data(forKey: Keys.tutorMessages),
           let decoded = try? JSONDecoder().decode([SavedTutorMessage].self, from: data) {
            recentTutorMessages = decoded
        }

        if let data = UserDefaults.standard.data(forKey: Keys.savedPhrases),
           let decoded = try? JSONDecoder().decode([SavedPhrase].self, from: data) {
            savedPhrases = decoded
        }
    }

    private func saveToDefaults() {
        if let data = try? JSONEncoder().encode(recentCorrections) {
            UserDefaults.standard.set(data, forKey: Keys.corrections)
        }
        if let data = try? JSONEncoder().encode(recentTutorMessages) {
            UserDefaults.standard.set(data, forKey: Keys.tutorMessages)
        }
        if let data = try? JSONEncoder().encode(savedPhrases) {
            UserDefaults.standard.set(data, forKey: Keys.savedPhrases)
        }
    }
}

// MARK: - Data Models

struct SavedCorrection: Identifiable, Codable {
    let id: UUID
    let original: String
    let corrected: String
    let english: String?
    let explanation: String?
    let scenario: String
    let date: Date

    init(original: String, corrected: String, english: String?, explanation: String?, scenario: String, date: Date) {
        self.id = UUID()
        self.original = original
        self.corrected = corrected
        self.english = english
        self.explanation = explanation
        self.scenario = scenario
        self.date = date
    }
}

struct SavedTutorMessage: Identifiable, Codable {
    let id: UUID
    let spanish: String
    let english: String?
    let scenario: String
    let date: Date

    init(spanish: String, english: String?, scenario: String, date: Date) {
        self.id = UUID()
        self.spanish = spanish
        self.english = english
        self.scenario = scenario
        self.date = date
    }
}

struct SavedPhrase: Identifiable, Codable {
    let id: UUID
    let spanish: String
    let english: String
    let date: Date

    init(spanish: String, english: String, date: Date) {
        self.id = UUID()
        self.spanish = spanish
        self.english = english
        self.date = date
    }
}
