import Foundation
import AVFoundation
import Accelerate

public enum AudioProcessorError: LocalizedError {
    case invalidSourceFile
    case unsupportedFormat
    case renderFailed(String)
    case fileWriteFailed(String)
    case invalidTrimRange
    
    public var errorDescription: String? {
        switch self {
        case .invalidSourceFile:
            return "Unable to open or read source audio file."
        case .unsupportedFormat:
            return "Audio format is not supported for processing."
        case .renderFailed(let details):
            return "Audio processing failed: \(details)"
        case .fileWriteFailed(let details):
            return "Failed to save processed audio: \(details)"
        case .invalidTrimRange:
            return "Invalid trim boundaries specified."
        }
    }
}

/// Core audio processing utility providing frame-correct reversal, trimming, fades, and offline rendering.
public final class AudioProcessor {
    public static let shared = AudioProcessor()
    
    public init() {}
    
    // MARK: - Frame-Correct Audio Reversal
    
    /// Reverses an audio file frame-by-frame, guaranteeing stereo/multichannel frame pairing.
    /// Uses chunk-based reading from the tail of the source file to prevent memory exhaustion on long tracks.
    /// Reversing twice produces bit-exact identical samples.
    public func reverseAudio(sourceURL: URL, destinationURL: URL, chunkSize: AVAudioFrameCount = 32768) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let processingFormat = sourceFile.processingFormat
        let totalFrames = sourceFile.length
        
        guard totalFrames > 0 else {
            throw AudioProcessorError.invalidSourceFile
        }
        
