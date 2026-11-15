import Foundation
import AVFoundation

@MainActor
public final class AudioPlayer: ObservableObject {
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 0.0
    @Published public var isLooping: Bool = false
    @Published public var isReversed: Bool = false
    
    @Published public var rate: Float = 1.0 {
        didSet {
            pitchNode.rate = max(0.5, min(2.0, rate))
        }
    }
    
    @Published public var pitchSemitones: Float = 0.0 {
        didSet {
            pitchNode.pitch = max(-2400.0, min(2400.0, pitchSemitones * 100.0))
        }
    }
    
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let pitchNode = AVAudioUnitTimePitch()
    
    private var currentOriginalURL: URL?
    private var currentReversedURL: URL?
    private var activeAudioFile: AVAudioFile?
    private var seekFrameOffset: AVAudioFramePosition = 0
    private var timer: Timer?
    
    public init() {
        setupEngine()
    }
    
    private func setupEngine() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
        try? session.setActive(true)
        
        engine.attach(playerNode)
        engine.attach(pitchNode)
        
        let format = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(playerNode, to: pitchNode, format: format)
        engine.connect(pitchNode, to: engine.mainMixerNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("AudioEngine start failed: \(error)")
        }
    }
    
    public func load(originalURL: URL) throws {
        self.currentOriginalURL = originalURL
        self.currentReversedURL = nil
        self.isReversed = false
        
        try loadFile(url: originalURL)
    }
    
    private func loadFile(url: URL) throws {
        stop()
        
        let file = try AVAudioFile(forReading: url)
        self.activeAudioFile = file
        self.duration = Double(file.length) / file.processingFormat.sampleRate
        self.currentTime = 0.0
        self.seekFrameOffset = 0
    }
    
    public func toggleReversed() async throws {
        guard let originalURL = currentOriginalURL else { return }
        let wasPlaying = isPlaying
        let prevTimeFraction = duration > 0 ? (currentTime / duration) : 0
        
        stop()
        
        if !isReversed {
            // Need reversed version
            if currentReversedURL == nil {
                let tempRev = FileManager.default.temporaryDirectory
                    .appendingPathComponent("rev_cache_\(UUID().uuidString).wav")
                try AudioProcessor.shared.reverseAudio(sourceURL: originalURL, destinationURL: tempRev)
                self.currentReversedURL = tempRev
            }
            if let revURL = currentReversedURL {
                try loadFile(url: revURL)
                self.isReversed = true
            }
        } else {
            // Revert to original forward version
            try loadFile(url: originalURL)
            self.isReversed = false
        }
        
        // Invert relative time position
        let newTargetTime = duration * (1.0 - prevTimeFraction)
        seek(to: max(0.0, min(duration, newTargetTime)))
        
        if wasPlaying {
            play()
        }
    }
    
    public func play() {
        guard let file = activeAudioFile else { return }
        
        if !engine.isRunning {
            try? engine.start()
        }
        
        scheduleSegment(from: seekFrameOffset)
        playerNode.play()
        isPlaying = true
        startPositionTracker()
    }
    
    public func pause() {
        guard isPlaying else { return }
        
        // Calculate offset before pausing
        if let lastRenderTime = playerNode.lastRenderTime,
           let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) {
            seekFrameOffset += playerTime.sampleTime
        }
        
        playerNode.pause()
        isPlaying = false
        stopPositionTracker()
    }
    
    public func stop() {
        playerNode.stop()
        isPlaying = false
        seekFrameOffset = 0
        currentTime = 0.0
        stopPositionTracker()
    }
    
    public func seek(to time: TimeInterval) {
        guard let file = activeAudioFile else { return }
        let wasPlaying = isPlaying
        
        playerNode.stop()
        
        let targetFrame = AVAudioFramePosition(time * file.processingFormat.sampleRate)
        seekFrameOffset = max(0, min(targetFrame, file.length))
        currentTime = time
        
        if wasPlaying {
            scheduleSegment(from: seekFrameOffset)
            playerNode.play()
        }
    }
    
    private func scheduleSegment(from startFrame: AVAudioFramePosition) {
        guard let file = activeAudioFile else { return }
        
        let totalFrames = file.length
        guard startFrame < totalFrames else {
            if isLooping {
                seekFrameOffset = 0
                currentTime = 0.0
                scheduleSegment(from: 0)
            } else {
                stop()
            }
            return
        }
        
        let frameCount = AVAudioFrameCount(totalFrames - startFrame)
        playerNode.scheduleSegment(
            file,
            startingFrame: startFrame,
            frameCount: frameCount,
            at: nil
        ) { [weak self] in
            Task { @MainActor in
                guard let self = self else { return }
                if self.isLooping && self.isPlaying {
                    self.seekFrameOffset = 0
                    self.currentTime = 0.0
                    self.scheduleSegment(from: 0)
                } else if self.isPlaying {
                    self.stop()
                }
            }
        }
    }
    
    private func startPositionTracker() {
        stopPositionTracker()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let file = self.activeAudioFile, self.isPlaying else { return }
            
            if let lastRenderTime = self.playerNode.lastRenderTime,
               let playerTime = self.playerNode.playerTime(forNodeTime: lastRenderTime) {
                let currentFrame = self.seekFrameOffset + playerTime.sampleTime
                let time = Double(currentFrame) / file.processingFormat.sampleRate
                self.currentTime = max(0.0, min(self.duration, time))
            }
        }
    }
    
    private func stopPositionTracker() {
        timer?.invalidate()
        timer = nil
    }
}

