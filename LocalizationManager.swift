import SwiftUI

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .french {
        didSet {
            // UserDefaults persistence (Keka approach)
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "AppLanguage")
            
            // Bundle loading (Apple approach)
            loadBundle()
            
            // SwiftUI force refresh (BetterZip approach)
            objectWillChange.send()
            
            // NotificationCenter pour rechargement interface
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }
    
    @Published var availableLanguages: [Language] = [.french, .english]
    
    // Bundle dynamique (Sketch approach)
    private var currentBundle: Bundle = Bundle.main
    
    // Bundle cache pour performance (BetterZip approach)
    private lazy var bundles: [String: Bundle] = {
        var result: [String: Bundle] = [:]
        for language in ["fr", "en"] {
            if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                result[language] = bundle
            }
        }
        return result
    }()
    
    // Translation cache pour performance
    private var translationCache: [String: String] = [:]
    
    private init() {
        loadSettings()
        loadBundle()
    }
    
    // MARK: - Language Management
    func setLanguage(_ language: Language) {
        currentLanguage = language
    }
    
    // MARK: - Localization
    func localizedString(_ key: String) -> String {
        // Cache check first (performance)
        let cacheKey = "\(currentLanguage.rawValue)_\(key)"
        if let cached = translationCache[cacheKey] {
            return cached
        }
        
        // Current language lookup
        let localized = currentBundle.localizedString(forKey: key, value: nil, table: nil)
        
        // Fallback to English if not found (BetterZip approach)
        if localized == key || localized.isEmpty,
           let englishBundle = bundles["en"] {
            let fallback = englishBundle.localizedString(forKey: key, value: key, table: nil)
            translationCache[cacheKey] = fallback
            return fallback
        }
        
        // Cache successful lookup
        translationCache[cacheKey] = localized
        return localized
    }
    
    // MARK: - Settings
    private func loadSettings() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "AppLanguage"),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
    }
    
    // Bundle loading optimisé
    private func loadBundle() {
        currentBundle = bundles[currentLanguage.rawValue] ?? Bundle.main
        translationCache.removeAll() // Clear cache on language change
    }
}

// MARK: - Language
enum Language: String, CaseIterable, Identifiable {
    case french = "fr"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .french: return "Français"
        case .english: return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .french: return "🇫🇷"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

// MARK: - Localized String Extension
extension String {
    var localized: String {
        return LocalizationManager.shared.localizedString(self)
    }
    
    // Support arguments formatés (BetterZip approach)
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
}