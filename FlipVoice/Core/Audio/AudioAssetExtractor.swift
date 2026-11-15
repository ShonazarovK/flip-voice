import Foundation
import AVFoundation

public enum AssetExtractionError: LocalizedError {
    case assetHasNoAudioTrack
    case exportSessionFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .assetHasNoAudioTrack:
            return "The selected file contains no audio track."
        case .exportSessionFailed(let msg):
            return "Audio extraction failed: \(msg)"
        }
    }
}

/// Helper that extracts audio from media files (videos, voice memos, non-WAV formats) into standard WAV format.
public final class AudioAssetExtractor {
    public static let shared = AudioAssetExtractor()
    
    public init() {}
    
    public func convertToStandardWAV(sourceURL: URL) async throws -> URL {
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("import_\(UUID().uuidString).wav")
        
        let asset = AVURLAsset(url: sourceURL)
        let tracks = try await asset.loadTracks(withMediaType: .audio)
        guard !tracks.isEmpty else {
            throw AssetExtractionError.assetHasNoAudioTrack
        }
        
        let reader = try AVAssetReader(asset: asset)
        let outputSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        
        let trackOutput = AVAssetReaderTrackOutput(track: tracks[0], outputSettings: outputSettings)
        reader.add(trackOutput)
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 44100.0,
            channels: 2,
            interleaved: true
        ) else {
            throw AudioProcessorError.unsupportedFormat
        }
        
        let audioFile = try AVAudioFile(
            forWriting: destinationURL,
            settings: format.settings,
            commonFormat: .pcmFormatInt16,
            interleaved: true
        )
        
        guard reader.startReading() else {
            throw AssetExtractionError.exportSessionFailed(reader.error?.localizedDescription ?? "Unknown")
        }
        
        while reader.status == .reading {
            if let sampleBuffer = trackOutput.copyNextSampleBuffer(),
               let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(count: length)
                data.withUnsafeMutableBytes { (rawPtr: UnsafeMutableRawBufferPointer) in
                    if let baseAddress = rawPtr.baseAddress {
                        CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: baseAddress)
                    }
                }
                
                let sampleCount = length / 4 // 2 channels * 2 bytes
                guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount)) else {
                    continue
                }
                pcmBuffer.frameLength = AVAudioFrameCount(sampleCount)
                
                data.withUnsafeBytes { rawBuffer in
                    if let ptr = rawBuffer.baseAddress, let int16Data = pcmBuffer.int16ChannelData {
                        memcpy(int16Data[0], ptr, length)
                    }
                }
                
                try audioFile.write(from: pcmBuffer)
            }
        }
        
        if reader.status == .failed {
            throw AssetExtractionError.exportSessionFailed(reader.error?.localizedDescription ?? "Reader failed")
        }
        
        return destinationURL
    }
}

