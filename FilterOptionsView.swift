import SwiftUI

// MARK: - Filter Options View
struct FilterOptionsView: View {
    @Binding var options: SevenZipOptions
    @Environment(\.dismiss) private var dismiss
    
    @State private var includePatterns: [String] = []
    @State private var excludePatterns: [String] = []
    @State private var newIncludePattern = ""
    @State private var newExcludePattern = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Filtres et exclusions")
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
                    // Include Patterns
                    includePatternsSection
                    
                    // Exclude Patterns
                    excludePatternsSection
                    
                    // Pattern Help
                    patternHelpSection
                }
            }
            
            Spacer()
            
            // Footer
            HStack {
                Button("Restaurer les valeurs par défaut") {
                    resetToDefaults()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Appliquer") {
                    applySettings()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 700, height: 600)
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Include Patterns Section
    private var includePatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns d'inclusion")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Les fichiers correspondant à ces patterns seront inclus dans l'archive.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Add include pattern
                HStack {
                    TextField("Entrez un pattern (ex: *.txt, docs/*, important.*)", text: $newIncludePattern)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addIncludePattern()
                        }
                    
                    Button("Ajouter") {
                        addIncludePattern()
                    }
                    .buttonStyle(.bordered)
                    .disabled(newIncludePattern.isEmpty)
                }
                
                // Include patterns list
                if !includePatterns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patterns d'inclusion actifs:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVStack(spacing: 4) {
                            ForEach(includePatterns, id: \.self) { pattern in
                                HStack {
                                    Text(pattern)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Button("Supprimer") {
                                        removeIncludePattern(pattern)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Exclude Patterns Section
    private var excludePatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns d'exclusion")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Les fichiers correspondant à ces patterns seront exclus de l'archive.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                // Add exclude pattern
                HStack {
                    TextField("Entrez un pattern (ex: *.tmp, logs/*, .DS_Store)", text: $newExcludePattern)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            addExcludePattern()
                        }
                    
                    Button("Ajouter") {
                        addExcludePattern()
                    }
                    .buttonStyle(.bordered)
                    .disabled(newExcludePattern.isEmpty)
                }
                
                // Exclude patterns list
                if !excludePatterns.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Patterns d'exclusion actifs:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVStack(spacing: 4) {
                            ForEach(excludePatterns, id: \.self) { pattern in
                                HStack {
                                    Text(pattern)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Button("Supprimer") {
                                        removeExcludePattern(pattern)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(6)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Pattern Help Section
    private var patternHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aide sur les patterns")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Les patterns utilisent la syntaxe des expressions régulières:")
                    .font(.body)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(pattern: "*.txt", description: "Tous les fichiers .txt")
                    HelpRow(pattern: "docs/*", description: "Tous les fichiers dans le dossier docs")
                    HelpRow(pattern: "*.{tmp,log}", description: "Fichiers .tmp et .log")
                    HelpRow(pattern: ".*", description: "Fichiers cachés (commençant par un point)")
                    HelpRow(pattern: "temp*", description: "Fichiers commençant par 'temp'")
                    HelpRow(pattern: "*.{jpg,png,gif}", description: "Images JPEG, PNG et GIF")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Help Row
    private func HelpRow(pattern: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(pattern)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(width: 120, alignment: .leading)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Add Include Pattern
    private func addIncludePattern() {
        let pattern = newIncludePattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pattern.isEmpty && !includePatterns.contains(pattern) {
            includePatterns.append(pattern)
            newIncludePattern = ""
        }
    }
    
    // MARK: - Remove Include Pattern
    private func removeIncludePattern(_ pattern: String) {
        includePatterns.removeAll { $0 == pattern }
    }
    
    // MARK: - Add Exclude Pattern
    private func addExcludePattern() {
        let pattern = newExcludePattern.trimmingCharacters(in: .whitespacesAndNewlines)
        if !pattern.isEmpty && !excludePatterns.contains(pattern) {
            excludePatterns.append(pattern)
            newExcludePattern = ""
        }
    }
    
    // MARK: - Remove Exclude Pattern
    private func removeExcludePattern(_ pattern: String) {
        excludePatterns.removeAll { $0 == pattern }
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        includePatterns = options.includePatterns
        excludePatterns = options.excludePatterns
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        options.includePatterns = includePatterns
        options.excludePatterns = excludePatterns
        dismiss()
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        includePatterns = []
        excludePatterns = []
        newIncludePattern = ""
        newExcludePattern = ""
    }
}

// MARK: - Preview
#Preview {
    FilterOptionsView(options: .constant(SevenZipOptions()))
}