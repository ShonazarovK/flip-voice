import SwiftUI
import AVFoundation

public struct ChallengeView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @StateObject private var recorder = AudioRecorder()
    
    // Steps 1 to 4
    @State private var currentStep: Int = 1
    
    // Audio URLs
    @State private var originalRecordingURL: URL?
    @State private var reversedPhraseURL: URL?
    @State private var imitationRecordingURL: URL?
    @State private var flippedResultURL: URL?
    
    // Active player nodes for challenge
    @State private var originalPlayer: AVAudioPlayer?
    @State private var reversedPlayer: AVAudioPlayer?
    @State private var imitationPlayer: AVAudioPlayer?
    @State private var flippedPlayer: AVAudioPlayer?
    
    @State private var isOriginalPlaying = false
    @State private var isReversedPlaying = false
    @State private var isImitationPlaying = false
    @State private var isFlippedPlaying = false
    
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Text(localization.localized(.challengeTitle))
                            .font(.title2.weight(.bold))
                        Text(localization.localized(.challengeSubtitle))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 10)
                    
                    // Step Progress Indicator
                    HStack(spacing: 12) {
                        ForEach(1...4, id: \.self) { step in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(currentStep >= step ? Color.purple : Color.secondary.opacity(0.3))
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Text("\(step)")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(Color.white)
                                    )
                                if step < 4 {
                                    Rectangle()
                                        .fill(currentStep > step ? Color.purple : Color.secondary.opacity(0.3))
                                        .frame(height: 2)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Card for Step 1
                    StepCard(
                        stepNumber: 1,
                        title: localization.localized(.step1Record),
                        isActive: currentStep == 1,
                        isCompleted: currentStep > 1
                    ) {
                        VStack(spacing: 12) {
                            if recorder.isRecording && currentStep == 1 {
                                Button {
                                    finishStep1Recording()
                                } label: {
                                    Label("Stop Recording", systemImage: "stop.circle.fill")
                                        .font(.headline)
                                        .foregroundStyle(Color.red)
                                }
                            } else if currentStep == 1 {
                                Button {
                                    startStep1Recording()
                                } label: {
                                    Label("Record Original Phrase", systemImage: "mic.fill")
                                        .font(.headline)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .background(Color.purple)
                                        .foregroundStyle(Color.white)
                                        .clipShape(Capsule())
                                }
                            }
                            
                            if let _ = originalRecordingURL {
                                Button {
                                    playOriginal()
                                } label: {
                                    Label(isOriginalPlaying ? "Pause Original" : "Listen to Original", systemImage: isOriginalPlaying ? "pause.fill" : "play.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.purple)
                                }
                            }
                        }
                    }
                    
                    // Card for Step 2
                    if currentStep >= 2 {
                        StepCard(
                            stepNumber: 2,
                            title: localization.localized(.step2ListenReversed),
                            isActive: currentStep == 2,
                            isCompleted: currentStep > 2
                        ) {
                            VStack(spacing: 12) {
                                Text("Listen closely to how this sounds backwards, and try to mimic these sounds:")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                
                                Button {
                                    playReversed()
                                } label: {
                                    HStack {
                                        Image(systemName: isReversedPlaying ? "pause.circle.fill" : "play.circle.fill")
                                            .font(.title2)
                                        Text(isReversedPlaying ? "Pause Reversed" : "Play Reversed Sound")
                                            .font(.headline)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(Color.orange)
                                    .foregroundStyle(Color.white)
                                    .clipShape(Capsule())
                                }
                                
                                if currentStep == 2 {
                                    Button("I'm Ready to Imitate ->") {
                                        currentStep = 3
                                    }
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(Color.cyan)
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Card for Step 3
                    if currentStep >= 3 {
                        StepCard(
                            stepNumber: 3,
                            title: localization.localized(.step3Imitate),
                            isActive: currentStep == 3,
                            isCompleted: currentStep > 3
                        ) {
                            VStack(spacing: 12) {
                                Text("Now say the backwards sound into the microphone:")
                                    .font(.caption)
                                    .foregroundStyle(Color.secondary)
                                
                                if recorder.isRecording && currentStep == 3 {
                                    Button {
                                        finishStep3Recording()
                                    } label: {
                                        Label("Stop Imitation Recording", systemImage: "stop.circle.fill")
                                            .font(.headline)
                                            .foregroundStyle(Color.red)
                                    }
                                } else if currentStep == 3 {
                                    Button {
                                        startStep3Recording()
                                    } label: {
                                        Label("Record Imitation", systemImage: "mic.fill")
                                            .font(.headline)
                                            .padding(.vertical, 10)
                                            .padding(.horizontal, 20)
                                            .background(Color.pink)
                                            .foregroundStyle(Color.white)
                                            .clipShape(Capsule())
                                    }
                                }
                                
                                if let _ = imitationRecordingURL {
                                    Button {
                                        playImitation()
                                    } label: {
                                        Label(isImitationPlaying ? "Pause Imitation" : "Play Imitation", systemImage: isImitationPlaying ? "pause.fill" : "play.fill")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.pink)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Card for Step 4
                    if currentStep >= 4 {
                        StepCard(
                            stepNumber: 4,
                            title: localization.localized(.step4Reveal),
                            isActive: currentStep == 4,
                            isCompleted: false
                        ) {
                            VStack(spacing: 16) {
                                Text("Here is your imitation flipped back! Does it match the original?")
                                    .font(.subheadline.weight(.medium))
                                    .multilineTextAlignment(.center)
                                
                                HStack(spacing: 16) {
                                    // Original
                                    Button {
                                        playOriginal()
                                    } label: {
                                        VStack {
                                            Image(systemName: isOriginalPlaying ? "pause.fill" : "play.fill")
                                                .font(.title2)
                                            Text("Original")
                                                .font(.caption.weight(.bold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.purple.opacity(0.15))
                                        .foregroundStyle(Color.purple)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                    
                                    // Flipped Result
                                    Button {
                                        playFlipped()
                                    } label: {
                                        VStack {
                                            Image(systemName: isFlippedPlaying ? "pause.fill" : "play.fill")
                                                .font(.title2)
                                            Text("Flipped Imitation")
                                                .font(.caption.weight(.bold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.green.opacity(0.2))
                                        .foregroundStyle(Color.green)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    }
                                }
                                
                                Button {
                                    resetChallenge()
                                } label: {
                                    Text("Try Another Phrase")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.secondary)
                                }
                                .padding(.top, 6)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle(localization.localized(.tabChallenge))
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An error occurred.")
            }
        }
    }
    
    // MARK: - Step 1 Actions
    private func startStep1Recording() {
        Task {
            let granted = await recorder.requestMicrophonePermission()
            guard granted else {
                errorMessage = "Microphone access is required."
                showErrorAlert = true
                return
            }
            do {
                _ = try recorder.startRecording()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func finishStep1Recording() {
        guard let url = recorder.stopRecording() else { return }
        self.originalRecordingURL = url
        
        // Generate reversed audio for Step 2
        let revURL = FileManager.default.temporaryDirectory.appendingPathComponent("challenge_rev_\(UUID().uuidString).wav")
        do {
            try AudioProcessor.shared.reverseAudio(sourceURL: url, destinationURL: revURL)
            self.reversedPhraseURL = revURL
            self.currentStep = 2
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    // MARK: - Step 3 Actions
    private func startStep3Recording() {
        do {
            _ = try recorder.startRecording()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func finishStep3Recording() {
        guard let url = recorder.stopRecording() else { return }
        self.imitationRecordingURL = url
        
        // Reverse imitation for Step 4
        let flippedURL = FileManager.default.temporaryDirectory.appendingPathComponent("challenge_flipped_\(UUID().uuidString).wav")
        do {
            try AudioProcessor.shared.reverseAudio(sourceURL: url, destinationURL: flippedURL)
            self.flippedResultURL = flippedURL
            self.currentStep = 4
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    // MARK: - Playback Helpers
    private func playOriginal() {
        guard let url = originalRecordingURL else { return }
        togglePlay(url: url, player: &originalPlayer, isPlaying: &isOriginalPlaying)
    }
    
    private func playReversed() {
        guard let url = reversedPhraseURL else { return }
        togglePlay(url: url, player: &reversedPlayer, isPlaying: &isReversedPlaying)
    }
    
    private func playImitation() {
        guard let url = imitationRecordingURL else { return }
        togglePlay(url: url, player: &imitationPlayer, isPlaying: &isImitationPlaying)
    }
    
    private func playFlipped() {
        guard let url = flippedResultURL else { return }
        togglePlay(url: url, player: &flippedPlayer, isPlaying: &isFlippedPlaying)
    }
    
    private func togglePlay(url: URL, player: inout AVAudioPlayer?, isPlaying: inout Bool) {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            stopAllPlayers()
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
                isPlaying = true
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func stopAllPlayers() {
        originalPlayer?.stop()
        reversedPlayer?.stop()
        imitationPlayer?.stop()
        flippedPlayer?.stop()
        isOriginalPlaying = false
        isReversedPlaying = false
        isImitationPlaying = false
        isFlippedPlaying = false
    }
    
    private func resetChallenge() {
        stopAllPlayers()
        originalRecordingURL = nil
        reversedPhraseURL = nil
        imitationRecordingURL = nil
        flippedResultURL = nil
        currentStep = 1
    }
}

// Reusable card container for challenge steps
struct StepCard<Content: View>: View {
    let stepNumber: Int
    let title: String
    let isActive: Bool
    let isCompleted: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.green)
                }
            }
            
            content()
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color.purple : AppTheme.cardBorder, lineWidth: isActive ? 1.5 : 1)
        )
    }
}

