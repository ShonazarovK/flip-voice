import SwiftUI

public struct LiveWaveformView: View {
    public let amplitudes: [Float]
    public let barColor: Color
    
    public init(amplitudes: [Float], barColor: Color = .cyan) {
        self.amplitudes = amplitudes
        self.barColor = barColor
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 3) {
            if amplitudes.isEmpty {
                ForEach(0..<40, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor.opacity(0.3))
                        .frame(width: 3, height: 6)
                }
            } else {
                ForEach(0..<amplitudes.count, id: \.self) { index in
                    let amp = amplitudes[index]
                    let height = CGFloat(max(6, min(90, amp * 90)))
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [barColor, barColor.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 3, height: height)
                        .animation(.spring(response: 0.15, dampingFraction: 0.7), value: height)
                }
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }
}

