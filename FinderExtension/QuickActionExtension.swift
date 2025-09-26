import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - Quick Action Extension
class QuickActionExtension: NSObject {
    
    // MARK: - Supported File Types
    private static let supportedArchiveTypes: Set<String> = [
        "public.zip-archive",
        "public.data",
        "com.pkware.zip-archive",
        "org.7zip.7z-archive",
        "public.tar-archive",
        "public.tar-gz-archive",
        "public.tar-bz2-archive",
        "public.tar-xz-archive"
    ]
    
    // MARK: - Quick Actions
    static func getQuickActions() -> [NSUserActivity] {
        var actions: [NSUserActivity] = []
        
        // Action: Compresser avec Mac7zip
        let compressAction = NSUserActivity(activityType: "com.mac7zip.compress")
        compressAction.title = "Compresser avec Mac7zip"
        compressAction.userInfo = ["action": "compress"]
        compressAction.isEligibleForSearch = true
        compressAction.isEligibleForPrediction = true
        actions.append(compressAction)
        
        // Action: Extraire avec Mac7zip
        let extractAction = NSUserActivity(activityType: "com.mac7zip.extract")
        extractAction.title = "Extraire avec Mac7zip"
        extractAction.userInfo = ["action": "extract"]
        extractAction.isEligibleForSearch = true
        extractAction.isEligibleForPrediction = true
        actions.append(extractAction)
        
        // Action: Ouvrir avec Mac7zip
        let openAction = NSUserActivity(activityType: "com.mac7zip.open")
        openAction.title = "Ouvrir avec Mac7zip"
        openAction.userInfo = ["action": "open"]
        openAction.isEligibleForSearch = true
        openAction.isEligibleForPrediction = true
        actions.append(openAction)
        
        return actions
    }
    
    // MARK: - Action Handler
    static func handleAction(_ action: String, with files: [URL]) {
        guard !files.isEmpty else { return }
        
        switch action {
        case "compress":
            compressFiles(files)
        case "extract":
            extractArchives(files)
        case "open":
            openArchives(files)
        default:
            break
        }
    }
    
