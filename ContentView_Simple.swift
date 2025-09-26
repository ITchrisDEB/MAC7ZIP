import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
    static let showNewArchive = Notification.Name("showNewArchive")
    static let showAddFiles = Notification.Name("showAddFiles")
    static let showExtract = Notification.Name("showExtract")
    static let showAdvancedOptions = Notification.Name("showAdvancedOptions")
    static let showSecurityOptions = Notification.Name("showSecurityOptions")
    static let showCompressionMethods = Notification.Name("showCompressionMethods")
    static let showFilters = Notification.Name("showFilters")
    static let showVolumeOptions = Notification.Name("showVolumeOptions")
    static let showRarOptions = Notification.Name("showRarOptions")
}

struct ContentView: View {
    @EnvironmentObject var archiveManager: ArchiveManager
    @StateObject private var windowManager = WindowManager.shared
    
    // Sheet states
    @State private var showPreferences = false
    @State private var showNewArchive = false
    @State private var newArchiveId = UUID()
    @State private var showAddFiles = false
    @State private var showExtract = false
    @State private var showAdvancedOptions = false
    @State private var showSecurityOptions = false
    @State private var showCompressionMethods = false
    @State private var showFilters = false
    @State private var showVolumeOptions = false
    @State private var showRarOptions = false

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            toolbarView
            
            // Main content
            mainContentView
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPreferences)) { _ in
            showPreferences = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNewArchive)) { _ in
            showNewArchive = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddFiles)) { _ in
            showAddFiles = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showExtract)) { _ in
            showExtract = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAdvancedOptions)) { _ in
            showAdvancedOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSecurityOptions)) { _ in
            showSecurityOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showCompressionMethods)) { _ in
            showCompressionMethods = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showFilters)) { _ in
            showFilters = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showVolumeOptions)) { _ in
            showVolumeOptions = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showRarOptions)) { _ in
            showRarOptions = true
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
        .sheet(isPresented: $showNewArchive) {
            NewArchiveView()
                .id(newArchiveId)
        }
        .sheet(isPresented: $showAddFiles) {
            AddFilesView()
        }
        .sheet(isPresented: $showExtract) {
            ExtractView()
        }
        .sheet(isPresented: $showAdvancedOptions) {
            AdvancedOptionsView(options: .constant(SevenZipOptions()))
        }
        .sheet(isPresented: $showSecurityOptions) {
            SecurityOptionsView()
        }
        .sheet(isPresented: $showCompressionMethods) {
            CompressionMethodsView()
        }
        .sheet(isPresented: $showFilters) {
            FilterOptionsView(options: .constant(SevenZipOptions()))
        }
        .sheet(isPresented: $showVolumeOptions) {
            VolumeOptionsView(options: .constant(SevenZipOptions()))
        }
        .sheet(isPresented: $showRarOptions) {
            RarOptionsView()
        }
        .sheet(isPresented: $windowManager.showAbout) {
            AboutView()
        }
        .sheet(isPresented: $windowManager.showBenchmark) {
            BenchmarkView()
        }
    }
    
    // MARK: - Toolbar View
    private var toolbarView: some View {
        HStack {
            Button(action: {
                showNewArchive = true
            }) {
                Image(systemName: "plus")
                    .foregroundColor(.green)
            }
            .buttonStyle(.bordered)
            .help("Nouvelle archive")

            Button(action: {
                archiveManager.openArchiveWithPanel()
            }) {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.bordered)
            .help("Ouvrir archive")

            Button(action: {
                archiveManager.closeCurrentArchive()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .help("Fermer archive")
            .disabled(archiveManager.currentArchive == nil)

            Spacer()

            Button(action: {
                showPreferences = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.bordered)
            .help("Préférences")
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        if let archive = archiveManager.currentArchive {
            FileListView(archive: archive)
        } else {
            emptyStateView
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("Aucune archive ouverte")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Ouvrez une archive existante ou créez-en une nouvelle")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Ouvrir archive") {
                    archiveManager.openArchiveWithPanel()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Nouvelle archive") {
                    showNewArchive = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}


