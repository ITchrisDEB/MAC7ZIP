import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
    static let showNewArchive = Notification.Name("showNewArchive")
    static let showAddFiles = Notification.Name("showAddFiles")
    static let showExtract = Notification.Name("showExtract")
    static let showAdvancedOptions = Notification.Name("showAdvancedOptions")
    static let showSecurityOptions = Notification.Name("showSecurityOptions")
    static let showCompressionMethods = Notification.Name("showCompressionMethods")
    static let showFilters = Notification.Name("showFilters")
    static let showVolumeOptions = Notification.Name("showVolumeOptions")
    static let showRarOptions = Notification.Name("showRarOptions")
}

struct ContentView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @StateObject private var windowManager = WindowManager.shared
    
    // Sheet states
    @State private var showPreferences = false
    @State private var showNewArchive = false
    @State private var newArchiveId = UUID()
    @State private var showAddFiles = false
    @State private var showExtract = false
    @State private var showAdvancedOptions = false
    @State private var showSecurityOptions = false
    @State private var showCompressionMethods = false
    @State private var showFilters = false
    @State private var showVolumeOptions = false
    @State private var showRarOptions = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button(action: {
                    showNewArchive = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
                .help("Nouvelle archive")

                Button(action: {
                    print("🔍 Bouton 'Ouvrir' cliqué - utilisation de NSOpenPanel")
                    archiveManager.openArchiveWithPanel()
                }) {
                    Image(systemName: "folder")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .help("Ouvrir archive")

                Button(action: {
                    showExtract = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.bordered)
                .disabled(archiveManager.currentArchive == nil)
                .help("Extraire")

                Button(action: {
                    archiveManager.testCurrentArchive()
                }) {
                    Image(systemName: "checkmark.shield")
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
                .disabled(archiveManager.currentArchive == nil)
                .help("Tester l'archive")

                Spacer()

                Button(action: {
                    windowManager.showAddFiles()
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                }
                .buttonStyle(.bordered)
                .disabled(archiveManager.currentArchive == nil)
                .help("Ajouter des fichiers")

                Button(action: {
                    archiveManager.deleteSelectedFiles()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.bordered)
                .disabled(archiveManager.selectedFiles.isEmpty)
                .help("Supprimer")
            }
            .padding()

            Divider()

            // Main content
            if archiveManager.currentArchive != nil {
                VStack(spacing: 0) {
                    // Archive info bar
                    if let archive = archiveManager.currentArchive {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(archive.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("\(archive.fileCount) fichiers • \(ByteCountFormatter.string(fromByteCount: archive.compressedSize, countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if archive.isEncrypted {
                                    HStack {
                                        Image(systemName: "lock.fill")
                                            .foregroundColor(.orange)
                                            .font(.caption)
                                        Text("Chiffré")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                archiveManager.refreshCurrentArchive()
                            }) {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            .help("Actualiser")
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        Divider()
                    }
                    
                    FileListView()
                        .environmentObject(archiveManager)
                }
            } else {
                VStack(spacing: 20) {
                    Text("Aucune archive ouverte")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text("Ouvrez une archive existante ou créez-en une nouvelle")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            windowManager.showNewArchive()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Nouvelle archive")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button(action: {
                            print("🔍 Bouton 'Ouvrir archive' cliqué - utilisation de NSOpenPanel")
                            archiveManager.openArchiveWithPanel()
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text("Ouvrir archive")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .fileImporter(
            isPresented: $archiveManager.showOpenArchiveDialog,
            allowedContentTypes: [.zip, .data, .archive, .gzip, .init(filenameExtension: "rar")!, .init(filenameExtension: "xz")!, .init(filenameExtension: "lzma")!],
            allowsMultipleSelection: false
        ) { result in
            print("🔍 fileImporter déclenché avec result: \(result)")
            switch result {
            case .success(let urls):
                print("✅ Fichier sélectionné avec succès: \(urls)")
                if let url = urls.first {
                    print(" Tentative d'ouverture de l'archive: \(url.path)")
                    archiveManager.openArchive(at: url)
                }
            case .failure(let error):
                print("❌ Erreur lors de la sélection du fichier: \(error.localizedDescription)")
                archiveManager.showError(error.localizedDescription)
            }
        }
        .fileImporter(
            isPresented: $archiveManager.showExtractDialog,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    if archiveManager.selectedFiles.isEmpty {
                        archiveManager.extractTo(url: url)
                    } else {
                        archiveManager.extractSelectedFiles(to: url)
                    }
                }
            case .failure(let error):
                archiveManager.showError(error.localizedDescription)
            }
        }
        // Sheets pour les fenêtres
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
                .environmentObject(archiveManager)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showNewArchive) {
            NewArchiveView()
                .frame(minWidth: 1000, minHeight: 800)
                .id(newArchiveId) // Force la recréation de la vue
        }
        .sheet(isPresented: $showAddFiles) {
            AddFilesView()
                .environmentObject(archiveManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .sheet(isPresented: $showExtract) {
            ExtractView()
                .environmentObject(archiveManager)
                .frame(minWidth: 900, minHeight: 700)
        }
        .sheet(isPresented: $showAdvancedOptions) {
            AdvancedOptionsView(options: .constant(SevenZipOptions()))
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showSecurityOptions) {
            SecurityOptionsView()
                .environmentObject(archiveManager)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showCompressionMethods) {
            CompressionMethodsView()
                .environmentObject(archiveManager)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showFilters) {
            FilterOptionsView(options: .constant(SevenZipOptions()))
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showVolumeOptions) {
            VolumeOptionsView(options: .constant(SevenZipOptions()))
                .frame(minWidth: 1000, minHeight: 700)
        }
        .sheet(isPresented: $showRarOptions) {
            RarOptionsView()
                .frame(minWidth: 1000, minHeight: 700)
        }
        .alert("Erreur", isPresented: $archiveManager.showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(archiveManager.errorMessage)
        }
        .overlay(
            ProgressOverlay(progressTracker: archiveManager.progressTracker)
        )
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            return handleDrop(providers: providers, archiveManager: archiveManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPreferences)) { _ in
            showPreferences = true
        }
                .onReceive(NotificationCenter.default.publisher(for: .showNewArchive)) { _ in
                    newArchiveId = UUID() // Nouvel ID à chaque ouverture
                    showNewArchive = true
                }
        .onReceive(NotificationCenter.default.publisher(for: .showAddFiles)) { _ in
            showAddFiles = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showExtract)) { _ in
            showExtract = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAdvancedOptions)) { _ in
            showAdvancedOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSecurityOptions)) { _ in
            showSecurityOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCompressionMethods)) { _ in
            showCompressionMethods = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFilters)) { _ in
            showFilters = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showVolumeOptions)) { _ in
            showVolumeOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showRarOptions)) { _ in
            showRarOptions = true
        }
    }
    
    private func handleDrop(providers: [NSItemProvider], archiveManager: ArchiveManager) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            // Vérifier si c'est une archive
                            let fileExtension = url.pathExtension.lowercased()
                            let archiveExtensions = ["7z", "zip", "rar", "tar", "gz", "bz2", "xz", "lzma", "dmg", "cab", "msi", "wim", "iso"]
                            
                            if archiveExtensions.contains(fileExtension) {
                                // Ouvrir l'archive
                                archiveManager.openArchive(at: url)
                            } else {
                                // Créer une nouvelle archive avec ces fichiers
                                archiveManager.showNewArchiveDialog = true
                                // TODO: Passer les fichiers sélectionnés à la vue de création
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}


#Preview {
    ContentView()
        .environmentObject(ArchiveManager())
}
