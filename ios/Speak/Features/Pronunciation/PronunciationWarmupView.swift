import SwiftUI
import AVFoundation

/// 60-second pronunciation warmup - listen, repeat, compare
struct PronunciationWarmupView: View {
    let level: CEFRLevel

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PronunciationViewModel

    init(level: CEFRLevel) {
        self.level = level
        _viewModel = StateObject(wrappedValue: PronunciationViewModel(level: level))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                if viewModel.isComplete {
                    completionView
                } else {
                    practiceView
                }
            }
            .navigationTitle("Pronunciation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }

    // MARK: - Practice View

    private var practiceView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Progress
            progressIndicator

            Spacer()

            // Current phrase card
            phraseCard

            Spacer()

            // User's attempt
            if let transcript = viewModel.userTranscript {
                userAttemptCard(transcript)
            }

            // Controls
            controlButtons

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(0..<viewModel.phrases.count, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.currentIndex ? Theme.Colors.success :
                              index == viewModel.currentIndex ? Theme.Colors.primary :
                              Theme.Colors.textTertiary.opacity(0.3))
                        .frame(width: 10, height: 10)
                }
            }

            Text("Phrase \(viewModel.currentIndex + 1) of \(viewModel.phrases.count)")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }

    // MARK: - Phrase Card

    private var phraseCard: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Spanish phrase
            Text(viewModel.currentPhrase.spanish)
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)

            // English translation
            Text(viewModel.currentPhrase.english)
                .font(Theme.Typography.subheadline)
                .foregroundColor(Theme.Colors.textSecondary)
                .italic()

            // Play button
            Button {
                HapticManager.selection()
                viewModel.playPhrase()
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: viewModel.isPlayingAudio ? "speaker.wave.2.fill" : "play.fill")
                    Text(viewModel.isPlayingAudio ? "Playing..." : "Listen")
                }
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primary)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(Theme.Colors.primary.opacity(0.1))
                .clipShape(Capsule())
            }
            .disabled(viewModel.isPlayingAudio)
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

    // MARK: - User Attempt Card

    private func userAttemptCard(_ transcript: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("You said:")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.textSecondary)

            Text(transcript)
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.textPrimary)

            // Simple match indicator
            if viewModel.isGoodAttempt {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)
                    Text("Good pronunciation!")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.success)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(viewModel.isGoodAttempt
            ? Theme.Colors.success.opacity(0.1)
            : Theme.Colors.surfaceSecondary
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Record button
            if viewModel.userTranscript == nil {
                Button {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(viewModel.isRecording ? Theme.Colors.recording : Theme.Colors.primary)
                            .frame(width: 72, height: 72)

                        Image(systemName: viewModel.isRecording ? "stop.fill" : "mic.fill")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.isPlayingAudio)

                Text(viewModel.isRecording ? "Tap to stop" : "Tap to speak")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.textSecondary)
            } else {
                // Try again / Next buttons
                HStack(spacing: Theme.Spacing.lg) {
                    Button {
                        HapticManager.selection()
                        viewModel.tryAgain()
                    } label: {
                        Text("Try Again")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.textSecondary)
                            .padding(.horizontal, Theme.Spacing.lg)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.surfaceSecondary)
                            .clipShape(Capsule())
                    }

                    Button {
                        HapticManager.mediumTap()
                        viewModel.nextPhrase()
                    } label: {
                        Text(viewModel.currentIndex == viewModel.phrases.count - 1 ? "Finish" : "Next")
                            .font(Theme.Typography.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, Theme.Spacing.xl)
                            .padding(.vertical, Theme.Spacing.md)
                            .background(Theme.Colors.primary)
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Theme.Colors.success.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.success)
            }

            Text("Nice work!")
                .font(Theme.Typography.title)
                .foregroundColor(Theme.Colors.textPrimary)

            Text("\(viewModel.phrases.count) phrases practiced")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            PrimaryButton("Done") {
                StreakManager.shared.recordSession(durationSeconds: 60)  // ~1 minute warmup
                dismiss()
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()
        }
        .padding(Theme.Spacing.lg)
    }
}

