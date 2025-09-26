import SwiftUI

// MARK: - Error Manager
class ErrorManager: ObservableObject {
    static let shared = ErrorManager()
    
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var errorTitle = "Erreur"
    @Published var errorDetails = ""
    @Published var canRetry = false
    @Published var retryAction: (() -> Void)?
    
    private init() {}
    
    // MARK: - Error Display
    func showError(_ message: String, title: String = "Erreur", details: String = "", canRetry: Bool = false, retryAction: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.errorTitle = title
            self.errorDetails = details
            self.canRetry = canRetry
            self.retryAction = retryAction
            self.showError = true
        }
    }
    
    func showArchiveError(_ error: ArchiveError) {
        let (title, message, details) = errorInfo(for: error)
        showError(message, title: title, details: details)
    }
    
    func showSystemError(_ error: Error) {
        showError(
            error.localizedDescription,
            title: "Erreur système",
            details: "\(error)"
        )
    }
    
    func showNetworkError(_ error: Error) {
        showError(
            "Erreur de réseau: \(error.localizedDescription)",
            title: "Erreur de connexion",
            details: "\(error)",
            canRetry: true
        )
    }
    
    func showFileError(_ error: Error) {
        showError(
            "Erreur de fichier: \(error.localizedDescription)",
            title: "Erreur de fichier",
            details: "\(error)"
        )
    }
    
    func showPermissionError() {
        showError(
            "Permission refusée",
            title: "Erreur de permission",
            details: "L'application n'a pas les permissions nécessaires pour effectuer cette action."
        )
    }
    
    func showDiskSpaceError() {
        showError(
            "Espace disque insuffisant",
            title: "Erreur d'espace disque",
            details: "Il n'y a pas assez d'espace disque pour effectuer cette opération."
        )
    }
    
    func showCorruptedArchiveError() {
        showError(
            "Archive corrompue",
            title: "Erreur d'archive",
            details: "L'archive semble être corrompue ou endommagée.",
            canRetry: true
        )
    }
    
    func showPasswordError() {
        showError(
            "Mot de passe incorrect",
            title: "Erreur de mot de passe",
            details: "Le mot de passe fourni est incorrect ou l'archive n'est pas chiffrée."
        )
    }
    
    func showBinaryNotFoundError(_ binaryName: String) {
        showError(
            "Binaire \(binaryName) non trouvé",
            title: "Erreur de binaire",
            details: "Le binaire \(binaryName) est introuvable dans le bundle de l'application."
        )
    }
    
    func showUnsupportedFormatError(_ format: String) {
        showError(
            "Format non supporté: \(format)",
            title: "Format non supporté",
            details: "Le format \(format) n'est pas supporté par cette application."
        )
    }
    
    func showCompressionError(_ error: Error) {
        showError(
            "Erreur de compression: \(error.localizedDescription)",
            title: "Erreur de compression",
            details: "\(error)",
            canRetry: true
        )
    }
    
    func showExtractionError(_ error: Error) {
        showError(
            "Erreur d'extraction: \(error.localizedDescription)",
            title: "Erreur d'extraction",
            details: "\(error)",
            canRetry: true
        )
    }
    
    // MARK: - Error Info
    private func errorInfo(for error: ArchiveError) -> (title: String, message: String, details: String) {
        switch error {
        case .binaryNotFound:
            return ("Binaire non trouvé", "Le binaire 7zz est introuvable", "Vérifiez que l'application est correctement installée.")
        case .invalidArchive:
            return ("Archive invalide", "L'archive semble être corrompue", "Essayez de télécharger à nouveau l'archive.")
        case .listFailed:
            return ("Erreur de listage", "Impossible de lister le contenu de l'archive", "L'archive pourrait être corrompue ou protégée par un mot de passe.")
        case .extractionFailed:
            return ("Erreur d'extraction", "L'extraction a échoué", "Vérifiez les permissions et l'espace disque disponible.")
        case .creationFailed:
            return ("Erreur de création", "La création de l'archive a échoué", "Vérifiez les permissions et l'espace disque disponible.")
        case .testFailed(let message):
            return ("Test échoué", "Le test de l'archive a échoué", message)
        case .unsupportedFormat:
            return ("Format non supporté", "Ce format d'archive n'est pas supporté", "Utilisez un format supporté comme 7z, zip, rar, ou xz.")
        }
    }
    
    // MARK: - Retry
    func retry() {
        retryAction?()
        dismissError()
    }
    
    func dismissError() {
        showError = false
        errorMessage = ""
        errorTitle = "Erreur"
        errorDetails = ""
        canRetry = false
        retryAction = nil
    }
}

// MARK: - Error View
struct ErrorView: View {
    @ObservedObject var errorManager = ErrorManager.shared
    
    var body: some View {
        if errorManager.showError {
            VStack(spacing: 20) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                // Error title
                Text(errorManager.errorTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Error message
                Text(errorManager.errorMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                
                // Error details
                if !errorManager.errorDetails.isEmpty {
                    Text(errorManager.errorDetails)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    if errorManager.canRetry {
                        Button("Réessayer") {
                            errorManager.retry()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button("Fermer") {
                        errorManager.dismissError()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .frame(maxWidth: 400)
        }
    }
}