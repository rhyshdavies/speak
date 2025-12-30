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
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }

            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text("Scenarios")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
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

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Level and Mode badges
            HStack(spacing: Theme.Spacing.md) {
                LevelBadge(level: selectedLevel)

                if selectedMode == .advanced {
                    LiveBadge()
                } else {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: selectedMode.icon)
                        Text(selectedMode.displayName)
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.surfaceSecondary)
                    .clipShape(Capsule())
                }
            }

            // Scenario count
            Text("\(availableScenarios.count) scenarios available")
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
                // Top section with gradient background
                ZStack(alignment: .bottomLeading) {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            scenarioColor.opacity(0.3),
                            scenarioColor.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Icon
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: scenario.type.icon)
                                .font(.system(size: 32))
                                .foregroundColor(scenarioColor)
                            Spacer()
                        }
                        .padding(Theme.Spacing.md)
                    }
                }
                .frame(height: 100)

                // Bottom section with title and level
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(scenario.title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Level indicator
                    Text(scenario.type.minimumLevel.rawValue)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
            .shadow(
                color: Theme.Shadows.small.color,
                radius: Theme.Shadows.small.radius,
                y: Theme.Shadows.small.y
            )
        }
        .buttonStyle(.plain)
        .aspectRatio(3/4, contentMode: .fit)
    }

    private var scenarioColor: Color {
        switch scenario.type.color {
        case "green": return Color(hex: "81B29A")
        case "mint": return Color(hex: "A8DADC")
        case "teal": return Color(hex: "2A9D8F")
        case "orange": return Color(hex: "F4A261")
        case "purple": return Color(hex: "9B72CF")
        case "pink": return Color(hex: "E07A9A")
        case "blue": return Color(hex: "457B9D")
        case "red": return Color(hex: "E07A5F")
        case "brown": return Color(hex: "8B7355")
        case "indigo": return Color(hex: "5C6BC0")
        case "cyan": return Color(hex: "4DD0E1")
        case "gray": return Color(hex: "78909C")
        case "yellow": return Color(hex: "F4A261")
        default: return Theme.Colors.primary
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ScenarioListView(selectedLevel: .b1, selectedMode: .beginner)
    }
}