// MARK: - ViewModel

@MainActor
final class PronunciationViewModel: ObservableObject {
    @Published var currentIndex: Int = 0
    @Published var userTranscript: String?
    @Published var isRecording: Bool = false
    @Published var isPlayingAudio: Bool = false
    @Published var isComplete: Bool = false

    let phrases: [PracticePhrase]

    private let audioRecorder = AudioRecorderService()
    private let speechSynthesizer = AVSpeechSynthesizer()

    init(level: CEFRLevel) {
        self.phrases = PracticePhrase.phrases(for: level)
    }

    var currentPhrase: PracticePhrase {
        phrases[currentIndex]
    }

    var isGoodAttempt: Bool {
        guard let transcript = userTranscript else { return false }
        // Simple comparison - normalize and check similarity
        let normalized = transcript.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ñ", with: "n")
            .replacingOccurrences(of: "¿", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "¡", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")

        let target = currentPhrase.spanish.lowercased()
            .replacingOccurrences(of: "á", with: "a")
            .replacingOccurrences(of: "é", with: "e")
            .replacingOccurrences(of: "í", with: "i")
            .replacingOccurrences(of: "ó", with: "o")
            .replacingOccurrences(of: "ú", with: "u")
            .replacingOccurrences(of: "ñ", with: "n")
            .replacingOccurrences(of: "¿", with: "")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "¡", with: "")
            .replacingOccurrences(of: "!", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: ".", with: "")

        // Check if at least 60% of words match
        let targetWords = Set(target.split(separator: " ").map(String.init))
        let spokenWords = Set(normalized.split(separator: " ").map(String.init))
        let matchCount = targetWords.intersection(spokenWords).count
        return Double(matchCount) / Double(targetWords.count) >= 0.6
    }

    func playPhrase() {
        isPlayingAudio = true
        let utterance = AVSpeechUtterance(string: currentPhrase.spanish)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)

        // Simple completion (AVSpeechSynthesizer doesn't have easy callbacks)
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(currentPhrase.spanish.count) * 0.08 + 1) {
            self.isPlayingAudio = false
        }
    }

    func startRecording() {
        Task {
            guard await audioRecorder.requestPermission() else { return }
            do {
                try audioRecorder.startRecording()
                isRecording = true
            } catch {
                print("Recording error: \(error)")
            }
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        guard let url = audioRecorder.stopRecording() else { return }
        isRecording = false

        // Transcribe using OpenAI Whisper via basic engine
        Task {
            do {
                let engine = OpenAIBasicEngine()
                // Simple transcription - we just need the text
                let transcript = try await engine.transcribe(audioFileURL: url)
                userTranscript = transcript
                audioRecorder.deleteRecording(at: url)
            } catch {
                print("Transcription error: \(error)")
                userTranscript = "(Could not transcribe)"
            }
        }
    }

    func tryAgain() {
        userTranscript = nil
    }

    func nextPhrase() {
        if currentIndex < phrases.count - 1 {
            currentIndex += 1
            userTranscript = nil
        } else {
            isComplete = true
        }
    }

    func cleanup() {
        speechSynthesizer.stopSpeaking(at: .immediate)
        audioRecorder.cleanup()
    }
}

// MARK: - Practice Phrase Model

struct PracticePhrase: Identifiable {
    let id = UUID()
    let spanish: String
    let english: String

