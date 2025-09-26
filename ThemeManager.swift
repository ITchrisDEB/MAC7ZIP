import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var accentColor: Color = .blue
    @Published var isDarkMode: Bool = false
    
    private init() {
        loadSettings()
        updateTheme()
    }
    
    // MARK: - Theme Management
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        updateTheme()
        saveSettings()
    }
    
    func setAccentColor(_ color: Color) {
        accentColor = color
        saveSettings()
    }
    
    private func updateTheme() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = NSAppearance.current?.name == .darkAqua
        }
    }
    
    // MARK: - Settings
    private func loadSettings() {
        if let themeRawValue = UserDefaults.standard.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
        
        if let accentColorData = UserDefaults.standard.data(forKey: "accentColor"),
           let color = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: accentColorData) {
            accentColor = Color(color)
        }
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "appTheme")
        
        let color = NSColor(accentColor)
        if let colorData = try? NSKeyedArchiver.archivedData(withRootObject: color, requiringSecureCoding: false) {
            UserDefaults.standard.set(colorData, forKey: "accentColor")
        }
    }
}

// MARK: - App Theme
enum AppTheme: String, CaseIterable, Identifiable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .light: return "Clair"
        case .dark: return "Sombre"
        case .system: return "Système"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
}

// MARK: - Accent Colors
extension Color {
    static let accentColors: [Color] = [
        .blue, .green, .orange, .red, .purple, .pink, .yellow, .cyan, .mint, .indigo
    ]
    
    var accentColorName: String {
        switch self {
        case .blue: return "Bleu"
        case .green: return "Vert"
        case .orange: return "Orange"
        case .red: return "Rouge"
        case .purple: return "Violet"
        case .pink: return "Rose"
        case .yellow: return "Jaune"
        case .cyan: return "Cyan"
        case .mint: return "Menthe"
        case .indigo: return "Indigo"
        default: return "Personnalisé"
        }
    }
}