import SwiftUI

/// Progress sheet shown when tapping the streak chip
struct ProgressSheetView: View {
    @ObservedObject var streakManager = StreakManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Streak hero
                        streakHeroCard

                        // Stats grid
                        statsGrid

                        // Message
                        messageCard

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Your Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Streak Hero

    private var streakHeroCard: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Flame icon
            ZStack {
                Circle()
                    .fill(streakManager.practicedToday
                        ? LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Theme.Colors.textTertiary, Theme.Colors.textSecondary], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            // Streak count
            Text("\(streakManager.currentStreak)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(streakManager.currentStreak == 1 ? "day streak" : "day streak")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textSecondary)

            // Practiced today indicator
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: streakManager.practicedToday ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(streakManager.practicedToday ? Theme.Colors.success : Theme.Colors.textTertiary)

                Text(streakManager.practicedToday ? "Practiced today" : "Not practiced yet")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(streakManager.practicedToday ? Theme.Colors.success : Theme.Colors.textSecondary)
            }
            .padding(.top, Theme.Spacing.xs)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.card))
        .shadow(
            color: Theme.Shadows.medium.color,
            radius: Theme.Shadows.medium.radius,
            y: Theme.Shadows.medium.y
        )
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatCard(
                icon: "book.closed.fill",
                value: "\(streakManager.totalSessions)",
                label: "Sessions"
            )

            StatCard(
                icon: "clock.fill",
                value: streakManager.formattedTotalTime,
                label: "Total Time"
            )
        }
    }

    // MARK: - Message Card

    private var messageCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: streakManager.practicedToday ? "sparkles" : "exclamationmark.circle")
                .font(.title2)
                .foregroundColor(streakManager.practicedToday ? Theme.Colors.secondary : Theme.Colors.primary)

            Text(streakManager.streakMessage)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(streakManager.practicedToday
            ? Theme.Colors.success.opacity(0.1)
            : Theme.Colors.primary.opacity(0.1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.textPrimary)

            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(
            color: Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
    }
}

// MARK: - Preview

#Preview {
    ProgressSheetView()
}
