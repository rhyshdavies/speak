import SwiftUI

/// Message bubble for displaying conversation messages - Matrix cyberpunk style
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
                // Terminal label
                HStack(spacing: Theme.Spacing.xs) {
                    Text(isUser ? "$ USER.INPUT" : "$ TUTOR.OUTPUT")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(Theme.Colors.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

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
            // Spanish text with Matrix styling
            if let spanish = message.spanishText {
                HStack(spacing: Theme.Spacing.xs) {
                    if !isUser {
                        Text(">")
                            .foregroundColor(Theme.Colors.secondary)
                    }
                    Text(spanish)
                        .foregroundColor(isUser ? .black : Theme.Colors.primary)
                }
                .font(isUser ? Theme.Typography.body : Theme.Typography.spanishBody)
            }

            // English translation disclosure (for tutor messages only)
            if let english = message.englishText, !isUser {
                translationDisclosure(english: english)
            }
        }
        .padding(Theme.Spacing.md)
        .background(bubbleBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                .stroke(
                    isUser ? Theme.Colors.primary : Theme.Colors.primary.opacity(0.3),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
        .shadow(
            color: isUser ? Theme.Colors.glowGreen : Theme.Colors.glowGreen.opacity(0.2),
            radius: isUser ? 8 : 4,
            y: 0
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
                    Text(isTranslationExpanded ? "[-]" : "[+]")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                    Text(isTranslationExpanded ? "HIDE_EN" : "SHOW_EN")
                        .font(Theme.Typography.caption)
                }
                .foregroundColor(Theme.Colors.textTertiary)
            }

            if isTranslationExpanded {
                Text("// \(english)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Correction Row

    private func correctionRow(_ correction: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Matrix-style coach header
            HStack(spacing: Theme.Spacing.xs) {
                Text(">>")
                    .foregroundColor(Theme.Colors.secondary)
                Text("SYNTAX_CORRECTION")
                    .foregroundColor(Theme.Colors.secondary)
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))

            // Corrected phrase
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("// suggested.fix:")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Theme.Colors.textTertiary)

                HStack(spacing: Theme.Spacing.xs) {
                    Text(">")
                        .foregroundColor(Theme.Colors.success)
                    Text(correction)
                        .foregroundColor(Theme.Colors.success)
                }
                .font(Theme.Typography.spanishBody)
            }

            // English translation of correction
            if let correctionEnglish = message.correctionEnglish {
                Text("// \(correctionEnglish)")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.success.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.success.opacity(0.3), lineWidth: 1)
        )
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
