import SwiftUI

/// List of available scenarios in a 2-column grid
struct ScenarioListView: View {
    let selectedLevel: CEFRLevel
    let selectedMode: ConversationMode

    @Environment(\.dismiss) private var dismiss
    @State private var selectedScenario: ScenarioContext?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    /// Scenarios appropriate for the selected level
    private var availableScenarios: [ScenarioContext] {
        ScenarioContext.scenarios(for: selectedLevel)
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    headerSection

                    // Scenario Grid
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(availableScenarios) { scenario in
                            ScenarioGridCard(
                                scenario: scenario,
                                level: selectedLevel
                            ) {
                                HapticManager.mediumTap()
                                selectedScenario = scenario
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.bottom, Theme.Spacing.xxl)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text("<")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                        Text("EXIT")
                            .font(Theme.Typography.caption)
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                Text("MISSION_SELECT")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Terminal status line
            HStack {
                Text("$ system.status")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Theme.Colors.textTertiary)
                Spacer()
            }

            // Level and Mode badges
            HStack(spacing: Theme.Spacing.md) {
                LevelBadge(level: selectedLevel)

                if selectedMode == .advanced {
                    LiveBadge()
                } else {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: selectedMode.icon)
                        Text(selectedMode.displayName.uppercased())
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.surfaceSecondary)
                    .overlay(
                        Capsule()
                            .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
            }

            // Scenario count - terminal style
            Text(">> \(availableScenarios.count) MISSIONS_LOADED")
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.top, Theme.Spacing.md)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Scenario Grid Card

struct ScenarioGridCard: View {
    let scenario: ScenarioContext
    let level: CEFRLevel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Top section with Matrix gradient
                ZStack(alignment: .bottomLeading) {
                    // Matrix gradient background
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary.opacity(0.2),
                            Theme.Colors.secondary.opacity(0.1),
                            Theme.Colors.surface
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Grid overlay effect
                    VStack(spacing: 8) {
                        ForEach(0..<6, id: \.self) { _ in
                            Rectangle()
                                .fill(Theme.Colors.primary.opacity(0.05))
                                .frame(height: 1)
                        }
                    }

                    // Icon with glow
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: scenario.type.icon)
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(Theme.Colors.primary)
                                .shadow(color: Theme.Colors.glowGreen, radius: 8, y: 0)
                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                    }
                }
                .frame(height: 90)

                // Bottom section with title and level
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    // Terminal-style title
                    Text("> \(scenario.title.uppercased())")
                        .font(Theme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.Colors.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Level indicator - terminal style
                    Text("[\(scenario.type.minimumLevel.rawValue)]")
                        .font(Theme.Typography.caption2)
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Theme.Colors.glowGreen.opacity(0.2), radius: 8, y: 0)
        }
        .buttonStyle(.plain)
        .aspectRatio(3/4, contentMode: .fit)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScenarioListView(selectedLevel: .b1, selectedMode: .beginner)
    }
}
