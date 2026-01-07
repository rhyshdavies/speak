import Foundation

/// Centralized premium feature access checks
/// Use these methods to determine what features are available for each tier
enum FeatureAccess {

    // MARK: - Practice Limits

    /// Free tier: 1 practice per day
    static func dailyPracticeLimit(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free: return 1
        case .premium: return nil
        }
    }

    // MARK: - Feedback Access

    /// Can view detailed corrections (free tier sees blurred preview)
    static func canViewDeepFeedback(tier: SubscriptionTier) -> Bool {
        tier == .premium
    }

    /// Can replay practice recordings
    static func canReplayPractice(tier: SubscriptionTier) -> Bool {
        tier == .premium
    }

    // MARK: - Level Access

    /// B2+ requires premium subscription
    static func canAccessLevel(_ level: CEFRLevel, tier: SubscriptionTier) -> Bool {
        switch tier {
        case .premium:
            return true
        case .free:
            return !level.requiresPremium
        }
    }

    // MARK: - Review Limits

    /// Free tier: 10 items in review. Premium: unlimited.
    static func reviewItemLimit(for tier: SubscriptionTier) -> Int? {
        switch tier {
        case .free: return 10
        case .premium: return nil
        }
    }

    /// Can access full session history
    static func canAccessFullHistory(tier: SubscriptionTier) -> Bool {
        tier == .premium
    }
}
