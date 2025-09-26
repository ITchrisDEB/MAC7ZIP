import SwiftUI

// MARK: - RAR Options View
struct RarOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var compressionMethod: RarCompressionMethod = .normal
    @State private var dictionarySize: RarDictionarySize = .auto
    @State private var enableDeltaCompression = false
    @State private var enableX86Compression = false
    @State private var enableLongRangeSearch = false
    @State private var enableExhaustiveSearch = false
    @State private var solidMode = false
    @State private var encryptHeaders = false
    @State private var deleteAfterCompression = false
    @State private var recursive = true
    @State private var volumeSize = VolumeManager.VolumeSize.noSplit
    @State private var customVolumeSize = ""
    @State private var volumeUnit = VolumeManager.VolumeUnit.mb
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("Options RAR")
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
                    // Compression Options
                    compressionOptionsSection
                    
                    // Advanced Options
                    advancedOptionsSection
                    
                    // Archive Options
                    archiveOptionsSection
                    
                    // Volume Options
                    volumeOptionsSection
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
    
    // MARK: - Compression Options Section
    private var compressionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options de compression")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Compression method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Méthode de compression")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Picker("Méthode", selection: $compressionMethod) {
                            ForEach(RarCompressionMethod.allCases, id: \.self) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 300, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Dictionary size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Taille du dictionnaire")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Picker("Taille", selection: $dictionarySize) {
                            ForEach(RarDictionarySize.allCases, id: \.self) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Solid mode
                Toggle("Mode solide", isOn: $solidMode)
                    .help("Améliore la compression en traitant tous les fichiers ensemble")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Advanced Options Section
    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options avancées")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Delta compression
                Toggle("Compression Delta", isOn: $enableDeltaCompression)
                    .help("Améliore la compression des données tabulaires")
                
                // X86 compression
                Toggle("Compression x86", isOn: $enableX86Compression)
                    .help("Optimisée pour les exécutables x86")
                
                // Long range search
                Toggle("Recherche longue portée", isOn: $enableLongRangeSearch)
                    .help("Recherche des blocs répétés distants")
                
                // Exhaustive search
                Toggle("Recherche exhaustive", isOn: $enableExhaustiveSearch)
                    .help("Compression maximale (très lent)")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Archive Options Section
    private var archiveOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Options d'archive")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Encrypt headers
                Toggle("Chiffrer les en-têtes", isOn: $encryptHeaders)
                    .help("Masque les métadonnées de l'archive")
                
                // Delete after compression
                Toggle("Supprimer après compression", isOn: $deleteAfterCompression)
                    .help("Supprime les fichiers originaux après création de l'archive")
                
                // Recursive
                Toggle("Récursion dans les sous-dossiers", isOn: $recursive)
                    .help("Inclut automatiquement les sous-dossiers")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Volume Options Section
    private var volumeOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Division en volumes")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Volume size
                VStack(alignment: .leading, spacing: 8) {
                    Text("Taille des volumes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Picker("Taille", selection: $volumeSize) {
                            ForEach(VolumeManager.VolumeSize.allCases, id: \.id) { size in
                                Text(size.displayName).tag(size)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Custom volume size
                if volumeSize == .custom {
                    HStack {
                        TextField("Taille", text: $customVolumeSize)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                        
                        Picker("Unité", selection: $volumeUnit) {
                            ForEach(VolumeManager.VolumeUnit.allCases, id: \.id) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 100)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        compressionMethod = UserDefaults.standard.object(forKey: "rarCompressionMethod") as? RarCompressionMethod ?? .normal
        dictionarySize = UserDefaults.standard.object(forKey: "rarDictionarySize") as? RarDictionarySize ?? .auto
        enableDeltaCompression = UserDefaults.standard.bool(forKey: "rarEnableDeltaCompression")
        enableX86Compression = UserDefaults.standard.bool(forKey: "rarEnableX86Compression")
        enableLongRangeSearch = UserDefaults.standard.bool(forKey: "rarEnableLongRangeSearch")
        enableExhaustiveSearch = UserDefaults.standard.bool(forKey: "rarEnableExhaustiveSearch")
        solidMode = UserDefaults.standard.bool(forKey: "rarSolidMode")
        encryptHeaders = UserDefaults.standard.bool(forKey: "rarEncryptHeaders")
        deleteAfterCompression = UserDefaults.standard.bool(forKey: "rarDeleteAfterCompression")
        recursive = UserDefaults.standard.bool(forKey: "rarRecursive")
        volumeSize = VolumeManager.VolumeSize(rawValue: UserDefaults.standard.string(forKey: "rarVolumeSize") ?? "no_split") ?? .noSplit
        customVolumeSize = UserDefaults.standard.string(forKey: "rarCustomVolumeSize") ?? ""
        volumeUnit = VolumeManager.VolumeUnit(rawValue: UserDefaults.standard.string(forKey: "rarVolumeUnit") ?? "mb") ?? .mb
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        UserDefaults.standard.set(compressionMethod, forKey: "rarCompressionMethod")
        UserDefaults.standard.set(dictionarySize, forKey: "rarDictionarySize")
        UserDefaults.standard.set(enableDeltaCompression, forKey: "rarEnableDeltaCompression")
        UserDefaults.standard.set(enableX86Compression, forKey: "rarEnableX86Compression")
        UserDefaults.standard.set(enableLongRangeSearch, forKey: "rarEnableLongRangeSearch")
        UserDefaults.standard.set(enableExhaustiveSearch, forKey: "rarEnableExhaustiveSearch")
        UserDefaults.standard.set(solidMode, forKey: "rarSolidMode")
        UserDefaults.standard.set(encryptHeaders, forKey: "rarEncryptHeaders")
        UserDefaults.standard.set(deleteAfterCompression, forKey: "rarDeleteAfterCompression")
        UserDefaults.standard.set(recursive, forKey: "rarRecursive")
        UserDefaults.standard.set(volumeSize.rawValue, forKey: "rarVolumeSize")
        UserDefaults.standard.set(customVolumeSize, forKey: "rarCustomVolumeSize")
        UserDefaults.standard.set(volumeUnit.rawValue, forKey: "rarVolumeUnit")
        
        dismiss()
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        compressionMethod = .normal
        dictionarySize = .auto
        enableDeltaCompression = false
        enableX86Compression = false
        enableLongRangeSearch = false
        enableExhaustiveSearch = false
        solidMode = false
        encryptHeaders = false
        deleteAfterCompression = false
        recursive = true
        volumeSize = .noSplit
        customVolumeSize = ""
        volumeUnit = .mb
    }
}

// MARK: - Preview
#Preview {
    RarOptionsView()
}