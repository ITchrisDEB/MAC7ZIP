import SwiftUI

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // App Icon and Title
            VStack(spacing: 16) {
                Image(systemName: "archivebox.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Mac7zip")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version \(appVersion)")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            
            // Description
            VStack(spacing: 12) {
                Text("Application d'archivage native pour macOS")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text("Interface graphique moderne pour 7-Zip, RAR et XZ avec support complet des formats d'archives.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Features
            VStack(alignment: .leading, spacing: 12) {
                Text("Fonctionnalités principales")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    FeatureRow(icon: "checkmark.circle.fill", text: "Support de tous les formats d'archives")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Interface SwiftUI native et moderne")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Compression multithread optimisée")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Chiffrement AES-256 sécurisé")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Support RAR et XZ natif")
                    FeatureRow(icon: "checkmark.circle.fill", text: "Accessibilité VoiceOver complète")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Copyright and Links
            VStack(spacing: 8) {
                Text("© 2025 Mac7zip Team")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    Link("Site Web", destination: URL(string: "https://mac7zip.app")!)
                    Link("GitHub", destination: URL(string: "https://github.com/mac7zip/mac7zip")!)
                    Link("Support", destination: URL(string: "https://github.com/mac7zip/mac7zip/issues")!)
                }
                .font(.caption)
            }
            
            Spacer()
            
            // Close Button
            Button("Fermer") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 500, height: 600)
    }
    
    // MARK: - App Version
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 16)
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Preview
#Preview {
    AboutView()
}