import SwiftUI

// MARK: - Extract View
struct ExtractView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var destinationFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
    @State private var keepPaths = true
    @State private var overwriteFiles = true
    @State private var showFolderPicker = false
    @State private var isExtracting = false
    @State private var extractProgress: Double = 0.0
    @State private var currentFile = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Extraire l'archive")
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
            
            // Extraction Options
            VStack(alignment: .leading, spacing: 20) {
                Text("Options d'extraction")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Destination folder
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dossier de destination")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            Text(destinationFolder.lastPathComponent)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            
                            Button("Choisir...") {
                                showFolderPicker = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    // Extraction options
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Conserver la structure des dossiers", isOn: $keepPaths)
                            .help("Préserve la hiérarchie des dossiers dans l'archive")
                        
                        Toggle("Écraser les fichiers existants", isOn: $overwriteFiles)
                            .help("Remplace les fichiers existants sans demander")
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Selected Files Info
            if !archiveManager.selectedFiles.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Fichiers sélectionnés")
                        .font(.headline)
                    
                    Text("\(archiveManager.selectedFiles.count) fichier(s) sélectionné(s)")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(Array(archiveManager.selectedFiles), id: \.id) { item in
                                HStack {
                                    Image(systemName: item.isDirectory ? "folder.fill" : "doc.fill")
                                        .foregroundColor(item.isDirectory ? .blue : .primary)
                                        .frame(width: 16)
                                    
                                    Text(item.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Progress
            if isExtracting {
                VStack(spacing: 12) {
                    ProgressView(value: extractProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    if !currentFile.isEmpty {
                        Text("Extraction: \(currentFile)")
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
                
                Button("Extraire") {
                    extractArchive()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isExtracting)
            }
        }
        .padding(24)
        .frame(width: 600, height: 500)
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    destinationFolder = url
                }
            case .failure(let error):
                print("Erreur sélection dossier: \(error)")
            }
        }
    }
    
    // MARK: - Extract Archive
    private func extractArchive() {
        guard let archive = archiveManager.currentArchive else { return }
        
        isExtracting = true
        extractProgress = 0.0
        currentFile = ""
        
        Task {
            do {
                if archiveManager.selectedFiles.isEmpty {
                    // Extract all files
                    try await archiveManager.extractArchive(at: archive.url, to: destinationFolder, options: ArchiveOptions())
                } else {
                    // Extract selected files
                    archiveManager.extractSelectedFiles(to: destinationFolder)
                }
                
                await MainActor.run {
                    isExtracting = false
                    extractProgress = 1.0
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isExtracting = false
                    extractProgress = 0.0
                    archiveManager.showError("Erreur lors de l'extraction: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ExtractView()
        .environmentObject(ArchiveManager())
}