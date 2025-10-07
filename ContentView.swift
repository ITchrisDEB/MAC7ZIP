import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let showPreferences = Notification.Name("showPreferences")
    static let showNewArchive = Notification.Name("showNewArchive")
    static let showAddFiles = Notification.Name("showAddFiles")
    static let showExtract = Notification.Name("showExtract")
    static let showProperties = Notification.Name("showProperties")
    static let showAdvancedOptions = Notification.Name("showAdvancedOptions")
    static let showSecurityOptions = Notification.Name("showSecurityOptions")
    static let showCompressionMethods = Notification.Name("showCompressionMethods")
    static let showFilters = Notification.Name("showFilters")
    static let showVolumeOptions = Notification.Name("showVolumeOptions")
    static let showRarOptions = Notification.Name("showRarOptions")
}

struct ContentView: View {
    @StateObject private var archiveManager = ArchiveManager()
    @StateObject private var windowManager = WindowManager()
    @EnvironmentObject var localizationManager: LocalizationManager
    
    // État pour savoir si cette vue est dans la fenêtre active
    @State private var isWindowActive = false
    
    // ID unique pour cette ContentView
    private let contentViewId = UUID()
    
    // Sheet states
    @State private var showPreferences = false
    @State private var showNewArchive = false
    @State private var newArchiveId = UUID()
    @State private var showAddFiles = false
    @State private var showExtract = false
    @State private var showProperties = false
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
        .environmentObject(archiveManager)
        .onReceive(NotificationCenter.default.publisher(for: .showPreferences)) { _ in
            showPreferences = true
        }
        // showNewArchive géré maintenant par FocusedBinding - plus besoin d'onReceive
        .onAppear {
            // S'enregistrer pour les notifications de fenêtre active
            NotificationCenter.default.addObserver(
                forName: NSWindow.didBecomeKeyNotification,
                object: nil,
                queue: .main
            ) { notification in
                // Vérifier si c'est notre fenêtre qui devient active
                if let window = notification.object as? NSWindow {
                    checkIfWindowIsActive(window)
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.didResignKeyNotification,
                object: nil,
                queue: .main
            ) { notification in
                // Notre fenêtre n'est plus active
                if let window = notification.object as? NSWindow {
                    checkIfWindowIsActive(window)
                }
            }
            
            // Vérifier l'état initial
            DispatchQueue.main.async {
                NSLog("🚀 ContentView \(contentViewId) - onAppear démarré")
                if let keyWindow = NSApp.keyWindow {
                    NSLog("🚀 ContentView \(contentViewId) - KeyWindow trouvée: \(keyWindow.title)")
                    checkIfWindowIsActive(keyWindow)
                } else {
                    NSLog("🚀 ContentView \(contentViewId) - Aucune KeyWindow trouvée")
                    isWindowActive = true  // Par défaut, la première fenêtre est active
                }
            }
        }
        .onDisappear {
            // Se désinscrire des notifications
            NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: NSWindow.didResignKeyNotification, object: nil)
        }
        // showAddFiles, showExtract, showProperties gérés par FocusedBinding
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("openArchive"))) { notification in
            NSLog("🔍 ContentView \(contentViewId) - Notification openArchive reçue")
            if let url = notification.object as? URL {
                NSLog("🔍 ContentView \(contentViewId) - URL extraite: \(url.path)")
                archiveManager.openArchive(at: url)
            } else {
                NSLog("❌ ContentView \(contentViewId) - Pas d'URL dans la notification")
            }
        }
        // openArchiveDialog et closeArchive gérés par FocusedBinding
        .onAppear {
            // S'assurer qu'on revient à l'état d'accueil si aucune archive n'est ouverte
            if archiveManager.currentArchive == nil {
                // L'état d'accueil sera affiché automatiquement
            }
        }
        .sheet(isPresented: $showPreferences) {
            PreferencesView()
        }
        .sheet(isPresented: $showNewArchive) {
            NewArchiveView()
                .environmentObject(archiveManager)
                .id(newArchiveId)
        }
        .sheet(isPresented: $showAddFiles) {
            AddFilesView()
                .environmentObject(archiveManager)
        }
        .sheet(isPresented: $showExtract) {
            ExtractView()
                .environmentObject(archiveManager)
        }
        .sheet(isPresented: $showProperties) {
            PropertiesView()
                .environmentObject(archiveManager)
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
        // EXPOSER LES FOCUSED VALUES pour que Mac7zipApp puisse les utiliser
        .focusedSceneValue(\.showNewArchive, $showNewArchive)
        .focusedSceneValue(\.showOpenArchive, Binding<Bool>(
            get: { false },
            set: { _ in archiveManager.openArchiveWithPanel() }
        ))
        .focusedSceneValue(\.showCloseArchive, Binding<Bool>(
            get: { false },
            set: { _ in archiveManager.closeCurrentArchive() }
        ))
        .focusedSceneValue(\.showExtract, $showExtract)
        .focusedSceneValue(\.showAddFiles, $showAddFiles)
        .focusedSceneValue(\.showProperties, $showProperties)
    }
    
    // MARK: - Helper Methods
    
    private func checkIfWindowIsActive(_ window: NSWindow) {
        // Vérifier si cette ContentView appartient à la fenêtre active
        DispatchQueue.main.async {
            let wasActive = isWindowActive
            let keyWindow = NSApp.keyWindow
            isWindowActive = (window == keyWindow)
            
            NSLog("🔍 ContentView \(contentViewId) - Window: \(window.title), KeyWindow: \(keyWindow?.title ?? "nil"), isActive: \(isWindowActive)")
            
            if wasActive != isWindowActive {
                NSLog("🔄 ContentView \(contentViewId) - État changé: \(wasActive) → \(isWindowActive)")
            }
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
            .help("new_archive".localized)

            Button(action: {
                archiveManager.openArchiveWithPanel()
            }) {
                Image(systemName: "folder")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.bordered)
            .help("open_archive".localized)

            Button(action: {
                archiveManager.closeCurrentArchive()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
            }
            .buttonStyle(.bordered)
            .help("close_archive".localized)
            .disabled(archiveManager.currentArchive == nil)

            Spacer()

            Button(action: {
                showPreferences = true
            }) {
                Image(systemName: "gear")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.bordered)
            .help("preferences".localized)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        if archiveManager.currentArchive != nil {
            AnyView(FileListView())
        } else {
            AnyView(emptyStateView)
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "archivebox")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            Text("no_archive_open".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("open_existing_or_create_new".localized)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("open_archive".localized) {
                    archiveManager.openArchiveWithPanel()
                }
                .buttonStyle(.borderedProminent)
                
                Button("new_archive".localized) {
                    showNewArchive = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
