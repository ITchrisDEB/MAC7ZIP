import SwiftUI

// MARK: - Advanced Options View
struct AdvancedOptionsView: View {
    @Binding var options: SevenZipOptions
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("advanced_options".localized)
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
                    // Compression Options
                    compressionOptionsSection
                    
                    // Archive Options
                    archiveOptionsSection
                    
                    // Memory Options
                    memoryOptionsSection
                    
                    // Filter Options
                    filterOptionsSection
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Button("restore_defaults".localized) {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("apply".localized) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 700, height: 600)
    }
    
    // MARK: - Compression Options Section
    private var compressionOptionsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("compression_options".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Compression method
                VStack(alignment: .leading, spacing: 8) {
                    Text("compression_method".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Picker("method".localized, selection: $options.compressionMethod) {
                            ForEach(SevenZipCompressionMethod.allCases, id: \.self) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Compression level
                VStack(alignment: .leading, spacing: 8) {
                    Text("compression_level".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Slider(
                            value: Binding(
                                get: { Double(options.compressionLevel) },
                                set: { options.compressionLevel = Int($0) }
                            ),
                            in: 0...9,
                            step: 1
                        )
                        .frame(width: 200)
                        
                        Text("\(options.compressionLevel)")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 30, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Solid mode
                Toggle("solid_mode".localized, isOn: $options.solidMode)
                    .help("Améliore la compression en traitant tous les fichiers ensemble")
                
                // Multithreading
                Toggle("multithreading".localized, isOn: $options.multithreading)
                    .help("Utilise plusieurs threads pour améliorer les performances")
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Archive Options Section
    private var archiveOptionsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("archive_options".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Delete after compression
                Toggle("delete_after_compression".localized, isOn: $options.deleteAfterCompression)
                    .help("Supprime les fichiers originaux après création de l'archive")
                
                // Create SFX
                Toggle("create_self_extracting_sfx".localized, isOn: $options.createSFX)
                    .help("Crée une archive qui peut s'extraire automatiquement")
                
                // Volume sizes
                VStack(alignment: .leading, spacing: 8) {
                    Text("volume_splitting".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("volume_size_ex".localized, text: Binding(
                            get: { options.volumeSizes.joined(separator: ", ") },
                            set: { options.volumeSizes = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300, alignment: .leading)
                        
                        Button("Ajouter") {
                            // TODO: Add volume size
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Memory Options Section
    private var memoryOptionsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("memory_options".localized)
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text("memory_usage_description".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    // TODO: Add memory-specific options
                    Text("memory_options_to_implement".localized)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Filter Options Section
    private var filterOptionsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("filters_and_exclusions".localized)
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Include patterns
                VStack(alignment: .leading, spacing: 8) {
                    Text("include_patterns".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("include_patterns_placeholder".localized, text: Binding(
                            get: { options.includePatterns.joined(separator: ", ") },
                            set: { options.includePatterns = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300, alignment: .leading)
                        
                        Button("Ajouter") {
                            // TODO: Add include pattern
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                // Exclude patterns
                VStack(alignment: .leading, spacing: 8) {
                    Text("exclude_patterns".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        TextField("exclude_patterns_placeholder".localized, text: Binding(
                            get: { options.excludePatterns.joined(separator: ", ") },
                            set: { options.excludePatterns = $0.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300, alignment: .leading)
                        
                        Button("Ajouter") {
                            // TODO: Add exclude pattern
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        options = SevenZipOptions()
    }
}

// MARK: - Preview
#Preview {
    AdvancedOptionsView(options: .constant(SevenZipOptions()))
}