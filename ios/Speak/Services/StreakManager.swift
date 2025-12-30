import Foundation

/// Manages user practice streaks and session history
/// Uses local timezone for all date comparisons to handle travel correctly
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    // MARK: - Published State

    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var practicedToday: Bool = false
    @Published private(set) var totalSessions: Int = 0
    @Published private(set) var totalSeconds: Int = 0

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let lastPracticeDayStart = "streak_lastPracticeDayStart"  // Stores start-of-day Date
        static let currentStreak = "streak_currentStreak"
        static let totalSessions = "streak_totalSessions"
        static let totalSeconds = "streak_totalSeconds"
    }

    private let calendar = Calendar.current

    // MARK: - Initialization

    private init() {
        loadFromDefaults()
        checkStreakValidity()
    }

    // MARK: - Public Methods

    /// Call this ONCE when a practice session ends (not per turn)
    /// - Parameter durationSeconds: Duration of the session in seconds
    func recordSession(durationSeconds: Int) {
        let now = Date()
        let todayStart = calendar.startOfDay(for: now)
        let lastPracticeDayStart = UserDefaults.standard.object(forKey: Keys.lastPracticeDayStart) as? Date

        if let lastDayStart = lastPracticeDayStart {
            if lastDayStart == todayStart {
                // Already practiced today - just add time, don't increment session count
                totalSeconds += durationSeconds
            } else if isConsecutiveDay(lastDayStart: lastDayStart, todayStart: todayStart) {
                // Consecutive day - extend streak
                currentStreak += 1
                totalSeconds += durationSeconds
                totalSessions += 1
            } else {
                // Streak broken - reset to 1
                currentStreak = 1
                totalSeconds += durationSeconds
                totalSessions += 1
            }
        } else {
            // First ever session
            currentStreak = 1
            totalSeconds = durationSeconds
            totalSessions = 1
        }

        practicedToday = true
        UserDefaults.standard.set(todayStart, forKey: Keys.lastPracticeDayStart)
        saveToDefaults()
    }

    /// Check if streak is still valid (call on app launch)
    func checkStreakValidity() {
        guard let lastDayStart = UserDefaults.standard.object(forKey: Keys.lastPracticeDayStart) as? Date else {
            currentStreak = 0
            practicedToday = false
            return
        }

        let todayStart = calendar.startOfDay(for: Date())

        if lastDayStart == todayStart {
            // Practiced today
            practicedToday = true
        } else if isConsecutiveDay(lastDayStart: lastDayStart, todayStart: todayStart) {
            // Practiced yesterday - streak still valid but needs practice today
            practicedToday = false
        } else {
            // More than a day gap - streak broken
            currentStreak = 0
            practicedToday = false
            saveToDefaults()
        }
    }

    // MARK: - Private Methods

    /// Check if todayStart is the day immediately after lastDayStart
    /// Handles midnight edge case: 11:59 PM → 12:01 AM should be consecutive
    private func isConsecutiveDay(lastDayStart: Date, todayStart: Date) -> Bool {
        // Get the next day after lastDayStart
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDayStart) else {
            return false
        }
        let nextDayStart = calendar.startOfDay(for: nextDay)
        return nextDayStart == todayStart
    }

    private func loadFromDefaults() {
        currentStreak = UserDefaults.standard.integer(forKey: Keys.currentStreak)
        totalSessions = UserDefaults.standard.integer(forKey: Keys.totalSessions)
        totalSeconds = UserDefaults.standard.integer(forKey: Keys.totalSeconds)
    }

    private func saveToDefaults() {
        UserDefaults.standard.set(currentStreak, forKey: Keys.currentStreak)
        UserDefaults.standard.set(totalSessions, forKey: Keys.totalSessions)
        UserDefaults.standard.set(totalSeconds, forKey: Keys.totalSeconds)
    }

    // MARK: - Computed Properties

    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your streak today!"
        } else if practicedToday {
            return "You're on fire! Keep it up."
        } else {
            return "Practice today to keep your streak!"
        }
    }

    var formattedTotalTime: String {
        let totalMinutes = totalSeconds / 60
        if totalMinutes < 60 {
            return "\(max(1, totalMinutes)) min"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
    }
}
