import SwiftUI
import StoreKit

public struct SettingsView: View {
    @ObservedObject var localization = LocalizationManager.shared
    @AppStorage("export_format") private var exportFormat: String = AudioExportFormat.m4a.rawValue
    @AppStorage("app_theme_mode") private var themeMode: AppThemeMode = .system
    
    @State private var showPrivacySheet = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                // Audio Export Section
                Section(header: Text("Audio & Export")) {
                    Picker(localization.localized(.settingsExportFormat), selection: $exportFormat) {
                        ForEach(AudioExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format.rawValue)
                        }
                    }
                }
                
                // Appearance & Language Section
                Section(header: Text("Preferences")) {
                    Picker(localization.localized(.settingsLanguage), selection: $localization.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    
                    Picker(localization.localized(.settingsTheme), selection: $themeMode) {
                        ForEach(AppThemeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
                
                // Privacy & Data
                Section(header: Text("Privacy")) {
                    Button {
                        showPrivacySheet = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundStyle(Color.green)
                            Text(localization.localized(.privacyPolicy))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                        }
                    }
                    .foregroundStyle(Color.primary)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(Color.blue)
                        Text(localization.localized(.offlineGuarantee))
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
                // Feedback & Support
                Section(header: Text("Support")) {
                    Button {
                        requestAppReview()
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.yellow)
                            Text(localization.localized(.rateApp))
                        }
                    }
                    .foregroundStyle(Color.primary)
                    
                    Button {
                        openFeedbackEmail()
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color.cyan)
                            Text(localization.localized(.feedback))
                        }
                    }
                    .foregroundStyle(Color.primary)
                }
                
                // About Section
                Section(header: Text(localization.localized(.about))) {
                    HStack {
                        Text("App Name")
                        Spacer()
                        Text("FlipVoice")
                            .foregroundStyle(Color.secondary)
                    }
                    
                    HStack {
                        Text(localization.localized(.version))
                        Spacer()
                        Text("1.0.0 (Build 1)")
                            .foregroundStyle(Color.secondary)
                    }
                }
            }
            .navigationTitle(localization.localized(.tabSettings))
            .sheet(isPresented: $showPrivacySheet) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("FlipVoice Privacy Policy")
                                .font(.title2.weight(.bold))
                                .padding(.top, 10)
                            
                            Text("Last Updated: 2026")
                                .font(.caption)
                                .foregroundStyle(Color.secondary)
                            
                            Divider()
                            
                            Group {
                                Text("1. 100% On-Device Processing")
                                    .font(.headline)
                                Text("FlipVoice is designed with complete privacy in mind. All audio recording, processing, reversing, trimming, and pitch shifting occurs entirely on your device. No audio recordings or personal data are ever uploaded to any external server or third party.")
                                
                                Text("2. Microphone Access")
                                    .font(.headline)
                                Text("FlipVoice requires microphone permission exclusively to record audio when you tap the record button. Audio is recorded locally and is completely under your control.")
                                
                                Text("3. No Tracking or Analytics")
                                    .font(.headline)
                                Text("FlipVoice contains zero ad trackers, zero telemetry, and zero analytics frameworks. Your usage remains completely private.")
                                
                                Text("4. File Sharing & Storage")
                                    .font(.headline)
                                Text("Saved audio files are stored in your device's local App Sandbox. You can manage, export, or delete these recordings at any time through the Library or the iOS Files app.")
                            }
                            .font(.subheadline)
                            .lineSpacing(4)
                        }
                        .padding()
                    }
                    .navigationTitle(localization.localized(.privacyPolicy))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showPrivacySheet = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func requestAppReview() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }
    
    private func openFeedbackEmail() {
        let email = "support@flipvoice.local"
        let subject = "FlipVoice iOS Feedback".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "mailto:\(email)?subject=\(subject)") {
            UIApplication.shared.open(url)
        }
    }
}

