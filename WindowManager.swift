import Foundation
import SwiftUI

// MARK: - Window Manager
class WindowManager: ObservableObject {
    @Published var showAbout = false
    @Published var showBenchmark = false
    @Published var showNewArchive = false
    @Published var showAddFiles = false
    @Published var showExtract = false
    @Published var showAdvancedOptions = false
    @Published var showSecurityOptions = false
    @Published var showCompressionMethods = false
    @Published var showFilters = false
    @Published var showVolumeOptions = false
    @Published var showRarOptions = false
    @Published var showPreferences = false
    
    init() {}
    
    // MARK: - Window Actions
    func showAboutWindow() {
        showAbout = true
    }
    
    func showBenchmarkWindow() {
        showBenchmark = true
    }
    
    func showNewArchiveWindow() {
        showNewArchive = true
    }
    
    func showAddFilesWindow() {
        showAddFiles = true
    }
    
    func showExtractWindow() {
        showExtract = true
    }
    
    func showAdvancedOptionsWindow() {
        showAdvancedOptions = true
    }
    
    func showSecurityOptionsWindow() {
        showSecurityOptions = true
    }
    
    func showCompressionMethodsWindow() {
        showCompressionMethods = true
    }
    
    func showFiltersWindow() {
        showFilters = true
    }
    
    func showVolumeOptionsWindow() {
        showVolumeOptions = true
    }
    
    func showRarOptionsWindow() {
        showRarOptions = true
    }
    
    func showPreferencesWindow() {
        showPreferences = true
    }
    
    // MARK: - Window Management
    func closeAllWindows() {
        showAbout = false
        showBenchmark = false
        showNewArchive = false
        showAddFiles = false
        showExtract = false
        showAdvancedOptions = false
        showSecurityOptions = false
        showCompressionMethods = false
        showFilters = false
        showVolumeOptions = false
        showRarOptions = false
        showPreferences = false
    }
    
    func isAnyWindowOpen() -> Bool {
        return showAbout || showBenchmark || showNewArchive || showAddFiles || 
               showExtract || showAdvancedOptions || showSecurityOptions || 
               showCompressionMethods || showFilters || showVolumeOptions || 
               showRarOptions || showPreferences
    }
}