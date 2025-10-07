import Foundation
import SwiftUI

// MARK: - Archive Errors
enum ArchiveError: LocalizedError {
    case binaryNotFound
    case invalidArchive
    case listFailed
    case extractionFailed
    case creationFailed
    case testFailed(String)
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "Binaire 7zz non trouvé"
        case .invalidArchive:
            return "Archive invalide ou corrompue"
        case .listFailed:
            return "Impossible de lister le contenu de l'archive"
        case .extractionFailed:
            return "Échec de l'extraction"
        case .creationFailed:
            return "Échec de la création de l'archive"
        case .testFailed(let message):
            return message
        case .unsupportedFormat:
            return "Format d'archive non supporté"
        }
    }
}

// MARK: - Archive Manager
class ArchiveManager: NSObject, ObservableObject {
    @Published var currentArchive: ArchiveInfo?
    @Published var archiveItems: [ArchiveItem] = []
    @Published var hierarchicalItems: [ArchiveTreeItem] = []
    @Published var selectedFiles: Set<ArchiveItem> = []
    @Published var currentPath = "/"
    private var currentArchiveEngine: ArchiveEngine?
    private var storedPassword: String?
    
    // Progress tracking
    @Published var progressTracker = ProgressTracker()
    
    // Notifications
    private let notificationManager = NotificationManager.shared
    
    // Logging
    private let logManager = LogManager.shared
    
    // Dialog states
    @Published var showNewArchiveDialog = false
    @Published var showOpenArchiveDialog = false
    @Published var showExtractDialog = false
    @Published var showAddFilesDialog = false
    @Published var showPropertiesPanel = false
    @Published var showBenchmarkDialog = false
    @Published var showAboutDialog = false
    @Published var showPreferencesDialog = false
    @Published var showCompressionMethodsDialog = false
    @Published var showFiltersDialog = false
    @Published var showVolumeDialog = false
    @Published var showAdvancedOptionsDialog = false
    @Published var showSecurityDialog = false
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    
    // Extract document
    var extractDocument: ExtractDocument?
    
    private let archiveEngine: ArchiveEngine

    override init() {
        self.archiveEngine = SevenZipArchiveEngine()
        super.init()
        
        // Handle command line arguments
        if CommandLine.arguments.count > 1 {
            let archivePath = CommandLine.arguments[1]
            if FileManager.default.fileExists(atPath: archivePath) {
                let url = URL(fileURLWithPath: archivePath)
                DispatchQueue.main.async {
                    self.openArchive(at: url)
                }
            }
        }
    }
    
