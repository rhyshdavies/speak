import SwiftUI

/// Push-to-Talk button with Matrix cyberpunk styling
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
    @State private var glowPulse = false

    private let buttonSize: CGFloat = 88

    /// Whether this is toggle mode (Advanced) vs hold mode (Beginner)
    private var isToggleMode: Bool { mode == .advanced }

    var body: some View {
        ZStack {
            // Outer glow rings
            if isRecording {
                pulseRings
            }

            // Hexagonal glow background
            hexagonGlow
                .opacity(isRecording ? 0.8 : 0.3)

            // Main hexagonal button
            hexagonButton
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
        .opacity(isLocked && !isRecording ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Pulse Rings (Recording)

    private var pulseRings: some View {
        let pulseScale = 1.0 + CGFloat(audioLevel) * 0.3
        return ZStack {
            // Outer ring
            Circle()
                .stroke(Theme.Colors.recording.opacity(0.3), lineWidth: 2)
                .frame(width: buttonSize * pulseScale + 48, height: buttonSize * pulseScale + 48)

            // Middle ring
            Circle()
                .stroke(Theme.Colors.recording.opacity(0.5), lineWidth: 1)
                .frame(width: buttonSize * pulseScale + 32, height: buttonSize * pulseScale + 32)

            // Inner glow
            Circle()
                .fill(Theme.Colors.recordingPulse)
                .frame(width: buttonSize * pulseScale + 16, height: buttonSize * pulseScale + 16)
        }
        .animation(.easeInOut(duration: 0.1), value: audioLevel)
    }

    // MARK: - Hexagon Glow Background

    private var hexagonGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        glowColor.opacity(0.4),
                        glowColor.opacity(0.1),
                        .clear
                    ],
                    center: .center,
                    startRadius: buttonSize * 0.3,
                    endRadius: buttonSize * 0.8
                )
            )
            .frame(width: buttonSize + 40, height: buttonSize + 40)
            .scaleEffect(glowPulse ? 1.1 : 1.0)
    }

    // MARK: - Hexagonal Button

    private var hexagonButton: some View {
        ZStack {
            // Background circle with border
            Circle()
                .fill(Theme.Colors.surface)
                .frame(width: buttonSize, height: buttonSize)
                .overlay(
                    Circle()
                        .stroke(buttonBorderColor, lineWidth: 2)
                )
                .shadow(color: glowColor, radius: isRecording ? 16 : 8, y: 0)

            // Inner content
            buttonContent
        }
        .scaleEffect(isPressed ? 0.92 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Colors

    private var buttonBorderColor: Color {
        if isProcessing {
            return Theme.Colors.textTertiary
        } else if isRecording {
            return Theme.Colors.recording
        } else {
            return Theme.Colors.primary
        }
    }

    private var glowColor: Color {
        if isRecording {
            return Theme.Colors.recording
        } else {
            return Theme.Colors.primary
        }
    }

    // MARK: - Button Content

    @ViewBuilder
    private var buttonContent: some View {
        if isProcessing {
            VStack(spacing: 6) {
                // Matrix-style loading
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Rectangle()
                            .fill(Theme.Colors.primary)
                            .frame(width: 4, height: 16)
                            .opacity(Double(i + 1) * 0.3)
                    }
                }

                Text("PROCESSING")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        } else {
            VStack(spacing: 6) {
                // Icon with glow
                Image(systemName: isRecording ? "waveform" : "mic.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isRecording ? Theme.Colors.recording : Theme.Colors.primary)
                    .shadow(color: glowColor.opacity(0.8), radius: 4, y: 0)

                // Terminal-style label
                Text(buttonLabel.uppercased())
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isRecording ? Theme.Colors.recording : Theme.Colors.primary)
            }
        }
    }

    private var buttonLabel: String {
        if isToggleMode {
            return isRecording ? ">> STOP" : ">> START"
        } else {
            return isRecording ? "RELEASE" : "HOLD"
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

#Preview("Matrix PTT Button") {
    ZStack {
        Theme.Colors.background
            .ignoresSafeArea()

        VStack(spacing: 60) {
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
                audioLevel: 0.6,
                onPress: {},
                onRelease: {}
            )

            PTTButton(
                mode: .beginner,
                isRecording: false,
                isProcessing: true,
                isLocked: false,
                audioLevel: 0,
                onPress: {},
                onRelease: {}
            )
        }
    }
}
