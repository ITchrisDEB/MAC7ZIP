import Foundation
import SwiftUI
import os.log

// MARK: - Log Manager
class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var isLoggingEnabled = false
    @Published var logLevel: LogLevel = .info
    
    private let logger = Logger(subsystem: "com.mac7zip.app", category: "main")
    private let maxLogEntries = 1000
    
    private init() {
        // Charger les préférences
        isLoggingEnabled = UserDefaults.standard.bool(forKey: "enableLogging")
        let levelString = UserDefaults.standard.string(forKey: "logLevel") ?? "Info"
        logLevel = LogLevel(rawValue: levelString) ?? .info
    }
    
    func log(_ message: String, level: LogLevel = .info, category: String = "general") {
        guard isLoggingEnabled && level.rawValue >= logLevel.rawValue else { return }
        
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message
        )
        
        DispatchQueue.main.async {
            self.logs.append(entry)
            
            // Limiter le nombre d'entrées
            if self.logs.count > self.maxLogEntries {
                self.logs.removeFirst(self.logs.count - self.maxLogEntries)
            }
        }
        
        // Logger aussi dans le système
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func exportLogs() -> URL? {
        let logText = logs.map { entry in
            "[\(entry.timestamp.formatted(date: .omitted, time: .standard))] [\(entry.level.rawValue.uppercased())] [\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("mac7zip_logs_\(Date().timeIntervalSince1970).txt")
        
        do {
            try logText.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            log("Erreur lors de l'export des logs: \(error.localizedDescription)", level: .error)
            return nil
        }
    }
    
    func setLoggingEnabled(_ enabled: Bool) {
        isLoggingEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "enableLogging")
    }
    
    func setLogLevel(_ level: LogLevel) {
        logLevel = level
        UserDefaults.standard.set(level.rawValue, forKey: "logLevel")
    }
}

// MARK: - Log Entry
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
}

// MARK: - Log Level
enum LogLevel: String, CaseIterable, Comparable {
    case debug = "Debug"
    case info = "Info"
    case warning = "Warning"
    case error = "Error"
    
    var color: String {
        switch self {
        case .debug: return "gray"
        case .info: return "blue"
        case .warning: return "orange"
        case .error: return "red"
        }
    }
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        let order: [LogLevel] = [.debug, .info, .warning, .error]
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}

// MARK: - Log View
struct LogView: View {
    @ObservedObject var logManager = LogManager.shared
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel? = nil
    
    var filteredLogs: [LogEntry] {
        var logs = logManager.logs
        
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let selectedLevel = selectedLevel {
            logs = logs.filter { $0.level == selectedLevel }
        }
        
        return logs.reversed() // Plus récent en premier
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Barre d'outils
            HStack {
                TextField("Rechercher dans les logs...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Niveau", selection: $selectedLevel) {
                    Text("Tous").tag(LogLevel?.none)
                    ForEach(LogLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(LogLevel?.some(level))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                
                Button("Effacer") {
                    logManager.clearLogs()
                }
                .buttonStyle(.bordered)
                
                Button("Exporter") {
                    if let url = logManager.exportLogs() {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Liste des logs
            List(filteredLogs) { entry in
                HStack(alignment: .top, spacing: 12) {
                    // Indicateur de niveau
                    Circle()
                        .fill(Color(entry.level.color))
                        .frame(width: 8, height: 8)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.timestamp.formatted(date: .omitted, time: .standard))
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(entry.level.rawValue.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(entry.level.color))
                        }
                        
                        Text("[\(entry.category)] \(entry.message)")
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .navigationTitle("Logs")
    }
}
