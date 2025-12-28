import SwiftUI

/// Message bubble for displaying conversation messages
struct MessageBubble: View {
    let message: ChatMessage
    var showTranslation: Bool = true

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: Theme.Spacing.sm) {
                // Main message
                mainBubble

                // Correction (if any)
                if let correction = message.correctionSpanish {
                    correctionBubble(correction)
                }
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }

    // MARK: - Main Bubble

    private var mainBubble: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Spanish text
            if let spanish = message.spanishText {
                Text(spanish)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            // English translation (for tutor messages, when enabled)
            if let english = message.englishText, !isUser, showTranslation {
                Text(english)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .italic()
            }
        }
        .padding(Theme.Spacing.md)
        .background(bubbleBackground)
        .cornerRadius(Theme.CornerRadius.md)
    }

    private var bubbleBackground: Color {
        isUser ? Theme.Colors.primary : Theme.Colors.surface
    }

    // MARK: - Correction Bubble

    private func correctionBubble(_ correction: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(Theme.Colors.warning)

                Text("Correction:")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.warning)
            }

            Text(correction)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.textPrimary)

            if let correctionEnglish = message.correctionEnglish {
                Text(correctionEnglish)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .italic()
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.warning.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.md)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Theme.Gradients.background
            .ignoresSafeArea()

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
                content: "Bienvenido. Tenemos una mesa disponible.",
                spanishText: "Bienvenido. Tenemos una mesa disponible.",
                englishText: "Welcome. We have a table available."
            ))

            // Tutor message with correction
            MessageBubble(message: ChatMessage(
                role: .assistant,
                content: "Muy bien!",
                spanishText: "Muy bien!",
                englishText: "Very good!",
                correctionSpanish: "Quiero una mesa para dos, por favor",
                correctionEnglish: "I would like a table for two, please"
            ))
        }
        .padding()
    }
}
