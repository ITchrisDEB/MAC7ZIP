import SwiftUI

// MARK: - File Row View
struct FileRowView: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône du fichier
            fileIcon
            
            // Informations du fichier
            VStack(alignment: .leading, spacing: 4) {
                Text(url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                HStack(spacing: 16) {
                    Text(fileSizeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(fileTypeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let date = fileModificationDate {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Bouton de suppression
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - File Icon
    private var fileIcon: some View {
        Group {
            if url.hasDirectoryPath {
                Image(systemName: "folder.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
            } else {
                Image(systemName: iconForFileType)
                    .foregroundColor(colorForFileType)
                    .font(.title2)
            }
        }
    }
    
    // MARK: - File Size String
    private var fileSizeString: String {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? Int64 {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
        } catch {
            // Ignore errors
        }
        return "Taille inconnue"
    }
    
    // MARK: - File Type String
    private var fileTypeString: String {
        let fileExtension = url.pathExtension.lowercased()
        if fileExtension.isEmpty {
            return "Fichier"
        }
        return fileExtension.uppercased()
    }
    
    // MARK: - File Modification Date
    private var fileModificationDate: Date? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.modificationDate] as? Date
        } catch {
            return nil
        }
    }
    
    // MARK: - Icon for File Type
    private var iconForFileType: String {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return "doc.fill"
        case "doc", "docx":
            return "doc.fill"
        case "txt", "rtf":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return "photo.fill"
        case "mp4", "mov", "avi", "mkv":
            return "video.fill"
        case "mp3", "wav", "aac", "flac":
            return "music.note"
        case "zip", "7z", "rar", "tar", "gz", "bz2", "xz":
            return "archivebox.fill"
        case "app":
            return "app.fill"
        case "dmg", "iso":
            return "opticaldisc.fill"
        case "html", "htm":
            return "globe"
        case "css":
            return "paintbrush.fill"
        case "js", "swift", "py", "java", "cpp", "c", "h":
            return "chevron.left.forwardslash.chevron.right"
        case "json", "xml", "plist":
            return "curlybraces"
        case "sql":
            return "database.fill"
        case "xls", "xlsx":
            return "tablecells.fill"
        case "ppt", "pptx":
            return "rectangle.3.group.fill"
        default:
            return "doc.fill"
        }
    }
    
    // MARK: - Color for File Type
    private var colorForFileType: Color {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "pdf":
            return .red
        case "doc", "docx":
            return .blue
        case "txt", "rtf":
            return .gray
        case "jpg", "jpeg", "png", "gif", "bmp", "tiff":
            return .green
        case "mp4", "mov", "avi", "mkv":
            return .purple
        case "mp3", "wav", "aac", "flac":
            return .orange
        case "zip", "7z", "rar", "tar", "gz", "bz2", "xz":
            return .brown
        case "app":
            return .blue
        case "dmg", "iso":
            return .gray
        case "html", "htm":
            return .orange
        case "css":
            return .blue
        case "js", "swift", "py", "java", "cpp", "c", "h":
            return .green
        case "json", "xml", "plist":
            return .yellow
        case "sql":
            return .blue
        case "xls", "xlsx":
            return .green
        case "ppt", "pptx":
            return .red
        default:
            return .primary
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 8) {
        FileRowView(
            url: URL(fileURLWithPath: "/Users/test/Documents/example.pdf"),
            onRemove: {}
        )
        
        FileRowView(
            url: URL(fileURLWithPath: "/Users/test/Documents/folder"),
            onRemove: {}
        )
        
        FileRowView(
            url: URL(fileURLWithPath: "/Users/test/Documents/archive.zip"),
            onRemove: {}
        )
    }
    .padding()
    .frame(width: 400)
}


