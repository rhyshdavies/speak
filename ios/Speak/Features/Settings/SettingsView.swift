import SwiftUI

/// Settings screen with level, account, and debug options
struct SettingsView: View {
    @Binding var selectedLevel: CEFRLevel
    var showPaywall: (PaywallTrigger) -> Void

    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var isRestoring = false
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Practice Settings
                        practiceSection

                        // Account Section
                        accountSection

                        #if DEBUG
                        // Debug Section
                        debugSection
                        #endif

                        // About Section
                        aboutSection

                        Spacer(minLength: Theme.Spacing.xxl)
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }

    // MARK: - Practice Section

    private var practiceSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Practice", icon: "book.fill")

            Card {
                VStack(spacing: 0) {
                    // Level picker
                    SettingsPickerRow(
                        icon: "chart.bar.fill",
                        iconColor: Theme.Colors.success,
                        title: "Spanish Level",
                        subtitle: selectedLevel.description
                    ) {
                        Menu {
                            ForEach(CEFRLevel.allCases) { level in
                                let isLocked = level.requiresPremium && subscriptionManager.tier == .free
                                Button {
                                    if isLocked {
                                        showPaywall(.levelLocked)
                                    } else {
                                        HapticManager.selection()
                                        selectedLevel = level
                                    }
                                } label: {
                                    HStack {
                                        Text(level.displayName)
                                        Spacer()
                                        if isLocked {
                                            Image(systemName: "lock.fill")
                                        } else if selectedLevel == level {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            SettingsValueLabel(value: selectedLevel.rawValue)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Account", icon: "person.fill")

            Card {
                VStack(spacing: 0) {
                    // Subscription status
                    SettingsRow(
                        icon: subscriptionManager.tier == .premium ? "crown.fill" : "crown",
                        iconColor: subscriptionManager.tier == .premium ? .orange : Theme.Colors.textTertiary,
                        title: "Subscription",
                        value: subscriptionManager.tier == .premium ? "Premium" : "Free"
                    )

                    if subscriptionManager.tier == .free {
                        SettingsDivider()

                        // Upgrade button
                        Button {
                            showPaywall(.practiceLimit)
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.body)
                                    .foregroundColor(.orange)
                                    .frame(width: 28)

                                Text("Upgrade to Premium")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.textPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                        }
                    }

                    SettingsDivider()

                    // Restore purchases
                    Button {
                        Task {
                            await restorePurchases()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                                .foregroundColor(Theme.Colors.primary)
                                .frame(width: 28)

                            Text("Restore Purchases")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.textPrimary)

                            Spacer()

                            if isRestoring {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                    .disabled(isRestoring)

                    if subscriptionManager.tier == .premium {
                        SettingsDivider()

                        // Manage subscription (opens App Store)
                        Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                            HStack {
                                Image(systemName: "creditcard")
                                    .font(.body)
                                    .foregroundColor(Theme.Colors.secondary)
                                    .frame(width: 28)

                                Text("Manage Subscription")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.textPrimary)

                                Spacer()

                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                                    .foregroundColor(Theme.Colors.textTertiary)
                            }
                            .padding(.vertical, Theme.Spacing.sm)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreAlertMessage)
        }
    }

    // MARK: - Actions

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionManager.restorePurchases()

            if subscriptionManager.tier == .premium {
                HapticManager.success()
                restoreAlertMessage = "Your Premium subscription has been restored!"
            } else {
                restoreAlertMessage = "No active subscription found for this account."
            }
            showRestoreAlert = true
        } catch {
            HapticManager.error()
            restoreAlertMessage = error.localizedDescription
            showRestoreAlert = true
        }
    }

    // MARK: - Debug Section

    #if DEBUG
    private var debugSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "Debug", icon: "ladybug.fill")

            Card {
                VStack(spacing: 0) {
                    // Tier toggle
                    SettingsPickerRow(
                        icon: "arrow.left.arrow.right",
                        iconColor: .purple,
                        title: "Mock Subscription",
                        subtitle: "Toggle for testing"
                    ) {
                        Button {
                            HapticManager.selection()
                            subscriptionManager.setTier(
                                subscriptionManager.tier == .premium ? .free : .premium
                            )
                        } label: {
                            SettingsValueLabel(
                                value: subscriptionManager.tier == .premium ? "Premium" : "Free"
                            )
                        }
                    }

                    SettingsDivider()

                    // Practice count
                    SettingsPickerRow(
                        icon: "number",
                        iconColor: .blue,
                        title: "Practices Today",
                        subtitle: "Reset to test limits"
                    ) {
                        Button {
                            HapticManager.selection()
                            subscriptionManager.resetPracticeCount()
                        } label: {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text("\(subscriptionManager.practicesToday)")
                                    .font(Theme.Typography.headline)
                                    .foregroundColor(Theme.Colors.primary)
                                Text("Reset")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.primary.opacity(0.7))
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
    }
    #endif

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            SectionHeader(title: "About", icon: "info.circle.fill")

            Card {
                VStack(spacing: 0) {
                    SettingsRow(
                        icon: "app.badge",
                        iconColor: Theme.Colors.primary,
                        title: "Version",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                    )
                }
                .padding(Theme.Spacing.md)
            }
        }
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(Theme.Colors.textTertiary)

            Text(title.uppercased())
                .font(Theme.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(Theme.Colors.textTertiary)
                .tracking(1)
        }
        .padding(.leading, Theme.Spacing.xs)
    }
}

// MARK: - Settings Row (Static)

private struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Settings Picker Row

private struct SettingsPickerRow<Content: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let content: Content

    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            Spacer()

            content
        }
        .padding(.vertical, Theme.Spacing.sm)
    }
}

// MARK: - Settings Value Label

private struct SettingsValueLabel: View {
    let value: String

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primary)

            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundColor(Theme.Colors.primary.opacity(0.7))
        }
    }
}

// MARK: - Settings Divider

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 36)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(
        selectedLevel: .constant(.a1),
        showPaywall: { _ in }
    )
    .environmentObject(SubscriptionManager.shared)
}
