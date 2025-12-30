import SwiftUI

/// Design system for the Speak app - Matrix / Cyberpunk Theme
enum Theme {
    // MARK: - Colors

    enum Colors {
        // Core palette - The Matrix
        static let background = Color(hex: "0A0A0A")           // Near black
        static let primary = Color(hex: "00FF41")               // Matrix green
        static let textPrimary = Color(hex: "00FF41")           // Matrix green text
        static let surface = Color(hex: "0D1117")               // Dark surface
        static let success = Color(hex: "39FF14")               // Neon green

        // Extended palette
        static let secondary = Color(hex: "00D4AA")             // Cyan accent
        static let accent = Color(hex: "00FF41")                // Matrix green
        static let surfaceSecondary = Color(hex: "161B22")      // Slightly lighter dark

        // Text - Matrix shades
        static let textSecondary = Color(hex: "00FF41").opacity(0.7)
        static let textTertiary = Color(hex: "00FF41").opacity(0.4)
        static let textDim = Color(hex: "00FF41").opacity(0.2)

        // Status
        static let warning = Color(hex: "FFD700")               // Gold warning
        static let error = Color(hex: "FF0040")                 // Neon red

        // Recording - Red alert
        static let recording = Color(hex: "FF0040")
        static let recordingPulse = Color(hex: "FF0040").opacity(0.3)

        // Live indicator
        static let live = Color(hex: "FF0040")

        // Glow colors
        static let glowGreen = Color(hex: "00FF41").opacity(0.5)
        static let glowCyan = Color(hex: "00D4AA").opacity(0.3)
    }

    // MARK: - Typography

    enum Typography {
        // Headings - Monospace for that terminal feel
        static let largeTitle = Font.system(.largeTitle, design: .monospaced).weight(.bold)
        static let title = Font.system(.title, design: .monospaced).weight(.bold)
        static let title2 = Font.system(.title2, design: .monospaced).weight(.bold)
        static let title3 = Font.system(.title3, design: .monospaced).weight(.semibold)

        // Body - Monospace throughout
        static let headline = Font.system(.headline, design: .monospaced).weight(.semibold)
        static let body = Font.system(.body, design: .monospaced)
        static let callout = Font.system(.callout, design: .monospaced)
        static let subheadline = Font.system(.subheadline, design: .monospaced)
        static let footnote = Font.system(.footnote, design: .monospaced)
        static let caption = Font.system(.caption, design: .monospaced)
        static let caption2 = Font.system(.caption2, design: .monospaced)

        // Spanish text (still monospace for consistency)
        static let spanishHeadline = Font.system(.headline, design: .monospaced).weight(.medium)
        static let spanishBody = Font.system(.body, design: .monospaced)
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
        static let xs: CGFloat = 2
        static let sm: CGFloat = 4
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let card: CGFloat = 8       // More angular for cyber look
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows (Glows in Matrix theme)

    enum Shadows {
        static let small = ShadowStyle(color: Color(hex: "00FF41").opacity(0.2), radius: 4, y: 0)
        static let medium = ShadowStyle(color: Color(hex: "00FF41").opacity(0.3), radius: 8, y: 0)
        static let large = ShadowStyle(color: Color(hex: "00FF41").opacity(0.4), radius: 16, y: 0)
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

/// Primary button with Matrix glow
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
                Text(title.uppercased())
            }
            .font(Theme.Typography.headline)
            .foregroundColor(isDisabled ? Theme.Colors.textTertiary : Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(
                isDisabled
                    ? Theme.Colors.textTertiary
                    : Theme.Colors.primary
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                    .stroke(Theme.Colors.primary, lineWidth: isDisabled ? 0 : 1)
            )
            .shadow(color: isDisabled ? .clear : Theme.Colors.glowGreen, radius: 8, y: 0)
        }
        .disabled(isDisabled)
    }
}

/// Card container with Matrix border glow
struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glowGreen.opacity(0.2), radius: 8, y: 0)
    }
}

/// Level badge chip - Matrix style
struct LevelBadge: View {
    let level: CEFRLevel

    var body: some View {
        Text("[\(level.rawValue)]")
            .font(Theme.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(Theme.Colors.primary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Theme.Colors.primary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                    .stroke(Theme.Colors.primary.opacity(0.5), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
    }
}

/// Duration badge - Terminal style
struct DurationBadge: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "clock")
            Text("\(minutes)min")
        }
        .font(Theme.Typography.caption)
        .foregroundColor(Theme.Colors.textSecondary)
    }
}

/// Streak chip - Matrix flame
struct StreakChip: View {
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundColor(Theme.Colors.warning)
            Text("\(count)")
                .fontWeight(.bold)
        }
        .font(Theme.Typography.subheadline)
        .foregroundColor(Theme.Colors.primary)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .overlay(
            Capsule()
                .stroke(Theme.Colors.primary.opacity(0.5), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: Theme.Colors.glowGreen.opacity(0.3), radius: 4, y: 0)
    }
}

/// Live badge - Pulsing red alert
struct LiveBadge: View {
    @State private var isPulsing = false

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Circle()
                .fill(Theme.Colors.live)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
            Text("LIVE")
                .font(Theme.Typography.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(Theme.Colors.live)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.live.opacity(0.15))
        .overlay(
            Capsule()
                .stroke(Theme.Colors.live, lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: Theme.Colors.live.opacity(0.5), radius: 4, y: 0)
        .onAppear { isPulsing = true }
    }
}

// MARK: - Matrix-specific Components

/// Scanline overlay effect
struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 2) {
                ForEach(0..<Int(geometry.size.height / 4), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .frame(height: 1)
                    Spacer()
                        .frame(height: 3)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Terminal cursor blink
struct TerminalCursor: View {
    @State private var isVisible = true

    var body: some View {
        Rectangle()
            .fill(Theme.Colors.primary)
            .frame(width: 8, height: 16)
            .opacity(isVisible ? 1 : 0)
            .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isVisible)
            .onAppear { isVisible.toggle() }
    }
}

/// Matrix rain character (for decorative use)
struct MatrixRainDrop: View {
    let character: String
    let delay: Double

    @State private var opacity: Double = 0

    var body: some View {
        Text(character)
            .font(.system(size: 12, design: .monospaced))
            .foregroundColor(Theme.Colors.primary)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeIn(duration: 0.5).delay(delay)) {
                    opacity = 1
                }
                withAnimation(.easeOut(duration: 1.0).delay(delay + 0.5)) {
                    opacity = 0.3
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
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glowGreen.opacity(0.2), radius: 8, y: 0)
    }

    func applyShadow(_ style: ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, y: style.y)
    }

    func matrixGlow(radius: CGFloat = 8) -> some View {
        self.shadow(color: Theme.Colors.glowGreen, radius: radius, y: 0)
    }

    func terminalBorder() -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.sm)
                .stroke(Theme.Colors.primary.opacity(0.5), lineWidth: 1)
        )
    }
}
