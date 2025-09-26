import SwiftUI

// MARK: - Properties View
struct PropertiesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var archiveManager: ArchiveManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Propriétés")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Fermer") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Archive Properties
                    if let archive = archiveManager.currentArchive {
                        archivePropertiesSection(archive: archive)
                    }
                    
                    // Selected Files Properties
                    if !archiveManager.selectedFiles.isEmpty {
                        selectedFilesPropertiesSection()
                    }
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 600, height: 500)
    }
    
    // MARK: - Archive Properties Section
    private func archivePropertiesSection(archive: ArchiveInfo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Propriétés de l'archive")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                PropertyRow(label: "Nom", value: archive.name)
                PropertyRow(label: "Chemin", value: archive.url.path)
                PropertyRow(label: "Format", value: archive.url.pathExtension.uppercased())
                PropertyRow(label: "Nombre de fichiers", value: "\(archive.fileCount)")
                PropertyRow(label: "Taille compressée", value: ByteCountFormatter.string(fromByteCount: archive.compressedSize, countStyle: .file))
                PropertyRow(label: "Chiffré", value: archive.isEncrypted ? "Oui" : "Non")
                
                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: archive.url.path) {
                    if let fileSize = fileAttributes[.size] as? Int64 {
                        PropertyRow(label: "Taille du fichier", value: ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))
                    }
                    
                    if let creationDate = fileAttributes[.creationDate] as? Date {
                        PropertyRow(label: "Date de création", value: creationDate.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    if let modificationDate = fileAttributes[.modificationDate] as? Date {
                        PropertyRow(label: "Date de modification", value: modificationDate.formatted(date: .abbreviated, time: .shortened))
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Selected Files Properties Section
    private func selectedFilesPropertiesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Propriétés des fichiers sélectionnés")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                PropertyRow(label: "Nombre de fichiers", value: "\(archiveManager.selectedFiles.count)")
                
                let totalSize = archiveManager.selectedFiles.reduce(0) { $0 + $1.size }
                PropertyRow(label: "Taille totale", value: ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                
                let totalCompressedSize = archiveManager.selectedFiles.reduce(0) { $0 + $1.compressedSize }
                PropertyRow(label: "Taille compressée totale", value: ByteCountFormatter.string(fromByteCount: totalCompressedSize, countStyle: .file))
                
                if totalSize > 0 {
                    let compressionRatio = Double(totalCompressedSize) / Double(totalSize) * 100
                    PropertyRow(label: "Ratio de compression", value: String(format: "%.1f%%", compressionRatio))
                }
                
                // File types
                let fileTypes = Set(archiveManager.selectedFiles.map { $0.name.components(separatedBy: ".").last?.uppercased() ?? "SANS EXTENSION" })
                PropertyRow(label: "Types de fichiers", value: fileTypes.sorted().joined(separator: ", "))
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Property Row
struct PropertyRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Preview
#Preview {
    PropertiesView()
        .environmentObject(ArchiveManager())
}