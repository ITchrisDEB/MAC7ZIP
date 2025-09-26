import SwiftUI

// MARK: - FocusedValues pour les raccourcis clavier par fenêtre
extension FocusedValues {
    var showNewArchive: Binding<Bool>? {
        get { self[ShowNewArchiveKey.self] }
        set { self[ShowNewArchiveKey.self] = newValue }
    }
    
    var showOpenArchive: Binding<Bool>? {
        get { self[ShowOpenArchiveKey.self] }
        set { self[ShowOpenArchiveKey.self] = newValue }
    }
    
    var showCloseArchive: Binding<Bool>? {
        get { self[ShowCloseArchiveKey.self] }
        set { self[ShowCloseArchiveKey.self] = newValue }
    }
    
    var showExtract: Binding<Bool>? {
        get { self[ShowExtractKey.self] }
        set { self[ShowExtractKey.self] = newValue }
    }
    
    var showAddFiles: Binding<Bool>? {
        get { self[ShowAddFilesKey.self] }
        set { self[ShowAddFilesKey.self] = newValue }
    }
    
    var showProperties: Binding<Bool>? {
        get { self[ShowPropertiesKey.self] }
        set { self[ShowPropertiesKey.self] = newValue }
    }
}

// MARK: - FocusedValue Keys
struct ShowNewArchiveKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowOpenArchiveKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowCloseArchiveKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowExtractKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowAddFilesKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

struct ShowPropertiesKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

@main
struct Mac7zipApp: App {
    // LocalizationManager pour toute l'application
    @StateObject private var localizationManager = LocalizationManager.shared
    
    // État minimal pour que macOS détecte le multi-fenêtres
    @State private var windowCount = 0
    
    // FocusedBindings pour les raccourcis clavier
    @FocusedBinding(\.showNewArchive) var showNewArchive
    @FocusedBinding(\.showOpenArchive) var showOpenArchive
    @FocusedBinding(\.showCloseArchive) var showCloseArchive
    @FocusedBinding(\.showExtract) var showExtract
    @FocusedBinding(\.showAddFiles) var showAddFiles
    @FocusedBinding(\.showProperties) var showProperties
    
