import SwiftUI

public struct AudioControlSliders: View {
    @ObservedObject var localization = LocalizationManager.shared
    
    @Binding var speed: Float
    @Binding var pitchSemitones: Float
    @Binding var fadeIn: TimeInterval
    @Binding var fadeOut: TimeInterval
    
    let speedPresets: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
    
    public init(
        speed: Binding<Float>,
        pitchSemitones: Binding<Float>,
        fadeIn: Binding<TimeInterval>,
        fadeOut: Binding<TimeInterval>
    ) {
        self._speed = speed
        self._pitchSemitones = pitchSemitones
        self._fadeIn = fadeIn
        self._fadeOut = fadeOut
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // Speed Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(localization.localized(.playbackSpeed), systemImage: "gauge.with.needle")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(String(format: "%.2fx", speed))
                        .font(.subheadline.weight(.bold).monospaced())
                        .foregroundStyle(Color.cyan)
                }
                
                Slider(value: $speed, in: 0.5...2.0, step: 0.05)
                    .tint(.cyan)
                
                // Speed Preset Chips
                HStack(spacing: 8) {
                    ForEach(speedPresets, id: \.self) { preset in
                        Button {
                            speed = preset
                        } label: {
                            Text(String(format: "%.2gx", preset))
                                .font(.caption2.weight(.medium))
                                .padding(.vertical, 4)
                                .padding(.horizontal, 8)
                                .background(abs(speed - preset) < 0.01 ? Color.cyan.opacity(0.3) : AppTheme.cardBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().stroke(abs(speed - preset) < 0.01 ? Color.cyan : AppTheme.cardBorder, lineWidth: 1)
                                )
                        }
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Pitch Shift Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(localization.localized(.pitchShift), systemImage: "waveform.badge.magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(String(format: "%+.1f %@", pitchSemitones, localization.localized(.semitones)))
                        .font(.subheadline.weight(.bold).monospaced())
                        .foregroundStyle(Color.purple)
                    
                    if abs(pitchSemitones) > 0.1 {
                        Button(localization.localized(.reset)) {
                            pitchSemitones = 0.0
                        }
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.secondary)
                        .padding(.leading, 4)
                    }
                }
                
                Slider(value: $pitchSemitones, in: -24...24, step: 1.0)
                    .tint(.purple)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Fades Section
            HStack(spacing: 12) {
                // Fade In
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localization.localized(.fadeIn))
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1fs", fadeIn))
                            .font(.caption.monospaced())
                    }
                    Slider(value: $fadeIn, in: 0.0...2.0, step: 0.1)
                        .tint(.orange)
                }
                .padding(12)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                // Fade Out
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localization.localized(.fadeOut))
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(String(format: "%.1fs", fadeOut))
                            .font(.caption.monospaced())
                    }
                    Slider(value: $fadeOut, in: 0.0...2.0, step: 0.1)
                        .tint(.orange)
                }
                .padding(12)
                .background(AppTheme.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }
}

