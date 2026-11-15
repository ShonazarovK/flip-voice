import Foundation
import AVFoundation

/// Protocol defining the high-level capabilities of the FlipVoice audio engine.
public protocol AudioEngineProtocol: AnyObject {
    var isRecording: Bool { get }
    var isPlaying: Bool { get }
    var playbackPosition: TimeInterval { get }
    var playbackDuration: TimeInterval { get }
    var playbackRate: Float { get set }
    var pitchSemitones: Float { get set }
    var isLooping: Bool { get set }
    var isReversed: Bool { get }
    
    // Recording
    func requestPermission() async -> Bool
    func startRecording() throws
    func pauseRecording()
    func resumeRecording() throws
    func stopRecording() async throws -> URL
    
    // Playback
    func load(url: URL) throws
    func play()
    func pause()
    func stop()
    func seek(to time: TimeInterval)
    func toggleReversed() async throws
    
    // Processing & Export
    func export(
        sourceURL: URL,
        reversed: Bool,
        speed: Float,
        pitchSemitones: Float,
        trimRange: ClosedRange<TimeInterval>?,
        fadeInDuration: TimeInterval,
        fadeOutDuration: TimeInterval,
        format: AudioExportFormat
    ) async throws -> URL
}

/// Supported export formats for FlipVoice
public enum AudioExportFormat: String, CaseIterable, Identifiable {
    case m4a = "M4A (AAC)"
    case wav = "WAV (Uncompressed)"
    
    public var id: String { rawValue }
    
    public var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        }
    }
    
    public var utTypeIdentifier: String {
        switch self {
        case .m4a: return "public.mpeg-4-audio"
        case .wav: return "com.microsoft.waveform-audio"
        }
    }
}

