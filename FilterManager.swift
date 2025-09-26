import SwiftUI

// MARK: - Filter Manager
class FilterManager: ObservableObject {
    static let shared = FilterManager()
    
    @Published var includePatterns: [String] = []
    @Published var excludePatterns: [String] = []
    @Published var caseSensitive = false
    @Published var useRegex = false
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Pattern Management
    func addIncludePattern(_ pattern: String) {
        let trimmedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPattern.isEmpty && !includePatterns.contains(trimmedPattern) {
            includePatterns.append(trimmedPattern)
            saveSettings()
        }
    }
    
    func removeIncludePattern(_ pattern: String) {
        includePatterns.removeAll { $0 == pattern }
        saveSettings()
    }
    
    func addExcludePattern(_ pattern: String) {
        let trimmedPattern = pattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPattern.isEmpty && !excludePatterns.contains(trimmedPattern) {
            excludePatterns.append(trimmedPattern)
            saveSettings()
        }
    }
    
    func removeExcludePattern(_ pattern: String) {
        excludePatterns.removeAll { $0 == pattern }
        saveSettings()
    }
    
    func clearAllPatterns() {
        includePatterns.removeAll()
        excludePatterns.removeAll()
        saveSettings()
    }
    
    // MARK: - Pattern Matching
    func shouldIncludeFile(_ fileName: String) -> Bool {
        let name = caseSensitive ? fileName : fileName.lowercased()
        
        // Check exclude patterns first
        for pattern in excludePatterns {
            if matchesPattern(name, pattern: pattern) {
                return false
            }
        }
        
        // If no include patterns, include all files
        if includePatterns.isEmpty {
            return true
        }
        
        // Check include patterns
        for pattern in includePatterns {
            if matchesPattern(name, pattern: pattern) {
                return true
            }
        }
        
        return false
    }
    
    private func matchesPattern(_ fileName: String, pattern: String) -> Bool {
        let searchPattern = caseSensitive ? pattern : pattern.lowercased()
        
        if useRegex {
            return matchesRegex(fileName, pattern: searchPattern)
        } else {
            return matchesWildcard(fileName, pattern: searchPattern)
        }
    }
    
    private func matchesWildcard(_ fileName: String, pattern: String) -> Bool {
        // Convert wildcard pattern to regex
        let regexPattern = pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")
        
        return matchesRegex(fileName, pattern: regexPattern)
    }
    
    private func matchesRegex(_ fileName: String, pattern: String) -> Bool {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: caseSensitive ? [] : .caseInsensitive)
            let range = NSRange(location: 0, length: fileName.count)
            return regex.firstMatch(in: fileName, options: [], range: range) != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Settings
    private func loadSettings() {
        includePatterns = UserDefaults.standard.stringArray(forKey: "includePatterns") ?? []
        excludePatterns = UserDefaults.standard.stringArray(forKey: "excludePatterns") ?? []
        caseSensitive = UserDefaults.standard.bool(forKey: "filterCaseSensitive")
        useRegex = UserDefaults.standard.bool(forKey: "filterUseRegex")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(includePatterns, forKey: "includePatterns")
        UserDefaults.standard.set(excludePatterns, forKey: "excludePatterns")
        UserDefaults.standard.set(caseSensitive, forKey: "filterCaseSensitive")
        UserDefaults.standard.set(useRegex, forKey: "filterUseRegex")
    }
    
    // MARK: - Default Patterns
    func loadDefaultPatterns() {
        excludePatterns = [
            "*.tmp",
            "*.temp",
            "*.log",
            "*.cache",
            ".DS_Store",
            "Thumbs.db",
            "*.swp",
            "*.swo",
            "*~",
            "*.bak",
            "*.backup"
        ]
        saveSettings()
    }
    
    // MARK: - Pattern Validation
    func validatePattern(_ pattern: String) -> Bool {
        if useRegex {
            do {
                _ = try NSRegularExpression(pattern: pattern)
                return true
            } catch {
                return false
            }
        } else {
            // Wildcard patterns are always valid
            return true
        }
    }
    
    // MARK: - Pattern Help
    func getPatternHelp() -> [String: String] {
        if useRegex {
            return [
                ".*": "Tous les fichiers",
                "\\.txt$": "Fichiers .txt",
                "^temp": "Fichiers commençant par 'temp'",
                "\\d{4}-\\d{2}-\\d{2}": "Fichiers avec date YYYY-MM-DD"
            ]
        } else {
            return [
                "*": "Tous les fichiers",
                "*.txt": "Fichiers .txt",
                "temp*": "Fichiers commençant par 'temp'",
                "*.{jpg,png,gif}": "Images JPEG, PNG et GIF"
            ]
        }
    }
}