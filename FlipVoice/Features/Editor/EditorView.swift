import SwiftUI
import UniformTypeIdentifiers

public struct EditorView: View {
    @ObservedObject var audioEngine: FlipVoiceAudioEngine
    @ObservedObject var libraryManager = LibraryManager.shared
    @ObservedObject var localization = LocalizationManager.shared
    
    @Binding var currentActiveURL: URL?
    
    @State private var waveformData: [Float] = []
    @State private var trimStart: TimeInterval = 0.0
    @State private var trimEnd: TimeInterval = 1.0
    @State private var fadeInDuration: TimeInterval = 0.0
    @State private var fadeOutDuration: TimeInterval = 0.0
    
    @State private var isExporting = false
    @State private var exportOutputURL: URL?
    @State private var showShareSheet = false
    
    @State private var showSaveSheet = false
    @State private var saveTitle = ""
    @State private var saveSuccessAlert = false
    
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    public init(audioEngine: FlipVoiceAudioEngine, currentActiveURL: Binding<URL?>) {
        self.audioEngine = audioEngine
        self._currentActiveURL = currentActiveURL
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let url = currentActiveURL {
                        // Waveform and Trim View
                        WaveformTrimView(
                            waveform: waveformData,
                            duration: audioEngine.player.duration,
                            currentTime: audioEngine.player.currentTime,
                            trimStart: $trimStart,
                            trimEnd: $trimEnd
                        ) { seekTime in
                            audioEngine.seek(to: seekTime)
                        }
                        .padding(.horizontal)
                        
                        // Time readout
                        HStack {
                            Text(formatTime(audioEngine.player.currentTime))
                                .font(.caption.monospaced().weight(.semibold))
                            Spacer()
                            Text(formatTime(audioEngine.player.duration))
                                .font(.caption.monospaced())
                                .foregroundStyle(Color.secondary)
                        }
                        .padding(.horizontal)
                        
                        // Main Transport Controls
                        HStack(spacing: 24) {
                            // Reverse Toggle Button
                            Button {
                                toggleReversal()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.system(size: 24, weight: .bold))
                                        .rotationEffect(audioEngine.player.isReversed ? .degrees(180) : .zero)
                                        .animation(.spring(response: 0.3), value: audioEngine.player.isReversed)
                                    Text(audioEngine.player.isReversed ? localization.localized(.reverse) : localization.localized(.forward))
                                        .font(.caption2.weight(.bold))
                                }
                                .frame(width: 70, height: 60)
                                .background(audioEngine.player.isReversed ? Color.purple.opacity(0.2) : AppTheme.cardBackground)
                                .foregroundStyle(audioEngine.player.isReversed ? Color.purple : Color.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(audioEngine.player.isReversed ? Color.purple : AppTheme.cardBorder, lineWidth: 1.5)
                                )
                            }
                            
                            // Play / Pause Button
                            Button {
                                if audioEngine.player.isPlaying {
                                    audioEngine.pause()
                                } else {
                                    audioEngine.play()
                                }
                            } label: {
                                Image(systemName: audioEngine.player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(Color.cyan)
                            }
                            
                            // Loop Toggle Button
                            Button {
                                audioEngine.player.isLooping.toggle()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "repeat")
                                        .font(.system(size: 24, weight: .bold))
                                    Text(localization.localized(.loop))
                                        .font(.caption2.weight(.bold))
                                }
                                .frame(width: 70, height: 60)
                                .background(audioEngine.player.isLooping ? Color.orange.opacity(0.2) : AppTheme.cardBackground)
                                .foregroundStyle(audioEngine.player.isLooping ? Color.orange : Color.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(audioEngine.player.isLooping ? Color.orange : AppTheme.cardBorder, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        
                        // Sliders for Speed, Pitch, Fades
                        AudioControlSliders(
                            speed: $audioEngine.player.rate,
                            pitchSemitones: $audioEngine.player.pitchSemitones,
                            fadeIn: $fadeInDuration,
                            fadeOut: $fadeOutDuration
                        )
                        .padding(.horizontal)
                        
                        // Bottom Action Buttons
                        HStack(spacing: 16) {
                            // Save to Library
                            Button {
                                saveTitle = "Recording \(libraryManager.items.count + 1)"
                                showSaveSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark.fill")
                                    Text(localization.localized(.saveToLibrary))
                                }
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder, lineWidth: 1))
                            }
                            
                            // Export & Share
                            Button {
                                exportAndShare()
                            } label: {
                                HStack {
                                    if isExporting {
                                        ProgressView()
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "square.and.arrow.up.fill")
                                    }
                                    Text(localization.localized(.exportShare))
                                }
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.cyan)
                                .foregroundStyle(Color.black)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(isExporting)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        
                    } else {
                        // Empty state placeholder
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.circle")
                                .font(.system(size: 72))
                                .foregroundStyle(Color.secondary)
                            Text("No Audio Selected")
                                .font(.title3.weight(.bold))
                            Text("Record or import audio in the Studio to begin reversing and editing.")
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color.secondary)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 80)
                    }
                }
            }
            .navigationTitle(localization.localized(.tabEditor))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                refreshWaveform()
            }
            .onChange(of: currentActiveURL) { _ in
                refreshWaveform()
            }
            .sheet(isPresented: $showSaveSheet) {
                NavigationStack {
                    Form {
                        Section("Title") {
                            TextField("Enter title", text: $saveTitle)
                        }
                    }
                    .navigationTitle(localization.localized(.saveToLibrary))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(localization.localized(.cancel)) {
                                showSaveSheet = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                performSave()
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.35)])
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportOutputURL {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Saved", isPresented: $saveSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Audio successfully saved to Library.")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private func refreshWaveform() {
        guard let url = currentActiveURL else { return }
        Task {
            let samples = await WaveformExtractor.shared.extractWaveform(from: url, targetCount: 64)
            await MainActor.run {
                self.waveformData = samples
                self.trimStart = 0.0
                self.trimEnd = max(0.1, audioEngine.player.duration)
            }
        }
    }
    
    private func toggleReversal() {
        Task {
            do {
                try await audioEngine.toggleReversed()
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func performSave() {
        guard let sourceURL = currentActiveURL else { return }
        do {
            _ = try libraryManager.saveAudio(
                from: sourceURL,
                title: saveTitle,
                tag: audioEngine.player.isReversed ? .reversed : .recording,
                isReversed: audioEngine.player.isReversed
            )
            showSaveSheet = false
            saveSuccessAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func exportAndShare() {
        guard let source = currentActiveURL else { return }
        isExporting = true
        
        let trimRange: ClosedRange<TimeInterval>? = (trimEnd < audioEngine.player.duration - 0.05 || trimStart > 0.05)
            ? (trimStart...trimEnd)
            : nil
        
        Task {
            do {
                let formatChoice: AudioExportFormat = UserDefaults.standard.string(forKey: "export_format") == AudioExportFormat.wav.rawValue ? .wav : .m4a
                
                let exportedURL = try await audioEngine.export(
                    sourceURL: source,
                    reversed: audioEngine.player.isReversed,
                    speed: audioEngine.player.rate,
                    pitchSemitones: audioEngine.player.pitchSemitones,
                    trimRange: trimRange,
                    fadeInDuration: fadeInDuration,
                    fadeOutDuration: fadeOutDuration,
                    format: formatChoice
                )
                self.exportOutputURL = exportedURL
                self.isExporting = false
                self.showShareSheet = true
            } catch {
                self.isExporting = false
                self.errorMessage = error.localizedDescription
                self.showErrorAlert = true
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let mins = Int(time) / 60
        let secs = Int(time) % 60
        let tenths = Int((time.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, tenths)
    }
}

// UIKit UIActivityViewController wrapper
public struct ShareSheet: UIViewControllerRepresentable {
    public let activityItems: [Any]
    
    public init(activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

