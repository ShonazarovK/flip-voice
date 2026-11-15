import SwiftUI

public struct WaveformTrimView: View {
    public let waveform: [Float]
    public let duration: TimeInterval
    public let currentTime: TimeInterval
    
    @Binding public var trimStart: TimeInterval
    @Binding public var trimEnd: TimeInterval
    public let onSeek: (TimeInterval) -> Void
    
    public init(
        waveform: [Float],
        duration: TimeInterval,
        currentTime: TimeInterval,
        trimStart: Binding<TimeInterval>,
        trimEnd: Binding<TimeInterval>,
        onSeek: @escaping (TimeInterval) -> Void
    ) {
        self.waveform = waveform
        self.duration = max(0.1, duration)
        self.currentTime = currentTime
        self._trimStart = trimStart
        self._trimEnd = trimEnd
        self.onSeek = onSeek
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height
            
            let startX = CGFloat(trimStart / duration) * totalWidth
            let endX = CGFloat(trimEnd / duration) * totalWidth
            let playheadX = CGFloat(currentTime / duration) * totalWidth
            
            ZStack(alignment: .leading) {
                // Background waveform bars
                HStack(alignment: .center, spacing: 2) {
                    ForEach(0..<waveform.count, id: \.self) { idx in
                        let amp = waveform[idx]
                        let barHeight = CGFloat(amp) * (totalHeight - 16)
                        
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.primary.opacity(0.35))
                            .frame(height: max(4, barHeight))
                    }
                }
                .frame(width: totalWidth, height: totalHeight)
                
                // Trim Dimming Overlays
                // Left dimmed region
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: max(0, startX), height: totalHeight)
                
                // Right dimmed region
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: max(0, totalWidth - endX), height: totalHeight)
                    .offset(x: endX)
                
                // Highlighted Trim Active Box
                Rectangle()
                    .stroke(Color.cyan, lineWidth: 2)
                    .frame(width: max(0, endX - startX), height: totalHeight)
                    .offset(x: startX)
                
                // Start Trim Handle
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: startX - 10, y: 0)
                    .gesture(
                        DragGesture().onChanged { value in
                            let fraction = Double((startX + value.translation.width) / totalWidth)
                            let newTime = max(0.0, min(trimEnd - 0.2, fraction * duration))
                            trimStart = newTime
                        }
                    )
                
                // End Trim Handle
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 20, height: 20)
                    .shadow(radius: 2)
                    .offset(x: endX - 10, y: 0)
                    .gesture(
                        DragGesture().onChanged { value in
                            let fraction = Double((endX + value.translation.width) / totalWidth)
                            let newTime = min(duration, max(trimStart + 0.2, fraction * duration))
                            trimEnd = newTime
                        }
                    )
                
                // Playhead Bar
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: 2.5, height: totalHeight)
                    .offset(x: max(0, min(totalWidth - 2.5, playheadX)))
                    .shadow(color: .orange.opacity(0.6), radius: 3)
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { tap in
                    let tappedFraction = tap.location.x / totalWidth
                    let seekTime = Double(tappedFraction) * duration
                    onSeek(max(0.0, min(duration, seekTime)))
                }
            )
        }
        .frame(height: 110)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.cardBorder, lineWidth: 1))
    }
}

