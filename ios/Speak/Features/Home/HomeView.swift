import SwiftUI

/// Home screen with greeting, hero card, quick actions, and recent scenarios
struct HomeView: View {
    @Binding var selectedLevel: CEFRLevel
    @Binding var selectedMode: ConversationMode
    @Binding var showingScenarios: Bool

    @ObservedObject private var streakManager = StreakManager.shared
    @State private var userName: String = "Learner"
    @State private var recentScenarios: [ScenarioContext] = [.greetings, .restaurant, .cafe]

    // Sheet states
    @State private var showingProgress: Bool = false
    @State private var showingReview: Bool = false
    @State private var showingPronunciation: Bool = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Buenos días"
        case 12..<18: return "Buenas tardes"
        default: return "Buenas noches"
        }
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("\(greeting),")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(userName)
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.textPrimary)
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
        .padding(.top, Theme.Spacing.md)
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        Card {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Top row
                HStack {
                    Text("Today's Practice")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)

                    Spacer()

                    if selectedMode == .advanced {
                        LiveBadge()
                    }
                }

                // Scenario info
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(suggestedScenario.title)
                        .font(Theme.Typography.title2)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(suggestedScenario.description)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(2)
                }

                // Badges
                HStack(spacing: Theme.Spacing.md) {
                    LevelBadge(level: selectedLevel)
                    DurationBadge(minutes: 5)

                    Spacer()

                    // Scenario icon
                    Image(systemName: suggestedScenario.type.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary.opacity(0.5))
                }

                // CTA Button
                PrimaryButton("Start", icon: "play.fill") {
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
            Text("Quick Actions")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.md) {
                QuickActionButton(
                    icon: "bubble.left.and.bubble.right",
                    title: "Free Chat",
                    color: Theme.Colors.success
                ) {
                    HapticManager.mediumTap()
                    showingScenarios = true
                }

                QuickActionButton(
                    icon: "book.closed",
                    title: "Review",
                    color: Theme.Colors.secondary
                ) {
                    HapticManager.selection()
                    showingReview = true
                }

                QuickActionButton(
                    icon: "waveform",
                    title: "Pronounce",
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
            Text("Settings")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textPrimary)

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
                Text("Jump Back In")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                Button {
                    showingScenarios = true
                } label: {
                    Text("See all")
                        .font(Theme.Typography.subheadline)
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
