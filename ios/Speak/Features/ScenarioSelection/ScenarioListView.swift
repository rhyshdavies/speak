import SwiftUI

/// List of available scenarios to practice
struct ScenarioListView: View {
    let selectedLevel: CEFRLevel
    let selectedMode: ConversationMode

    @Environment(\.dismiss) private var dismiss
    @State private var selectedScenario: ScenarioContext?

    var body: some View {
        ZStack {
            Theme.Gradients.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection

                    // Scenario Cards
                    ForEach(ScenarioContext.allScenarios) { scenario in
                        ScenarioCard(scenario: scenario) {
                            HapticManager.mediumTap()
                            selectedScenario = scenario
                        }
                    }
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .navigationDestination(isPresented: Binding(
            get: { selectedScenario != nil },
            set: { if !$0 { selectedScenario = nil } }
        )) {
            if let scenario = selectedScenario {
                ConversationView(
                    scenario: scenario,
                    cefrLevel: selectedLevel,
                    mode: selectedMode
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Text("Choose a Scenario")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.md) {
                Label(selectedLevel.displayName, systemImage: selectedLevel.icon)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)

                Label(selectedMode.displayName, systemImage: selectedMode.icon)
                    .font(Theme.Typography.caption)
                    .foregroundColor(selectedMode == .advanced ? Theme.Colors.primary : Theme.Colors.textSecondary)
            }
        }
        .padding(.bottom, Theme.Spacing.md)
    }
}

// MARK: - Scenario Card

struct ScenarioCard: View {
    let scenario: ScenarioContext
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Header
                HStack {
                    Image(systemName: scenario.type.icon)
                        .font(.title2)
                        .foregroundColor(Theme.Colors.primary)
                        .frame(width: 40, height: 40)
                        .background(Theme.Colors.primary.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.sm)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(scenario.title)
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text(scenario.setting)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(Theme.Colors.textTertiary)
                }

                // Description
                Text(scenario.description)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.leading)

                // Objectives
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("You'll practice:")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textTertiary)

                    ForEach(scenario.objectives.prefix(2), id: \.self) { objective in
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.accent)

                            Text(objective)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.md)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScenarioListView(selectedLevel: .a1, selectedMode: .beginner)
    }
}
