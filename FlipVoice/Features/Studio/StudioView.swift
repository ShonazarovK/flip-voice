import SwiftUI
import UniformTypeIdentifiers

public struct StudioView: View {
    @ObservedObject var audioEngine: FlipVoiceAudioEngine
    @ObservedObject var localization = LocalizationManager.shared
    
    @Binding var selectedTab: Int
    @Binding var currentActiveURL: URL?
    
    @State private var hasPermission = true
    @State private var showPermissionAlert = false
    @State private var showFileImporter = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    public init(
        audioEngine: FlipVoiceAudioEngine,
        selectedTab: Binding<Int>,
        currentActiveURL: Binding<URL?>
    ) {
        self.audioEngine = audioEngine
        self._selectedTab = selectedTab
        self._currentActiveURL = currentActiveURL
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header status
                VStack(spacing: 8) {
                    Text(statusTitle)
                        .font(.title2.weight(.bold))
                    
                    Text(formattedTimer)
                        .font(.system(size: 48, weight: .semibold, design: .monospaced))
                        .foregroundStyle(audioEngine.recorder.isRecording ? Color.red : Color.primary)
                }
                .padding(.top, 20)
                
                // Live Waveform Visualizer
                LiveWaveformView(
                    amplitudes: audioEngine.recorder.liveWaveformLevels,
                    barColor: audioEngine.recorder.isRecording ? .red : .cyan
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                
                Spacer()
                
                // Action Controls
                if audioEngine.recorder.isRecording || audioEngine.recorder.isPaused {
                    HStack(spacing: 36) {
                        // Pause / Resume
                        Button {
                            if audioEngine.recorder.isPaused {
                                try? audioEngine.resumeRecording()
                            } else {
                                audioEngine.pauseRecording()
                            }
                        } label: {
                            Image(systemName: audioEngine.recorder.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 54))
                                .foregroundStyle(Color.orange)
                        }
                        
                        // Finish & Edit
                        Button {
                            finishRecording()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(Color.green)
                                Text(localization.localized(.stopAndEdit))
                                    .font(.caption.weight(.medium))
                            }
                        }
                    }
                    .padding(.bottom, 20)
                } else {
                    // Big Record Button
                    VStack(spacing: 16) {
                        Button {
                            handleRecordTap()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 110, height: 110)
                                
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: Color.red.opacity(0.4), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(Color.white)
                            }
                        }
                        
                        Text(localization.localized(.recordTapToStart))
                            .font(.subheadline)
                            .foregroundStyle(Color.secondary)
                    }
                    .padding(.bottom, 10)
                }
                
                Divider()
                    .padding(.horizontal)
                
                // Import Audio File Button
                Button {
                    showFileImporter = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text(localization.localized(.importAudio))
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(AppTheme.cardBackground)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(AppTheme.cardBorder, lineWidth: 1))
                }
                .disabled(audioEngine.recorder.isRecording)
                .padding(.bottom, 24)
            }
            .navigationTitle(localization.localized(.tabStudio))
            .navigationBarTitleDisplayMode(.inline)
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.audio, .movie, .quickTimeMovie, .mpeg4Movie],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result: result)
            }
            .alert(localization.localized(.permissionNeeded), isPresented: $showPermissionAlert) {
                Button(localization.localized(.openSettings)) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button(localization.localized(.cancel), role: .cancel) {}
            } message: {
                Text(localization.localized(.permissionDesc))
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    private var statusTitle: String {
        if audioEngine.recorder.isRecording {
            return localization.localized(.recording)
        } else if audioEngine.recorder.isPaused {
            return localization.localized(.paused)
        } else {
            return localization.localized(.recordTapToStart)
        }
    }
    
    private var formattedTimer: String {
        let dur = audioEngine.recorder.recordingDuration
        let mins = Int(dur) / 60
        let secs = Int(dur) % 60
        let tenths = Int((dur.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%02d:%02d.%d", mins, secs, tenths)
    }
    
    private func handleRecordTap() {
        Task {
            let granted = await audioEngine.requestPermission()
            if granted {
                do {
                    try audioEngine.startRecording()
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            } else {
                showPermissionAlert = true
            }
        }
    }
    
    private func finishRecording() {
        Task {
            do {
                let recordedURL = try await audioEngine.stopRecording()
                self.currentActiveURL = recordedURL
                try audioEngine.load(url: recordedURL)
                // Switch to Editor tab
                self.selectedTab = 1
            } catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
    
    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let selected = urls.first else { return }
            
            isImporting = true
            Task {
                guard selected.startAccessingSecurityScopedResource() else {
                    errorMessage = "Permission denied to access selected file."
                    showErrorAlert = true
                    isImporting = false
                    return
                }
                
                defer { selected.stopAccessingSecurityScopedResource() }
                
                do {
                    let converted = try await AudioAssetExtractor.shared.convertToStandardWAV(sourceURL: selected)
                    self.currentActiveURL = converted
                    try audioEngine.load(url: converted)
                    self.selectedTab = 1
                } catch {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
                isImporting = false
            }
            
        case .failure(let error):
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}

