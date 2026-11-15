import Foundation
import AVFoundation

@MainActor
public final class FlipVoiceAudioEngine: ObservableObject, AudioEngineProtocol {
    public static let shared = FlipVoiceAudioEngine()
    
    @Published public var recorder = AudioRecorder()
    @Published public var player = AudioPlayer()
    
    public var isRecording: Bool { recorder.isRecording }
    public var isPlaying: Bool { player.isPlaying }
    public var playbackPosition: TimeInterval { player.currentTime }
    public var playbackDuration: TimeInterval { player.duration }
    
    public var playbackRate: Float {
        get { player.rate }
        set { player.rate = newValue }
    }
    
    public var pitchSemitones: Float {
        get { player.pitchSemitones }
        set { player.pitchSemitones = newValue }
    }
    
    public var isLooping: Bool {
        get { player.isLooping }
        set { player.isLooping = newValue }
    }
    
    public var isReversed: Bool { player.isReversed }
    
    public init() {}
    
    public func requestPermission() async -> Bool {
        await recorder.requestMicrophonePermission()
    }
    
    public func startRecording() throws {
        if player.isPlaying {
            player.stop()
        }
        _ = try recorder.startRecording()
    }
    
    public func pauseRecording() {
        recorder.pauseRecording()
    }
    
    public func resumeRecording() throws {
        recorder.resumeRecording()
    }
    
    public func stopRecording() async throws -> URL {
        guard let url = recorder.stopRecording() else {
            throw AudioProcessorError.renderFailed("No recording URL returned.")
        }
        return url
    }
    
    public func load(url: URL) throws {
        try player.load(originalURL: url)
    }
    
    public func play() {
        player.play()
    }
    
    public func pause() {
        player.pause()
    }
    
    public func stop() {
        player.stop()
    }
    
    public func seek(to time: TimeInterval) {
        player.seek(to: time)
    }
    
    public func toggleReversed() async throws {
        try await player.toggleReversed()
    }
    
    public func export(
        sourceURL: URL,
        reversed: Bool,
        speed: Float,
        pitchSemitones: Float,
        trimRange: ClosedRange<TimeInterval>?,
        fadeInDuration: TimeInterval,
        fadeOutDuration: TimeInterval,
        format: AudioExportFormat
    ) async throws -> URL {
        try await AudioProcessor.shared.exportRender(
            sourceURL: sourceURL,
            reversed: reversed,
            speed: speed,
            pitchSemitones: pitchSemitones,
            trimRange: trimRange,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
            format: format
        )
    }
}

