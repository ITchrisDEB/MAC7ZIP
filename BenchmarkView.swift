import SwiftUI

// MARK: - Benchmark View
struct BenchmarkView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var benchmarkManager = BenchmarkManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Benchmark de compression")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Testez les performances des différents algorithmes de compression")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Fermer") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            
            // Benchmark Controls
            VStack(spacing: 16) {
                HStack {
                    Text("Fichier de test")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Sélectionner un fichier") {
                        selectTestFile()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let testFile = benchmarkManager.testFile {
                    HStack {
                        Image(systemName: "doc.fill")
                            .foregroundColor(.blue)
                        
                        Text(testFile.lastPathComponent)
                            .font(.body)
                        
                        Spacer()
                        
                        Text(ByteCountFormatter.string(fromByteCount: testFile.fileSize, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                }
                
                HStack {
                    Button("Lancer le benchmark") {
                        runBenchmark()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(benchmarkManager.testFile == nil || benchmarkManager.isRunning)
                    
                    if benchmarkManager.isRunning {
                        Button("Annuler") {
                            benchmarkManager.cancelBenchmark()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            
            // Progress
            if benchmarkManager.isRunning {
                VStack(spacing: 12) {
                    ProgressView(value: benchmarkManager.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(benchmarkManager.currentOperation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            // Results
            if !benchmarkManager.results.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Résultats")
                        .font(.headline)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(benchmarkManager.results) { result in
                                BenchmarkResultRow(result: result)
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 800, height: 600)
    }
    
    // MARK: - Select Test File
    private func selectTestFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.item]
        panel.title = "Sélectionner un fichier de test"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                benchmarkManager.setTestFile(url)
            }
        }
    }
    
    // MARK: - Run Benchmark
    private func runBenchmark() {
        guard let testFile = benchmarkManager.testFile else { return }
        
        Task {
            await benchmarkManager.runBenchmark(testFile: testFile)
        }
    }
}

// MARK: - Benchmark Result Row
struct BenchmarkResultRow: View {
    let result: BenchmarkResult
    
    var body: some View {
        HStack(spacing: 16) {
            // Method name
            VStack(alignment: .leading, spacing: 4) {
                Text(result.method)
                    .font(.headline)
                
                Text("Niveau \(result.level)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 120, alignment: .leading)
            
            // Compression ratio
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(format: "%.1f", result.compressionRatio))%")
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("Ratio")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Compression time
            VStack(alignment: .leading, spacing: 4) {
                Text(formatTime(result.compressionTime))
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("Temps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            
            // Speed
            VStack(alignment: .leading, spacing: 4) {
                Text(formatSpeed(result.speed))
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("Vitesse")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, alignment: .leading)
            
            // Size
            VStack(alignment: .leading, spacing: 4) {
                Text(ByteCountFormatter.string(fromByteCount: result.compressedSize, countStyle: .file))
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("Taille")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, alignment: .leading)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        if time < 1.0 {
            return String(format: "%.2fs", time)
        } else {
            return String(format: "%.1fs", time)
        }
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed < 1024 {
            return String(format: "%.0f B/s", speed)
        } else if speed < 1024 * 1024 {
            return String(format: "%.1f KB/s", speed / 1024)
        } else {
            return String(format: "%.1f MB/s", speed / (1024 * 1024))
        }
    }
}

// MARK: - Benchmark Manager
class BenchmarkManager: ObservableObject {
    static let shared = BenchmarkManager()
    
    @Published var testFile: URL?
    @Published var isRunning = false
    @Published var progress: Double = 0.0
    @Published var currentOperation = ""
    @Published var results: [BenchmarkResult] = []
    
    private var currentProcess: Process?
    
    private init() {}
    
    func setTestFile(_ url: URL) {
        testFile = url
        results.removeAll()
    }
    
    func runBenchmark(testFile: URL) async {
        await MainActor.run {
            isRunning = true
            progress = 0.0
            results.removeAll()
        }
        
        let methods = [
            ("LZMA2", 5),
            ("LZMA2", 9),
            ("LZMA", 5),
            ("LZMA", 9),
            ("PPMd", 6),
            ("PPMd", 16),
            ("BZip2", 5),
            ("BZip2", 9),
            ("Deflate", 5),
            ("Deflate", 9)
        ]
        
        let totalMethods = methods.count
        
        for (index, (method, level)) in methods.enumerated() {
            await MainActor.run {
                currentOperation = "Test de \(method) niveau \(level)..."
                progress = Double(index) / Double(totalMethods)
            }
            
            if let result = await runCompressionTest(file: testFile, method: method, level: level) {
                await MainActor.run {
                    results.append(result)
                }
            }
        }
        
        await MainActor.run {
            isRunning = false
            progress = 1.0
            currentOperation = "Benchmark terminé"
        }
    }
    
    func cancelBenchmark() {
        currentProcess?.terminate()
        isRunning = false
        progress = 0.0
        currentOperation = "Benchmark annulé"
    }
    
    private func runCompressionTest(file: URL, method: String, level: Int) async -> BenchmarkResult? {
        // This is a simplified implementation
        // In a real implementation, you would run the actual compression commands
        
        let startTime = Date()
        
        // Simulate compression time
        try? await Task.sleep(nanoseconds: UInt64.random(in: 100_000_000...500_000_000))
        
        let endTime = Date()
        let compressionTime = endTime.timeIntervalSince(startTime)
        
        // Simulate results
        let originalSize = file.fileSize
        let compressionRatio = Double.random(in: 0.3...0.8)
        let compressedSize = Int64(Double(originalSize) * compressionRatio)
        let speed = Double(originalSize) / compressionTime
        
        return BenchmarkResult(
            method: method,
            level: level,
            compressionRatio: compressionRatio * 100,
            compressionTime: compressionTime,
            compressedSize: compressedSize,
            speed: speed
        )
    }
}

// MARK: - Benchmark Result
struct BenchmarkResult: Identifiable {
    let id = UUID()
    let method: String
    let level: Int
    let compressionRatio: Double
    let compressionTime: TimeInterval
    let compressedSize: Int64
    let speed: Double
}

// MARK: - URL Extension
extension URL {
    var fileSize: Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
}

// MARK: - Preview
#Preview {
    BenchmarkView()
}