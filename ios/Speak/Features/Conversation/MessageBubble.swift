import SwiftUI

/// Message bubble for displaying conversation messages
struct MessageBubble: View {
    let message: ChatMessage
    var showTranslation: Bool = true
    var forceShowTranslation: Bool = false  // Global toggle to show all translations
    var tier: SubscriptionTier = .free
    var onPaywallTrigger: (() -> Void)?
    var onSavePhrase: ((String, String) -> Void)?
    var isSaved: Bool = false

    @State private var isTranslationExpanded: Bool = false

    /// Whether translation should be visible (either forced globally or expanded locally)
    private var shouldShowTranslation: Bool {
        forceShowTranslation || isTranslationExpanded
    }
    @State private var showExplanationSheet: Bool = false

    private var isUser: Bool {
        message.role == .user
    }

    private var canViewCorrection: Bool {
        FeatureAccess.canViewDeepFeedback(tier: tier)
    }

    var body: some View {
        HStack(alignment: .top) {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.Spacing.sm) {
                // Main message bubble with optional save button
                HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                    mainBubble

                    // Star button for tutor messages
                    if !isUser, let spanish = message.spanishText, let english = message.englishText {
                        Button {
                            HapticManager.selection()
                            onSavePhrase?(spanish, english)
                        } label: {
                            Image(systemName: isSaved ? "star.fill" : "star")
                                .font(.system(size: 16))
                                .foregroundColor(isSaved ? Theme.Colors.secondary : Theme.Colors.textTertiary)
                        }
                        .padding(.top, Theme.Spacing.sm)
                    }
                }

                // Correction coach row (if user made an error)
                if let correction = message.correctionSpanish {
                    correctionRow(correction)
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Main Bubble

    private var mainBubble: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Spanish text - serif for tutor, rounded for user
            if let spanish = message.spanishText {
                Text(spanish)
                    .font(isUser ? Theme.Typography.body : Theme.Typography.spanishBody)
                    .foregroundColor(isUser ? .white : Theme.Colors.textPrimary)
            }

            // English translation disclosure (for tutor messages only)
            if let english = message.englishText, !isUser {
                translationDisclosure(english: english)
            }
        }
        .padding(Theme.Spacing.md)
        .background(bubbleBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(
            color: isUser ? Color.clear : Theme.Shadows.small.color,
            radius: Theme.Shadows.small.radius,
            y: Theme.Shadows.small.y
        )
    }

    private var bubbleBackground: Color {
        isUser ? Theme.Colors.primary : Theme.Colors.surface
    }

    // MARK: - Translation Disclosure

    private func translationDisclosure(english: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Only show toggle button if not globally forced
            if !forceShowTranslation {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isTranslationExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: shouldShowTranslation ? "chevron.down" : "chevron.right")
                            .font(.caption2)
                        Text(shouldShowTranslation ? "Hide English" : "Show English")
                            .font(Theme.Typography.caption)
                    }
                    .foregroundColor(Theme.Colors.textTertiary)
                }
            }

            if shouldShowTranslation {
                Text(english)
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .italic()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Correction Row

    private func correctionRow(_ correction: String) -> some View {
        Group {
            if canViewCorrection {
                // Premium: show full correction
                unlockCorrectionContent(correction)
            } else {
                // Free: show blurred preview
                lockedCorrectionContent(correction)
            }
        }
    }

    /// Full correction content for premium users
    private func unlockCorrectionContent(_ correction: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Coach header with Why? button
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "graduationcap.fill")
                        .font(.caption)
                        .foregroundColor(Theme.Colors.success)

                    Text("Coach")
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.success)
                }

                Spacer()

                // Why? button - only show if explanation exists
                if message.correctionExplanation != nil {
                    Button {
                        showExplanationSheet = true
                    } label: {
                        HStack(spacing: 2) {
                            Text("Why?")
                                .font(Theme.Typography.caption)
                                .fontWeight(.medium)
                            Image(systemName: "questionmark.circle")
                                .font(.caption)
                        }
                        .foregroundColor(Theme.Colors.primary)
                    }
                }
            }

            // Corrected phrase with dashed underline effect
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Try saying:")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)

                Text(correction)
                    .font(Theme.Typography.spanishBody)
                    .foregroundColor(Theme.Colors.textPrimary)
                    .padding(.vertical, Theme.Spacing.xs)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 2]))
                            .foregroundColor(Theme.Colors.success.opacity(0.5))
                            .frame(height: 1)
                    }
            }

            // English translation of correction
            if let correctionEnglish = message.correctionEnglish {
                Text(correctionEnglish)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .italic()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.success.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .sheet(isPresented: $showExplanationSheet) {
            ExplanationSheetView(
                correction: correction,
                correctionEnglish: message.correctionEnglish,
                explanation: message.correctionExplanation ?? ""
            )
            .presentationDetents([.medium])
        }
    }

    /// Blurred correction preview for free users
    private func lockedCorrectionContent(_ correction: String) -> some View {
        Button {
            onPaywallTrigger?()
        } label: {
            ZStack {
                // Blurred content preview
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "graduationcap.fill")
                            .font(.caption)
                        Text("Coach")
                            .font(Theme.Typography.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(Theme.Colors.success)

                    Text("Try saying:")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text(correction)
                        .font(Theme.Typography.spanishBody)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(Theme.Spacing.md)
                .blur(radius: 6)

                // Lock overlay
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(Theme.Colors.primary)

                    Text("Unlock corrections")
                        .font(Theme.Typography.caption)
                        .fontWeight(.medium)
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            .background(Theme.Colors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Explanation Sheet

/// Sheet view for displaying grammar explanation
struct ExplanationSheetView: View {
    let correction: String
    let correctionEnglish: String?
    let explanation: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Correction section
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Correction", systemImage: "checkmark.circle.fill")
                            .font(Theme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.success)

                        Text(correction)
                            .font(Theme.Typography.spanishBody)
                            .foregroundColor(Theme.Colors.textPrimary)

                        if let english = correctionEnglish {
                            Text(english)
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .italic()
                        }
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

                    // Explanation section
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Label("Why?", systemImage: "lightbulb.fill")
                            .font(Theme.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Theme.Colors.primary)

                        Text(explanation)
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.textPrimary)
                            .lineSpacing(4)
                    }
                    .padding(Theme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.Colors.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

                    Spacer()
                }
                .padding(Theme.Spacing.lg)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Grammar Tip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Premium") {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Tutor message with correction (premium - visible)
                MessageBubble(
                    message: ChatMessage(
                        role: .assistant,
                        content: "Perfecto, síganme por favor.",
                        spanishText: "Perfecto, síganme por favor.",
                        englishText: "Perfect, follow me please.",
                        correctionSpanish: "Yo tengo hambre",
                        correctionEnglish: "I am hungry",
                        correctionExplanation: "In Spanish, we use 'tener' (to have) for physical states like hunger, thirst, and being cold/hot. 'Ser' means 'to be' but isn't used for these feelings. Think of it as 'I have hunger' rather than 'I am hunger'."
                    ),
                    tier: .premium
                )
            }
            .padding()
        }
    }
}

#Preview("Free") {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // Tutor message with correction (free - blurred)
                MessageBubble(
                    message: ChatMessage(
                        role: .assistant,
                        content: "Perfecto, síganme por favor.",
                        spanishText: "Perfecto, síganme por favor.",
                        englishText: "Perfect, follow me please.",
                        correctionSpanish: "Yo tengo hambre",
                        correctionEnglish: "I am hungry",
                        correctionExplanation: "In Spanish, we use 'tener' (to have) for physical states."
                    ),
                    tier: .free
                ) {
                    print("Paywall triggered")
                }
            }
            .padding()
        }
    }
}

#Preview("Explanation Sheet") {
    ExplanationSheetView(
        correction: "Yo tengo hambre",
        correctionEnglish: "I am hungry",
        explanation: "In Spanish, we use 'tener' (to have) for physical states like hunger, thirst, and being cold/hot. 'Ser' means 'to be' but isn't used for these feelings. Think of it as 'I have hunger' rather than 'I am hunger'."
    )
}
