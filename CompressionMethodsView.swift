import SwiftUI

// MARK: - Compression Methods View
struct CompressionMethodsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("compression_methods".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("close".localized) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // 7-Zip Methods
                    compressionMethodsSection(
                        title: "7zip_methods".localized,
                        methods: CompressionMethod.allMethods.filter { 
                            ["LZMA2", "LZMA", "PPMd", "BZip2", "Deflate", "Deflate64", "Copy"].contains($0.name) 
                        }
                    )
                    
                    // RAR Methods
                    compressionMethodsSection(
                        title: "Méthodes RAR",
                        methods: CompressionMethod.allMethods.filter { 
                            $0.name.hasPrefix("RAR") 
                        }
                    )
                    
                    
                    // GZip Methods
                    compressionMethodsSection(
                        title: "Méthodes GZip",
                        methods: CompressionMethod.allMethods.filter { 
                            $0.name == "GZip" 
                        }
                    )
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 800, height: 600)
    }
    
    // MARK: - Compression Methods Section
    private func compressionMethodsSection(title: String, methods: [CompressionMethod]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(methods, id: \.id) { method in
                    CompressionMethodRow(method: method)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Compression Method Row
struct CompressionMethodRow: View {
    let method: CompressionMethod
    
    var body: some View {
        HStack(spacing: 16) {
            // Method icon
            Image(systemName: iconForMethod)
                .font(.title2)
                .foregroundColor(colorForMethod)
                .frame(width: 24)
            
            // Method info
            VStack(alignment: .leading, spacing: 4) {
                Text(method.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(method.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Method properties
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 16) {
                    if method.supportsEncryption {
                        Label("Chiffrement", systemImage: "lock.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    if method.supportsSolid {
                        Label("Solide", systemImage: "square.stack.3d.up.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if method.supportsMultithreading {
                        Label("Multithread", systemImage: "cpu")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Text("Niveau: \(method.minLevel)-\(method.maxLevel)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    // MARK: - Icon for Method
    private var iconForMethod: String {
        switch method.name {
        case "LZMA2": return "gear"
        case "LZMA": return "gear"
        case "PPMd": return "textformat"
        case "BZip2": return "arrow.down.circle"
        case "Deflate": return "arrow.down.circle"
        case "Deflate64": return "arrow.down.circle"
        case "Copy": return "doc.on.doc"
        case let name where name.hasPrefix("RAR"): return "archivebox"
        case "GZip": return "g.circle"
        default: return "gear"
        }
    }
    
    // MARK: - Color for Method
    private var colorForMethod: Color {
        switch method.name {
        case "LZMA2": return .blue
        case "LZMA": return .blue
        case "PPMd": return .green
        case "BZip2": return .orange
        case "Deflate": return .purple
        case "Deflate64": return .purple
        case "Copy": return .gray
        case let name where name.hasPrefix("RAR"): return .red
        case "GZip": return .mint
        default: return .primary
        }
    }
}

// MARK: - Preview
#Preview {
    CompressionMethodsView()
}