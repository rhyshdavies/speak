import SwiftUI

/// Home screen with CEFR level and mode selection
struct HomeView: View {
    @Binding var selectedLevel: CEFRLevel
    @Binding var selectedMode: ConversationMode
    @Binding var showingScenarios: Bool

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Header
                    headerSection

                    // Mode Selection
                    modeSelectionSection

                    // Level Selection
                    levelSelectionSection

                    // Start Button
                    startButton

                    Spacer(minLength: Theme.Spacing.xxl)
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Mode Selection

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Conversation Mode")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(ConversationMode.allCases) { mode in
                    ModeCard(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        onSelect: {
                            HapticManager.selection()
                            selectedMode = mode
                        }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Speak")
                .font(Theme.Typography.largeTitle)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("Practice Spanish conversations")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.xxl)
    }

    // MARK: - Level Selection

    private var levelSelectionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Your Level")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(CEFRLevel.allCases) { level in
                    LevelCard(
                        level: level,
                        isSelected: selectedLevel == level,
                        onSelect: {
                            HapticManager.selection()
                            selectedLevel = level
                        }
                    )
                }
            }
        }
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            HapticManager.mediumTap()
            showingScenarios = true
        } label: {
            HStack {
                Text("Choose Scenario")
                    .font(Theme.Typography.headline)

                Image(systemName: "arrow.right")
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Gradients.primaryButton)
            .cornerRadius(Theme.CornerRadius.md)
        }
        .padding(.top, Theme.Spacing.lg)
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: CEFRLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                Image(systemName: level.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)
                    .frame(width: 32)

                // Text
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(level.displayName)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(level.description)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.surface : Theme.Colors.surface.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mode Card

struct ModeCard: View {
    let mode: ConversationMode
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: mode.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.textSecondary)

                Text(mode.displayName)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text(mode.description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.surface : Theme.Colors.surface.opacity(0.5))
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
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
