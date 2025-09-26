import SwiftUI

// MARK: - Security Options View
struct SecurityOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var defaultPassword = ""
    @State private var rememberPassword = false
    @State private var useKeychain = false
    @State private var encryptFileNames = false
    @State private var encryptionMethod: EncryptionMethod = .aes256
    @State private var requirePasswordForExtraction = false
    @State private var autoDeleteAfterExtraction = false
    @State private var secureDelete = false
    @State private var passwordStrength: PasswordStrength = .medium
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                Text("security_options".localized)
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
                    // Password Settings
                    passwordSettingsSection
                    
                    // Encryption Settings
                    encryptionSettingsSection
                    
                    // Security Features
                    securityFeaturesSection
                    
                    // Password Strength Indicator
                    passwordStrengthSection
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
    
    // MARK: - Password Settings Section
    private var passwordSettingsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("password_settings".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Default password
                VStack(alignment: .leading, spacing: 8) {
                    Text("default_password".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("enter_default_password_optional".localized, text: $defaultPassword)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: defaultPassword) { _ in
                            updatePasswordStrength()
                        }
                }
                
                // Remember password
                Toggle("remember_password".localized, isOn: $rememberPassword)
                    .help("Mémorise le mot de passe pour les prochaines archives")
                
                // Use keychain
                if rememberPassword {
                    Toggle("use_macos_keychain".localized, isOn: $useKeychain)
                        .help("Stocke le mot de passe de manière sécurisée dans le trousseau")
                }
                
                // Require password for extraction
                Toggle("require_password_for_extraction".localized, isOn: $requirePasswordForExtraction)
                    .help("Demande toujours un mot de passe lors de l'extraction")
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Encryption Settings Section
    private var encryptionSettingsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("encryption_settings".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Encryption method
                VStack(alignment: .leading, spacing: 8) {
                    Text("encryption_method".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Picker("method".localized, selection: $encryptionMethod) {
                            ForEach(EncryptionMethod.allCases, id: \.self) { method in
                                Text(method.displayName).tag(method)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200, alignment: .leading)
                        
                        Spacer()
                    }
                }
                
                // Encrypt file names
                Toggle("encrypt_file_names".localized, isOn: $encryptFileNames)
                    .help("Masque les noms de fichiers dans l'archive")
                
                // Secure delete
                Toggle("secure_delete".localized, isOn: $secureDelete)
                    .help("Écrase les fichiers originaux de manière sécurisée")
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Security Features Section
    private var securityFeaturesSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("security_features".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Auto delete after extraction
                Toggle("auto_delete_after_extraction".localized, isOn: $autoDeleteAfterExtraction)
                    .help("Supprime automatiquement l'archive après extraction")
                
                // Security info
                VStack(alignment: .leading, spacing: 8) {
                    Text("security_info".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("• Les mots de passe sont stockés de manière sécurisée")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Le chiffrement AES-256 est utilisé par défaut")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("• Les noms de fichiers peuvent être masqués")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Password Strength Section
    private var passwordStrengthSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("password_strength".localized)
                    .font(.headline)
                    .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("current_strength".localized)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(passwordStrength.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(passwordStrength.color)
                }
                
                // Password strength indicator
                HStack(spacing: 4) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(index < passwordStrength.rawValue ? passwordStrength.color : Color.gray.opacity(0.3))
                            .frame(width: 20, height: 4)
                            .cornerRadius(2)
                    }
                }
                
                if !defaultPassword.isEmpty {
                    Text(passwordStrength.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - Update Password Strength
    private func updatePasswordStrength() {
        let password = defaultPassword
        
        if password.isEmpty {
            passwordStrength = .none
        } else if password.count < 6 {
            passwordStrength = .weak
        } else if password.count < 8 {
            passwordStrength = .medium
        } else if password.count < 12 {
            passwordStrength = .strong
        } else {
            passwordStrength = .veryStrong
        }
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        defaultPassword = UserDefaults.standard.string(forKey: "defaultPassword") ?? ""
        rememberPassword = UserDefaults.standard.bool(forKey: "rememberPassword")
        useKeychain = UserDefaults.standard.bool(forKey: "useKeychain")
        encryptFileNames = UserDefaults.standard.bool(forKey: "encryptFileNames")
        encryptionMethod = EncryptionMethod(rawValue: UserDefaults.standard.string(forKey: "encryptionMethod") ?? "aes256") ?? .aes256
        requirePasswordForExtraction = UserDefaults.standard.bool(forKey: "requirePasswordForExtraction")
        autoDeleteAfterExtraction = UserDefaults.standard.bool(forKey: "autoDeleteAfterExtraction")
        secureDelete = UserDefaults.standard.bool(forKey: "secureDelete")
        
        updatePasswordStrength()
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        UserDefaults.standard.set(defaultPassword, forKey: "defaultPassword")
        UserDefaults.standard.set(rememberPassword, forKey: "rememberPassword")
        UserDefaults.standard.set(useKeychain, forKey: "useKeychain")
        UserDefaults.standard.set(encryptFileNames, forKey: "encryptFileNames")
        UserDefaults.standard.set(encryptionMethod.rawValue, forKey: "encryptionMethod")
        UserDefaults.standard.set(requirePasswordForExtraction, forKey: "requirePasswordForExtraction")
        UserDefaults.standard.set(autoDeleteAfterExtraction, forKey: "autoDeleteAfterExtraction")
        UserDefaults.standard.set(secureDelete, forKey: "secureDelete")
        
        dismiss()
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        defaultPassword = ""
        rememberPassword = false
        useKeychain = false
        encryptFileNames = false
        encryptionMethod = .aes256
        requirePasswordForExtraction = false
        autoDeleteAfterExtraction = false
        secureDelete = false
        passwordStrength = .none
    }
}

// MARK: - Encryption Method
enum EncryptionMethod: String, CaseIterable {
    case aes128 = "aes128"
    case aes192 = "aes192"
    case aes256 = "aes256"
    case zipCrypto = "zipcrypto"
    
    var displayName: String {
        switch self {
        case .aes128: return "AES-128"
        case .aes192: return "AES-192"
        case .aes256: return "AES-256 (recommandé)"
        case .zipCrypto: return "ZipCrypto (moins sécurisé)"
        }
    }
}

// MARK: - Password Strength
enum PasswordStrength: Int, CaseIterable {
    case none = 0
    case weak = 1
    case medium = 2
    case strong = 3
    case veryStrong = 4
    
    var displayName: String {
        switch self {
        case .none: return "Aucun"
        case .weak: return "Faible"
        case .medium: return "Moyen"
        case .strong: return "Fort"
        case .veryStrong: return "Très fort"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .gray
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .yellow
        case .veryStrong: return .green
        }
    }
    
    var description: String {
        switch self {
        case .none: return "Entrez un mot de passe"
        case .weak: return "Utilisez au moins 6 caractères"
        case .medium: return "Ajoutez des chiffres et symboles"
        case .strong: return "Bon mot de passe"
        case .veryStrong: return "Excellent mot de passe"
        }
    }
}

// MARK: - Preview
#Preview {
    SecurityOptionsView()
}