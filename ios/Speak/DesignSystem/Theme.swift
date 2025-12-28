import SwiftUI

/// Design system for the Speak app
enum Theme {
    // MARK: - Colors

    enum Colors {
        // Backgrounds
        static let background = Color(hex: "0A0A0F")
        static let backgroundGradientTop = Color(hex: "0A0A0F")
        static let backgroundGradientBottom = Color(hex: "1A1020")

        static let surface = Color(hex: "1C1C2E")
        static let surfaceSecondary = Color(hex: "2C2C3E")

        // Brand Colors - Spanish inspired
        static let primary = Color(hex: "FF6B35")      // Warm orange
        static let secondary = Color(hex: "FFD166")    // Golden yellow
        static let accent = Color(hex: "06D6A0")       // Mint green

        // Text
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "AEAEB2")
        static let textTertiary = Color(hex: "636366")

        // Status
        static let success = Color(hex: "30D158")
        static let warning = Color(hex: "FFD60A")
        static let error = Color(hex: "FF453A")

        // Recording
        static let recording = Color(hex: "FF3B30")
        static let recordingPulse = Color(hex: "FF3B30").opacity(0.3)
    }

    // MARK: - Gradients

    enum Gradients {
        static let background = LinearGradient(
            colors: [Colors.backgroundGradientTop, Colors.backgroundGradientBottom],
            startPoint: .top,
            endPoint: .bottom
        )

        static let primaryButton = LinearGradient(
            colors: [Colors.primary, Colors.primary.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )

        static let surface = LinearGradient(
            colors: [Colors.surface, Colors.surfaceSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Typography

    enum Typography {
        static let largeTitle = Font.system(size: 34, weight: .bold)
        static let title = Font.system(size: 28, weight: .bold)
        static let title2 = Font.system(size: 22, weight: .bold)
        static let title3 = Font.system(size: 20, weight: .semibold)
        static let headline = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 17, weight: .regular)
        static let callout = Font.system(size: 16, weight: .regular)
        static let subheadline = Font.system(size: 15, weight: .regular)
        static let footnote = Font.system(size: 13, weight: .regular)
        static let caption = Font.system(size: 12, weight: .regular)
        static let caption2 = Font.system(size: 11, weight: .regular)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = ShadowStyle(color: .black.opacity(0.1), radius: 4, y: 2)
        static let medium = ShadowStyle(color: .black.opacity(0.15), radius: 8, y: 4)
        static let large = ShadowStyle(color: .black.opacity(0.2), radius: 16, y: 8)
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

extension View {
    func primaryButtonStyle() -> some View {
        self
            .font(Theme.Typography.headline)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Gradients.primaryButton)
            .cornerRadius(Theme.CornerRadius.md)
    }

    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.md)
    }
}
