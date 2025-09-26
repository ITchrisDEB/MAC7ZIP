import Foundation
import SwiftUI

// MARK: - Progress Tracker
class ProgressTracker: ObservableObject {
    @Published var isRunning = false
    @Published var progress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var currentFile: String = ""
    @Published var speed: String = ""
    @Published var eta: String = ""
    @Published var canCancel = false
    
    private var currentProcess: Process?
    private var isCancelled = false
    
    func startOperation(_ operation: String, canCancel: Bool = true) {
        DispatchQueue.main.async {
            self.isRunning = true
            self.progress = 0.0
            self.currentOperation = operation
            self.currentFile = ""
            self.speed = ""
            self.eta = ""
            self.canCancel = canCancel
            self.isCancelled = false
        }
    }
    
    func updateProgress(_ progress: Double, file: String = "", speed: String = "", eta: String = "") {
        DispatchQueue.main.async {
            self.progress = progress
            if !file.isEmpty {
                self.currentFile = file
            }
            if !speed.isEmpty {
                self.speed = speed
            }
            if !eta.isEmpty {
                self.eta = eta
            }
        }
    }
    
    func finishOperation() {
        DispatchQueue.main.async {
            self.isRunning = false
            self.progress = 1.0
            self.currentOperation = ""
            self.currentFile = ""
            self.speed = ""
            self.eta = ""
            self.canCancel = false
        }
    }
    
    func cancelOperation() {
        isCancelled = true
        currentProcess?.terminate()
        finishOperation()
    }
    
    func setProcess(_ process: Process) {
        currentProcess = process
    }
    
    var isCancelledOperation: Bool {
        return isCancelled
    }
}

// MARK: - Progress View
struct Mac7zipProgressView: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        VStack(spacing: 16) {
            // Titre de l'opération
            Text(progressTracker.currentOperation)
                .font(.headline)
                .foregroundColor(.primary)
            
            // Barre de progression
            ProgressView(value: progressTracker.progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(height: 8)
            
            // Informations détaillées
            VStack(spacing: 8) {
                if !progressTracker.currentFile.isEmpty {
                    Text("Fichier: \(progressTracker.currentFile)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack {
                    if !progressTracker.speed.isEmpty {
                        Text("Vitesse: \(progressTracker.speed)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !progressTracker.eta.isEmpty {
                        Text("Temps restant: \(progressTracker.eta)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Bouton d'annulation
            if progressTracker.canCancel {
                Button("Annuler") {
                    progressTracker.cancelOperation()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .frame(maxWidth: 400)
    }
}

// MARK: - Progress Overlay
struct ProgressOverlay: View {
    @ObservedObject var progressTracker: ProgressTracker
    
    var body: some View {
        if progressTracker.isRunning {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                Mac7zipProgressView(progressTracker: progressTracker)
            }
        }
    }
}