    private func getArchiveEngine(for url: URL) -> ArchiveEngine {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        NSLog("🔍 Analyse du fichier: \(fileName) (extension: \(fileExtension))")
        
        // Formats supportés - vérifier d'abord les extensions composées
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            NSLog("🔍 Sélection du moteur AppleArchiveEngine pour TAR.GZ")
            return AppleArchiveEngine()
        } else if fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz2") {
            NSLog("🔍 Sélection du moteur AppleArchiveEngine pour TAR.BZ2")
            return AppleArchiveEngine()
        }
        
        // Puis vérifier les extensions simples
        switch fileExtension {
        case "rar":
            // RAR utilise ses propres binaires
            NSLog("🔍 Sélection du moteur RAR pour extension: \(fileExtension)")
            return RarArchiveEngine()
        case "7z":
            // 7z utilise 7zz
            NSLog("🔍 Sélection du moteur 7z pour extension: \(fileExtension)")
            return SevenZipArchiveEngine()
        case "zip":
            // ZIP utilise temporairement 7zz pour plus de robustesse
            NSLog("🔍 Sélection du moteur 7z pour extension ZIP: \(fileExtension)")
            return SevenZipArchiveEngine()
        case "tar":
            // TAR utilise AppleArchiveEngine
            NSLog("🔍 Sélection du moteur AppleArchiveEngine pour extension: \(fileExtension)")
            return AppleArchiveEngine()
        default:
            // Par défaut, utiliser 7zz qui supporte la plupart des formats
            NSLog("🔍 Sélection du moteur 7z par défaut pour extension: \(fileExtension)")
            return SevenZipArchiveEngine()
        }
    }
    
    func openArchive(at url: URL) {
        NSLog("🔍 ArchiveManager.openArchive appelé avec: \(url.path)")
        logManager.log("Ouverture de l'archive: \(url.lastPathComponent)", level: .info, category: "archive")
        progressTracker.startOperation("Ouverture de l'archive...", canCancel: false)
        
        Task {
            do {
                NSLog("🔍 Sélection du moteur d'archive pour: \(url.pathExtension)")
                let engine = getArchiveEngine(for: url)
                NSLog("🔍 Moteur sélectionné: \(type(of: engine))")
                
                let archive = try await engine.openArchive(at: url)
                NSLog("✅ Archive parsée avec succès: \(archive.name) (\(archive.fileCount) fichiers)")
                
                await MainActor.run {
                    NSLog("🔍 Mise à jour de l'interface utilisateur")
                    self.currentArchive = archive
                    self.currentArchiveEngine = engine
                    self.progressTracker.finishOperation()
                    self.refreshCurrentArchive()
                    self.logManager.log("Archive ouverte avec succès: \(archive.name)", level: .info, category: "archive")
                    NSLog("✅ Archive ouverte et interface mise à jour")
                }
            } catch {
                NSLog("❌ Erreur lors de l'ouverture de l'archive: \(error)")
                
                // Check if it's a password error
                if error.localizedDescription.contains("password") || error.localizedDescription.contains("mot de passe") {
                    await MainActor.run {
                        self.progressTracker.finishOperation()
                        self.showPasswordDialog(for: url)
                    }
                } else {
                    await MainActor.run {
                        self.progressTracker.finishOperation()
                        self.showError(error.localizedDescription)
                        self.logManager.log("Erreur lors de l'ouverture de l'archive: \(error.localizedDescription)", level: .error, category: "archive")
                    }
                }
            }
        }
    }
    
    private func showPasswordDialog(for url: URL) {
        let alert = NSAlert()
        alert.messageText = "Archive protégée par mot de passe"
        alert.informativeText = "Cette archive est chiffrée. Veuillez entrer le mot de passe pour continuer."
        alert.alertStyle = .informational
        
        let passwordField = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        passwordField.placeholderString = "Mot de passe"
        alert.accessoryView = passwordField
        
        alert.addButton(withTitle: "Ouvrir")
        alert.addButton(withTitle: "Annuler")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            let password = passwordField.stringValue
            if !password.isEmpty {
                openArchiveWithPassword(at: url, password: password)
            }
        }
    }
    
    private func openArchiveWithPassword(at url: URL, password: String) {
        NSLog("🔍 Tentative d'ouverture avec mot de passe")
        logManager.log("Ouverture de l'archive avec mot de passe: \(url.lastPathComponent)", level: .info, category: "archive")
        progressTracker.startOperation("Ouverture de l'archive...", canCancel: false)
        
        Task {
            do {
                let engine = getArchiveEngine(for: url)
                // Store password for later use
                self.storedPassword = password
                let archive = try await engine.openArchive(at: url)
                
                await MainActor.run {
                    self.currentArchive = archive
                    self.currentArchiveEngine = engine
                    self.progressTracker.finishOperation()
                    self.refreshCurrentArchive()
                    self.logManager.log("Archive ouverte avec succès avec mot de passe: \(archive.name)", level: .info, category: "archive")
                }
            } catch {
                await MainActor.run {
                    self.progressTracker.finishOperation()
                    self.showError("Mot de passe incorrect ou erreur: \(error.localizedDescription)")
                    self.logManager.log("Erreur avec le mot de passe: \(error.localizedDescription)", level: .error, category: "archive")
                }
            }
        }
    }
    
    func openArchiveWithPanel() {
        NSLog("🔍 Ouverture du sélecteur de fichiers avec NSOpenPanel")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.zip, .data, .archive, .gzip]
        panel.title = "Sélectionner une archive"
        panel.message = "Choisissez une archive à ouvrir"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                NSLog("✅ Fichier sélectionné via NSOpenPanel: \(url.path)")
                DispatchQueue.main.async {
                    self.openArchive(at: url)
                }
            } else {
                NSLog("❌ Sélection annulée ou échouée")
            }
        }
    }
    
    func refreshCurrentArchive() {
        guard let archive = currentArchive else { 
            NSLog("❌ refreshCurrentArchive: Aucune archive courante")
            return 
        }
        
        // Vérifier que le fichier d'archive existe
        guard FileManager.default.fileExists(atPath: archive.url.path) else {
            NSLog("❌ refreshCurrentArchive: Le fichier d'archive n'existe pas: \(archive.url.path)")
            Task { @MainActor in
                self.currentArchive = nil
                self.archiveItems = []
                self.currentArchiveEngine = nil
            }
            return
        }
        
        NSLog("🔍 refreshCurrentArchive: Rafraîchissement de l'archive \(archive.name)")
        
        Task {
            do {
                let engine = currentArchiveEngine ?? archiveEngine
                NSLog("🔍 refreshCurrentArchive: Utilisation du moteur \(type(of: engine))")
                NSLog("🔍 refreshCurrentArchive: Chemin de l'archive: \(archive.url.path)")
                NSLog("🔍 refreshCurrentArchive: Chemin courant: \(currentPath)")
                
                let items = try await engine.listContents(of: archive.url, path: currentPath)
                NSLog("✅ refreshCurrentArchive: \(items.count) éléments trouvés")
                
                await MainActor.run {
                    self.archiveItems = items
        // Construire l'arbre hiérarchique
        self.hierarchicalItems = self.buildHierarchicalTree(from: items)
        NSLog("✅ Arbre hiérarchique construit: \(self.hierarchicalItems.count) items racine")
        
        // Debug de l'arbre
        for (index, rootItem) in self.hierarchicalItems.enumerated() {
            NSLog("🌳 Root[\(index)]: \(rootItem.name) (dir: \(rootItem.isDirectory), enfants: \(rootItem.children.count))")
            for (childIndex, child) in rootItem.children.enumerated() {
                NSLog("🌳   Child[\(childIndex)]: \(child.name) (dir: \(child.isDirectory))")
            }
        }
                }
            } catch {
                NSLog("❌ refreshCurrentArchive: Erreur lors du listage: \(error)")
                NSLog("❌ refreshCurrentArchive: Type d'erreur: \(type(of: error))")
                
                await MainActor.run {
                    // Ne pas afficher l'erreur si aucune archive n'a été explicitement ouverte
                    if self.currentArchive != nil {
                        self.showError("Impossible de lister le contenu de l'archive")
                    }
                    // Réinitialiser l'état
                    self.currentArchive = nil
                    self.archiveItems = []
                    self.hierarchicalItems = []
                    self.currentArchiveEngine = nil
                }
            }
        }
    }
    
    func addFiles(_ files: [URL], options: ArchiveOptions) {
        // Implementation à compléter
    }
    
    func extractTo(url: URL) {
        guard let archive = currentArchive else { return }
        
        Task {
            do {
                let engine = currentArchiveEngine ?? archiveEngine
                let options = ArchiveOptions()
                try await engine.extractArchive(at: archive.url, to: url, options: options)
                await MainActor.run {
                    self.showSuccess("Extraction terminée avec succès")
                    self.notificationManager.sendArchiveExtractedNotification(archiveName: archive.name)
                }
            } catch {
                await MainActor.run {
                    self.showError("Erreur lors de l'extraction: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func extractSelectedFiles(to url: URL) {
        guard let archive = currentArchive else { return }
        
        Task {
            do {
                let engine = currentArchiveEngine ?? archiveEngine
                let options = ArchiveOptions()
                
                // Extraire seulement les fichiers sélectionnés
                let selectedPaths = selectedFiles.map { $0.path }
                try await engine.extractFiles(from: archive.url, files: selectedPaths, to: url, options: options)
                
                await MainActor.run {
                    self.showSuccess("Extraction des fichiers sélectionnés terminée")
                }
            } catch {
                await MainActor.run {
                    self.showError("Erreur lors de l'extraction: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showSuccess(_ message: String) {
        // Implementation des notifications de succès
        NSLog("✅ \(message)")
    }
    
    func testCurrentArchive() {
        guard let archive = currentArchive else { return }
        
        Task {
            do {
                let engine = currentArchiveEngine ?? archiveEngine
                try await engine.testArchive(at: archive.url, options: ArchiveOptions())
                await MainActor.run {
                    self.showSuccess("L'archive est valide")
                    // Notification de test réussi
                    NSLog("✅ Archive testée avec succès: \(archive.name)")
                }
            } catch {
                await MainActor.run {
                    self.showError("L'archive est corrompue: \(error.localizedDescription)")
                    // Notification de test échoué
                    NSLog("❌ Archive corrompue: \(archive.name)")
                }
            }
        }
    }
    
    func deleteSelectedFiles() {
        guard let archive = currentArchive, !selectedFiles.isEmpty else { return }
        
        Task {
            do {
                let engine = currentArchiveEngine ?? archiveEngine
                let filesToDelete = selectedFiles.map { $0.path }
                try await engine.deleteFiles(from: archive.url, files: filesToDelete, options: ArchiveOptions())
                await MainActor.run {
                    self.selectedFiles.removeAll()
                    self.refreshCurrentArchive()
                    self.showSuccess("Fichiers supprimés avec succès")
                }
            } catch {
                await MainActor.run {
                    self.showError("Erreur lors de la suppression: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func closeCurrentArchive() {
        currentArchive = nil
        archiveItems = []
        selectedFiles.removeAll()
        currentPath = "/"
    }
    
    func navigateUp() {
        let pathComponents = currentPath.components(separatedBy: "/").filter { !$0.isEmpty }
        if pathComponents.count > 1 {
            currentPath = "/" + pathComponents.dropLast().joined(separator: "/")
        } else {
            currentPath = "/"
        }
        refreshCurrentArchive()
    }
    
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        NSLog("🚀 ArchiveManager.createArchive appelé - URL: \(url.path)")
        NSLog("🚀 ArchiveManager.createArchive - Fichiers: \(files.count)")
        NSLog("🚀 ArchiveManager.createArchive - Format: \(options.format.rawValue)")
        print("🚀 ArchiveManager.createArchive appelé - URL: \(url.path)")
        print("🚀 ArchiveManager.createArchive - Fichiers: \(files.count)")
        print("🚀 ArchiveManager.createArchive - Format: \(options.format.rawValue)")
        
        // Log détaillé des fichiers
        for (index, file) in files.enumerated() {
            NSLog("🚀 Fichier \(index): \(file.path)")
            print("🚀 Fichier \(index): \(file.path)")
        }
        
        do {
            // Sélectionner le moteur approprié selon le format
            let engine = getArchiveEngine(for: url)
            NSLog("🚀 Moteur sélectionné: \(type(of: engine)) pour format: \(url.pathExtension)")
            print("🚀 Moteur sélectionné: \(type(of: engine)) pour format: \(url.pathExtension)")
            
            try await engine.createArchive(at: url, files: files, options: options)
            NSLog("🚀 createArchive terminé avec succès")
            print("🚀 createArchive terminé avec succès")
            
            await MainActor.run {
                self.showSuccess("Archive créée avec succès: \(url.lastPathComponent)")
                self.notificationManager.sendArchiveCreatedNotification(archiveName: url.lastPathComponent)
            }
        } catch {
            NSLog("❌ Erreur dans createArchive: \(error.localizedDescription)")
            NSLog("❌ Type d'erreur: \(type(of: error))")
            print("❌ Erreur dans createArchive: \(error.localizedDescription)")
            print("❌ Type d'erreur: \(type(of: error))")
            await MainActor.run {
                self.showError("Erreur lors de la création de l'archive: \(error.localizedDescription)")
            }
            throw error
        }
    }
    
    func copySelectedFiles() {
        // Implementation à compléter
    }
    
    func pasteFiles() {
        // Implementation à compléter
    }
    
    func showDocumentation() {
        if let url = URL(string: "https://github.com/mac7zip/Mac7zip/wiki") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openOfficialWebsite() {
        if let url = URL(string: "https://www.7-zip.org/") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    // MARK: - Hierarchical Tree Building
    func buildHierarchicalTree(from flatItems: [ArchiveItem]) -> [ArchiveTreeItem] {
        var pathToItem: [String: ArchiveTreeItem] = [:]
        var rootItems: [ArchiveTreeItem] = []
        
        // Trier les items par chemin pour traiter les parents avant les enfants
        let sortedItems = flatItems.sorted { $0.path < $1.path }
        
        for item in sortedItems {
            let treeItem = ArchiveTreeItem(
                name: item.name,
                path: item.path,
                isDirectory: item.isDirectory,
                size: item.size,
                compressedSize: item.compressedSize,
                modificationDate: item.modificationDate,
                compressionMethod: item.compressionMethod
            )
            
            pathToItem[item.path] = treeItem
            
            // Trouver le parent
            let pathComponents = item.path.split(separator: "/").map(String.init)
            
            if pathComponents.count == 1 {
                // Item racine
                rootItems.append(treeItem)
            } else {
                // Item avec parent
                let parentPath = pathComponents.dropLast().joined(separator: "/")
                
                if let parentItem = pathToItem[parentPath] {
                    parentItem.children.append(treeItem)
                } else {
                    // Créer les dossiers parents manquants
                    createMissingParents(for: item.path, pathToItem: &pathToItem, rootItems: &rootItems)
                    if let parentItem = pathToItem[parentPath] {
                        parentItem.children.append(treeItem)
                    }
                }
            }
        }
        
        // Trier récursivement tous les niveaux
        sortTreeItemsRecursively(&rootItems)
        
        return rootItems
    }
    
    private func createMissingParents(for path: String, pathToItem: inout [String: ArchiveTreeItem], rootItems: inout [ArchiveTreeItem]) {
        let pathComponents = path.split(separator: "/").map(String.init)
        var currentPath = ""
        
        for (index, component) in pathComponents.dropLast().enumerated() {
            currentPath = index == 0 ? component : currentPath + "/" + component
            
            if pathToItem[currentPath] == nil {
                let parentItem = ArchiveTreeItem(
                    name: component,
                    path: currentPath,
                    isDirectory: true,
                    size: 0,
                    compressedSize: 0,
                    modificationDate: nil,
                    compressionMethod: nil
                )
                
                pathToItem[currentPath] = parentItem
                
                if index == 0 {
                    rootItems.append(parentItem)
                } else {
                    let grandParentPath = pathComponents[0..<index].joined(separator: "/")
                    if let grandParentItem = pathToItem[grandParentPath] {
                        grandParentItem.children.append(parentItem)
                    }
                }
            }
        }
    }
    
    private func sortTreeItemsRecursively(_ items: inout [ArchiveTreeItem]) {
        // Trier par : dossiers d'abord, puis par nom
        items.sort { item1, item2 in
            if item1.isDirectory && !item2.isDirectory {
                return true
            } else if !item1.isDirectory && item2.isDirectory {
                return false
            } else {
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }
        }
        
        // Trier récursivement les enfants
        for item in items {
            sortTreeItemsRecursively(&item.children)
        }
    }
    
    func extractArchive(at url: URL, to destination: URL, options: ArchiveOptions) async throws {
        guard let engine = currentArchiveEngine else {
            throw ArchiveError.binaryNotFound
        }
        
        try await engine.extractArchive(at: url, to: destination, options: options)
    }
}

// MARK: - Archive Engine Protocol
protocol ArchiveEngine {
    func openArchive(at url: URL) async throws -> ArchiveInfo
    func listContents(of url: URL, path: String) async throws -> [ArchiveItem]
    func extractArchive(at url: URL, to destination: URL, options: ArchiveOptions) async throws
    func extractFiles(from url: URL, files: [String], to destination: URL, options: ArchiveOptions) async throws
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws
    func addFiles(to url: URL, files: [URL], options: ArchiveOptions) async throws
    func deleteFiles(from url: URL, files: [String], options: ArchiveOptions) async throws
    func testArchive(at url: URL, options: ArchiveOptions) async throws
}

// MARK: - SevenZip Archive Engine
class SevenZipArchiveEngine: ArchiveEngine {
    private let sevenZipPath: String
    
    init() {
        // Chercher le binaire 7zz dans Resources
        if let sevenZipDirectPath = Bundle.main.path(forResource: "7zz", ofType: nil) {
            self.sevenZipPath = sevenZipDirectPath
            NSLog("✅ Binaire 7zz trouvé dans Resources: \(sevenZipDirectPath)")
        } else {
            let bundlePath = Bundle.main.bundlePath
            self.sevenZipPath = bundlePath + "/Contents/Resources/7zz"
            NSLog("✅ Binaire 7zz cherché dans bundle: \(bundlePath)/Contents/Resources/7zz")
        }
        
        // Vérifier que le binaire existe et est exécutable
        if !FileManager.default.fileExists(atPath: sevenZipPath) {
            NSLog("❌ Binaire 7zz non trouvé: \(sevenZipPath)")
        } else {
            NSLog("✅ Binaire 7zz existe: \(sevenZipPath)")
        }
        
        if !FileManager.default.isExecutableFile(atPath: sevenZipPath) {
            NSLog("❌ Binaire 7zz non exécutable: \(sevenZipPath)")
        } else {
            NSLog("✅ Binaire 7zz exécutable: \(sevenZipPath)")
        }
    }
    
    func openArchive(at url: URL) async throws -> ArchiveInfo {
        NSLog("🔍 SevenZipArchiveEngine.openArchive appelé avec: \(url.path)")
        
        NSLog("✅ Binaire 7zz trouvé: \(sevenZipPath)")
        
        // Test if archive is valid and get basic info
        NSLog("🔍 Test de l'archive avec 7zz...")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["t", url.path, "-y"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        NSLog("📊 Code de sortie du test: \(process.terminationStatus)")
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            NSLog("❌ Erreur lors du test: \(output)")
            throw ArchiveError.invalidArchive
        }
        
        NSLog("✅ Test d'archive réussi, récupération des informations...")
        
        // Get archive info using list command
        let listProcess = Process()
        listProcess.executableURL = URL(fileURLWithPath: sevenZipPath)
        listProcess.arguments = ["l", url.path, "-slt", "-y"]
        
        let listPipe = Pipe()
        listProcess.standardOutput = listPipe
        listProcess.standardError = listPipe
        
        try listProcess.run()
        listProcess.waitUntilExit()
        
        let data = listPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        NSLog("📋 Sortie de la commande list:")
        NSLog("📋 \(output)")
        
        let archiveInfo = parseArchiveInfo(from: output, url: url)
        NSLog("✅ ArchiveInfo créé: \(archiveInfo.name) (\(archiveInfo.fileCount) fichiers)")
        
        return archiveInfo
    }
    
    func listContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["l", url.path, "-slt"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.listFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseArchiveItems(from: output, currentPath: path)
    }
    
    func extractArchive(at url: URL, to destination: URL, options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["x", url.path, "-o\(destination.path)", "-y"]
        
        if let password = options.password {
            process.arguments?.append("-p\(password)")
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    func extractFiles(from url: URL, files: [String], to destination: URL, options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["x", url.path, "-o\(destination.path)", "-y"]
        
        // Ajouter les fichiers spécifiques à extraire
        for file in files {
            process.arguments?.append(file)
        }
        
        if let password = options.password {
            process.arguments?.append("-p\(password)")
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        NSLog("🚀 DEBUT createArchive - URL: \(url.path)")
        NSLog("🚀 DEBUT createArchive - Fichiers: \(files.count)")
        print("🚀 DEBUT createArchive - URL: \(url.path)")
        print("🚀 DEBUT createArchive - Fichiers: \(files.count)")
        
        NSLog("✅ Binaire 7zz trouvé: \(sevenZipPath)")
        print("✅ Binaire 7zz trouvé: \(sevenZipPath)")
        
        // Vérifier que le binaire existe
        guard FileManager.default.fileExists(atPath: sevenZipPath) else {
            NSLog("❌ Binaire 7zz introuvable: \(sevenZipPath)")
            print("❌ Binaire 7zz introuvable: \(sevenZipPath)")
            throw ArchiveError.binaryNotFound
        }
        
        // Vérifier que le binaire est exécutable
        guard FileManager.default.isExecutableFile(atPath: sevenZipPath) else {
            NSLog("❌ Binaire 7zz non exécutable: \(sevenZipPath)")
            print("❌ Binaire 7zz non exécutable: \(sevenZipPath)")
            throw ArchiveError.binaryNotFound
        }
        
        NSLog("✅ Binaire 7zz validé et prêt: \(sevenZipPath)")
        print("✅ Binaire 7zz validé et prêt: \(sevenZipPath)")
        
        // Vérifications préalables
        NSLog("🔍 Vérification des fichiers sources...")
        for file in files {
            guard FileManager.default.fileExists(atPath: file.path) else {
                NSLog("❌ Fichier source introuvable: \(file.path)")
                throw ArchiveError.creationFailed
            }
        }
        
        // Vérifier le dossier de destination
        let destinationDir = url.deletingLastPathComponent()
        guard FileManager.default.fileExists(atPath: destinationDir.path) else {
            NSLog("❌ Dossier de destination introuvable: \(destinationDir.path)")
            throw ArchiveError.creationFailed
        }
        
        // Vérifier les permissions d'écriture
        guard FileManager.default.isWritableFile(atPath: destinationDir.path) else {
            NSLog("❌ Pas de permission d'écriture dans: \(destinationDir.path)")
            throw ArchiveError.creationFailed
        }
        
        NSLog("🔍 Création d'archive avec 7zz: \(sevenZipPath)")
        NSLog("🔍 Fichiers à compresser: \(files.map { $0.path })")
        NSLog("🔍 Archive de destination: \(url.path)")
        print("🔍 Création d'archive avec 7zz: \(sevenZipPath)")
        print("🔍 Fichiers à compresser: \(files.map { $0.path })")
        print("🔍 Archive de destination: \(url.path)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["a", url.path]
        
        // Forcer le format 7z si nécessaire
        if url.pathExtension.lowercased() == "7z" {
            process.arguments?.append("-t7z")
        }
        
        // Ajouter les fichiers (utiliser le chemin complet)
        for file in files {
            process.arguments?.append(file.path)
        }
        
        // Options de compression
        process.arguments?.append("-mx\(options.compressionLevel)")
        
        // Méthode de compression spécifique si définie
        if let sevenZipOptions = options.sevenZipOptions {
            let method = sevenZipOptions.compressionMethod.rawValue
            process.arguments?.append("-m0=\(method)")
        }
        
        if let password = options.password {
            process.arguments?.append("-p\(password)")
        }
        
        if options.encryptFileNames {
            process.arguments?.append("-mhe")
        }
        
        if options.solidArchive {
            process.arguments?.append("-ms")
        }
        
        if options.multithreading {
            process.arguments?.append("-mmt")
        }
        
        if let volumeSize = options.volumeSize {
            process.arguments?.append("-v\(volumeSize)")
        }
        
        if options.createSFX {
            process.arguments?.append("-sfx")
        }
        
        if options.deleteAfterCompression {
            process.arguments?.append("-sdel")
        }
        
        // Toujours dire oui
        process.arguments?.append("-y")
        
        NSLog("🔍 Commande 7zz: \(sevenZipPath) \(process.arguments?.joined(separator: " ") ?? "")")
        print("🔍 Commande 7zz: \(sevenZipPath) \(process.arguments?.joined(separator: " ") ?? "")")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            NSLog("🔍 Lancement du processus 7zz...")
            print("🔍 Lancement du processus 7zz...")
            try process.run()
            NSLog("🔍 Processus lancé, attente de la fin...")
            print("🔍 Processus lancé, attente de la fin...")
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            NSLog("📊 Code de sortie: \(process.terminationStatus)")
            NSLog("📋 Sortie 7zz: \(output)")
            print("📊 Code de sortie: \(process.terminationStatus)")
            print("📋 Sortie 7zz: \(output)")
            
            if process.terminationStatus != 0 {
                NSLog("❌ Erreur lors de la création de l'archive - Code: \(process.terminationStatus)")
                NSLog("❌ Sortie d'erreur 7zz: \(output)")
                print("❌ Erreur lors de la création de l'archive - Code: \(process.terminationStatus)")
                print("❌ Sortie d'erreur 7zz: \(output)")
                
                // Analyser l'erreur spécifique
                if output.contains("Cannot open file") {
                    NSLog("❌ Erreur: Impossible d'ouvrir le fichier")
                    throw ArchiveError.creationFailed
                } else if output.contains("Access denied") {
                    NSLog("❌ Erreur: Accès refusé")
                    throw ArchiveError.creationFailed
                } else if output.contains("No space left") {
                    NSLog("❌ Erreur: Espace disque insuffisant")
                    throw ArchiveError.creationFailed
                } else if output.contains("Unsupported archive type") {
                    NSLog("❌ Erreur: Type d'archive non supporté")
                    throw ArchiveError.creationFailed
                } else if output.contains("Unsupported method") {
                    NSLog("❌ Erreur: Méthode de compression non supportée")
                    throw ArchiveError.creationFailed
                } else if output.contains("Command Line Error") {
                    NSLog("❌ Erreur: Erreur de ligne de commande - Arguments invalides")
                    throw ArchiveError.creationFailed
                } else if output.contains("Unknown switch") {
                    NSLog("❌ Erreur: Paramètre inconnu - Vérifier les arguments")
                    throw ArchiveError.creationFailed
                } else {
                    NSLog("❌ Erreur inconnue: \(output)")
                    throw ArchiveError.creationFailed
                }
            }
            
            // Vérifier si l'archive a été créée
            if FileManager.default.fileExists(atPath: url.path) {
                let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
                NSLog("✅ Archive 7z créée avec succès - Taille: \(fileSize ?? 0) bytes")
                print("✅ Archive 7z créée avec succès - Taille: \(fileSize ?? 0) bytes")
            } else {
                NSLog("❌ Archive 7z non créée - Fichier inexistant: \(url.path)")
                print("❌ Archive 7z non créée - Fichier inexistant: \(url.path)")
                throw ArchiveError.creationFailed
            }
            
            NSLog("✅ Archive créée avec succès")
            print("✅ Archive créée avec succès")
        } catch {
            NSLog("❌ Erreur lors de l'exécution de 7zz: \(error)")
            NSLog("❌ Type d'erreur: \(type(of: error))")
            print("❌ Erreur lors de l'exécution de 7zz: \(error)")
            print("❌ Type d'erreur: \(type(of: error))")
            throw ArchiveError.creationFailed
        }
    }
    
    func addFiles(to url: URL, files: [URL], options: ArchiveOptions) async throws {
        // Implementation à compléter
    }
    
    func deleteFiles(from url: URL, files: [String], options: ArchiveOptions) async throws {
        // Implementation à compléter
    }
    
    func testArchive(at url: URL, options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: sevenZipPath)
        process.arguments = ["t", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? "Erreur inconnue"
            throw ArchiveError.testFailed(output)
        }
    }
    
    // MARK: - Parsing Functions
    private func parseArchiveInfo(from output: String, url: URL) -> ArchiveInfo {
        let lines = output.components(separatedBy: .newlines)
        var fileCount = 0
        var compressedSize: Int64 = 0
        var isEncrypted = false
        
        // Count files by counting "Path = " lines that are not the archive itself
        var filePaths: [String] = []
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("Path = ") {
                let path = trimmedLine.replacingOccurrences(of: "Path = ", with: "")
                if path != url.lastPathComponent {
                    filePaths.append(path)
                }
            } else if trimmedLine.hasPrefix("Physical Size = ") {
                if let size = Int64(trimmedLine.replacingOccurrences(of: "Physical Size = ", with: "")) {
                    compressedSize = size
                }
            } else if trimmedLine.contains("Encrypted = +") {
                isEncrypted = true
            }
        }
        
        fileCount = filePaths.count
        
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: fileCount,
            compressedSize: compressedSize,
            isEncrypted: isEncrypted
        )
    }
    
    private func parseArchiveItems(from output: String, currentPath: String) -> [ArchiveItem] {
        let lines = output.components(separatedBy: .newlines)
        var items: [ArchiveItem] = []
        var currentItem: [String: String] = [:]
        var inFileSection = false
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if we're entering a file section
            if trimmedLine == "----------" {
                inFileSection = true
                continue
            }
            
            // Skip archive header info
            if !inFileSection {
                continue
            }
            
            if trimmedLine.isEmpty {
                if !currentItem.isEmpty {
                    if let item = createArchiveItem(from: currentItem, currentPath: currentPath) {
                        items.append(item)
                    }
                    currentItem = [:]
                }
            } else if trimmedLine.contains(" = ") {
                let components = trimmedLine.components(separatedBy: " = ")
                if components.count == 2 {
                    currentItem[components[0]] = components[1]
                }
            }
        }
        
        // Process last item if exists
        if !currentItem.isEmpty {
            if let item = createArchiveItem(from: currentItem, currentPath: currentPath) {
                items.append(item)
            }
        }
        
        return items
    }
    
    private func createArchiveItem(from attributes: [String: String], currentPath: String) -> ArchiveItem? {
        guard let path = attributes["Path"] else {
            return nil
        }
        
        let size = Int64(attributes["Size"] ?? "0") ?? 0
        let compressedSize = Int64(attributes["Packed Size"] ?? "0") ?? 0
        
        let name = URL(fileURLWithPath: path).lastPathComponent
        let isDirectory = attributes["Folder"] == "+" || 
                         (attributes["Attributes"]?.hasPrefix("D") == true) ||
                         path.hasSuffix("/")
        
        return ArchiveItem(
            name: name,
            path: path,
            size: size,
            compressedSize: compressedSize,
            isDirectory: isDirectory,
            attributes: attributes,
            compressionMethod: attributes["Method"],
            crc: attributes["CRC"],
            modificationDate: parseDate(from: attributes["Modified"])
        )
    }
    
    private func parseDate(from dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: dateString)
    }
}


// MARK: - Data Models
struct ArchiveInfo {
    let url: URL
    let name: String
    let fileCount: Int
    let compressedSize: Int64
    let isEncrypted: Bool
}

struct ArchiveItem: Identifiable, Hashable, Equatable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let compressedSize: Int64
    let isDirectory: Bool
    let attributes: [String: String]
    let compressionMethod: String?
    let crc: String?
    let modificationDate: Date?
    
    static func == (lhs: ArchiveItem, rhs: ArchiveItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct ArchiveOptions {
    let format: ArchiveFormat
    let compressionLevel: Int
    let password: String?
    let encryptFileNames: Bool
    let createSFX: Bool
    let volumeSize: String?
    let solidArchive: Bool
    let multithreading: Bool
    let deleteAfterCompression: Bool
    let sevenZipOptions: SevenZipOptions?
    
    init(format: ArchiveFormat = .sevenZip,
         compressionLevel: Int = 5,
         password: String? = nil,
         encryptFileNames: Bool = false,
         createSFX: Bool = false,
         volumeSize: String? = nil,
         solidArchive: Bool = true,
         multithreading: Bool = true,
         deleteAfterCompression: Bool = false,
         sevenZipOptions: SevenZipOptions? = nil) {
        self.format = format
        self.compressionLevel = compressionLevel
        self.password = password
        self.encryptFileNames = encryptFileNames
        self.createSFX = createSFX
        self.volumeSize = volumeSize
        self.solidArchive = solidArchive
        self.multithreading = multithreading
        self.deleteAfterCompression = deleteAfterCompression
        self.sevenZipOptions = sevenZipOptions
    }
}

enum ArchiveFormat: String, CaseIterable {
    case sevenZip = "7z"
    case zip = "zip"
    case rar = "rar"
    case tar = "tar"
    case gzip = "tar.gz"
    case bzip2 = "tar.bz2"
    
    var displayName: String {
        switch self {
        case .sevenZip: return "7z"
        case .zip: return "ZIP"
        case .rar: return "RAR"
        case .tar: return "TAR"
        case .gzip: return "TAR.GZ"
        case .bzip2: return "TAR.BZ2"
        }
    }
    
    var fileExtension: String {
        return "." + rawValue
    }
    
    var canCreate: Bool {
        return true // Tous les formats peuvent être créés
    }
    
    var supportsEncryption: Bool {
        switch self {
        case .sevenZip, .zip, .rar:
            return true
        default:
            return false
        }
    }
}

// MARK: - Extract Document
struct ExtractDocument {
    // Simplified implementation
}

// MARK: - SevenZip Options (simplified)
struct SevenZipOptions {
    var compressionMethod: SevenZipCompressionMethod = .lzma2
    var compressionLevel: Int = 5
    var solidMode: Bool = true
    var encryptData: Bool = false
    var encryptHeaders: Bool = false
    var multithreading: Bool = true
    var volumeSizes: [String] = []
    var includePatterns: [String] = []
    var excludePatterns: [String] = []
    var deleteAfterCompression: Bool = false
    var createSFX: Bool = false
}

enum SevenZipCompressionMethod: String, CaseIterable {
    case lzma = "LZMA"
    case lzma2 = "LZMA2"
    case ppmd = "PPMd"
    case bzip2 = "BZip2"
    case deflate = "Deflate"
    case copy = "Copy"
    
    var displayName: String {
        switch self {
        case .lzma: return "LZMA"
        case .lzma2: return "LZMA2"
        case .ppmd: return "PPMd"
        case .bzip2: return "BZip2"
        case .deflate: return "Deflate"
        case .copy: return "Copie (sans compression)"
        }
    }
}

// MARK: - RAR Archive Engine
class RarArchiveEngine: ArchiveEngine {
    private let rarPath: String
    private let unrarPath: String
    
    init() {
        // Chemin vers les binaires RAR dans le bundle
        if let rarBundlePath = Bundle.main.path(forResource: "rar", ofType: nil),
           let unrarBundlePath = Bundle.main.path(forResource: "unrar", ofType: nil) {
            self.rarPath = rarBundlePath
            self.unrarPath = unrarBundlePath
        } else if let resourcePath = Bundle.main.resourcePath {
            // Fallback vers les binaires dans Resources
            self.rarPath = resourcePath + "/rar"
            self.unrarPath = resourcePath + "/unrar"
        } else {
            // Dernier fallback - utiliser les noms des binaires directement
            self.rarPath = "rar"
            self.unrarPath = "unrar"
            NSLog("⚠️ Binaires RAR non trouvés dans le bundle, utilisation des noms directs")
        }
        
        // Vérifier que les binaires existent et sont exécutables
        if !FileManager.default.fileExists(atPath: rarPath) {
            NSLog("❌ Binaire RAR non trouvé: \(rarPath)")
        }
        if !FileManager.default.fileExists(atPath: unrarPath) {
            NSLog("❌ Binaire UNRAR non trouvé: \(unrarPath)")
        }
    }
    
    // MARK: - ArchiveEngine Protocol Implementation
    
    func openArchive(at url: URL) async throws -> ArchiveInfo {
        let items = try await listContents(of: url, path: "/")
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: items.count,
            compressedSize: items.reduce(0) { $0 + $1.compressedSize },
            isEncrypted: false // Pour l'instant, on assume pas de chiffrement détecté
        )
    }
    
    func listContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let arguments = ["vt", url.path]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unrarPath)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus != 0 {
                throw ArchiveError.listFailed
            }
            
            return parseRarListing(output)
        } catch {
            throw ArchiveError.listFailed
        }
    }
    
    func extractArchive(at url: URL, to destination: URL, options: ArchiveOptions) async throws {
        var arguments = ["x", url.path, destination.path + "/"]
        
        // Ajouter le mot de passe si fourni
        if let password = options.password, !password.isEmpty {
            arguments.append("-p\(password)")
        }
        
        // Options d'extraction
        arguments.append("-o+") // Écraser les fichiers existants
        arguments.append("-y")  // Répondre oui à toutes les questions
        
        // Log pour debug
        NSLog("🔍 Commande UNRAR extract: \(unrarPath) \(arguments.joined(separator: " "))")
        print("🔍 Commande UNRAR extract: \(unrarPath) \(arguments.joined(separator: " "))")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unrarPath)
        process.arguments = arguments
        
        // Capturer la sortie et les erreurs
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            NSLog("📊 Code de sortie UNRAR extract: \(process.terminationStatus)")
            NSLog("📋 Sortie UNRAR extract: \(output)")
            print("📊 Code de sortie UNRAR extract: \(process.terminationStatus)")
            print("📋 Sortie UNRAR extract: \(output)")
            
            if process.terminationStatus != 0 {
                NSLog("❌ Erreur UNRAR extract - Code de sortie: \(process.terminationStatus)")
                NSLog("❌ Sortie d'erreur UNRAR extract: \(output)")
                print("❌ Erreur UNRAR extract - Code de sortie: \(process.terminationStatus)")
                print("❌ Sortie d'erreur UNRAR extract: \(output)")
                throw ArchiveError.extractionFailed
            }
            
            NSLog("✅ Extraction RAR réussie")
            print("✅ Extraction RAR réussie")
        } catch {
            NSLog("❌ Erreur lors de l'extraction RAR: \(error.localizedDescription)")
            print("❌ Erreur lors de l'extraction RAR: \(error.localizedDescription)")
            throw ArchiveError.extractionFailed
        }
    }
    
    func extractFiles(from url: URL, files: [String], to destination: URL, options: ArchiveOptions) async throws {
        var arguments = ["x", url.path] + files + [destination.path + "/"]
        
        // Ajouter le mot de passe si fourni
        if let password = options.password, !password.isEmpty {
            arguments.append("-p\(password)")
        }
        
        // Options d'extraction
        arguments.append("-o+") // Écraser les fichiers existants
        arguments.append("-y")  // Répondre oui à toutes les questions
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unrarPath)
        process.arguments = arguments
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                throw ArchiveError.extractionFailed
            }
        } catch {
            throw ArchiveError.extractionFailed
        }
    }
    
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        NSLog("🚀 RarArchiveEngine.createArchive DÉBUT - URL: \(url.path)")
        NSLog("🚀 RarArchiveEngine.createArchive - Fichiers: \(files.count)")
        print("🚀 RarArchiveEngine.createArchive DÉBUT - URL: \(url.path)")
        print("🚀 RarArchiveEngine.createArchive - Fichiers: \(files.count)")
        
        // Vérifier que le binaire RAR existe
        guard FileManager.default.fileExists(atPath: rarPath) else {
            NSLog("❌ Binaire RAR introuvable: \(rarPath)")
            print("❌ Binaire RAR introuvable: \(rarPath)")
            throw ArchiveError.binaryNotFound
        }
        
        // Vérifier que le binaire est exécutable
        guard FileManager.default.isExecutableFile(atPath: rarPath) else {
            NSLog("❌ Binaire RAR non exécutable: \(rarPath)")
            print("❌ Binaire RAR non exécutable: \(rarPath)")
            throw ArchiveError.binaryNotFound
        }
        
        NSLog("✅ Binaire RAR trouvé et exécutable: \(rarPath)")
        print("✅ Binaire RAR trouvé et exécutable: \(rarPath)")
        
        // Vérifications préalables
        NSLog("🔍 Vérification des fichiers sources...")
        for file in files {
            guard FileManager.default.fileExists(atPath: file.path) else {
                NSLog("❌ Fichier source introuvable: \(file.path)")
                throw ArchiveError.creationFailed
            }
        }
        
        // Vérifier le dossier de destination
        let destinationDir = url.deletingLastPathComponent()
        guard FileManager.default.fileExists(atPath: destinationDir.path) else {
            NSLog("❌ Dossier de destination introuvable: \(destinationDir.path)")
            throw ArchiveError.creationFailed
        }
        
        // Vérifier les permissions d'écriture
        guard FileManager.default.isWritableFile(atPath: destinationDir.path) else {
            NSLog("❌ Pas de permission d'écriture dans: \(destinationDir.path)")
            throw ArchiveError.creationFailed
        }
        
        let filePaths = files.map { $0.path }
        var arguments = ["a"] // Commande de base
        
        // Exclure l'arborescence des dossiers
        arguments.append("-ep1")
        
        // Méthode de compression RAR (utiliser le niveau de compression) - AVANT les fichiers
        let rarMethod = getRarCompressionMethod(from: options.compressionLevel)
        arguments.append("-m\(rarMethod)")
        
        // Mode solide si activé - AVANT les fichiers
        if options.solidArchive {
            arguments.append("-s")
        }
        
        // Chiffrement - AVANT les fichiers
        if let password = options.password, !password.isEmpty {
            arguments.append("-p\(password)")
            if options.encryptFileNames {
                arguments.append("-hp\(password)")
            }
        }
        
        // Volumes si spécifié - AVANT les fichiers
        if let volumeSize = options.volumeSize, !volumeSize.isEmpty && volumeSize != "Aucune division" {
            arguments.append("-v\(volumeSize)")
        }
        
        // Récursion par défaut - AVANT les fichiers
        arguments.append("-r")
        
        // Répondre oui à toutes les questions - AVANT les fichiers
        arguments.append("-y")
        
        // Archive de destination - AVANT les fichiers sources
        arguments.append(url.path)
        
        // Fichiers sources - EN DERNIER
        arguments.append(contentsOf: filePaths)
        
        NSLog("🔍 Création d'archive avec RAR: \(rarPath)")
        NSLog("🔍 Fichiers à compresser: \(filePaths)")
        NSLog("🔍 Archive de destination: \(url.path)")
        print("🔍 Création d'archive avec RAR: \(rarPath)")
        print("🔍 Fichiers à compresser: \(filePaths)")
        print("🔍 Archive de destination: \(url.path)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rarPath)
        process.arguments = arguments
        
        NSLog("🔍 Commande RAR: \(rarPath) \(arguments.joined(separator: " "))")
        print("🔍 Commande RAR: \(rarPath) \(arguments.joined(separator: " "))")
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            NSLog("🔍 Lancement du processus RAR...")
            print("🔍 Lancement du processus RAR...")
            try process.run()
            NSLog("🔍 Processus lancé, attente de la fin...")
            print("🔍 Processus lancé, attente de la fin...")
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            NSLog("📊 Code de sortie: \(process.terminationStatus)")
            NSLog("📋 Sortie RAR: \(output)")
            print("📊 Code de sortie: \(process.terminationStatus)")
            print("📋 Sortie RAR: \(output)")
            
            if process.terminationStatus != 0 {
                NSLog("❌ Erreur lors de la création de l'archive - Code: \(process.terminationStatus)")
                NSLog("❌ Sortie d'erreur RAR: \(output)")
                print("❌ Erreur lors de la création de l'archive - Code: \(process.terminationStatus)")
                print("❌ Sortie d'erreur RAR: \(output)")
                
                // Analyser l'erreur spécifique
                if output.contains("Cannot open file") {
                    NSLog("❌ Erreur: Impossible d'ouvrir le fichier")
                    throw ArchiveError.creationFailed
                } else if output.contains("Access denied") {
                    NSLog("❌ Erreur: Accès refusé")
                    throw ArchiveError.creationFailed
                } else if output.contains("No space left") {
                    NSLog("❌ Erreur: Espace disque insuffisant")
                    throw ArchiveError.creationFailed
                } else if output.contains("Evaluation copy") {
                    NSLog("❌ Erreur: Version d'évaluation RAR")
                    throw ArchiveError.creationFailed
                } else {
                    NSLog("❌ Erreur inconnue: \(output)")
                    throw ArchiveError.creationFailed
                }
            }
            
            // Vérifier si l'archive a été créée
            if FileManager.default.fileExists(atPath: url.path) {
                let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0
                NSLog("✅ Archive RAR créée avec succès - Taille: \(fileSize ?? 0) bytes")
                print("✅ Archive RAR créée avec succès - Taille: \(fileSize ?? 0) bytes")
            } else {
                NSLog("❌ Archive RAR non créée - Fichier inexistant: \(url.path)")
                print("❌ Archive RAR non créée - Fichier inexistant: \(url.path)")
                throw ArchiveError.creationFailed
            }
            
            NSLog("✅ Archive créée avec succès")
            print("✅ Archive créée avec succès")
        } catch {
            NSLog("❌ Erreur lors de l'exécution de RAR: \(error)")
            NSLog("❌ Type d'erreur: \(type(of: error))")
            print("❌ Erreur lors de l'exécution de RAR: \(error)")
            print("❌ Type d'erreur: \(type(of: error))")
            throw ArchiveError.creationFailed
        }
    }
    
    // MARK: - RAR Helper Methods
    
    private func getRarCompressionMethod(from level: Int) -> String {
        // RAR utilise des niveaux 0-5, pas 0-9
        // 0 = Store, 1 = Fastest, 2 = Fast, 3 = Normal, 4 = Good, 5 = Best
        let rarLevel = min(max(level, 0), 5)
        NSLog("🔍 Conversion niveau compression: \(level) -> RAR niveau \(rarLevel)")
        print("🔍 Conversion niveau compression: \(level) -> RAR niveau \(rarLevel)")
        return String(rarLevel)
    }
    
    private func getRarCompressionMethod(from compressionMethod: CompressionMethod) -> String {
        // Mapper les noms CompressionMethod vers les niveaux RAR
        let rarLevel: String
        switch compressionMethod.name {
        case "RAR Store": rarLevel = "0"
        case "RAR Fastest": rarLevel = "1"
        case "RAR Fast": rarLevel = "2"
        case "RAR Normal": rarLevel = "3"
        case "RAR Good": rarLevel = "4"
        case "RAR Best": rarLevel = "5"
        default: rarLevel = "3" // RAR Normal par défaut
        }
        NSLog("🔍 Conversion méthode compression: \(compressionMethod.name) -> RAR niveau \(rarLevel)")
        print("🔍 Conversion méthode compression: \(compressionMethod.name) -> RAR niveau \(rarLevel)")
        return rarLevel
    }
    
    func addFiles(to url: URL, files: [URL], options: ArchiveOptions) async throws {
        let filePaths = files.map { $0.path }
        var arguments = ["a"] // Commande de base
        
        // Méthode de compression RAR
        let rarMethod = getRarCompressionMethod(from: options.compressionLevel)
        arguments.append("-m\(rarMethod)")
        
        // Mode solide si activé - AVANT les fichiers
        if options.solidArchive {
            arguments.append("-s")
        }
        
        // Chiffrement - AVANT les fichiers
        if let password = options.password, !password.isEmpty {
            arguments.append("-p\(password)")
            if options.encryptFileNames {
                arguments.append("-hp\(password)")
            }
        }
        
        // Récursion par défaut - AVANT les fichiers
        arguments.append("-r")
        
        // Répondre oui à toutes les questions - AVANT les fichiers
        arguments.append("-y")
        
        // Archive de destination - AVANT les fichiers sources
        arguments.append(url.path)
        
        // Fichiers sources - EN DERNIER
        arguments.append(contentsOf: filePaths)
        
        // Log pour debug
        NSLog("🔍 Commande RAR addFiles: \(rarPath) \(arguments.joined(separator: " "))")
        print("🔍 Commande RAR addFiles: \(rarPath) \(arguments.joined(separator: " "))")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rarPath)
        process.arguments = arguments
        
        // Capturer la sortie et les erreurs
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            NSLog("📊 Code de sortie RAR addFiles: \(process.terminationStatus)")
            NSLog("📋 Sortie RAR addFiles: \(output)")
            print("📊 Code de sortie RAR addFiles: \(process.terminationStatus)")
            print("📋 Sortie RAR addFiles: \(output)")
            
            if process.terminationStatus != 0 {
                NSLog("❌ Erreur RAR addFiles - Code de sortie: \(process.terminationStatus)")
                NSLog("❌ Sortie d'erreur RAR addFiles: \(output)")
                print("❌ Erreur RAR addFiles - Code de sortie: \(process.terminationStatus)")
                print("❌ Sortie d'erreur RAR addFiles: \(output)")
                throw ArchiveError.creationFailed
            }
            
            NSLog("✅ Fichiers ajoutés à l'archive RAR avec succès")
            print("✅ Fichiers ajoutés à l'archive RAR avec succès")
        } catch {
            NSLog("❌ Erreur lors de l'ajout de fichiers RAR: \(error.localizedDescription)")
            print("❌ Erreur lors de l'ajout de fichiers RAR: \(error.localizedDescription)")
            throw ArchiveError.creationFailed
        }
    }
    
    func deleteFiles(from url: URL, files: [String], options: ArchiveOptions) async throws {
        let arguments = ["d", url.path] + files + ["-y"]
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: rarPath)
        process.arguments = arguments
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                throw ArchiveError.extractionFailed
            }
        } catch {
            throw ArchiveError.extractionFailed
        }
    }
    
    func testArchive(at url: URL, options: ArchiveOptions) async throws {
        var arguments = ["t", url.path]
        
        // Ajouter le mot de passe si fourni
        if let password = options.password, !password.isEmpty {
            arguments.append("-p\(password)")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: unrarPath)
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if process.terminationStatus != 0 {
                throw ArchiveError.testFailed("Test de l'archive RAR échoué: \(output)")
            }
        } catch {
            throw ArchiveError.testFailed("Erreur lors du test de l'archive RAR")
        }
    }
    
    private func parseRarListing(_ output: String) -> [ArchiveItem] {
        var items: [ArchiveItem] = []
        let lines = output.components(separatedBy: .newlines)
        
        var currentName: String?
        var currentType: String?
        var currentSize: Int64 = 0
        var currentPackedSize: Int64 = 0
        var currentCRC: String?
        var currentAttributes: String?
        var currentMTime: String?
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Parser le format key-value de "unrar vt"
            if trimmedLine.contains("Name: ") {
                // Si on a un élément précédent complet, l'ajouter
                if let name = currentName, let type = currentType {
                    let isDirectory = (type.lowercased() == "directory")
                    let item = ArchiveItem(
                        name: name.components(separatedBy: "/").last ?? name,
                        path: name,
                        size: currentSize,
                        compressedSize: currentPackedSize > 0 ? currentPackedSize : currentSize,
                        isDirectory: isDirectory,
                        attributes: [
                            "Type": type,
                            "Attributes": currentAttributes ?? "",
                            "CRC32": currentCRC ?? "",
                            "MTime": currentMTime ?? ""
                        ],
                        compressionMethod: "RAR",
                        crc: currentCRC,
                        modificationDate: parseMTime(currentMTime ?? "")
                    )
                    items.append(item)
                }
                
                // Commencer un nouvel élément
                currentName = String(trimmedLine.components(separatedBy: "Name: ").last ?? "")
                currentType = nil
                currentSize = 0
                currentPackedSize = 0
                currentCRC = nil
                currentAttributes = nil
                currentMTime = nil
                
            } else if trimmedLine.contains("Type: ") {
                currentType = String(trimmedLine.components(separatedBy: "Type: ").last ?? "")
                
            } else if trimmedLine.contains("Size: ") {
                let sizeString = String(trimmedLine.components(separatedBy: "Size: ").last ?? "0")
                currentSize = Int64(sizeString) ?? 0
                
            } else if trimmedLine.contains("Packed size: ") {
                let sizeString = String(trimmedLine.components(separatedBy: "Packed size: ").last ?? "0")
                currentPackedSize = Int64(sizeString) ?? 0
                
            } else if trimmedLine.contains("CRC32: ") {
                currentCRC = String(trimmedLine.components(separatedBy: "CRC32: ").last ?? "")
                
            } else if trimmedLine.contains("Attributes: ") {
                currentAttributes = String(trimmedLine.components(separatedBy: "Attributes: ").last ?? "")
                
            } else if trimmedLine.contains("mtime: ") {
                currentMTime = String(trimmedLine.components(separatedBy: "mtime: ").last ?? "")
            }
        }
        
        // Ajouter le dernier élément s'il existe
        if let name = currentName, let type = currentType {
            let isDirectory = (type.lowercased() == "directory")
            let item = ArchiveItem(
                name: name.components(separatedBy: "/").last ?? name,
                path: name,
                size: currentSize,
                compressedSize: currentPackedSize > 0 ? currentPackedSize : currentSize,
                isDirectory: isDirectory,
                attributes: [
                    "Type": type,
                    "Attributes": currentAttributes ?? "",
                    "CRC32": currentCRC ?? "",
                    "MTime": currentMTime ?? ""
                ],
                compressionMethod: "RAR",
                crc: currentCRC,
                modificationDate: parseMTime(currentMTime ?? "")
            )
            items.append(item)
        }
        
        NSLog("🔍 RAR parsing terminé - \(items.count) éléments trouvés")
        for item in items {
            NSLog("📁 RAR item: \(item.path) (isDir: \(item.isDirectory))")
        }
        
        return items
    }
    
    private func parseMTime(_ mtimeString: String) -> Date {
        // Format: "2025-09-24 11:34:03,326584689"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        // Extraire la partie principale (avant la virgule)
        let mainPart = mtimeString.components(separatedBy: ",").first ?? mtimeString
        return formatter.date(from: mainPart) ?? Date()
    }
}