    init() {
        NSLog("🚀 Mac7zipApp démarré - Arguments: \(CommandLine.arguments)")
        
        // Gestion arguments CLI COMPLETS
        let args = CommandLine.arguments
        if args.count > 1 {
            for i in 1..<args.count {
                let arg = args[i]
                
                if arg == "--open" && i + 1 < args.count {
                    let archivePath = args[i + 1]
                    let url = URL(fileURLWithPath: archivePath)
                    NSLog("🔍 CLI --open: \(archivePath)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Archive opening will be handled by individual windows
                        NotificationCenter.default.post(name: Notification.Name("openArchive"), object: url)
                    }
                } else if arg == "--extract" && i + 1 < args.count {
                    let archivePath = args[i + 1]
                    let url = URL(fileURLWithPath: archivePath)
                    NSLog("🔍 CLI --extract: \(archivePath)")
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Archive opening will be handled by individual windows
                        NotificationCenter.default.post(name: Notification.Name("openArchive"), object: url)
                        // Déclencher extraction automatique
                        NotificationCenter.default.post(name: .showExtract, object: nil)
                    }
                } else if arg == "--compress" {
                    NSLog("🔍 CLI --compress détecté")
                    let filesToCompress = Array(args[(i+1)...])
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // Ouvrir interface de création avec fichiers pré-sélectionnés
                        _ = filesToCompress.map { URL(fileURLWithPath: $0) }
                        // TODO: Implémenter preSelectedFiles dans ArchiveManager
                        NotificationCenter.default.post(name: .showNewArchive, object: nil)
                    }
                    break
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, minHeight: 700)
                .environmentObject(localizationManager)
                .environment(\.locale, Locale(identifier: localizationManager.currentLanguage.rawValue))
                .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
                    // Force UI refresh when language changes
                    NSLog("🌍 Language changed notification received")
                }
                .onOpenURL { url in
                    NSLog("🔍 onOpenURL appelé avec: \(url.path)")
                    handleFileOpening(url: url)
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        .windowStyle(.automatic)
        .commands {
            // Menu Mac7zip
            CommandGroup(replacing: .appInfo) {
                Button("À propos de Mac7zip") {
                    // TODO: Implémenter avec notification
                }
                
                Divider()
                
                Button("Préférences...") {
                    NotificationCenter.default.post(name: .showPreferences, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
                
                Button("Quitter Mac7zip") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }
            
            // Menu Fichier - garder les éléments natifs + ajouter les nôtres
            CommandGroup(after: .newItem) {
                Button("Nouvelle archive") {
                    // Utiliser FocusedBinding - automatiquement dirigé vers la fenêtre active
                    showNewArchive = true
                }
                .keyboardShortcut("b", modifiers: .command)
                
                Button("Ouvrir archive") {
                    showOpenArchive = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Fermer archive") {
                    showCloseArchive = true
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            
            // Menu Opérations
            CommandGroup(after: .newItem) {
                Button("Extraire") {
                    showExtract = true
                }
                .keyboardShortcut("e", modifiers: .command)
                
                Button("Ajouter des fichiers") {
                    showAddFiles = true
                }
                .keyboardShortcut("a", modifiers: .command)
                
                Divider()
                
                Button("Propriétés") {
                    showProperties = true
                }
                .keyboardShortcut("i", modifiers: .command)
            }
            
            // Menu Options
            CommandGroup(after: .toolbar) {
                Button("Options avancées") {
                    NotificationCenter.default.post(
                        name: .showAdvancedOptions, 
                        object: nil,
                        userInfo: ["activeWindowOnly": true]
                    )
                }
                
                Button("Méthodes de compression") {
                    NotificationCenter.default.post(
                        name: .showCompressionMethods, 
                        object: nil,
                        userInfo: ["activeWindowOnly": true]
                    )
                }
                
                Button("Options de sécurité") {
                    NotificationCenter.default.post(
                        name: .showSecurityOptions, 
                        object: nil,
                        userInfo: ["activeWindowOnly": true]
                    )
                }
            }
        }
    }
    
    // MARK: - Window Management
    private func closeAllWindowsExceptMain() {
        // Fermer toutes les fenêtres sauf la première (fenêtre principale)
        let windows = NSApp.windows
        if windows.count > 1 {
            for i in 1..<windows.count {
                windows[i].close()
            }
        }
        
        // Activer la fenêtre principale
        if let mainWindow = windows.first {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    // MARK: - File Opening Handler
    private func handleFileOpening(url: URL) {
        let fileExtension = url.pathExtension.lowercased()
        NSLog("🔍 handleFileOpening appelée avec: \(url.path) (extension: \(fileExtension))")
        
        // Vérifier que c'est un format supporté
        let supportedFormats = ["7z", "zip", "rar", "tar", "gz", "bz2", "xz", "cab", "iso", "dmg"]
        let compositeFormats = ["tar.gz", "tar.bz2", "tar.xz"]
        
        let fileName = url.lastPathComponent.lowercased()
        let isSupported = supportedFormats.contains(fileExtension) || 
                         compositeFormats.contains { fileName.hasSuffix($0) }
        
        NSLog("🔍 handleFileOpening - fileName: \(fileName), isSupported: \(isSupported)")
        
        if isSupported {
            NSLog("✅ Format supporté, envoi de la notification openArchive")
            // Archive opening will be handled by individual windows
            NotificationCenter.default.post(name: Notification.Name("openArchive"), object: url)
            NSLog("📡 Notification openArchive envoyée avec URL: \(url.path)")
            
            // Forcer l'affichage de la fenêtre principale
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                if let window = NSApp.windows.first {
                    window.makeKeyAndOrderFront(nil)
                    NSLog("🪟 Fenêtre principale activée: \(window.title)")
                }
            }
        } else {
            NSLog("❌ Format non supporté: \(fileExtension)")
            showUnsupportedFormatAlert(fileExtension)
        }
    }
    
    private func showUnsupportedFormatAlert(_ format: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Format non supporté"
            alert.informativeText = "Le format .\(format) n'est pas encore supporté par Mac7zip.\n\nFormats supportés: 7z, ZIP, RAR, TAR, TAR.GZ, TAR.BZ2, TAR.XZ, CAB, ISO, DMG"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