    // MARK: - Compress Files
    private static func compressFiles(_ files: [URL]) {
        // Ouvrir Mac7zip avec les fichiers sélectionnés pour compression
        let appURL = getMac7zipAppURL()
        guard let appURL = appURL else {
            showError("Mac7zip n'est pas installé")
            return
        }
        
        var arguments = ["--compress"]
        for file in files {
            arguments.append(file.path)
        }
        
        let process = Process()
        process.executableURL = appURL
        process.arguments = arguments
        
        do {
            try process.run()
        } catch {
            showError("Impossible de lancer Mac7zip: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Extract Archives
    private static func extractArchives(_ archives: [URL]) {
        let appURL = getMac7zipAppURL()
        guard let appURL = appURL else {
            showError("Mac7zip n'est pas installé")
            return
        }
        
        for archive in archives {
            var arguments = ["--extract", archive.path]
            
            let process = Process()
            process.executableURL = appURL
            process.arguments = arguments
            
            do {
                try process.run()
            } catch {
                showError("Impossible d'extraire \(archive.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Open Archives
    private static func openArchives(_ archives: [URL]) {
        let appURL = getMac7zipAppURL()
        guard let appURL = appURL else {
            showError("Mac7zip n'est pas installé")
            return
        }
        
        for archive in archives {
            var arguments = ["--open", archive.path]
            
            let process = Process()
            process.executableURL = appURL
            process.arguments = arguments
            
            do {
                try process.run()
            } catch {
                showError("Impossible d'ouvrir \(archive.lastPathComponent): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helper Methods
    private static func getMac7zipAppURL() -> URL? {
        // Chercher Mac7zip dans les emplacements habituels
        let possiblePaths = [
            "/Applications/Mac7zip.app",
            "/Applications/Mac7zip.app/Contents/MacOS/Mac7zip",
            "/usr/local/bin/Mac7zip",
            "/opt/homebrew/bin/Mac7zip"
        ]
        
        for path in possiblePaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
    
    private static func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Erreur Mac7zip"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
    
    // MARK: - File Type Detection
    static func isArchiveFile(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()
        let archiveExtensions = ["7z", "zip", "rar", "tar", "gz", "bz2", "xz", "cab", "msi", "wim", "iso"]
        return archiveExtensions.contains(fileExtension)
    }
    
    static func isCompressibleFile(_ url: URL) -> Bool {
        // Vérifier si le fichier peut être compressé
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
            return true // Tous les fichiers et dossiers peuvent être compressés
        }
        return false
    }
}

// MARK: - Finder Extension Info.plist Generator
class FinderExtensionInfoGenerator {
    static func generateInfoPlist() -> [String: Any] {
        return [
            "CFBundleDisplayName": "Mac7zip Quick Actions",
            "CFBundleIdentifier": "com.mac7zip.finder-extension",
            "CFBundleVersion": "1.0",
            "CFBundleShortVersionString": "1.0",
            "NSExtension": [
                "NSExtensionPointIdentifier": "com.apple.quicklook.thumbnail",
                "NSExtensionAttributes": [
                    "QLSupportsSearchableItems": true,
                    "QLThumbnailMinimumSize": 80,
                    "QLThumbnailMaximumSize": 256
                ]
            ],
            "CFBundleDocumentTypes": [
                [
                    "CFBundleTypeName": "Archive Files",
                    "CFBundleTypeRole": "Viewer",
                    "LSItemContentTypes": [
                        "public.zip-archive",
                        "public.data",
                        "com.pkware.zip-archive",
                        "org.7zip.7z-archive",
                        "public.tar-archive",
                        "public.tar-gz-archive",
                        "public.tar-bz2-archive",
                        "public.tar-xz-archive"
                    ]
                ]
            ],
            "UTExportedTypeDeclarations": [
                [
                    "UTTypeIdentifier": "org.7zip.7z-archive",
                    "UTTypeDescription": "7-Zip Archive",
                    "UTTypeConformsTo": ["public.data"],
                    "UTTypeTagSpecification": [
                        "public.filename-extension": ["7z"]
                    ]
                ]
            ]
        ]
    }
}

// MARK: - Quick Action Menu
class QuickActionMenu: NSMenu {
    override init(title: String) {
        super.init(title: title)
        setupMenu()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupMenu()
    }
    
    private func setupMenu() {
        // Compresser
        let compressItem = NSMenuItem(title: "Compresser avec Mac7zip", action: #selector(compressAction), keyEquivalent: "")
        compressItem.target = self
        addItem(compressItem)
        
        addItem(NSMenuItem.separator())
        
        // Extraire
        let extractItem = NSMenuItem(title: "Extraire avec Mac7zip", action: #selector(extractAction), keyEquivalent: "")
        extractItem.target = self
        addItem(extractItem)
        
        // Ouvrir
        let openItem = NSMenuItem(title: "Ouvrir avec Mac7zip", action: #selector(openAction), keyEquivalent: "")
        openItem.target = self
        addItem(openItem)
    }
    
    @objc private func compressAction() {
        // Implementation pour compresser
        QuickActionExtension.handleAction("compress", with: getSelectedFiles())
    }
    
    @objc private func extractAction() {
        // Implementation pour extraire
        QuickActionExtension.handleAction("extract", with: getSelectedFiles())
    }
    
    @objc private func openAction() {
        // Implementation pour ouvrir
        QuickActionExtension.handleAction("open", with: getSelectedFiles())
    }
    
    private func getSelectedFiles() -> [URL] {
        // Récupérer les fichiers sélectionnés dans le Finder
        // Cette fonction nécessiterait une intégration plus poussée avec le Finder
        return []
    }
}
