import XCTest
import AVFoundation
@testable import FlipVoice

final class AudioTrimFadeTests: XCTestCase {
    
    func testFadeCurveMath() {
        let frameCount = 100
        let fadeInFrames = 20
        
        var samples = [Float](repeating: 1.0, count: frameCount)
        
        // Emulate linear fade-in
        for i in 0..<fadeInFrames {
            let gain = Float(i) / Float(fadeInFrames)
            samples[i] *= gain
        }
        
        XCTAssertEqual(samples[0], 0.0, accuracy: 0.0001)
        XCTAssertEqual(samples[10], 0.5, accuracy: 0.0001)
        XCTAssertEqual(samples[20], 1.0, accuracy: 0.0001)
        XCTAssertEqual(samples[50], 1.0, accuracy: 0.0001)
    }
}

