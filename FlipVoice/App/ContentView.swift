import SwiftUI

public struct ContentView: View {
    @StateObject private var audioEngine = FlipVoiceAudioEngine.shared
    @StateObject private var localization = LocalizationManager.shared
    @AppStorage("app_theme_mode") private var themeMode: AppThemeMode = .system
    
    @State private var selectedTab: Int = 0
    @State private var currentActiveURL: URL?
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            StudioView(
                audioEngine: audioEngine,
                selectedTab: $selectedTab,
                currentActiveURL: $currentActiveURL
            )
            .tabItem {
                Label(localization.localized(.tabStudio), systemImage: "mic.fill")
            }
            .tag(0)
            
            EditorView(
                audioEngine: audioEngine,
                currentActiveURL: $currentActiveURL
            )
            .tabItem {
                Label(localization.localized(.tabEditor), systemImage: "waveform")
            }
            .tag(1)
            
            ChallengeView()
            .tabItem {
                Label(localization.localized(.tabChallenge), systemImage: "gamecontroller.fill")
            }
            .tag(2)
            
            LibraryView(
                audioEngine: audioEngine,
                selectedTab: $selectedTab,
                currentActiveURL: $currentActiveURL
            )
            .tabItem {
                Label(localization.localized(.tabLibrary), systemImage: "folder.fill")
            }
            .tag(3)
            
            SettingsView()
            .tabItem {
                Label(localization.localized(.tabSettings), systemImage: "gearshape.fill")
            }
            .tag(4)
        }
        .preferredColorScheme(themeMode.colorScheme)
        .tint(.cyan)
    }
}