    static func phrases(for level: CEFRLevel) -> [PracticePhrase] {
        switch level {
        case .a1:
            return [
                PracticePhrase(spanish: "Hola, ¿cómo estás?", english: "Hello, how are you?"),
                PracticePhrase(spanish: "Me llamo María.", english: "My name is María."),
                PracticePhrase(spanish: "Mucho gusto.", english: "Nice to meet you."),
                PracticePhrase(spanish: "¿De dónde eres?", english: "Where are you from?"),
                PracticePhrase(spanish: "Gracias, hasta luego.", english: "Thank you, see you later.")
            ]
        case .a2:
            return [
                PracticePhrase(spanish: "Quisiera un café, por favor.", english: "I would like a coffee, please."),
                PracticePhrase(spanish: "¿Cuánto cuesta esto?", english: "How much does this cost?"),
                PracticePhrase(spanish: "¿Dónde está el baño?", english: "Where is the bathroom?"),
                PracticePhrase(spanish: "No entiendo, más despacio.", english: "I don't understand, slower please."),
                PracticePhrase(spanish: "Me gusta mucho esta ciudad.", english: "I really like this city.")
            ]
        case .b1:
            return [
                PracticePhrase(spanish: "¿Podría repetir eso, por favor?", english: "Could you repeat that, please?"),
                PracticePhrase(spanish: "Me gustaría hacer una reservación.", english: "I would like to make a reservation."),
                PracticePhrase(spanish: "¿Qué me recomienda del menú?", english: "What do you recommend from the menu?"),
                PracticePhrase(spanish: "Llevo viviendo aquí tres años.", english: "I've been living here for three years."),
                PracticePhrase(spanish: "Si tuviera tiempo, viajaría más.", english: "If I had time, I would travel more.")
            ]
        case .b2:
            return [
                PracticePhrase(spanish: "A pesar de los obstáculos, lo logré.", english: "Despite the obstacles, I achieved it."),
                PracticePhrase(spanish: "Me habría gustado asistir a la reunión.", english: "I would have liked to attend the meeting."),
                PracticePhrase(spanish: "Es imprescindible que lleguemos a tiempo.", english: "It's essential that we arrive on time."),
                PracticePhrase(spanish: "No me cabe duda de que tendremos éxito.", english: "I have no doubt that we will succeed."),
                PracticePhrase(spanish: "Cuanto antes terminemos, mejor.", english: "The sooner we finish, the better.")
            ]
        case .c1:
            return [
                PracticePhrase(spanish: "Hubiera preferido que me lo dijeras antes.", english: "I would have preferred you told me earlier."),
                PracticePhrase(spanish: "Por mucho que insistas, no cambiaré de opinión.", english: "No matter how much you insist, I won't change my mind."),
                PracticePhrase(spanish: "De haberlo sabido, habría actuado diferente.", english: "Had I known, I would have acted differently."),
                PracticePhrase(spanish: "Sea como fuere, debemos tomar una decisión.", english: "Be that as it may, we must make a decision."),
                PracticePhrase(spanish: "Dicho esto, pasemos al siguiente tema.", english: "That said, let's move on to the next topic.")
            ]
        case .c2:
            return [
                PracticePhrase(spanish: "Quien mucho abarca, poco aprieta.", english: "He who grasps much, holds little. (Proverb)"),
                PracticePhrase(spanish: "A buen entendedor, pocas palabras bastan.", english: "A word to the wise is sufficient."),
                PracticePhrase(spanish: "No hay mal que por bien no venga.", english: "Every cloud has a silver lining."),
                PracticePhrase(spanish: "En casa del herrero, cuchillo de palo.", english: "The cobbler's children go barefoot."),
                PracticePhrase(spanish: "Más vale maña que fuerza.", english: "Brain over brawn.")
            ]
        }
    }
}

// MARK: - OpenAI Transcription Extension

extension OpenAIBasicEngine {
    /// Simple transcription without full turn processing
    func transcribe(audioFileURL: URL) async throws -> String {
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/transcriptions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(AppConfig.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let audioData = try Data(contentsOf: audioFileURL)

        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add model
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Add language hint
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        body.append("es\r\n".data(using: .utf8)!)

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: request)

        struct TranscriptionResponse: Decodable {
            let text: String
        }

        let response = try JSONDecoder().decode(TranscriptionResponse.self, from: data)
        return response.text
    }
}

// MARK: - Preview

#Preview {
    PronunciationWarmupView(level: .a1)
}
