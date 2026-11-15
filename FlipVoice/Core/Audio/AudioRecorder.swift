import Foundation
import AVFoundation

@MainActor
public final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published public var isRecording = false
    @Published public var isPaused = false
    @Published public var recordingDuration: TimeInterval = 0.0
    @Published public var liveMeterLevel: Float = 0.0
    @Published public var liveWaveformLevels: [Float] = []
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var currentRecordingURL: URL?
    
    public override init() {
        super.init()
    }
    
    public func requestMicrophonePermission() async -> Bool {
        if #available(iOS 17.0, *) {
            return await AVAudioApplication.requestRecordPermission()
        } else {
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
    
    public func startRecording() throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        let filename = "rec_\(UUID().uuidString).wav"
        let outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        self.currentRecordingURL = outputURL
        
        // 16-bit PCM Linear WAV at 44.1 kHz
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false
        ]
        
        let recorder = try AVAudioRecorder(url: outputURL, settings: settings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        
        guard recorder.record() else {
            throw AudioProcessorError.renderFailed("Audio recorder failed to start.")
        }
        
        self.audioRecorder = recorder
        self.isRecording = true
        self.isPaused = false
        self.recordingDuration = 0.0
        self.liveWaveformLevels.removeAll()
        
        startTimer()
        return outputURL
    }
    
    public func pauseRecording() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }
        recorder.pause()
        isPaused = true
        timer?.invalidate()
    }
    
    public func resumeRecording() {
        guard let recorder = audioRecorder, !recorder.isRecording else { return }
        recorder.record()
        isPaused = false
        startTimer()
    }
    
    public func stopRecording() -> URL? {
        timer?.invalidate()
        timer = nil
        
        audioRecorder?.stop()
        audioRecorder = nil
        
        isRecording = false
        isPaused = false
        
        return currentRecordingURL
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let recorder = self.audioRecorder, recorder.isRecording else { return }
            recorder.updateMeters()
            
            let power = recorder.averagePower(forChannel: 0)
            // Map dB from [-60, 0] to [0.05, 1.0]
            let normalized = max(0.05, min(1.0, (power + 60.0) / 60.0))
            
            Task { @MainActor in
                self.liveMeterLevel = normalized
                self.recordingDuration = recorder.currentTime
                self.liveWaveformLevels.append(normalized)
                if self.liveWaveformLevels.count > 60 {
                    self.liveWaveformLevels.removeFirst()
                }
            }
        }
    }
}