        // Remove destination file if already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        let destinationFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: processingFormat.settings,
            commonFormat: processingFormat.commonFormat,
            interleaved: processingFormat.isInterleaved
        )
        
        var remainingFrames = totalFrames
        let channelCount = Int(processingFormat.channelCount)
        
        while remainingFrames > 0 {
            let framesToRead = min(remainingFrames, AVAudioFramePosition(chunkSize))
            let readStartPos = remainingFrames - framesToRead
            
            sourceFile.framePosition = readStartPos
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: AVAudioFrameCount(framesToRead)) else {
                throw AudioProcessorError.renderFailed("Cannot allocate PCM buffer for reversal chunk.")
            }
            
            try sourceFile.read(into: buffer, frameCount: AVAudioFrameCount(framesToRead))
            
            // In-place reverse buffer frames
            reverseBuffer(buffer, channelCount: channelCount)
            
            try destinationFile.write(from: buffer)
            remainingFrames -= framesToRead
        }
    }
    
    /// In-place reverses an AVAudioPCMBuffer by swapping frames symmetrically
    public func reverseBuffer(_ buffer: AVAudioPCMBuffer, channelCount: Int) {
        let length = Int(buffer.frameLength)
        guard length > 1 else { return }
        
        let halfLength = length / 2
        
        if let floatData = buffer.floatChannelData {
            for ch in 0..<channelCount {
                let channelPtr = floatData[ch]
                for i in 0..<halfLength {
                    let opposite = length - 1 - i
                    let temp = channelPtr[i]
                    channelPtr[i] = channelPtr[opposite]
                    channelPtr[opposite] = temp
                }
            }
        } else if let int16Data = buffer.int16ChannelData {
            for ch in 0..<channelCount {
                let channelPtr = int16Data[ch]
                for i in 0..<halfLength {
                    let opposite = length - 1 - i
                    let temp = channelPtr[i]
                    channelPtr[i] = channelPtr[opposite]
                    channelPtr[opposite] = temp
                }
            }
        }
    }
    
    // MARK: - Trimming and Fades
    
    /// Applies trim and fade-in/fade-out to an audio file
    public func trimAndFade(
        sourceURL: URL,
        destinationURL: URL,
        trimRange: ClosedRange<TimeInterval>?,
        fadeInDuration: TimeInterval = 0.0,
        fadeOutDuration: TimeInterval = 0.0
    ) throws {
        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let format = sourceFile.processingFormat
        let sampleRate = format.sampleRate
        let totalDuration = Double(sourceFile.length) / sampleRate
        
        let startSeconds = max(0.0, trimRange?.lowerBound ?? 0.0)
        let endSeconds = min(totalDuration, trimRange?.upperBound ?? totalDuration)
        
        guard endSeconds > startSeconds else {
            throw AudioProcessorError.invalidTrimRange
        }
        
        let startFrame = AVAudioFramePosition(startSeconds * sampleRate)
        let endFrame = AVAudioFramePosition(endSeconds * sampleRate)
        let framesToProcess = AVAudioFrameCount(endFrame - startFrame)
        
        sourceFile.framePosition = startFrame
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesToProcess) else {
            throw AudioProcessorError.renderFailed("Failed to allocate buffer for trim.")
        }
        
        try sourceFile.read(into: buffer, frameCount: framesToProcess)
        
        // Apply fades
        applyFades(
            buffer: buffer,
            fadeInDuration: fadeInDuration,
            fadeOutDuration: fadeOutDuration,
            sampleRate: sampleRate
        )
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        let destinationFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: format.settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
        
        try destinationFile.write(from: buffer)
    }
    
    private func applyFades(
        buffer: AVAudioPCMBuffer,
        fadeInDuration: TimeInterval,
        fadeOutDuration: TimeInterval,
        sampleRate: Double
    ) {
        let frameCount = Int(buffer.frameLength)
        let channels = Int(buffer.format.channelCount)
        guard frameCount > 0, let floatData = buffer.floatChannelData else { return }
        
        // Fade in
        let fadeInFrames = min(frameCount, Int(fadeInDuration * sampleRate))
        if fadeInFrames > 0 {
            for i in 0..<fadeInFrames {
                let gain = Float(i) / Float(fadeInFrames)
                for ch in 0..<channels {
                    floatData[ch][i] *= gain
                }
            }
        }
        
        // Fade out
        let fadeOutFrames = min(frameCount, Int(fadeOutDuration * sampleRate))
        if fadeOutFrames > 0 {
            let startFrame = frameCount - fadeOutFrames
            for i in 0..<fadeOutFrames {
                let frameIdx = startFrame + i
                let gain = Float(fadeOutFrames - i) / Float(fadeOutFrames)
                for ch in 0..<channels {
                    floatData[ch][frameIdx] *= gain
                }
            }
        }
    }
    
    // MARK: - Full Offline Render with Pitch, Speed, Reversal & Trim
    
    /// Renders an audio asset with all processing parameters applied (reverse, pitch, rate, trim, fades)
    /// to either M4A (AAC) or uncompressed WAV.
    public func exportRender(
        sourceURL: URL,
        reversed: Bool,
        speed: Float,
        pitchSemitones: Float,
        trimRange: ClosedRange<TimeInterval>?,
        fadeInDuration: TimeInterval,
        fadeOutDuration: TimeInterval,
        format: AudioExportFormat,
        progressHandler: ((Double) -> Void)? = nil
    ) async throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        var currentInputURL = sourceURL
        
        // 1. Reversal step if requested
        if reversed {
            let reversedURL = tempDir.appendingPathComponent("rev_\(UUID().uuidString).wav")
            try reverseAudio(sourceURL: currentInputURL, destinationURL: reversedURL)
            currentInputURL = reversedURL
        }
        
        // 2. Pitch / Speed render via AVAudioEngine offline manual rendering
        let hasPitchShift = abs(pitchSemitones) > 0.05
        let hasSpeedChange = abs(speed - 1.0) > 0.02
        
        if hasPitchShift || hasSpeedChange {
            let pitchSpeedRenderURL = tempDir.appendingPathComponent("ps_\(UUID().uuidString).wav")
            try renderPitchAndSpeed(
                sourceURL: currentInputURL,
                destinationURL: pitchSpeedRenderURL,
                speed: speed,
                pitchSemitones: pitchSemitones
            )
            currentInputURL = pitchSpeedRenderURL
        }
        
        // 3. Trim and Fade step
        let hasTrim = trimRange != nil
        let hasFades = fadeInDuration > 0.01 || fadeOutDuration > 0.01
        
        if hasTrim || hasFades {
            let trimmedURL = tempDir.appendingPathComponent("tf_\(UUID().uuidString).wav")
            try trimAndFade(
                sourceURL: currentInputURL,
                destinationURL: trimmedURL,
                trimRange: trimRange,
                fadeInDuration: fadeInDuration,
                fadeOutDuration: fadeOutDuration
            )
            currentInputURL = trimmedURL
        }
        
        // 4. Final format conversion if target is M4A
        let outputFileName = "FlipVoice_\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)"
        let finalOutputURL = tempDir.appendingPathComponent(outputFileName)
        
        if FileManager.default.fileExists(atPath: finalOutputURL.path) {
            try? FileManager.default.removeItem(at: finalOutputURL)
        }
        
        if format == .m4a {
            try await convertToAAC(sourceURL: currentInputURL, destinationURL: finalOutputURL)
        } else {
            try FileManager.default.copyItem(at: currentInputURL, to: finalOutputURL)
        }
        
        return finalOutputURL
    }
    
    // MARK: - Pitch & Speed Offline Manual Rendering
    
    private func renderPitchAndSpeed(
        sourceURL: URL,
        destinationURL: URL,
        speed: Float,
        pitchSemitones: Float
    ) throws {
        let inputFile = try AVAudioFile(forReading: sourceURL)
        let clientFormat = inputFile.processingFormat
        let totalInputFrames = inputFile.length
        guard totalInputFrames > 0 else { throw AudioProcessorError.invalidSourceFile }
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let pitchUnit = AVAudioUnitTimePitch()
        
        // pitch is in cents (1 semitone = 100 cents, clamped to -2400...+2400)
        pitchUnit.pitch = pitchSemitones * 100.0
        pitchUnit.rate = max(0.5, min(2.0, speed))
        
        engine.attach(player)
        engine.attach(pitchUnit)
        
        engine.connect(player, to: pitchUnit, format: clientFormat)
        engine.connect(pitchUnit, to: engine.mainMixerNode, format: clientFormat)
        
        let maxFrames: AVAudioFrameCount = 4096
        try engine.enableManualRenderingMode(.offline, format: clientFormat, maximumFrameCount: maxFrames)
        try engine.start()
        
        player.scheduleFile(inputFile, at: nil)
        player.play()
        
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try? FileManager.default.removeItem(at: destinationURL)
        }
        
        let outputFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: clientFormat.settings,
            commonFormat: clientFormat.commonFormat,
            interleaved: clientFormat.isInterleaved
        )
        
        guard let renderBuffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: maxFrames) else {
            throw AudioProcessorError.renderFailed("Cannot allocate rendering buffer.")
        }
        
        // Estimated output length based on speed
        let estimatedOutputFrames = AVAudioFramePosition(Double(totalInputFrames) / Double(max(0.1, speed))) + 2048
        var framesRendered: AVAudioFramePosition = 0
        
        while engine.manualRenderingSampleTime < estimatedOutputFrames {
            let framesToRender = min(maxFrames, AVAudioFrameCount(estimatedOutputFrames - engine.manualRenderingSampleTime))
            let status = try engine.renderOffline(framesToRender, to: renderBuffer)
            
            switch status {
            case .success:
                try outputFile.write(from: renderBuffer)
                framesRendered += AVAudioFramePosition(renderBuffer.frameLength)
            case .insufficientDataFromInputNode:
                break
            case .cannotDoInCurrentContext:
                break
            case .error:
                throw AudioProcessorError.renderFailed("Offline render error.")
            @unknown default:
                break
            }
            
            if !player.isPlaying && engine.manualRenderingSampleTime >= estimatedOutputFrames {
                break
            }
        }
        
        player.stop()
        engine.stop()
        engine.disableManualRenderingMode()
    }
    
    // MARK: - AAC Conversion
    
    private func convertToAAC(sourceURL: URL, destinationURL: URL) async throws {
        let asset = AVURLAsset(url: sourceURL)
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw AudioProcessorError.renderFailed("Cannot create M4A export session.")
        }
        
        exportSession.outputURL = destinationURL
        exportSession.outputFileType = .m4a
        
        await exportSession.export()
        
        if let error = exportSession.error {
            throw AudioProcessorError.renderFailed("M4A export failed: \(error.localizedDescription)")
        }
    }
}

