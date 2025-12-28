import SwiftUI

/// Main conversation screen with PTT interface
struct ConversationView: View {
    let scenario: ScenarioContext
    let cefrLevel: CEFRLevel
    let mode: ConversationMode

    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss

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
            Theme.Gradients.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                conversationHeader

                // Messages
                messagesSection

                // Vocabulary Spotlight
                if let vocab = viewModel.vocabularySpotlight {
                    vocabularyCard(vocab)
                }

                // Suggested Responses
                if let suggestions = viewModel.suggestedResponses, !suggestions.isEmpty {
                    suggestionsRow(suggestions)
                }

                // Control buttons - different for Beginner vs Advanced mode
                if mode == .advanced {
                    advancedModeControls
                        .padding(.bottom, Theme.Spacing.xl)
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
                    .padding(.bottom, Theme.Spacing.xl)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("End") {
                    viewModel.cleanup()
                    dismiss()
                }
                .foregroundColor(Theme.Colors.primary)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    translationToggle
                    speedPicker
                }
            }
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
            HStack {
                Image(systemName: scenario.type.icon)
                    .font(.title2)
                Text(scenario.title)
                    .font(Theme.Typography.headline)
            }
            .foregroundColor(Theme.Colors.textPrimary)

            // Mode indicator
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: mode.icon)
                    .font(.caption)
                Text(mode == .advanced ? "Real-time" : "Turn-based")
                    .font(Theme.Typography.caption)
            }
            .foregroundColor(mode == .advanced ? Theme.Colors.primary : Theme.Colors.textSecondary)

            // Progress indicator
            ProgressView(value: viewModel.scenarioProgress.progressPercentage)
                .tint(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.xl)

            Text(scenario.setting)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
        }
        .padding()
        .background(Theme.Colors.surface.opacity(0.5))
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

                    // Live status indicator (Advanced mode - only when active and not locked)
                    if mode == .advanced && viewModel.conversationState == .active && !viewModel.isLocked {
                        listeningIndicator
                    }

                    // Paused indicator (Advanced mode)
                    if mode == .advanced && viewModel.conversationState == .paused {
                        pausedIndicator
                    }

                    // Live transcript (Advanced mode - while recording)
                    if mode == .advanced && !viewModel.liveTranscript.isEmpty {
                        liveTranscriptBubble
                    }

                    // Live tutor response (Advanced mode - streaming)
                    if mode == .advanced && !viewModel.liveTutorText.isEmpty {
                        liveTutorBubble
                    }

                    // Bottom anchor for scrolling
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding()
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
            .onChange(of: viewModel.isRecording) { _ in
                scrollToBottom(proxy: proxy)
            }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }

    // MARK: - Advanced Mode Controls

    @ViewBuilder
    private var advancedModeControls: some View {
        switch viewModel.conversationState {
        case .idle:
            // Start button
            Button {
                viewModel.startRecording()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("Start Conversation")
                        .font(Theme.Typography.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.lg)
                .background(Theme.Gradients.primaryButton)
                .cornerRadius(Theme.CornerRadius.lg)
            }
            .padding(.horizontal, Theme.Spacing.xl)

        case .active:
            // Pause and Stop buttons
            HStack(spacing: Theme.Spacing.lg) {
                // Pause button (disabled when audio playing)
                Button {
                    viewModel.pauseConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(viewModel.isLocked ? Theme.Colors.surface : Theme.Colors.secondary)
                                .frame(width: 70, height: 70)

                            Image(systemName: "pause.fill")
                                .font(.title)
                                .foregroundColor(viewModel.isLocked ? Theme.Colors.textSecondary : .white)
                        }
                        Text("Pause")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
                .disabled(viewModel.isLocked)

                // Recording/Playing indicator
                ZStack {
                    if viewModel.isLocked {
                        // Playing indicator
                        Circle()
                            .fill(Theme.Colors.primary.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Circle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 80, height: 80)

                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    } else {
                        // Recording indicator
                        Circle()
                            .fill(Theme.Colors.recording.opacity(0.2))
                            .frame(width: 100 + CGFloat(viewModel.audioLevel) * 30, height: 100 + CGFloat(viewModel.audioLevel) * 30)
                            .animation(.easeInOut(duration: 0.1), value: viewModel.audioLevel)

                        Circle()
                            .fill(Theme.Colors.recording)
                            .frame(width: 80, height: 80)

                        Image(systemName: "waveform")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }

                // Stop button
                Button {
                    viewModel.stopConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.surface)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.textSecondary, lineWidth: 2)
                                )

                            Image(systemName: "stop.fill")
                                .font(.title)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        Text("Stop")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }

        case .paused:
            // Resume and Stop buttons
            HStack(spacing: Theme.Spacing.xl) {
                // Resume button
                Button {
                    viewModel.resumeConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(Theme.Gradients.primaryButton)
                                .frame(width: 80, height: 80)

                            Image(systemName: "play.fill")
                                .font(.title)
                                .foregroundColor(.white)
                        }
                        Text("Resume")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }

                // Stop button
                Button {
                    viewModel.stopConversation()
                } label: {
                    VStack(spacing: Theme.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.surface)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Theme.Colors.textSecondary, lineWidth: 2)
                                )

                            Image(systemName: "stop.fill")
                                .font(.title)
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                        Text("End")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Live Transcript (Advanced Mode)

    private var listeningIndicator: some View {
        HStack {
            Spacer()
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "waveform")
                    .foregroundColor(Theme.Colors.primary)
                Text("Listening...")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface.opacity(0.8))
            .cornerRadius(Theme.CornerRadius.md)
            Spacer()
        }
    }

    private var pausedIndicator: some View {
        HStack {
            Spacer()
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "pause.circle.fill")
                    .foregroundColor(Theme.Colors.secondary)
                Text("Paused")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface.opacity(0.8))
            .cornerRadius(Theme.CornerRadius.md)
            Spacer()
        }
    }

    private var liveTranscriptBubble: some View {
        HStack {
            Spacer()
            Text(viewModel.liveTranscript)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.primary.opacity(0.3))
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.primary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                )
        }
    }

    private var liveTutorBubble: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(viewModel.liveTutorText)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(Theme.Colors.primary)
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.6))
                        .frame(width: 6, height: 6)
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .cornerRadius(Theme.CornerRadius.md)
            Spacer()
        }
    }

    // MARK: - Vocabulary Card

    private func vocabularyCard(_ vocab: VocabularySpotlight) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(Theme.Colors.secondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("\(vocab.word) - \(vocab.translation)")
                    .font(Theme.Typography.subheadline)
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(vocab.usage)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondary.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.sm)
        .padding(.horizontal)
    }

    // MARK: - Suggestions

    private func suggestionsRow(_ suggestions: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Text(suggestion)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.textPrimary)
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, Theme.Spacing.sm)
    }

    // MARK: - Translation Toggle

    private var translationToggle: some View {
        Button {
            viewModel.showTranslations.toggle()
            HapticManager.selection()
        } label: {
            Image(systemName: viewModel.showTranslations ? "text.bubble.fill" : "text.bubble")
                .font(.body)
                .foregroundColor(viewModel.showTranslations ? Theme.Colors.primary : Theme.Colors.textSecondary)
        }
    }

    // MARK: - Speed Picker

    private var speedPicker: some View {
        Button {
            viewModel.cyclePlaybackSpeed()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "speaker.wave.2")
                Text(String(format: "%.2fx", viewModel.playbackSpeed))
            }
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ConversationView(scenario: .restaurant, cefrLevel: .a1)
    }
}
