import SwiftUI

/// Review screen showing corrections, saved phrases, and tutor highlights
struct ReviewView: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @ObservedObject var history = SessionHistory.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: ReviewTab = .corrections
    @State private var showPaywall: Bool = false

    enum ReviewTab: String, CaseIterable {
        case corrections = "Corrections"
        case saved = "Saved"
        case recent = "Recent"
    }

    /// Item limit based on tier (nil = unlimited)
    private var itemLimit: Int? {
        FeatureAccess.reviewItemLimit(for: subscriptionManager.tier)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Tab picker
                    tabPicker

                    // Content
                    if isEmpty {
                        emptyState
                    } else {
                        contentList
                    }
                }
            }
            .navigationTitle("Review")
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

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(ReviewTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(tab.rawValue)
                            .font(Theme.Typography.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? Theme.Colors.primary : Theme.Colors.textSecondary)

                        Rectangle()
                            .fill(selectedTab == tab ? Theme.Colors.primary : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .background(Theme.Colors.surface)
    }

    // MARK: - Empty State

    private var isEmpty: Bool {
        switch selectedTab {
        case .corrections: return history.recentCorrections.isEmpty
        case .saved: return history.savedPhrases.isEmpty
        case .recent: return history.recentTutorMessages.isEmpty
        }
    }

    private var emptyState: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.textTertiary)

            Text(emptyTitle)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textPrimary)

            Text(emptyMessage)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
    }

    private var emptyIcon: String {
        switch selectedTab {
        case .corrections: return "pencil.circle"
        case .saved: return "star.circle"
        case .recent: return "bubble.left.circle"
        }
    }

    private var emptyTitle: String {
        switch selectedTab {
        case .corrections: return "No corrections yet"
        case .saved: return "No saved phrases"
        case .recent: return "No recent messages"
        }
    }

    private var emptyMessage: String {
        switch selectedTab {
        case .corrections: return "When the tutor corrects your Spanish, it will appear here for review."
        case .saved: return "Tap the star on tutor messages to save phrases for later."
        case .recent: return "Recent tutor responses will appear here after practice sessions."
        }
    }

    // MARK: - Content List

    private var contentList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                switch selectedTab {
                case .corrections:
                    let items = limitedItems(history.recentCorrections)
                    ForEach(items) { correction in
                        CorrectionCard(correction: correction)
                    }
                    if hasMoreItems(history.recentCorrections) {
                        unlockMoreButton(total: history.recentCorrections.count)
                    }
                case .saved:
                    let items = limitedItems(history.savedPhrases)
                    ForEach(items) { phrase in
                        SavedPhraseCard(phrase: phrase) {
                            history.removePhrase(phrase)
                        }
                    }
                    if hasMoreItems(history.savedPhrases) {
                        unlockMoreButton(total: history.savedPhrases.count)
                    }
                case .recent:
                    let items = limitedItems(history.recentTutorMessages)
                    ForEach(items) { message in
                        TutorMessageCard(message: message)
                    }
                    if hasMoreItems(history.recentTutorMessages) {
                        unlockMoreButton(total: history.recentTutorMessages.count)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(trigger: .reviewLimitReached)
        }
    }

    // MARK: - Item Limiting

    private func limitedItems<T>(_ items: [T]) -> ArraySlice<T> {
        if let limit = itemLimit {
            return items.prefix(limit)
        }
        return items[...]
    }

    private func hasMoreItems<T>(_ items: [T]) -> Bool {
        guard let limit = itemLimit else { return false }
        return items.count > limit
    }

    private func unlockMoreButton(total: Int) -> some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.caption)
                Text("See all \(total) items")
                    .font(Theme.Typography.subheadline)
                Text("Premium")
                    .font(Theme.Typography.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(Theme.Colors.primary.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundColor(Theme.Colors.primary)
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
    }
}

// MARK: - Correction Card

struct CorrectionCard: View {
    let correction: SavedCorrection

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // What you said
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("You said:")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)

                Text(correction.original)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .strikethrough(true, color: Theme.Colors.error.opacity(0.5))
            }

            // Correction
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                        .font(.caption)
                    Text("Correct:")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.success)
                }

                Text(correction.corrected)
                    .font(Theme.Typography.spanishBody)
                    .foregroundColor(Theme.Colors.textPrimary)

                if let english = correction.english {
                    Text(english)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .italic()
                }
            }

            // Explanation (Why?)
            if let explanation = correction.explanation {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(Theme.Colors.primary)
                            .font(.caption)
                        Text("Why?")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.primary)
                    }

                    Text(explanation)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineSpacing(2)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.primary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
            }

            // Scenario badge
            HStack {
                Text(correction.scenario)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textTertiary)

                Spacer()

                Text(correction.date, style: .relative)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(
            color: Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
    }
}

// MARK: - Saved Phrase Card

struct SavedPhraseCard: View {
    let phrase: SavedPhrase
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(phrase.spanish)
                    .font(Theme.Typography.spanishHeadline)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(phrase.english)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Button {
                HapticManager.selection()
                onRemove()
            } label: {
                Image(systemName: "star.fill")
                    .foregroundColor(Theme.Colors.secondary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(
            color: Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
    }
}

// MARK: - Tutor Message Card

struct TutorMessageCard: View {
    let message: SavedTutorMessage

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(message.spanish)
                .font(Theme.Typography.spanishBody)
                .foregroundColor(Theme.Colors.textPrimary)

            if let english = message.english {
                Text(english)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .italic()
            }

            HStack {
                Text(message.scenario)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textTertiary)

                Spacer()

                Text(message.date, style: .relative)
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
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
    ReviewView()
        .environmentObject(SubscriptionManager.shared)
}
