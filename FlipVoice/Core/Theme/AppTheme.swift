import SwiftUI

public enum AppThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    public var id: String { rawValue }
    
    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

public struct AppTheme {
    public static let primaryAccent = Color.cyan
    public static let secondaryAccent = Color.purple
    public static let warningAccent = Color.orange
    public static let recordRed = Color.red
    
    public static let cardBackground = Color(UIColor.secondarySystemBackground)
    public static let cardBorder = Color(UIColor.separator).opacity(0.3)
}

