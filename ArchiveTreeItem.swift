import SwiftUI
import Foundation

// MARK: - Archive Tree Item
class ArchiveTreeItem: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let isDirectory: Bool
    let size: Int64
    let compressedSize: Int64
    let modificationDate: Date?
    let compressionMethod: String?
    @Published var children: [ArchiveTreeItem] = []
    
    init(name: String, path: String, isDirectory: Bool, size: Int64 = 0, compressedSize: Int64 = 0, modificationDate: Date? = nil, compressionMethod: String? = nil) {
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.size = size
        self.compressedSize = compressedSize
        self.modificationDate = modificationDate
        self.compressionMethod = compressionMethod
    }
    
    // Computed property pour le ratio de compression
    var compressionRatio: Double {
        guard compressedSize > 0, size > 0 else { return 0.0 }
        return Double(compressedSize) / Double(size)
    }
    
    // Computed property pour l'économie d'espace
    var spaceSavings: Double {
        guard size > 0 else { return 0.0 }
        return 1.0 - compressionRatio
    }
}

// MARK: - Archive Tree Row View
struct ArchiveTreeRowView: View {
    let item: ArchiveTreeItem
    let level: Int
    @Binding var expandedItems: Set<String>
    @Binding var selectedItems: Set<String>
    let onItemTap: (ArchiveTreeItem) -> Void
    @EnvironmentObject var archiveManager: ArchiveManager
    
    private var isExpanded: Bool {
        expandedItems.contains(item.path)
    }
    
    private var isSelected: Bool {
        selectedItems.contains(item.path)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Ligne principale de l'item
            HStack(spacing: 4) {
                // Indentation selon le niveau
                HStack(spacing: 0) {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 20, height: 1)
                    }
                }
                
                // Icône expansion/contraction pour dossiers
                if item.isDirectory {
                    Button(action: {
                        onItemTap(item)
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 16, height: 16)
                    }
                    .buttonStyle(.plain)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16, height: 16)
                }
                
                // Icône du type de fichier/dossier
                Image(systemName: getItemIcon(for: item))
                    .foregroundColor(getItemColor(for: item))
                    .frame(width: 20, height: 16)
                
                // Nom du fichier/dossier
                Text(item.name)
                    .font(.system(.body, design: .default))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                // Informations additionnelles
                VStack(alignment: .trailing, spacing: 2) {
                    if !item.isDirectory {
                        Text(ByteCountFormatter.string(fromByteCount: item.size, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(isSelected ? .white : .secondary)
                    }
                    
                    if let date = item.modificationDate {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(isSelected ? .white : .gray)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor : Color.clear)
            .cornerRadius(4)
            .onTapGesture {
                onItemTap(item)
            }
            .contextMenu {
                contextMenuItems(for: item)
            }
            
            // Enfants si dossier étendu
            if item.isDirectory && isExpanded && !item.children.isEmpty {
                ForEach(item.children, id: \.path) { child in
                    ArchiveTreeRowView(
                        item: child,
                        level: level + 1,
                        expandedItems: $expandedItems,
                        selectedItems: $selectedItems,
                        onItemTap: onItemTap
                    )
                    .environmentObject(archiveManager)
                }
            }
        }
    }
    
    private func getItemIcon(for item: ArchiveTreeItem) -> String {
        if item.isDirectory {
            return isExpanded ? "folder.fill" : "folder"
        } else {
            // Icônes spécifiques par type de fichier
            let fileExtension = (item.name as NSString).pathExtension.lowercased()
            switch fileExtension {
            case "txt", "md", "rtf": return "doc.text"
            case "pdf": return "doc.richtext"
            case "jpg", "jpeg", "png", "gif", "bmp": return "photo"
            case "mp3", "wav", "aiff", "m4a": return "music.note"
            case "mp4", "mov", "avi", "mkv": return "film"
            case "zip", "7z", "rar", "tar": return "archivebox"
            case "app": return "app"
            case "dmg": return "externaldrive"
            case "xlsx", "xls": return "tablecells"
            case "mpp": return "calendar"
            default: return "doc"
            }
        }
    }
    
    private func getItemColor(for item: ArchiveTreeItem) -> Color {
        if item.isDirectory {
            return .blue
        } else {
            let fileExtension = (item.name as NSString).pathExtension.lowercased()
            switch fileExtension {
            case "jpg", "jpeg", "png", "gif", "bmp": return .orange
            case "mp3", "wav", "aiff", "m4a": return .purple
            case "mp4", "mov", "avi", "mkv": return .red
            case "zip", "7z", "rar", "tar": return .green
            case "app": return .blue
            case "xlsx", "xls", "mpp": return .mint
            default: return .primary
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuItems(for item: ArchiveTreeItem) -> some View {
        Button("Extraire...") {
            NSLog("🔍 Menu contextuel - Extraire cliqué pour: \(item.name)")
            // Convertir ArchiveTreeItem en ArchiveItem pour la sélection
            let archiveItem = ArchiveItem(
                name: item.name,
                path: item.path,
                size: item.size,
                compressedSize: item.compressedSize,
                isDirectory: item.isDirectory,
                attributes: [:], // Attributs vides pour le menu contextuel
                compressionMethod: item.compressionMethod,
                crc: nil, // CRC non disponible depuis ArchiveTreeItem
                modificationDate: item.modificationDate
            )
            archiveManager.selectedFiles = Set([archiveItem])
            NSLog("🔍 Fichiers sélectionnés: \(archiveManager.selectedFiles.count)")
            NotificationCenter.default.post(name: .showExtract, object: nil)
            NSLog("🔍 Notification showExtract envoyée")
        }
        
        Divider()
        
        Button("Propriétés...") {
            NSLog("🔍 Menu contextuel - Propriétés cliqué pour: \(item.name)")
            // Convertir ArchiveTreeItem en ArchiveItem pour la sélection
            let archiveItem = ArchiveItem(
                name: item.name,
                path: item.path,
                size: item.size,
                compressedSize: item.compressedSize,
                isDirectory: item.isDirectory,
                attributes: [:], // Attributs vides pour le menu contextuel
                compressionMethod: item.compressionMethod,
                crc: nil, // CRC non disponible depuis ArchiveTreeItem
                modificationDate: item.modificationDate
            )
            archiveManager.selectedFiles = Set([archiveItem])
            NotificationCenter.default.post(name: .showProperties, object: nil)
            NSLog("🔍 Notification showProperties envoyée")
        }
    }
}
