import Foundation
import AVFoundation
import Accelerate

public final class WaveformExtractor {
    public static let shared = WaveformExtractor()
    
    public init() {}
    
    /// Reads audio file and downsamples it into a normalized amplitude array of requested sampleCount (e.g. 60 bars)
    public func extractWaveform(from url: URL, targetCount: Int = 60) async -> [Float] {
        return await Task.detached(priority: .userInitiated) {
            guard let file = try? AVAudioFile(forReading: url) else {
                return Array(repeating: 0.1, count: targetCount)
            }
            
            let format = file.processingFormat
            let totalFrames = file.length
            guard totalFrames > 0 else {
                return Array(repeating: 0.1, count: targetCount)
            }
            
            let framesPerBin = max(1, Int(totalFrames) / targetCount)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(framesPerBin)) else {
                return Array(repeating: 0.1, count: targetCount)
            }
            
            var amplitudes: [Float] = []
            amplitudes.reserveCapacity(targetCount)
            
            for _ in 0..<targetCount {
                do {
                    buffer.frameLength = 0
                    try file.read(into: buffer, frameCount: AVAudioFrameCount(framesPerBin))
                    
                    if let floatData = buffer.floatChannelData {
                        var rms: Float = 0.0
                        vDSP_rmsqv(floatData[0], 1, &rms, vDSP_Length(buffer.frameLength))
                        amplitudes.append(rms)
                    } else {
                        amplitudes.append(0.1)
                    }
                } catch {
                    amplitudes.append(0.1)
                }
            }
            
            // Normalize amplitudes between 0.08 and 1.0
            let maxVal = amplitudes.max() ?? 1.0
            if maxVal > 0.001 {
                return amplitudes.map { max(0.08, min(1.0, $0 / maxVal)) }
            } else {
                return Array(repeating: 0.15, count: targetCount)
            }
        }.value
    }
}

