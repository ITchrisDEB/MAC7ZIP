import SwiftUI

// MARK: - Volume Options View
struct VolumeOptionsView: View {
    @Binding var options: SevenZipOptions
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var volumeManager = VolumeManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Division en volumes")
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
                    // Volume Size Selection
                    volumeSizeSection
                    
                    // Custom Volume Size
                    if volumeManager.volumeSize == .custom {
                        customVolumeSizeSection
                    }
                    
                    // Volume Information
                    volumeInfoSection
                    
                    // Volume Help
                    volumeHelpSection
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
        .frame(width: 600, height: 500)
        .onAppear {
            loadSettings()
        }
    }
    
    // MARK: - Volume Size Section
    private var volumeSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Taille des volumes")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Divisez l'archive en plusieurs fichiers de taille spécifiée.")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                HStack {
                    Picker("Taille des volumes", selection: $volumeManager.volumeSize) {
                        ForEach(VolumeManager.VolumeSize.allCases, id: \.id) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 300, alignment: .leading)
                    
                    Spacer()
                }
                
                if volumeManager.volumeSize != .noSplit {
                    Text("Taille sélectionnée: \(volumeManager.getVolumeSizeDisplayString())")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Custom Volume Size Section
    private var customVolumeSizeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Taille personnalisée")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    TextField("Taille", text: $volumeManager.customVolumeSize)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: volumeManager.customVolumeSize) { _ in
                            validateCustomVolumeSize()
                        }
                    
                    Picker("Unité", selection: $volumeManager.volumeUnit) {
                        ForEach(VolumeManager.VolumeUnit.allCases, id: \.id) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                    
                    Spacer()
                }
                
                if !volumeManager.validateCustomVolumeSize() {
                    Text("Veuillez entrer une taille valide")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Text("Exemples: 100m, 1g, 500k")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Volume Info Section
    private var volumeInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Informations sur les volumes")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                if volumeManager.volumeSize == .noSplit {
                    Text("L'archive sera créée en un seul fichier.")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("L'archive sera divisée en volumes de \(volumeManager.getVolumeSizeDisplayString()).")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Text("• Chaque volume sera numéroté (ex: archive.7z.001, archive.7z.002)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Tous les volumes sont nécessaires pour extraire l'archive")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Les volumes peuvent être stockés sur différents supports")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Volume Help Section
    private var volumeHelpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aide sur les volumes")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Les volumes sont utiles pour:")
                    .font(.body)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 8) {
                    HelpRow(icon: "externaldrive", text: "Stocker sur plusieurs supports (CD, DVD, clés USB)")
                    HelpRow(icon: "network", text: "Transférer via des services avec limite de taille")
                    HelpRow(icon: "mail", text: "Envoyer par email avec des pièces jointes limitées")
                    HelpRow(icon: "cloud", text: "Sauvegarder sur des services cloud avec restrictions")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Help Row
    private func HelpRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(text)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Validate Custom Volume Size
    private func validateCustomVolumeSize() {
        // Validation is handled by VolumeManager
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        // Load settings from options if needed
        if let volumeSize = options.volumeSizes.first {
            if let parsed = VolumeManager.parseVolumeSize(volumeSize) {
                volumeManager.volumeSize = parsed.size
                volumeManager.customVolumeSize = parsed.custom
                volumeManager.volumeUnit = parsed.unit
            }
        }
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        if let volumeSizeString = volumeManager.getVolumeSizeString() {
            options.volumeSizes = [volumeSizeString]
        } else {
            options.volumeSizes = []
        }
        dismiss()
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        volumeManager.reset()
    }
}

// MARK: - Preview
#Preview {
    VolumeOptionsView(options: .constant(SevenZipOptions()))
}