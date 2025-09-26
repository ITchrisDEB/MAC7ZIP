import SwiftUI

// MARK: - Adaptive Advanced Options View
struct AdaptiveAdvancedOptionsView: View {
    @Binding var archiveFormat: ArchiveFormat
    @Binding var selectedCompressionMethod: CompressionMethod
    @Binding var compressionLevel: Int
    @Binding var password: String
    @Binding var encryptFileNames: Bool
    @Binding var solidArchive: Bool
    @Binding var multithreading: Bool
    @Binding var volumeSize: VolumeManager.VolumeSize
    @Binding var customVolumeSize: String
    @Binding var volumeUnit: VolumeManager.VolumeUnit
    @Binding var deleteAfterCompression: Bool
    @Binding var createSFX: Bool
    
    @StateObject private var volumeManager = VolumeManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Options avancées")
                .font(.title2)
                .fontWeight(.bold)
            
            // Options de compression
            compressionOptionsSection
            
            // Options de sécurité
            if archiveFormat.supportsEncryption {
                securityOptionsSection
            }
            
            // Options d'archive
            archiveOptionsSection
            
            // Options de volumes (si supporté)
            if supportsVolumes {
                volumeOptionsSection
            }
            
            // Options de traitement
            processingOptionsSection
        }
        .onAppear {
            updateOptionsForFormat()
        }
        .onChange(of: archiveFormat) { _ in
            updateOptionsForFormat()
        }
    }
    
    // MARK: - Compression Options Section
    private var compressionOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compression")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Méthode de compression
                VStack(alignment: .leading, spacing: 8) {
                    Text("Méthode de compression")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Méthode", selection: $selectedCompressionMethod) {
                        ForEach(CompressionMethod.methodsForFormat(archiveFormat), id: \.id) { method in
                            Text(method.name).tag(method)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 200)
                }
                
                // Niveau de compression
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
                            in: Double(selectedCompressionMethod.minLevel)...Double(selectedCompressionMethod.maxLevel),
                            step: 1
                        )
                        .frame(width: 200)
                        
                        Text("\(compressionLevel)")
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 30)
                    }
                    
                    Text(compressionLevelDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Multithreading (si supporté)
                if selectedCompressionMethod.supportsMultithreading {
                    Toggle("Utiliser plusieurs threads", isOn: $multithreading)
                        .help("Améliore les performances sur les processeurs multi-cœurs")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Security Options Section
    private var securityOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sécurité")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Mot de passe
                VStack(alignment: .leading, spacing: 8) {
                    Text("Mot de passe")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Entrez un mot de passe (optionnel)", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                
                // Chiffrement des noms de fichiers
                if !password.isEmpty {
                    Toggle("Chiffrer les noms de fichiers", isOn: $encryptFileNames)
                        .help("Masque les noms de fichiers dans l'archive")
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Archive Options Section
    private var archiveOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Archive")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                // Mode solide (si supporté)
                if selectedCompressionMethod.supportsSolid {
                    Toggle("Archive solide", isOn: $solidArchive)
                        .help("Améliore la compression en traitant tous les fichiers ensemble")
                }
                
                // SFX (si supporté)
                if archiveFormat == .sevenZip {
                    Toggle("Créer une archive auto-extractible (SFX)", isOn: $createSFX)
                        .help("Crée une archive qui peut s'extraire automatiquement")
                }
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
            
            VStack(alignment: .leading, spacing: 12) {
                Picker("Taille des volumes", selection: $volumeSize) {
                    ForEach(VolumeManager.VolumeSize.allCases, id: \.id) { size in
                        Text(size.displayName).tag(size)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 200)
                
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
                        .frame(width: 80)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Processing Options Section
    private var processingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Traitement")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Supprimer les fichiers après compression", isOn: $deleteAfterCompression)
                    .help("Supprime les fichiers originaux après création de l'archive")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    private var supportsVolumes: Bool {
        switch archiveFormat {
        case .sevenZip, .rar:
            return true
        default:
            return false
        }
    }
    
    private var compressionLevelDescription: String {
        switch compressionLevel {
        case 0: return "Aucune compression (rapide)"
        case 1...3: return "Compression rapide"
        case 4...6: return "Compression normale"
        case 7...8: return "Compression élevée"
        case 9: return "Compression maximale (lent)"
        default: return "Niveau de compression"
        }
    }
    
    // MARK: - Helper Methods
    private func updateOptionsForFormat() {
        // Mettre à jour la méthode de compression selon le format
        let availableMethods = CompressionMethod.methodsForFormat(archiveFormat)
        if !availableMethods.contains(selectedCompressionMethod) {
            selectedCompressionMethod = availableMethods.first ?? CompressionMethod.allMethods.first!
        }
        
        // Mettre à jour le niveau de compression selon la méthode
        compressionLevel = max(selectedCompressionMethod.minLevel, min(compressionLevel, selectedCompressionMethod.maxLevel))
        
        // Désactiver les options non supportées
        if !selectedCompressionMethod.supportsSolid {
            solidArchive = false
        }
        
        if !selectedCompressionMethod.supportsMultithreading {
            multithreading = false
        }
        
        // Désactiver le chiffrement si non supporté
        if !archiveFormat.supportsEncryption {
            password = ""
            encryptFileNames = false
        }
        
        // Désactiver SFX si non supporté
        if archiveFormat != .sevenZip {
            createSFX = false
        }
        
        // Désactiver les volumes si non supporté
        if !supportsVolumes {
            volumeSize = .noSplit
        }
    }
}

// MARK: - Preview
#Preview {
    AdaptiveAdvancedOptionsView(
        archiveFormat: .constant(.sevenZip),
        selectedCompressionMethod: .constant(CompressionMethod.allMethods.first!),
        compressionLevel: .constant(5),
        password: .constant(""),
        encryptFileNames: .constant(false),
        solidArchive: .constant(true),
        multithreading: .constant(true),
        volumeSize: .constant(.noSplit),
        customVolumeSize: .constant(""),
        volumeUnit: .constant(.mb),
        deleteAfterCompression: .constant(false),
        createSFX: .constant(false)
    )
    .frame(width: 600, height: 500)
    .padding()
}