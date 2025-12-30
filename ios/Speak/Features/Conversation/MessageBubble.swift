import SwiftUI

/// Message bubble for displaying conversation messages
struct MessageBubble: View {
    let message: ChatMessage
    var showTranslation: Bool = true

    @State private var isTranslationExpanded: Bool = false

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.Spacing.sm) {
                // Main message bubble
                mainBubble

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
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isTranslationExpanded.toggle()
                }
            } label: {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: isTranslationExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                    Text(isTranslationExpanded ? "Hide English" : "Show English")
                        .font(Theme.Typography.caption)
                }
                .foregroundColor(Theme.Colors.textTertiary)
            }

            if isTranslationExpanded {
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Coach header
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "graduationcap.fill")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.success)

                Text("Coach")
                    .font(Theme.Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.Colors.success)
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
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: Theme.Spacing.md) {
                // User message
                MessageBubble(message: ChatMessage(
                    role: .user,
                    content: "Hola, quiero una mesa para dos",
                    spanishText: "Hola, quiero una mesa para dos"
                ))

                // Tutor message
                MessageBubble(message: ChatMessage(
                    role: .assistant,
                    content: "Bienvenido. Tenemos una mesa disponible cerca de la ventana. ¿Le parece bien?",
                    spanishText: "Bienvenido. Tenemos una mesa disponible cerca de la ventana. ¿Le parece bien?",
                    englishText: "Welcome. We have a table available near the window. Does that work for you?"
                ))

                // User message with error
                MessageBubble(message: ChatMessage(
                    role: .user,
                    content: "Si, esta bien",
                    spanishText: "Si, esta bien"
                ))

                // Tutor message with correction
                MessageBubble(message: ChatMessage(
                    role: .assistant,
                    content: "Perfecto, síganme por favor.",
                    spanishText: "Perfecto, síganme por favor.",
                    englishText: "Perfect, follow me please.",
                    correctionSpanish: "Sí, está bien",
                    correctionEnglish: "Yes, that's fine (with proper accents)"
                ))
            }
            .padding()
        }
    }
}
