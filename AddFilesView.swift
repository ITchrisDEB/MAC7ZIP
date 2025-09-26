import SwiftUI

// MARK: - Add Files View
struct AddFilesView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFiles: [URL] = []
    @State private var showFilePicker = false
    @State private var isAdding = false
    @State private var addProgress: Double = 0.0
    @State private var currentFile = ""
    @State private var compressionLevel = 5
    @State private var password = ""
    @State private var encryptFileNames = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ajouter des fichiers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    if let archive = archiveManager.currentArchive {
                        Text("Archive: \(archive.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Fermer") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            // File Selection
            VStack(alignment: .leading, spacing: 16) {
                Text("Fichiers à ajouter")
                    .font(.headline)
                
                if selectedFiles.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        VStack(spacing: 8) {
                            Text("Sélectionnez des fichiers à ajouter")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Utilisez le bouton ci-dessous pour choisir des fichiers")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        Button("Choisir des fichiers...") {
                            showFilePicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 200)
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
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
                        .frame(maxHeight: 200)
                    }
                }
            }
            
            // Compression Options
            VStack(alignment: .leading, spacing: 16) {
                Text("Options de compression")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    // Compression level
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Niveau de compression")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { Double(compressionLevel) },
                                    set: { compressionLevel = Int($0) }
                                ),
                                in: 0...9,
                                step: 1
                            )
                            .frame(width: 200)
                            
                            Text("\(compressionLevel)")
                                .font(.system(.body, design: .monospaced))
                                .frame(width: 30)
                        }
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mot de passe (optionnel)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Entrez un mot de passe", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Encrypt file names
                    if !password.isEmpty {
                        Toggle("Chiffrer les noms de fichiers", isOn: $encryptFileNames)
                            .help("Masque les noms de fichiers dans l'archive")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Progress
            if isAdding {
                VStack(spacing: 12) {
                    ProgressView(value: addProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if !currentFile.isEmpty {
                        Text("Ajout: \(currentFile)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            Spacer()
            
            // Action Buttons
            HStack {
                Button("Annuler") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Ajouter") {
                    addFiles()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFiles.isEmpty || isAdding)
            }
        }
        .padding(24)
        .frame(width: 700, height: 600)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                selectedFiles.append(contentsOf: urls)
            case .failure(let error):
                print("Erreur sélection fichiers: \(error)")
            }
        }
    }
    
    // MARK: - Add Files
    private func addFiles() {
        guard let archive = archiveManager.currentArchive else { return }
        
        isAdding = true
        addProgress = 0.0
        currentFile = ""
        
        let options = ArchiveOptions(
            format: archiveFormat,
            compressionLevel: compressionLevel,
            password: password.isEmpty ? nil : password,
            encryptFileNames: encryptFileNames,
            createSFX: false,
            volumeSize: nil,
            solidArchive: true,
            multithreading: true,
            deleteAfterCompression: false,
            sevenZipOptions: nil
        )
        
        Task {
            do {
                try await archiveManager.addFiles(selectedFiles, options: options)
                
                await MainActor.run {
                    isAdding = false
                    addProgress = 1.0
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAdding = false
                    addProgress = 0.0
                    archiveManager.showError("Erreur lors de l'ajout: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Archive Format
    private var archiveFormat: ArchiveFormat {
        guard let archive = archiveManager.currentArchive else { return .sevenZip }
        
        let fileExtension = archive.url.pathExtension.lowercased()
        switch fileExtension {
        case "7z": return .sevenZip
        case "zip": return .zip
        case "rar": return .rar
        case "tar": return .tar
        case "gz": return .gzip
        case "bz2": return .bzip2
        default: return .sevenZip
        }
    }
}

// MARK: - Preview
#Preview {
    AddFilesView()
        .environmentObject(ArchiveManager())
}