// MARK: - RAR Options
struct RarOptions {
    var compressionLevel: Int = 3 // 0-5 pour RAR
    var solidMode: Bool = false
    var encryptHeaders: Bool = false
    var volumeSizes: [String] = []
    var recursive: Bool = true
    var deleteAfterCompression: Bool = false
    var password: String? = nil
    
    // Méthodes de compression spécifiques à RAR
    var compressionMethod: RarCompressionMethod = .normal
    var dictionarySize: RarDictionarySize = .auto
    var enableDeltaCompression: Bool = false
    var enableX86Compression: Bool = false
    var enableLongRangeSearch: Bool = false
    var enableExhaustiveSearch: Bool = false
}

// MARK: - RAR Compression Methods
enum RarCompressionMethod: Int, CaseIterable {
    case store = 0
    case fastest = 1
    case fast = 2
    case normal = 3
    case good = 4
    case best = 5
    
    var displayName: String {
        switch self {
        case .store: return "Store (aucune compression)"
        case .fastest: return "Rapide (compression minimale)"
        case .fast: return "Rapide"
        case .normal: return "Normal"
        case .good: return "Bon (plus de compression)"
        case .best: return "Meilleur (compression maximale)"
        }
    }
}

// MARK: - RAR Dictionary Sizes
enum RarDictionarySize: String, CaseIterable {
    case auto = "auto"
    case kb64 = "64k"
    case kb128 = "128k"
    case kb256 = "256k"
    case kb512 = "512k"
    case mb1 = "1m"
    case mb2 = "2m"
    case mb4 = "4m"
    case mb8 = "8m"
    case mb16 = "16m"
    case mb32 = "32m"
    case mb64 = "64m"
    case mb128 = "128m"
    case mb256 = "256m"
    case mb512 = "512m"
    case gb1 = "1g"
    case gb2 = "2g"
    case gb4 = "4g"
    
    var displayName: String {
        switch self {
        case .auto: return "Automatique"
        case .kb64: return "64 KB"
        case .kb128: return "128 KB"
        case .kb256: return "256 KB"
        case .kb512: return "512 KB"
        case .mb1: return "1 MB"
        case .mb2: return "2 MB"
        case .mb4: return "4 MB"
        case .mb8: return "8 MB"
        case .mb16: return "16 MB"
        case .mb32: return "32 MB"
        case .mb64: return "64 MB"
        case .mb128: return "128 MB"
        case .mb256: return "256 MB"
        case .mb512: return "512 MB"
        case .gb1: return "1 GB"
        case .gb2: return "2 GB"
        case .gb4: return "4 GB"
        }
    }
}

