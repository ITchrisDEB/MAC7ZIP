import SwiftUI

struct NewArchiveView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @EnvironmentObject var localizationManager: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: ArchiveStep = .basic
    @State private var archiveName = ""
    @State private var archiveFormat = ArchiveFormat.sevenZip
    @State private var destinationFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    @State private var password = ""
    @State private var encryptFileNames = false
    @State private var createSFX = false
    @State private var deleteAfterCompression = false
    @State private var solidArchive = false
    @State private var multithreading = true
    @State private var updateMode = UpdateMode.addAndReplace
    @State private var volumeSize = VolumeManager.VolumeSize.noSplit
    @State private var customVolumeSize = ""
    @State private var volumeUnit = VolumeManager.VolumeUnit.mb
    @State private var compressionLevel = 5
    @State private var selectedCompressionMethod: CompressionMethod = CompressionMethod.method(named: "LZMA2") ?? CompressionMethod.methodsForFormat(.sevenZip).first!
    @State private var selectedFiles: [URL] = []
    @State private var showFilePicker = false
    @State private var showFolderPicker = false
    @State private var isDragOver = false
    
    enum ArchiveStep: String, CaseIterable, Identifiable {
        case basic = "basic"
        case advanced = "advanced"
        case files = "files"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .basic: return "gear"
            case .advanced: return "slider.horizontal.3"
            case .files: return "folder"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("new_archive".localized)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("create_new_archive_with_files".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                            Spacer()
                
                HStack(spacing: 12) {
                    Button("cancel".localized) {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("create".localized) {
                        print("🔍 BOUTON CRÉER CLIQUÉ !")
                        NSLog("🔍 BOUTON CRÉER CLIQUÉ !")
                        print("🔍 archiveName: '\(archiveName)'")
                        print("🔍 selectedFiles: \(selectedFiles.count)")
                        print("🔍 archiveFormat: \(archiveFormat.rawValue)")
                        createArchive()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(false) // Test temporaire - toujours activé
                    .onAppear {
                        print("🔍 Bouton Créer - archiveName: '\(archiveName)', selectedFiles: \(selectedFiles.count)")
                        print("🔍 Bouton Créer - disabled: \(archiveName.isEmpty || selectedFiles.isEmpty)")
                        NSLog("🔍 Bouton Créer - archiveName: '\(archiveName)', selectedFiles: \(selectedFiles.count)")
                        NSLog("🔍 Bouton Créer - disabled: \(archiveName.isEmpty || selectedFiles.isEmpty)")
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            HStack(spacing: 0) {
                // Left sidebar - Steps
                VStack(alignment: .leading, spacing: 0) {
                    Text("steps".localized)
                                    .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    ForEach(ArchiveStep.allCases) { step in
                        Button(action: {
                            currentStep = step
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: step.icon)
                                    .frame(width: 20)
                                
                                Text(step.rawValue.localized)
                                    .font(.body)
                                        
                                        Spacer()
                                
                                if currentStep == step {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(currentStep == step ? Color.blue.opacity(0.1) : Color.clear)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .frame(width: 200)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Right content - Step content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        switch currentStep {
                        case .basic:
                            BasicArchiveSettingsView(
                                archiveName: $archiveName,
                                archiveFormat: $archiveFormat,
                                destinationFolder: $destinationFolder,
                                createSFX: $createSFX,
                                deleteAfterCompression: $deleteAfterCompression,
                                showFolderPicker: $showFolderPicker
                            )
                        case .advanced:
                            AdaptiveAdvancedOptionsView(
                                archiveFormat: $archiveFormat,
                                selectedCompressionMethod: $selectedCompressionMethod,
                                compressionLevel: $compressionLevel,
                                password: $password,
                                encryptFileNames: $encryptFileNames,
                                solidArchive: $solidArchive,
                                multithreading: $multithreading,
                                volumeSize: $volumeSize,
                                customVolumeSize: $customVolumeSize,
                                volumeUnit: $volumeUnit,
                                deleteAfterCompression: $deleteAfterCompression,
                                createSFX: $createSFX
                            )
                        case .files:
                            FilesSelectionView(
                                selectedFiles: $selectedFiles,
                                showFilePicker: $showFilePicker,
                                isDragOver: $isDragOver,
                                onSelectFiles: selectFilesWithPanel
                            )
                        }
                    }
                    .padding(24)
                }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            print("🔍 NewArchiveView onAppear - currentStep: \(currentStep)")
            resetState()
            print("✅ NewArchiveView réinitialisé")
        }
        .onChange(of: archiveFormat) { newFormat in
            // Les options sont mises à jour automatiquement par AdaptiveAdvancedOptionsView
            print("🔍 NewArchiveView - Format changé vers: \(newFormat.rawValue)")
            print("🔍 NewArchiveView - Ancien format: \(archiveFormat.rawValue)")
            // Mettre à jour la méthode de compression selon le nouveau format avec la méthode par défaut appropriée
            selectedCompressionMethod = CompressionMethod.defaultMethodForFormat(newFormat)
            print("🔍 NewArchiveView - Méthode de compression mise à jour vers: \(selectedCompressionMethod.name)")
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            print("🔍 fileImporter pour fichiers déclenché")
            switch result {
            case .success(let urls):
                print("🔍 Fichiers sélectionnés: \(urls.count)")
                selectedFiles.append(contentsOf: urls)
            case .failure(let error):
                print("❌ Erreur lors de la sélection des fichiers: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            print("🔍 fileImporter pour dossier déclenché")
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    print("🔍 Dossier sélectionné: \(url.path)")
                    destinationFolder = url
                }
            case .failure(let error):
                print("❌ Erreur sélection dossier: \(error)")
                break
            }
        }
    }
    
    private func createArchive() {
        print("🔍 createArchive appelé - Fichiers sélectionnés: \(selectedFiles.count)")
        NSLog("🔍 createArchive appelé - Fichiers sélectionnés: \(selectedFiles.count)")
        print("🔍 createArchive - archiveName: '\(archiveName)'")
        NSLog("🔍 createArchive - archiveName: '\(archiveName)'")
        print("🔍 createArchive - archiveFormat: \(archiveFormat.rawValue)")
        NSLog("🔍 createArchive - archiveFormat: \(archiveFormat.rawValue)")
        
        // Vérifier qu'il y a des fichiers sélectionnés
        guard !selectedFiles.isEmpty else {
            print("❌ Aucun fichier sélectionné")
            NSLog("❌ Aucun fichier sélectionné")
            return
        }
        
        // Vérifier qu'il y a un nom d'archive
        guard !archiveName.isEmpty else {
            print("❌ Nom d'archive vide")
            NSLog("❌ Nom d'archive vide")
            return
        }
        
        let archiveURL = destinationFolder.appendingPathComponent(archiveName + "." + archiveFormat.rawValue)
        
        // Mettre à jour les options selon le format sélectionné
        var updatedSevenZipOptions: SevenZipOptions? = nil
        var updatedCompressionLevel = compressionLevel
        
        if archiveFormat == .sevenZip {
            var sevenZipOptions = SevenZipOptions()
            // Convertir CompressionMethod vers SevenZipCompressionMethod
            let sevenZipMethod = SevenZipCompressionMethod(rawValue: selectedCompressionMethod.name) ?? .lzma2
            sevenZipOptions.compressionMethod = sevenZipMethod
            sevenZipOptions.compressionLevel = compressionLevel
            sevenZipOptions.solidMode = solidArchive
            sevenZipOptions.encryptData = !password.isEmpty
            sevenZipOptions.encryptHeaders = encryptFileNames
            sevenZipOptions.multithreading = multithreading
            sevenZipOptions.deleteAfterCompression = deleteAfterCompression
            sevenZipOptions.createSFX = createSFX
            updatedSevenZipOptions = sevenZipOptions
        } else if archiveFormat == .rar {
            // Pour RAR, utiliser le niveau de compression de la méthode sélectionnée
            // RAR utilise des niveaux 0-5, pas 0-9
            updatedCompressionLevel = selectedCompressionMethod.defaultLevel
        }
        
        // Log des options pour debug
        NSLog("🔍 Format sélectionné: \(archiveFormat.rawValue)")
        NSLog("🔍 Méthode de compression: \(selectedCompressionMethod.name)")
        NSLog("🔍 Niveau de compression original: \(compressionLevel)")
        NSLog("🔍 Niveau de compression mis à jour: \(updatedCompressionLevel)")
        NSLog("🔍 Mot de passe: \(password.isEmpty ? "Aucun" : "Présent")")
        NSLog("🔍 Archive solide: \(solidArchive)")
        NSLog("🔍 Multithreading: \(multithreading)")
        
        let options = ArchiveOptions(
            format: archiveFormat,
            compressionLevel: updatedCompressionLevel,
            password: password.isEmpty ? nil : password,
            encryptFileNames: encryptFileNames,
            createSFX: createSFX,
            volumeSize: getVolumeSizeString(),
            solidArchive: solidArchive,
            multithreading: multithreading,
            deleteAfterCompression: deleteAfterCompression,
            sevenZipOptions: updatedSevenZipOptions
        )
        
        print("🔍 Création de l'archive: \(archiveURL.path)")
        NSLog("🔍 Création de l'archive: \(archiveURL.path)")
        
        Task {
            do {
                try await archiveManager.createArchive(at: archiveURL, files: selectedFiles, options: options)
                await MainActor.run {
                    resetState()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    print("❌ Erreur lors de la création: \(error.localizedDescription)")
                    NSLog("❌ Erreur lors de la création: \(error.localizedDescription)")
                    // Ne pas appeler resetState() en cas d'erreur pour garder l'état RAR
                }
            }
        }
    }
    
    private func resetState() {
        // Réinitialiser les variables locales
        
        // Puis réinitialiser les variables locales
        currentStep = .basic
        archiveName = ""
        archiveFormat = .sevenZip
        destinationFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        password = ""
        encryptFileNames = false
        createSFX = false
        deleteAfterCompression = false
        solidArchive = false
        multithreading = true
        updateMode = .addAndReplace
        volumeSize = .noSplit
        customVolumeSize = ""
        volumeUnit = .mb
        compressionLevel = 5
        // Initialiser la méthode de compression selon le format avec la méthode par défaut appropriée
        selectedCompressionMethod = CompressionMethod.defaultMethodForFormat(archiveFormat)
        selectedFiles = []
        showFilePicker = false
        showFolderPicker = false
        isDragOver = false
    }
    
    private func getVolumeSizeString() -> String? {
        if volumeSize == VolumeManager.VolumeSize.noSplit {
            return nil
        } else if case VolumeManager.VolumeSize.custom = volumeSize {
            return "\(customVolumeSize)\(volumeUnit.rawValue)"
        } else {
            return "\(volumeSize.sizeInMB)m"
        }
    }
    
    // ⚠️ ATTENTION : NE PAS MODIFIER CETTE FONCTION
    // Cette fonction utilise NSOpenPanel et fonctionne correctement
    // Ne pas la remplacer par fileImporter ou autre méthode
    private func selectFilesWithPanel() {
        print("🔍 selectFilesWithPanel appelé - ouverture de NSOpenPanel")
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        panel.title = "Sélectionner des fichiers pour l'archive"
        panel.prompt = "Ajouter"
        
        panel.begin { response in
            DispatchQueue.main.async {
                if response == .OK {
                    print("🔍 Fichiers sélectionnés via NSOpenPanel: \(panel.urls.count)")
                    self.selectedFiles.append(contentsOf: panel.urls)
                } else {
                    print("❌ Sélection de fichiers annulée")
                }
            }
        }
    }
    
    
    
}

// MARK: - Basic Archive Settings
struct BasicArchiveSettingsView: View {
    @Binding var archiveName: String
    @Binding var archiveFormat: ArchiveFormat
    @Binding var destinationFolder: URL
    @Binding var createSFX: Bool
    @Binding var deleteAfterCompression: Bool
    @Binding var showFolderPicker: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("basic_parameters".localized)
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("archive_name".localized)
                        .font(.headline)
                    
                    TextField("enter_archive_name".localized, text: $archiveName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("archive_format".localized)
                        .font(.headline)
                    
                    HStack {
                        Picker("format".localized, selection: $archiveFormat) {
                            ForEach(ArchiveFormat.allCases.filter { $0.canCreate }, id: \.self) { format in
                                Text(format.displayName).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("destination_folder".localized)
                        .font(.headline)
                    
                    HStack {
                        Text(destinationFolder.lastPathComponent)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        
                        Button("choose".localized) {
                            showFolderPicker = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("create_self_extracting_archive".localized, isOn: $createSFX)
                        .disabled(archiveFormat != .sevenZip)
                    
                    Toggle("delete_files_after_compression".localized, isOn: $deleteAfterCompression)
                }
            }
        }
    }
}


// MARK: - Files Selection
struct FilesSelectionView: View {
    @Binding var selectedFiles: [URL]
    @Binding var showFilePicker: Bool
    @Binding var isDragOver: Bool
    let onSelectFiles: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Sélection des fichiers")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                if selectedFiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Glissez-déposez vos fichiers ici")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("ou utilisez le bouton ci-dessous pour les sélectionner")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // ⚠️ ATTENTION : NE PAS MODIFIER CE BOUTON
                        // Ce bouton utilise NSOpenPanel via onSelectFiles() et fonctionne correctement
                        // Ne pas le remplacer par showFilePicker = true ou autre méthode
                        Button("Choisir des fichiers...") {
                            print("🔍 Bouton 'Choisir des fichiers' cliqué")
                            onSelectFiles()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .padding(40)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Fichiers sélectionnés (\(selectedFiles.count))")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Ajouter d'autres...") {
                                showFilePicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(selectedFiles, id: \.self) { url in
                                    FileRowView(
                                        url: url,
                                        onRemove: {
                                            selectedFiles.removeAll { $0 == url }
                                        }
                                    )
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isDragOver ? Color.blue.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isDragOver ? Color.blue : Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    )
            )
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                handleDrop(providers: providers)
            }
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { (item, error) in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            selectedFiles.append(url)
                        }
                    }
                }
            }
        }
        return true
    }
}

// Enum pour les modes de mise à jour
enum UpdateMode: String, CaseIterable, Identifiable {
    case addAndReplace = "add"
    case addAndUpdate = "update"
    case fresh = "fresh"
    case synchronize = "sync"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .addAndReplace: return "Ajouter/Remplacer"
        case .addAndUpdate: return "Ajouter/Mettre à jour"
        case .fresh: return "Frais"
        case .synchronize: return "Synchroniser"
        }
    }
}

#Preview {
    NewArchiveView()
        .environmentObject(ArchiveManager())
}