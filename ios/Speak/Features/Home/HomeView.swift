import SwiftUI

/// Home screen with greeting, hero card, quick actions, and recent scenarios
struct HomeView: View {
    @Binding var selectedLevel: CEFRLevel
    @Binding var selectedLanguage: Language
    @Binding var showingScenarios: Bool
    var showPaywall: (PaywallTrigger) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @ObservedObject private var streakManager = StreakManager.shared
    @ObservedObject private var sessionHistory = SessionHistory.shared
    @State private var userName: String = "Learner"

    // Sheet states
    @State private var showingProgress: Bool = false
    @State private var showingReview: Bool = false
    @State private var showingSettings: Bool = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greetings = selectedLanguage.greeting
        switch hour {
        case 5..<12: return greetings.morning
        case 12..<18: return greetings.afternoon
        default: return greetings.evening
        }
    }

    /// Recent scenarios the user has actually practiced
    private var recentScenarios: [ScenarioContext] {
        return sessionHistory.recentScenarioTitles.compactMap { title in
            ScenarioContext.allScenarios.first { $0.title == title }
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
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                selectedLevel: $selectedLevel,
                showPaywall: showPaywall
            )
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Top row: Greeting and settings
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

                // Settings gear
                Button {
                    HapticManager.selection()
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }

            // Bottom row: Language and Level selectors
            HStack(spacing: Theme.Spacing.sm) {
                // Language selector
                LanguageSelectorChip(selectedLanguage: $selectedLanguage)

                // Level selector
                LevelSelectorChip(
                    selectedLevel: $selectedLevel,
                    tier: subscriptionManager.tier,
                    showPaywall: showPaywall
                )

                Spacer()
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

                    LiveBadge()
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
                    PracticeLimitBadge(tier: subscriptionManager.tier, usedToday: subscriptionManager.practicesToday)

                    Spacer()

                    // Scenario icon
                    Image(systemName: suggestedScenario.type.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary.opacity(0.5))
                }

                // CTA Button
                if subscriptionManager.canStartPractice() {
                    PrimaryButton("Start", icon: "play.fill") {
                        HapticManager.mediumTap()
                        showingScenarios = true
                    }
                    .padding(.top, Theme.Spacing.sm)
                } else {
                    VStack(spacing: Theme.Spacing.sm) {
                        PrimaryButton("Start", icon: "play.fill", isDisabled: true) {}
                            .padding(.top, Theme.Spacing.sm)

                        Button {
                            showPaywall(.practiceLimit)
                        } label: {
                            Text("Unlock unlimited practice")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.primary)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    private var suggestedScenario: ScenarioContext {
        // Daily pinning: same scenario all day, rotates tomorrow
        subscriptionManager.pinnedScenario(for: selectedLevel)
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
                    title: "Chat",
                    color: Theme.Colors.success
                ) {
                    HapticManager.mediumTap()
                    showingScenarios = true
                }

                QuickActionButton(
                    icon: "theatermasks",
                    title: "Scenarios",
                    color: Theme.Colors.primary
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

// MARK: - Level Selector Chip

struct LevelSelectorChip: View {
    @Binding var selectedLevel: CEFRLevel
    let tier: SubscriptionTier
    var showPaywall: (PaywallTrigger) -> Void

    private let levels: [CEFRLevel] = CEFRLevel.allCases

    var body: some View {
        Menu {
            levelButton(for: .a1)
            levelButton(for: .a2)
            levelButton(for: .b1)
            levelButton(for: .b2)
            levelButton(for: .c1)
            levelButton(for: .c2)
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text(selectedLevel.rawValue)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.primary)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
            }
            .font(Theme.Typography.subheadline)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.primary.opacity(0.12))
            .clipShape(Capsule())
        }
    }

    @ViewBuilder
    private func levelButton(for level: CEFRLevel) -> some View {
        Button {
            HapticManager.selection()
            if level.requiresPremium && tier == .free {
                showPaywall(.levelLocked)
            } else {
                selectedLevel = level
            }
        } label: {
            HStack {
                Text("\(level.rawValue) – \(levelName(for: level))")

                Spacer()

                if level == selectedLevel {
                    Image(systemName: "checkmark")
                } else if level.requiresPremium && tier == .free {
                    Image(systemName: "lock.fill")
                }
            }
        }
    }

    private func levelName(for level: CEFRLevel) -> String {
        switch level {
        case .a1: return "Beginner"
        case .a2: return "Elementary"
        case .b1: return "Intermediate"
        case .b2: return "Upper Intermediate"
        case .c1: return "Advanced"
        case .c2: return "Mastery"
        }
    }
}

// MARK: - Language Selector Chip

struct LanguageSelectorChip: View {
    @Binding var selectedLanguage: Language

    var body: some View {
        Menu {
            ForEach(Language.allCases) { language in
                Button {
                    HapticManager.selection()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedLanguage = language
                    }
                } label: {
                    HStack {
                        Text("\(language.flag) \(language.displayName)")

                        Spacer()

                        if language == selectedLanguage {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text(selectedLanguage.flag)
                    .font(.title3)

                Text(selectedLanguage.displayName)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textPrimary)

                Image(systemName: "chevron.down")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.textSecondary)
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
            selectedLanguage: .constant(.spanish),
            showingScenarios: .constant(false),
            showPaywall: { _ in }
        )
        .environmentObject(SubscriptionManager.shared)
    }
}
