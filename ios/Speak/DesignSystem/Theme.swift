import SwiftUI

/// Design system for the Speak app - Warm Modernity
enum Theme {
    // MARK: - Colors

    enum Colors {
        // Core palette
        static let background = Color(hex: "FDFCF8")      // Warm Sand
        static let primary = Color(hex: "E07A5F")          // Terracotta
        static let textPrimary = Color(hex: "3D405B")      // Slate
        static let surface = Color(hex: "FFFFFF")          // White
        static let success = Color(hex: "81B29A")          // Sage

        // Extended palette
        static let secondary = Color(hex: "F4A261")        // Warm amber
        static let accent = Color(hex: "81B29A")           // Sage (same as success)
        static let surfaceSecondary = Color(hex: "F8F6F0") // Slightly darker warm

        // Text
        static let textSecondary = Color(hex: "3D405B").opacity(0.6)
        static let textTertiary = Color(hex: "3D405B").opacity(0.4)

        // Status
        static let warning = Color(hex: "F4A261")
        static let error = Color(hex: "E07A5F")

        // Recording
        static let recording = Color(hex: "E07A5F")
        static let recordingPulse = Color(hex: "E07A5F").opacity(0.3)

        // Live indicator
        static let live = Color(hex: "E63946")
    }

    // MARK: - Typography

    enum Typography {
        // Headings - Serif design for elegance
        static let largeTitle = Font.system(.largeTitle, design: .serif).weight(.bold)
        static let title = Font.system(.title, design: .serif).weight(.bold)
        static let title2 = Font.system(.title2, design: .serif).weight(.bold)
        static let title3 = Font.system(.title3, design: .serif).weight(.semibold)

        // Body - Rounded design for warmth
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let caption2 = Font.system(.caption2, design: .rounded)

        // Spanish text (serif for tutor messages)
        static let spanishHeadline = Font.system(.headline, design: .serif).weight(.medium)
        static let spanishBody = Font.system(.body, design: .serif)
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
        static let xl: CGFloat = 20
        static let card: CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadows {
        static let small = ShadowStyle(color: Color(hex: "3D405B").opacity(0.08), radius: 4, y: 2)
        static let medium = ShadowStyle(color: Color(hex: "3D405B").opacity(0.1), radius: 8, y: 4)
        static let large = ShadowStyle(color: Color(hex: "3D405B").opacity(0.12), radius: 16, y: 8)
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

// MARK: - Reusable Components

/// Primary button with capsule shape
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(_ title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(Theme.Typography.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(isDisabled ? Theme.Colors.textTertiary : Theme.Colors.primary)
            .clipShape(Capsule())
        }
        .disabled(isDisabled)
    }
}

/// Card container with surface background and shadow
struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .shadow(
                color: Theme.Shadows.medium.color,
                radius: Theme.Shadows.medium.radius,
                y: Theme.Shadows.medium.y
            )
    }
}

/// Level badge chip
struct LevelBadge: View {
    let level: CEFRLevel

    var body: some View {
        Text(level.rawValue)
            .font(Theme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.primary.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// Duration badge
struct DurationBadge: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "clock")
            Text("\(minutes) min")
        }
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    }
}

/// Streak chip with flame icon
struct StreakChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
            Text("\(count)")
                .fontWeight(.semibold)
        }
        .font(Theme.Typography.subheadline)
        .foregroundColor(Theme.Colors.textPrimary)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .shadow(
            color: Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
    }
}

/// Live badge for advanced mode
struct LiveBadge: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(Theme.Colors.live)
                .frame(width: 6, height: 6)
            Text("Live")
                .font(Theme.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(Theme.Colors.live)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.live.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Practice limit badge showing daily allowance
struct PracticeLimitBadge: View {
    let tier: SubscriptionTier
    let usedToday: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: tier == .premium ? "infinity" : "clock")
            Text(badgeText)
        }
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    }

    private var badgeText: String {
        switch tier {
        case .premium:
            return "Unlimited"
        case .free:
            let remaining = max(0, 1 - usedToday)
            return remaining > 0 ? "1 per day" : "Limit reached"
        }
    }
}

/// Lock overlay for premium-gated content
struct LockedOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)

            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.white)

                Text("Premium")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .shadow(
                color: Theme.Shadows.medium.color,
                radius: Theme.Shadows.medium.radius,
                y: Theme.Shadows.medium.y
            )
    }

    func applyShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, y: style.y)
    }
}
