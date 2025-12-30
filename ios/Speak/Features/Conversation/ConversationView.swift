import SwiftUI

/// Main conversation screen with unified UI for Beginner and Advanced modes
struct ConversationView: View {
    let scenario: ScenarioContext
    let cefrLevel: CEFRLevel
    let mode: ConversationMode

    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showKeyPhrases: Bool = false

    init(scenario: ScenarioContext, cefrLevel: CEFRLevel, mode: ConversationMode = .beginner) {
        self.scenario = scenario
        self.cefrLevel = cefrLevel
        self.mode = mode
        _viewModel = StateObject(wrappedValue: ConversationViewModel(
            scenario: scenario,
            cefrLevel: cefrLevel,
            mode: mode
        ))
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                conversationHeader

                // Messages
                messagesSection

                // Live transcript line (Advanced mode only)
                if mode == .advanced && !viewModel.liveTranscript.isEmpty {
                    liveTranscriptLine
                }

                // Suggestions
                if let suggestions = viewModel.suggestedResponses, !suggestions.isEmpty {
                    suggestionsRow(suggestions)
                }

                // Bottom controls - unified PTT for both modes
                bottomControls
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    viewModel.cleanup()
                    dismiss()
                } label: {
                    Text("[X]")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.Colors.error)
                        .frame(width: 32, height: 32)
                        .background(Theme.Colors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.xs))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.xs)
                                .stroke(Theme.Colors.error.opacity(0.5), lineWidth: 1)
                        )
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("> \(scenario.title.uppercased())")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primary)

                    if mode == .advanced && viewModel.conversationState == .active {
                        LiveBadge()
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    // Key Phrases button
                    Button {
                        HapticManager.selection()
                        showKeyPhrases = true
                    } label: {
                        Image(systemName: "text.book.closed")
                            .font(.body)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    // Speed control
                    speedButton
                }
            }
        }
        .sheet(isPresented: $showKeyPhrases) {
            KeyPhrasesSheet(scenario: scenario)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Header

    private var conversationHeader: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Theme.Colors.surfaceSecondary)
                        .frame(height: 4)

                    Rectangle()
                        .fill(Theme.Colors.primary)
                        .frame(width: geometry.size.width * viewModel.scenarioProgress.progressPercentage, height: 4)
                }
            }
            .frame(height: 4)

            // Setting description
            Text(scenario.setting)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
        }
        .background(Theme.Colors.surface)
    }

    // MARK: - Messages

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.md) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message, showTranslation: viewModel.showTranslations)
                            .id(message.id)
                    }

                    // Live tutor response (Advanced mode - streaming)
                    if mode == .advanced && !viewModel.liveTutorText.isEmpty {
                        liveTutorBubble
                    }

                    // Status indicator
                    if mode == .advanced {
                        statusIndicator
                    }

                    // Bottom anchor
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(Theme.Spacing.md)
            }
            .onChange(of: viewModel.messages.count) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.liveTranscript) { _ in
                scrollToBottom(proxy: proxy)
            }
            .onChange(of: viewModel.liveTutorText) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // MARK: - Status Indicator (Advanced Mode)

    @ViewBuilder
    private var statusIndicator: some View {
        if viewModel.conversationState == .active && !viewModel.isLocked && viewModel.liveTranscript.isEmpty {
            HStack(spacing: Theme.Spacing.sm) {
                // VAD indicator dot with glow
                Circle()
                    .fill(viewModel.audioLevel > 0.1 ? Theme.Colors.success : Theme.Colors.textTertiary)
                    .frame(width: 8, height: 8)
                    .shadow(color: viewModel.audioLevel > 0.1 ? Theme.Colors.glowGreen : .clear, radius: 4, y: 0)
                    .animation(.easeInOut(duration: 0.15), value: viewModel.audioLevel)

                Text(">> LISTENING_")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primary)
            }
            .padding(Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.sm)
            .background(Theme.Colors.surfaceSecondary)
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        } else if viewModel.conversationState == .paused {
            HStack(spacing: Theme.Spacing.sm) {
                Text("||")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                Text("PAUSED")
                    .font(Theme.Typography.caption)
            }
            .foregroundColor(Theme.Colors.warning)
            .padding(Theme.Spacing.sm)
            .padding(.horizontal, Theme.Spacing.sm)
            .background(Theme.Colors.surfaceSecondary)
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.warning.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
    }

    // MARK: - Live Transcript Line

    private var liveTranscriptLine: some View {
        HStack {
            Spacer()
            HStack(spacing: Theme.Spacing.xs) {
                Text(">")
                    .foregroundColor(Theme.Colors.secondary)
                Text(viewModel.liveTranscript)
                    .foregroundColor(Theme.Colors.textSecondary)
                TerminalCursor()
            }
            .font(Theme.Typography.subheadline)
            .lineLimit(1)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.surfaceSecondary)
            .overlay(
                Capsule()
                    .stroke(Theme.Colors.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.sm)
    }

    // MARK: - Live Tutor Bubble

    private var liveTutorBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Terminal prefix
                Text("$ TUTOR.RESPONSE")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(Theme.Colors.textTertiary)

                Text(viewModel.liveTutorText)
                    .font(Theme.Typography.spanishBody)
                    .foregroundColor(Theme.Colors.primary)

                // Matrix-style typing indicator
                HStack(spacing: 4) {
                    ForEach(0..<3) { i in
                        Rectangle()
                            .fill(Theme.Colors.primary.opacity(0.6 - Double(i) * 0.15))
                            .frame(width: 4, height: 12)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(Theme.Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .shadow(color: Theme.Colors.glowGreen.opacity(0.2), radius: 8, y: 0)

            Spacer(minLength: 60)
        }
    }

    // MARK: - Suggestions

    private func suggestionsRow(_ suggestions: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                // Prefix label
                Text("//")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textTertiary)

                ForEach(suggestions, id: \.self) { suggestion in
                    Text("[\(suggestion)]")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .overlay(
                            Capsule()
                                .stroke(Theme.Colors.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Unified PTT button for both modes
            if mode == .advanced {
                advancedModeControls
            } else {
                PTTButton(
                    mode: mode,
                    isRecording: viewModel.isRecording,
                    isProcessing: viewModel.isProcessing,
                    isLocked: viewModel.isLocked,
                    audioLevel: viewModel.audioLevel,
                    onPress: viewModel.startRecording,
                    onRelease: viewModel.stopRecordingAndSend
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.xl)
        .background(
            Theme.Colors.background
                .shadow(color: Theme.Colors.textPrimary.opacity(0.05), radius: 10, y: -5)
        )
    }

    // MARK: - Advanced Mode Controls

    @ViewBuilder
    private var advancedModeControls: some View {
        switch viewModel.conversationState {
        case .idle:
            PrimaryButton("INITIALIZE", icon: "play.fill") {
                viewModel.startRecording()
            }

        case .active:
            HStack(spacing: Theme.Spacing.xl) {
                // Pause button
                Button {
                    viewModel.pauseConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("||")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(viewModel.isLocked ? Theme.Colors.textTertiary : Theme.Colors.warning)
                            .frame(width: 56, height: 56)
                            .background(Theme.Colors.surfaceSecondary)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.warning.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(Circle())

                        Text("PAUSE")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.warning)
                    }
                }
                .disabled(viewModel.isLocked)

                // Main recording indicator - Matrix style
                ZStack {
                    // Outer pulse with glow
                    Circle()
                        .fill(viewModel.isLocked ? Theme.Colors.primary.opacity(0.15) : Theme.Colors.recording.opacity(0.15))
                        .frame(
                            width: 88 + CGFloat(viewModel.audioLevel) * 20,
                            height: 88 + CGFloat(viewModel.audioLevel) * 20
                        )
                        .shadow(
                            color: viewModel.isLocked ? Theme.Colors.glowGreen : Theme.Colors.recording.opacity(0.5),
                            radius: 12, y: 0
                        )
                        .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)

                    // Inner circle with border
                    Circle()
                        .fill(Theme.Colors.surface)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Circle()
                                .stroke(viewModel.isLocked ? Theme.Colors.primary : Theme.Colors.recording, lineWidth: 2)
                        )

                    // Icon
                    Image(systemName: viewModel.isLocked ? "speaker.wave.2.fill" : "waveform")
                        .font(.title)
                        .foregroundColor(viewModel.isLocked ? Theme.Colors.primary : Theme.Colors.recording)
                        .shadow(
                            color: viewModel.isLocked ? Theme.Colors.glowGreen : Theme.Colors.recording.opacity(0.5),
                            radius: 4, y: 0
                        )
                }

                // Stop button
                Button {
                    viewModel.stopConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("[X]")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.error)
                            .frame(width: 56, height: 56)
                            .background(Theme.Colors.surfaceSecondary)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(Circle())

                        Text("END")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.error)
                    }
                }
            }

        case .paused:
            HStack(spacing: Theme.Spacing.xl) {
                // Resume button
                Button {
                    viewModel.resumeConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                            .frame(width: 72, height: 72)
                            .background(Theme.Colors.primary)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.primary, lineWidth: 1)
                            )
                            .clipShape(Circle())
                            .shadow(color: Theme.Colors.glowGreen, radius: 8, y: 0)

                        Text("RESUME")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }

                // End button
                Button {
                    viewModel.stopConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("[X]")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(Theme.Colors.error)
                            .frame(width: 72, height: 72)
                            .background(Theme.Colors.surfaceSecondary)
                            .overlay(
                                Circle()
                                    .stroke(Theme.Colors.error.opacity(0.3), lineWidth: 1)
                            )
                            .clipShape(Circle())

                        Text("END")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.error)
                    }
                }
            }
        }
    }

    // MARK: - Speed Button

    private var speedButton: some View {
        Button {
            viewModel.cyclePlaybackSpeed()
        } label: {
            Text(String(format: "%.1fx", viewModel.playbackSpeed))
                .font(Theme.Typography.caption)
                .fontWeight(.medium)
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Colors.surfaceSecondary)
                .clipShape(Capsule())
        }
    }
}

