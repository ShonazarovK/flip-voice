import XCTest
import AVFoundation
@testable import FlipVoice

final class AudioReversalTests: XCTestCase {
    
    func testBufferReversalIsInvolution() throws {
        // Create a test stereo float PCM buffer with 100 frames
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 100) else {
            XCTFail("Failed to allocate test buffer")
            return
        }
        
        buffer.frameLength = 100
        guard let floatData = buffer.floatChannelData else {
            XCTFail("Missing float channel data")
            return
        }
        
        // Populate distinct test signals in both channels
        for i in 0..<100 {
            floatData[0][i] = Float(i) * 0.01 // Left channel
            floatData[1][i] = Float(100 - i) * 0.02 // Right channel
        }
        
        // Take a snapshot of original samples
        var originalLeft = [Float](repeating: 0, count: 100)
        var originalRight = [Float](repeating: 0, count: 100)
        for i in 0..<100 {
            originalLeft[i] = floatData[0][i]
            originalRight[i] = floatData[1][i]
        }
        
        // 1. First reversal
        AudioProcessor.shared.reverseBuffer(buffer, channelCount: 2)
        
        // Verify reversed order
        for i in 0..<100 {
            XCTAssertEqual(floatData[0][i], originalLeft[99 - i], accuracy: 0.0001)
            XCTAssertEqual(floatData[1][i], originalRight[99 - i], accuracy: 0.0001)
        }
        
        // 2. Second reversal (must restore exact original)
        AudioProcessor.shared.reverseBuffer(buffer, channelCount: 2)
        
        for i in 0..<100 {
            XCTAssertEqual(floatData[0][i], originalLeft[i], accuracy: 0.000001)
            XCTAssertEqual(floatData[1][i], originalRight[i], accuracy: 0.000001)
        }
    }
}

