import SwiftUI

// MARK: - Preferences View
struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logManager = LogManager.shared
    @EnvironmentObject var localizationManager: LocalizationManager
    
    @State private var selectedLanguage: Language = .french
    @State private var enableLogging = false
    @State private var logLevel: LogLevel = .info
    @State private var maxLogEntries = 1000
    @State private var defaultCompressionLevel = 5
    @State private var defaultMultithreading = true
    @State private var defaultSolidArchive = true
    @State private var showNotifications = true
    @State private var autoOpenAfterExtraction = false
    @State private var confirmBeforeDeletion = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("preferences".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("close".localized) {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // General Settings
                    preferencesSection(
                        title: "general".localized,
                        content: {
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle("show_notifications".localized, isOn: $showNotifications)
                                
                                Toggle("auto_open_after_extraction".localized, isOn: $autoOpenAfterExtraction)
                                
                                Toggle("confirm_before_deletion".localized, isOn: $confirmBeforeDeletion)
                            }
                        }
                    )
                    
                    // Language Settings (NOUVELLE SECTION)
                    preferencesSection(
                        title: "language".localized,
                        content: {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("select_language".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Picker("", selection: $selectedLanguage) {
                                            ForEach(localizationManager.availableLanguages, id: \.id) { language in
                                                HStack(spacing: 8) {
                                                    Text(language.flag)
                                                        .font(.title2)
                                                    Text(language.displayName)
                                                        .font(.body)
                                                }
                                                .tag(language)
                                            }
                                        }
                                        .pickerStyle(.menu)
                                        .frame(width: 200, alignment: .leading)
                                        .onChange(of: selectedLanguage) { newLanguage in
                                            localizationManager.setLanguage(newLanguage)
                                        }
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                    )
                    
                    // Compression Settings
                    preferencesSection(
                        title: "compression".localized,
                        content: {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("default_compression_level".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Slider(
                                            value: Binding(
                                                get: { Double(defaultCompressionLevel) },
                                                set: { defaultCompressionLevel = Int($0) }
                                            ),
                                            in: 0...9,
                                            step: 1
                                        )
                                        .frame(width: 200, alignment: .leading)
                                        
                                        Text("\(defaultCompressionLevel)")
                                            .font(.system(.body, design: .monospaced))
                                            .frame(width: 30, alignment: .leading)
                                        
                                        Spacer()
                                    }
                                }
                                
                                Toggle("default_multithreading".localized, isOn: $defaultMultithreading)
                                
                                Toggle("default_solid_archive".localized, isOn: $defaultSolidArchive)
                            }
                        }
                    )
                    
                    // Logging Settings
                    preferencesSection(
                        title: "logging".localized,
                        content: {
                            VStack(alignment: .leading, spacing: 16) {
                                Toggle("enable_logging".localized, isOn: $enableLogging)
                                
                                if enableLogging {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("log_level".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            Picker("", selection: $logLevel) {
                                                ForEach(LogLevel.allCases, id: \.self) { level in
                                                    Text(level.rawValue).tag(level)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .frame(width: 150, alignment: .leading)
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("max_log_entries".localized)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        
                                        HStack {
                                            Slider(
                                                value: Binding(
                                                    get: { Double(maxLogEntries) },
                                                    set: { maxLogEntries = Int($0) }
                                                ),
                                                in: 100...5000,
                                                step: 100
                                            )
                                            .frame(width: 200, alignment: .leading)
                                            
                                            Text("\(maxLogEntries)")
                                                .font(.system(.body, design: .monospaced))
                                                .frame(width: 60, alignment: .leading)
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    HStack(spacing: 12) {
                                        Button("view_logs".localized) {
                                            // TODO: Show logs view
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("export_logs".localized) {
                                            if let url = logManager.exportLogs() {
                                                NSWorkspace.shared.open(url)
                                            }
                                        }
                                        .buttonStyle(.bordered)
                                        
                                        Button("clear_logs".localized) {
                                            logManager.clearLogs()
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }
                            }
                        }
                    )
                    
                    // About Section
                    preferencesSection(
                        title: "about".localized,
                        content: {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("version".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text(appVersion)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("build".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text(buildNumber)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Text("architecture".localized)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Spacer()
                                    
                                    Text("ARM64")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    )
                }
                .padding()
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
            .padding()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadSettings()
            selectedLanguage = localizationManager.currentLanguage
        }
        .onReceive(NotificationCenter.default.publisher(for: .languageChanged)) { _ in
            // Rechargement interface automatique grâce à .localized
        }
    }
    
    // MARK: - Preferences Section
    private func preferencesSection<Content: View>(
        title: String,
        content: () -> Content
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                content()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Spacer()
        }
    }
    
    // MARK: - App Version
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Load Settings
    private func loadSettings() {
        enableLogging = UserDefaults.standard.bool(forKey: "enableLogging")
        logLevel = LogLevel(rawValue: UserDefaults.standard.string(forKey: "logLevel") ?? "Info") ?? .info
        maxLogEntries = UserDefaults.standard.integer(forKey: "maxLogEntries")
        if maxLogEntries == 0 { maxLogEntries = 1000 }
        
        defaultCompressionLevel = UserDefaults.standard.integer(forKey: "defaultCompressionLevel")
        if defaultCompressionLevel == 0 { defaultCompressionLevel = 5 }
        
        defaultMultithreading = UserDefaults.standard.bool(forKey: "defaultMultithreading")
        defaultSolidArchive = UserDefaults.standard.bool(forKey: "defaultSolidArchive")
        showNotifications = UserDefaults.standard.bool(forKey: "showNotifications")
        autoOpenAfterExtraction = UserDefaults.standard.bool(forKey: "autoOpenAfterExtraction")
        confirmBeforeDeletion = UserDefaults.standard.bool(forKey: "confirmBeforeDeletion")
    }
    
    // MARK: - Apply Settings
    private func applySettings() {
        UserDefaults.standard.set(enableLogging, forKey: "enableLogging")
        UserDefaults.standard.set(logLevel.rawValue, forKey: "logLevel")
        UserDefaults.standard.set(maxLogEntries, forKey: "maxLogEntries")
        UserDefaults.standard.set(defaultCompressionLevel, forKey: "defaultCompressionLevel")
        UserDefaults.standard.set(defaultMultithreading, forKey: "defaultMultithreading")
        UserDefaults.standard.set(defaultSolidArchive, forKey: "defaultSolidArchive")
        UserDefaults.standard.set(showNotifications, forKey: "showNotifications")
        UserDefaults.standard.set(autoOpenAfterExtraction, forKey: "autoOpenAfterExtraction")
        UserDefaults.standard.set(confirmBeforeDeletion, forKey: "confirmBeforeDeletion")
        
        // Apply to log manager
        logManager.setLoggingEnabled(enableLogging)
        logManager.setLogLevel(logLevel)
        
        dismiss()
    }
    
    // MARK: - Reset to Defaults
    private func resetToDefaults() {
        enableLogging = false
        logLevel = .info
        maxLogEntries = 1000
        defaultCompressionLevel = 5
        defaultMultithreading = true
        defaultSolidArchive = true
        showNotifications = true
        autoOpenAfterExtraction = false
        confirmBeforeDeletion = true
    }
}

// MARK: - Preview
#Preview {
    PreferencesView()
}