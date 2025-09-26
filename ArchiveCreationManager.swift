import SwiftUI

// MARK: - Archive Creation Manager
class ArchiveCreationManager: ObservableObject {
    static let shared = ArchiveCreationManager()
    
    @Published var isCreating = false
    @Published var creationProgress: Double = 0.0
    @Published var currentFile = ""
    @Published var currentOperation = ""
    @Published var canCancel = false
    @Published var creationError: String?
    
    private var currentProcess: Process?
    private var isCancelled = false
    
    private init() {}
    
    // MARK: - Archive Creation
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        await MainActor.run {
            isCreating = true
            creationProgress = 0.0
            currentFile = ""
            currentOperation = "Préparation de l'archive..."
            canCancel = true
            creationError = nil
            isCancelled = false
        }
        
        do {
            // Select appropriate engine based on format
            let engine = getArchiveEngine(for: url)
            
            // Update operation
            await MainActor.run {
                currentOperation = "Création de l'archive..."
            }
            
            // Create archive
            try await engine.createArchive(at: url, files: files, options: options)
            
            // Update progress
            await MainActor.run {
                creationProgress = 1.0
                currentOperation = "Archive créée avec succès"
                isCreating = false
                canCancel = false
            }
            
        } catch {
            await MainActor.run {
                creationError = error.localizedDescription
                isCreating = false
                canCancel = false
            }
            throw error
        }
    }
    
    // MARK: - Archive Engine Selection
    private func getArchiveEngine(for url: URL) -> ArchiveEngine {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "rar":
            return RarArchiveEngine()
        case "7z":
            return SevenZipArchiveEngine()
        default:
            return SevenZipArchiveEngine()
        }
    }
    
    // MARK: - Progress Updates
    func updateProgress(_ progress: Double, file: String = "", operation: String = "") {
        DispatchQueue.main.async {
            self.creationProgress = progress
            if !file.isEmpty {
                self.currentFile = file
            }
            if !operation.isEmpty {
                self.currentOperation = operation
            }
        }
    }
    
    // MARK: - Cancellation
    func cancelCreation() {
        isCancelled = true
        currentProcess?.terminate()
        
        DispatchQueue.main.async {
            self.isCreating = false
            self.canCancel = false
            self.currentOperation = "Création annulée"
        }
    }
    
    func setProcess(_ process: Process) {
        currentProcess = process
    }
    
    var isCancelledOperation: Bool {
        return isCancelled
    }
    
    // MARK: - Error Handling
    func clearError() {
        creationError = nil
    }
}

// MARK: - Archive Creation View
struct ArchiveCreationView: View {
    @ObservedObject var creationManager = ArchiveCreationManager.shared
    
    var body: some View {
        if creationManager.isCreating {
            VStack(spacing: 20) {
                // Progress indicator
                VStack(spacing: 12) {
                    ProgressView(value: creationManager.creationProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 300)
                    
                    Text(creationManager.currentOperation)
                        .font(.headline)
                    
                    if !creationManager.currentFile.isEmpty {
                        Text("Fichier: \(creationManager.currentFile)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // Cancel button
                if creationManager.canCancel {
                    Button("Annuler") {
                        creationManager.cancelCreation()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                }
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .frame(maxWidth: 400)
        }
    }
}

// MARK: - Archive Creation Overlay
struct ArchiveCreationOverlay: View {
    @ObservedObject var creationManager = ArchiveCreationManager.shared
    
    var body: some View {
        if creationManager.isCreating {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ArchiveCreationView()
            }
        }
    }
}