import SwiftUI

/// Home screen with Matrix cyberpunk styling
struct HomeView: View {
    @Binding var selectedLevel: CEFRLevel
    @Binding var selectedMode: ConversationMode
    @Binding var showingScenarios: Bool

    @ObservedObject private var streakManager = StreakManager.shared
    @State private var userName: String = "AGENT"
    @State private var recentScenarios: [ScenarioContext] = [.greetings, .restaurant, .cafe]

    // Sheet states
    @State private var showingProgress: Bool = false
    @State private var showingReview: Bool = false
    @State private var showingPronunciation: Bool = false

    // Animation states
    @State private var terminalReady = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "// BUENOS_DÍAS"
        case 12..<18: return "// BUENAS_TARDES"
        default: return "// BUENAS_NOCHES"
        }
    }

    private var systemTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection

                    // Hero Card
                    heroCard

                    // Quick Actions
                    quickActionsSection

                    // Level & Mode Selection
                    settingsSection

                    // Jump Back In
                    if !recentScenarios.isEmpty {
                        recentScenariosSection
                    }

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            streakManager.checkStreakValidity()
        }
        .sheet(isPresented: $showingProgress) {
            ProgressSheetView()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showingReview) {
            ReviewView()
        }
        .sheet(isPresented: $showingPronunciation) {
            PronunciationWarmupView(level: selectedLevel)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Terminal header line
            HStack {
                Text("SPEAK://SYSTEM")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.Colors.textTertiary)

                Spacer()

                Text("[\(systemTime)]")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            // Main greeting
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(greeting)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)

                    HStack(spacing: Theme.Spacing.xs) {
                        Text(">")
                            .foregroundColor(Theme.Colors.primary)
                        Text(userName)
                            .foregroundColor(Theme.Colors.primary)
                        TerminalCursor()
                    }
                    .font(Theme.Typography.title)
                }

                Spacer()

                // Streak chip - tappable
                Button {
                    HapticManager.selection()
                    showingProgress = true
                } label: {
                    StreakChipView(
                        count: streakManager.currentStreak,
                        isActive: streakManager.practicedToday
                    )
                }
            }
        }
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Top row - terminal style
                HStack {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("$")
                            .foregroundColor(Theme.Colors.primary)
                        Text("MISSION_BRIEF")
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                    .font(.system(size: 11, weight: .bold, design: .monospaced))

                    Spacer()

                    if selectedMode == .advanced {
                        LiveBadge()
                    }
                }

                // Scenario info - terminal output style
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(">>")
                            .foregroundColor(Theme.Colors.secondary)
                        Text(suggestedScenario.title.uppercased())
                    }
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primary)

                    Text(suggestedScenario.description)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                // Badges - data readout style
                HStack(spacing: Theme.Spacing.md) {
                    LevelBadge(level: selectedLevel)
                    DurationBadge(minutes: 5)

                    Spacer()

                    // Scenario icon with glow
                    Image(systemName: suggestedScenario.type.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary)
                        .shadow(color: Theme.Colors.glowGreen, radius: 4, y: 0)
                }

                // CTA Button - EXECUTE command
                PrimaryButton("EXECUTE", icon: "play.fill") {
                    HapticManager.mediumTap()
                    showingScenarios = true
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var suggestedScenario: ScenarioContext {
        // Get appropriate scenarios for level and return the first one (more predictable)
        let appropriate = ScenarioContext.scenarios(for: selectedLevel)
        return appropriate.first ?? .greetings
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("//")
                    .foregroundColor(Theme.Colors.textTertiary)
                Text("QUICK_ACCESS")
            }
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.textSecondary)

            HStack(spacing: Theme.Spacing.md) {
                QuickActionButton(
                    icon: "bubble.left.and.bubble.right",
                    title: "CHAT",
                    color: Theme.Colors.success
                ) {
                    HapticManager.mediumTap()
                    showingScenarios = true
                }

                QuickActionButton(
                    icon: "book.closed",
                    title: "REVIEW",
                    color: Theme.Colors.secondary
                ) {
                    HapticManager.selection()
                    showingReview = true
                }

                QuickActionButton(
                    icon: "waveform",
                    title: "AUDIO",
                    color: Theme.Colors.primary
                ) {
                    HapticManager.selection()
                    showingPronunciation = true
                }
            }
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: Theme.Spacing.xs) {
                Text("//")
                    .foregroundColor(Theme.Colors.textTertiary)
                Text("SYSTEM_CONFIG")
            }
            .font(Theme.Typography.headline)
            .foregroundColor(Theme.Colors.textSecondary)

            Card {
                VStack(spacing: Theme.Spacing.md) {
                    // Level picker
                    SettingsRow(
                        icon: "chart.bar.fill",
                        title: "Level",
                        value: selectedLevel.displayName
                    ) {
                        Menu {
                            ForEach(CEFRLevel.allCases) { level in
                                Button {
                                    HapticManager.selection()
                                    selectedLevel = level
                                } label: {
                                    HStack {
                                        Text(level.displayName)
                                        if selectedLevel == level {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(selectedLevel.rawValue)
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }

                    Divider()

                    // Mode picker
                    SettingsRow(
                        icon: selectedMode.icon,
                        title: "Mode",
                        value: selectedMode.displayName
                    ) {
                        Menu {
                            ForEach(ConversationMode.allCases) { mode in
                                Button {
                                    HapticManager.selection()
                                    selectedMode = mode
                                } label: {
                                    HStack {
                                        Text(mode.displayName)
                                        if selectedMode == mode {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text(selectedMode.displayName)
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.primary)
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
    }

    // MARK: - Recent Scenarios

    private var recentScenariosSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Text("//")
                        .foregroundColor(Theme.Colors.textTertiary)
                    Text("RECENT_MISSIONS")
                }
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textSecondary)

                Spacer()

                Button {
                    showingScenarios = true
                } label: {
                    Text("[VIEW_ALL]")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.primary)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    ForEach(recentScenarios) { scenario in
                        RecentScenarioCard(scenario: scenario) {
                            HapticManager.mediumTap()
                            showingScenarios = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Streak Chip View

struct StreakChipView: View {
    let count: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundColor(isActive ? .orange : Theme.Colors.textTertiary)

            Text("\(max(count, 0))")
                .fontWeight(.semibold)
                .foregroundColor(isActive ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
        }
        .font(Theme.Typography.subheadline)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .clipShape(Capsule())
        .shadow(
            color: Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
        .overlay(
            // Subtle indicator if not practiced today but has streak
            !isActive && count > 0 ?
            Capsule()
                .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            : nil
        )
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .shadow(
                color: Theme.Shadows.small.color,
                radius: Theme.Shadows.small.radius,
                y: Theme.Shadows.small.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let value: String
    let content: Content

    init(icon: String, title: String, value: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.value = value
        self.content = content()
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 28)

            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            content
        }
    }
}

// MARK: - Recent Scenario Card

struct RecentScenarioCard: View {
    let scenario: ScenarioContext
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Icon
                Image(systemName: scenario.type.icon)
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(width: 40, height: 40)
                    .background(Theme.Colors.primary.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))

                // Title
                Text(scenario.title)
                    .font(Theme.Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                // Level badge
                Text(scenario.type.minimumLevel.rawValue)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .frame(width: 120)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .shadow(
                color: Theme.Shadows.small.color,
                radius: Theme.Shadows.small.radius,
                y: Theme.Shadows.small.y
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView(
            selectedLevel: .constant(.a1),
            selectedMode: .constant(.beginner),
            showingScenarios: .constant(false)
        )
    }
}
