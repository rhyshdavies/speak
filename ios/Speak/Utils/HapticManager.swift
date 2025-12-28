import UIKit

/// Manages haptic feedback throughout the app
enum HapticManager {
    /// Light impact feedback
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Selection feedback (light tap)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    /// Notification feedback
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    // MARK: - Convenience Methods

    /// Light tap for selections
    static func lightTap() {
        impact(.light)
    }

    /// Medium tap for button presses
    static func mediumTap() {
        impact(.medium)
    }

    /// Heavy tap for important actions
    static func heavyTap() {
        impact(.heavy)
    }

    /// Success feedback
    static func success() {
        notification(.success)
    }

    /// Error feedback
    static func error() {
        notification(.error)
    }

    /// Warning feedback
    static func warning() {
        notification(.warning)
    }
}
