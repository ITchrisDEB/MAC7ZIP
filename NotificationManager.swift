import Foundation
import UserNotifications

// MARK: - Notification Manager
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private var isAvailable = false
    
    private init() {
        // Vérifier si les notifications sont disponibles
        checkAvailability()
    }
    
    private func checkAvailability() {
        // Désactiver les notifications pour éviter les crashes
        // TODO: Réactiver quand l'app sera correctement packagée
        isAvailable = false
        print("⚠️ Notifications désactivées temporairement")
    }
    
    private func requestPermission() {
        guard isAvailable else { return }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Erreur lors de la demande d'autorisation pour les notifications: \(error)")
            }
        }
    }
    
    func sendNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        guard isAvailable else {
            print("📢 Notification (non disponible): \(title) - \(body)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Erreur lors de l'envoi de la notification: \(error)")
            }
        }
    }
    
    func sendArchiveCreatedNotification(archiveName: String) {
        sendNotification(
            title: "Archive créée",
            body: "L'archive '\(archiveName)' a été créée avec succès",
            identifier: "archive_created_\(archiveName)"
        )
    }
    
    func sendArchiveExtractedNotification(archiveName: String) {
        sendNotification(
            title: "Archive extraite",
            body: "L'archive '\(archiveName)' a été extraite avec succès",
            identifier: "archive_extracted_\(archiveName)"
        )
    }
    
    func sendErrorNotification(error: String) {
        sendNotification(
            title: "Erreur Mac7zip",
            body: error,
            identifier: "error_\(UUID().uuidString)"
        )
    }
    
    func sendProgressNotification(operation: String, progress: Double) {
        let percentage = Int(progress * 100)
        sendNotification(
            title: "Mac7zip - \(operation)",
            body: "Progression: \(percentage)%",
            identifier: "progress_\(operation)"
        )
    }
}
