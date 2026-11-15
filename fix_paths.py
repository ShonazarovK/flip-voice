with open("FlipVoice.xcodeproj/project.pbxproj", "r") as f:
    content = f.read()

replacements = {
    'path = "LibraryManager.swift";': 'path = "Core/Storage/LibraryManager.swift";',
    'path = "AudioItem.swift";': 'path = "Core/Storage/AudioItem.swift";',
    'path = "AudioPlayer.swift";': 'path = "Core/Audio/AudioPlayer.swift";',
    'path = "WaveformExtractor.swift";': 'path = "Core/Audio/WaveformExtractor.swift";',
    'path = "AudioAssetExtractor.swift";': 'path = "Core/Audio/AudioAssetExtractor.swift";',
    'path = "AudioEngineProtocol.swift";': 'path = "Core/Audio/AudioEngineProtocol.swift";',
    'path = "AudioRecorder.swift";': 'path = "Core/Audio/AudioRecorder.swift";',
    'path = "AudioEngine.swift";': 'path = "Core/Audio/AudioEngine.swift";',
    'path = "AudioProcessor.swift";': 'path = "Core/Audio/AudioProcessor.swift";',
    'path = "AppTheme.swift";': 'path = "Core/Theme/AppTheme.swift";',
    'path = "AppLocalization.swift";': 'path = "Core/Localization/AppLocalization.swift";',
    'path = "ContentView.swift";': 'path = "App/ContentView.swift";',
    'path = "FlipVoiceApp.swift";': 'path = "App/FlipVoiceApp.swift";',
    'path = "SettingsView.swift";': 'path = "Features/Settings/SettingsView.swift";',
    'path = "StudioView.swift";': 'path = "Features/Studio/StudioView.swift";',
    'path = "LiveWaveformView.swift";': 'path = "Features/Studio/LiveWaveformView.swift";',
    'path = "LibraryView.swift";': 'path = "Features/Library/LibraryView.swift";',
    'path = "ChallengeView.swift";': 'path = "Features/Challenge/ChallengeView.swift";',
    'path = "WaveformTrimView.swift";': 'path = "Features/Editor/WaveformTrimView.swift";',
    'path = "EditorView.swift";': 'path = "Features/Editor/EditorView.swift";',
    'path = "AudioControlSliders.swift";': 'path = "Features/Editor/AudioControlSliders.swift";',
    'path = Assets.xcassets;': 'path = "Resources/Assets.xcassets";',
    'path = Info.plist;': 'path = "Resources/Info.plist";',
    'path = PrivacyInfo.xcprivacy;': 'path = "Resources/PrivacyInfo.xcprivacy";',
    'ENABLE_PREVIEWS = YES;': 'ENABLE_PREVIEWS = NO;',
}

for k, v in replacements.items():
    if k in content:
        content = content.replace(k, v)
    else:
        print(f"Warning: pattern not found: {k}")

with open("FlipVoice.xcodeproj/project.pbxproj", "w") as f:
    f.write(content)

print("Paths updated successfully")