// MARK: - Key Phrases Sheet

struct KeyPhrasesSheet: View {
    let scenario: ScenarioContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Terminal header
                        HStack {
                            Text("$ cat phrases.db")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(Theme.Colors.textTertiary)
                            Spacer()
                        }

                        // Scenario context
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            HStack(spacing: Theme.Spacing.xs) {
                                Text("//")
                                    .foregroundColor(Theme.Colors.textTertiary)
                                Text("KEY_PHRASES")
                            }
                            .font(Theme.Typography.title3)
                            .foregroundColor(Theme.Colors.primary)

                            Text(">> MISSION: \(scenario.title.uppercased())")
                                .font(Theme.Typography.subheadline)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        // Phrases based on scenario objectives
                        ForEach(keyPhrases, id: \.spanish) { phrase in
                            KeyPhraseRow(phrase: phrase)
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("[CLOSE]") {
                        dismiss()
                    }
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
    }

    private var keyPhrases: [KeyPhrase] {
        // Generate key phrases based on scenario type
        switch scenario.type {
        case .greetings, .freeConversationA1:
            return [
                KeyPhrase(spanish: "Hola, me llamo...", english: "Hello, my name is..."),
                KeyPhrase(spanish: "Mucho gusto", english: "Nice to meet you"),
                KeyPhrase(spanish: "¿Cómo te llamas?", english: "What's your name?"),
                KeyPhrase(spanish: "¿De dónde eres?", english: "Where are you from?"),
                KeyPhrase(spanish: "Soy de...", english: "I'm from...")
            ]
        case .restaurant:
            return [
                KeyPhrase(spanish: "Una mesa para dos, por favor", english: "A table for two, please"),
                KeyPhrase(spanish: "¿Qué me recomienda?", english: "What do you recommend?"),
                KeyPhrase(spanish: "La cuenta, por favor", english: "The check, please"),
                KeyPhrase(spanish: "Soy alérgico a...", english: "I'm allergic to..."),
                KeyPhrase(spanish: "¿Tienen algo vegetariano?", english: "Do you have anything vegetarian?")
            ]
        case .airport:
            return [
                KeyPhrase(spanish: "¿Dónde está la puerta...?", english: "Where is gate...?"),
                KeyPhrase(spanish: "Mi vuelo sale a las...", english: "My flight leaves at..."),
                KeyPhrase(spanish: "Vengo de vacaciones", english: "I'm here on vacation"),
                KeyPhrase(spanish: "Solo llevo equipaje de mano", english: "I only have carry-on luggage"),
                KeyPhrase(spanish: "¿A qué hora es el embarque?", english: "What time is boarding?")
            ]
        case .hotel:
            return [
                KeyPhrase(spanish: "Tengo una reservación", english: "I have a reservation"),
                KeyPhrase(spanish: "¿A qué hora es el desayuno?", english: "What time is breakfast?"),
                KeyPhrase(spanish: "¿Tiene wifi?", english: "Do you have WiFi?"),
                KeyPhrase(spanish: "Quisiera una habitación con vista", english: "I'd like a room with a view"),
                KeyPhrase(spanish: "¿Puedo dejar el equipaje?", english: "Can I leave my luggage?")
            ]
        default:
            return [
                KeyPhrase(spanish: "¿Puede repetir, por favor?", english: "Can you repeat, please?"),
                KeyPhrase(spanish: "No entiendo", english: "I don't understand"),
                KeyPhrase(spanish: "¿Cómo se dice...?", english: "How do you say...?"),
                KeyPhrase(spanish: "Más despacio, por favor", english: "More slowly, please"),
                KeyPhrase(spanish: "Gracias por su ayuda", english: "Thank you for your help")
            ]
        }
    }
}

struct KeyPhrase {
    let spanish: String
    let english: String
}

struct KeyPhraseRow: View {
    let phrase: KeyPhrase

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            // Spanish - primary text
            HStack(spacing: Theme.Spacing.xs) {
                Text(">")
                    .foregroundColor(Theme.Colors.secondary)
                Text(phrase.spanish)
                    .foregroundColor(Theme.Colors.primary)
            }
            .font(Theme.Typography.spanishHeadline)

            // English translation - dimmed
            Text("  // \(phrase.english)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.Colors.primary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConversationView(scenario: .restaurant, cefrLevel: .a1, mode: .beginner)
    }
}
