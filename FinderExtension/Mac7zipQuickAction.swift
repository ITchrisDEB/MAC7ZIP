import Cocoa
import QuickLookThumbnailing

class Mac7zipQuickAction: NSObject, QLThumbnailProvider {
    
    func provideThumbnail(for request: QLThumbnailRequest, _ handler: @escaping (QLThumbnailReply?, Error?) -> Void) {
        
        // Vérifier si c'est une archive supportée
        let fileExtension = request.fileURL.pathExtension.lowercased()
        let supportedExtensions = ["7z", "zip", "rar", "tar", "gz", "bz2", "xz", "dmg", "cab", "msi", "wim", "iso"]
        
        guard supportedExtensions.contains(fileExtension) else {
            handler(nil, NSError(domain: "Mac7zipQuickAction", code: 1, userInfo: [NSLocalizedDescriptionKey: "Format non supporté"]))
            return
        }
        
        // Créer une icône personnalisée pour l'archive
        let icon = createArchiveIcon(for: fileExtension)
        
        // Créer la réponse avec l'icône
        let reply = QLThumbnailReply(contextSize: request.maximumSize, currentContextDrawing: { context in
            icon.draw(in: CGRect(origin: .zero, size: request.maximumSize))
            return true
        })
        
        handler(reply, nil)
    }
    
    private func createArchiveIcon(for fileExtension: String) -> NSImage {
        let size = NSSize(width: 64, height: 64)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Couleur de fond selon le type d'archive
        let backgroundColor: NSColor
        switch fileExtension {
        case "7z":
            backgroundColor = NSColor.systemBlue
        case "zip":
            backgroundColor = NSColor.systemGreen
        case "rar":
            backgroundColor = NSColor.systemRed
        case "tar", "gz", "bz2", "xz":
            backgroundColor = NSColor.systemOrange
        case "dmg":
            backgroundColor = NSColor.systemPurple
        default:
            backgroundColor = NSColor.systemGray
        }
        
        // Dessiner le fond
        backgroundColor.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size), xRadius: 8, yRadius: 8).fill()
        
        // Dessiner l'icône d'archive
        let iconRect = NSRect(x: 8, y: 8, width: 48, height: 48)
        NSColor.white.setFill()
        NSBezierPath(roundedRect: iconRect, xRadius: 4, yRadius: 4).fill()
        
        // Dessiner le texte de l'extension
        let text = fileExtension.uppercased()
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 12),
            .foregroundColor: backgroundColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
}
