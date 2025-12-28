import SwiftUI

/// Push-to-Talk button with visual feedback
/// - Beginner Mode: Hold to talk, release to send
/// - Advanced Mode: Tap to start/stop listening (continuous)
struct PTTButton: View {
    let mode: ConversationMode
    let isRecording: Bool
    let isProcessing: Bool
    let isLocked: Bool
    let audioLevel: Float
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    private let buttonSize: CGFloat = 100

    /// Whether this is toggle mode (Advanced) vs hold mode (Beginner)
    private var isToggleMode: Bool { mode == .advanced }

    var body: some View {
        ZStack {
            // Outer pulse ring (when recording)
            if isRecording {
                pulseRing
            }

            // Main button
            Circle()
                .fill(buttonGradient)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(buttonContent)
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .shadow(
                    color: shadowColor,
                    radius: isRecording ? 20 : 10
                )
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .gesture(isToggleMode ? nil : pttGesture)
        .onTapGesture {
            guard isToggleMode else { return }
            if isRecording {
                onRelease()
            } else if !isLocked {
                onPress()
            }
        }
        .disabled(isLocked && !isRecording)
        .opacity(isLocked && !isRecording ? 0.6 : 1.0)
    }

    // MARK: - Pulse Ring

    private var pulseRing: some View {
        let pulseScale = 1.0 + CGFloat(audioLevel) * 0.3
        return Circle()
            .fill(Theme.Colors.recordingPulse)
            .frame(
                width: buttonSize * pulseScale + 40,
                height: buttonSize * pulseScale + 40
            )
            .animation(.easeInOut(duration: 0.1), value: audioLevel)
    }

    // MARK: - Button Gradient

    private var buttonGradient: LinearGradient {
        if isProcessing {
            return LinearGradient(
                colors: [Theme.Colors.surface, Theme.Colors.surfaceSecondary],
                startPoint: .top,
                endPoint: .bottom
            )
        } else if isRecording {
            return LinearGradient(
                colors: [Theme.Colors.recording, Theme.Colors.recording.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return Theme.Gradients.primaryButton
        }
    }

    // MARK: - Shadow Color

    private var shadowColor: Color {
        if isRecording {
            return Theme.Colors.recording.opacity(0.5)
        } else {
            return Theme.Colors.primary.opacity(0.5)
        }
    }

    // MARK: - Button Content

    @ViewBuilder
    private var buttonContent: some View {
        if isProcessing {
            VStack(spacing: 4) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.textPrimary))
                    .scaleEffect(1.2)

                Text("Thinking...")
                    .font(Theme.Typography.caption2)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        } else {
            VStack(spacing: 4) {
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 32, weight: .medium))

                Text(buttonLabel)
                    .font(Theme.Typography.caption)
            }
            .foregroundColor(.white)
        }
    }

    private var buttonLabel: String {
        if isToggleMode {
            return isRecording ? "Tap to Stop" : "Tap to Start"
        } else {
            return isRecording ? "Release" : "Hold to Talk"
        }
    }

    // MARK: - Gesture

    private var pttGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                guard !isPressed, !isLocked else { return }
                isPressed = true
                onPress()
            }
            .onEnded { _ in
                guard isPressed else { return }
                isPressed = false
                onRelease()
            }
    }
}

// MARK: - Preview

#Preview("Beginner Mode") {
    ZStack {
        Theme.Gradients.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            PTTButton(
                mode: .beginner,
                isRecording: false,
                isProcessing: false,
                isLocked: false,
                audioLevel: 0,
                onPress: {},
                onRelease: {}
            )

            PTTButton(
                mode: .beginner,
                isRecording: true,
                isProcessing: false,
                isLocked: false,
                audioLevel: 0.5,
                onPress: {},
                onRelease: {}
            )
        }
    }
}

#Preview("Advanced Mode") {
    ZStack {
        Theme.Gradients.background
            .ignoresSafeArea()

        VStack(spacing: 40) {
            PTTButton(
                mode: .advanced,
                isRecording: false,
                isProcessing: false,
                isLocked: false,
                audioLevel: 0,
                onPress: {},
                onRelease: {}
            )

            PTTButton(
                mode: .advanced,
                isRecording: true,
                isProcessing: false,
                isLocked: false,
                audioLevel: 0.5,
                onPress: {},
                onRelease: {}
            )
        }
    }
}
