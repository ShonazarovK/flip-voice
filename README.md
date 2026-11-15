# FlipVoice: Reverse Audio Lab (Native iOS App)

A complete, production-ready offline iOS app built with Swift and SwiftUI that records, imports, reverses, pitch-shifts, and trims audio with sample-level accuracy.

---

## Key Features

1. **Studio & Recording:**
   - 16-bit 44.1kHz linear PCM WAV recording.
   - Dynamic live waveform visualizer reacting to microphone levels in real time.
   - Graceful microphone permission handling and session interruption management.
   - Universal media file importer (WAV, MP3, M4A, AAC, AIFF, and video audio tracks).

2. **Audio Lab & Editor:**
   - Bit-accurate frame-by-frame sample reversal (stereo pairs strictly preserved).
   - Real-time pitch shift ($-24$ to $+24$ semitones) independent of playback speed via `AVAudioUnitTimePitch`.
   - Variable playback speed ($0.5\times$ to $2.0\times$) with quick preset buttons.
   - Interactive waveform visualizer with start/end trim handles.
   - Smooth Fade-in and Fade-out controls.
   - Offline multi-stage export to M4A (AAC) or uncompressed WAV.

3. **Backwards Talk Challenge:**
   - Interactive 4-step game flow:
     1. Record original phrase.
     2. Listen to the reversed sound.
     3. Record your imitation of the backwards sound.
     4. Flip the imitation back to compare side-by-side with your original voice.

4. **Library & Management:**
   - Local file storage in app documents (discoverable in iOS Files app).
   - Search by title, sort by date, name, or duration.
   - Rename, delete, and direct share.

5. **Settings & Localization:**
   - Full localized translations for **English**, **Russian (Русский)**, and **Uzbek (O'zbekcha)**.
   - System, Light, and Dark mode theme support.
   - Format selection (M4A vs. WAV).
   - In-app Privacy Policy display.

6. **Privacy & App Store Ready:**
   - 100% on-device processing.
   - Zero tracking, zero ads, zero analytics (`PrivacyInfo.xcprivacy` included).
   - Complete App Store submission metadata, review notes, and screenshot plans in `docs/`.

---

## How to Run in Xcode

1. Open `FlipVoice.xcodeproj` in Xcode:
   ```bash
   open /Users/macbookpro/.gemini/antigravity/scratch/FlipVoice/FlipVoice.xcodeproj
   ```
2. Select your target device (e.g., **iPhone 16 Simulator** or your connected iPhone).
3. Press **Cmd + R** to build and run!

