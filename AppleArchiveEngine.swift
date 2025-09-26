import Foundation
import Compression

// MARK: - Apple Archive Engine
class AppleArchiveEngine: ArchiveEngine {
    
    func openArchive(at url: URL) async throws -> ArchiveInfo {
        // Vérifier si c'est un format supporté par Apple
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        // Vérifier d'abord les extensions composées
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            return try await openTarGzArchive(at: url)
        } else if fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz2") {
            return try await openTarBz2Archive(at: url)
        }
        
        // Puis les extensions simples
        switch fileExtension {
        case "zip":
            return try await openZipArchive(at: url)
        case "tar":
            return try await openTarArchive(at: url)
        case "dmg":
            return try await openDmgArchive(at: url)
        default:
            throw ArchiveError.unsupportedFormat
        }
    }
    
    func listContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        // Vérifier d'abord les extensions composées
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            return try await listTarGzContents(of: url, path: path)
        } else if fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz2") {
            return try await listTarBz2Contents(of: url, path: path)
        }
        
        // Puis les extensions simples
        switch fileExtension {
        case "zip":
            return try await listZipContents(of: url, path: path)
        case "tar":
            return try await listTarContents(of: url, path: path)
        case "dmg":
            return try await listDmgContents(of: url, path: path)
        default:
            throw ArchiveError.unsupportedFormat
        }
    }
    
    func extractArchive(at url: URL, to destination: URL, options: ArchiveOptions) async throws {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        // Vérifier d'abord les extensions composées
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            try await extractTarGzArchive(at: url, to: destination)
        } else if fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz2") {
            try await extractTarBz2Archive(at: url, to: destination)
        } else {
            // Puis les extensions simples
            switch fileExtension {
            case "zip":
                try await extractZipArchive(at: url, to: destination)
            case "tar":
                try await extractTarArchive(at: url, to: destination)
            case "dmg":
                try await extractDmgArchive(at: url, to: destination)
            default:
                throw ArchiveError.unsupportedFormat
            }
        }
    }
    
    func extractFiles(from url: URL, files: [String], to destination: URL, options: ArchiveOptions) async throws {
        let fileName = url.lastPathComponent.lowercased()
        let fileExtension = url.pathExtension.lowercased()
        
        // Vérifier d'abord les extensions composées
        if fileName.hasSuffix(".tar.gz") || fileName.hasSuffix(".tgz") {
            try await extractTarGzFiles(from: url, files: files, to: destination)
        } else if fileName.hasSuffix(".tar.bz2") || fileName.hasSuffix(".tbz2") {
            try await extractTarBz2Files(from: url, files: files, to: destination)
        } else {
            // Puis les extensions simples
            switch fileExtension {
            case "zip":
                try await extractZipFiles(from: url, files: files, to: destination)
            case "tar":
                try await extractTarFiles(from: url, files: files, to: destination)
            case "dmg":
                try await extractDmgFiles(from: url, files: files, to: destination)
            default:
                throw ArchiveError.unsupportedFormat
            }
        }
    }
    
    // MARK: - ZIP Extraction
    private func extractZipArchive(at url: URL, to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", url.path, "-d", destination.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    private func extractZipFiles(from url: URL, files: [String], to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", url.path, "-d", destination.path]
        process.arguments?.append(contentsOf: files)
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    // MARK: - TAR Extraction
    private func extractTarArchive(at url: URL, to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xf", url.path, "-C", destination.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    private func extractTarFiles(from url: URL, files: [String], to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xf", url.path, "-C", destination.path]
        process.arguments?.append(contentsOf: files)
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    // MARK: - DMG Extraction
    private func extractDmgArchive(at url: URL, to destination: URL) async throws {
        let mountPoint = "/tmp/mac7zip_dmg_\(UUID().uuidString)"
        
        // Monter l'image DMG
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", url.path, "-mountpoint", mountPoint, "-nobrowse", "-quiet"]
        
        try mountProcess.run()
        mountProcess.waitUntilExit()
        
        defer {
            // Démontage
            let unmountProcess = Process()
            unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            unmountProcess.arguments = ["detach", mountPoint, "-quiet"]
            try? unmountProcess.run()
        }
        
        if mountProcess.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
        
        // Copier le contenu
        let copyProcess = Process()
        copyProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cp")
        copyProcess.arguments = ["-R", "\(mountPoint)/.", destination.path]
        
        try copyProcess.run()
        copyProcess.waitUntilExit()
        
        if copyProcess.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    private func extractDmgFiles(from url: URL, files: [String], to destination: URL) async throws {
        let mountPoint = "/tmp/mac7zip_dmg_\(UUID().uuidString)"
        
        // Monter l'image DMG
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", url.path, "-mountpoint", mountPoint, "-nobrowse", "-quiet"]
        
        try mountProcess.run()
        mountProcess.waitUntilExit()
        
        defer {
            // Démontage
            let unmountProcess = Process()
            unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            unmountProcess.arguments = ["detach", mountPoint, "-quiet"]
            try? unmountProcess.run()
        }
        
        if mountProcess.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
        
        // Copier les fichiers spécifiques
        for file in files {
            let sourcePath = "\(mountPoint)/\(file)"
            let destinationPath = "\(destination.path)/\(URL(fileURLWithPath: file).lastPathComponent)"
            
            let copyProcess = Process()
            copyProcess.executableURL = URL(fileURLWithPath: "/usr/bin/cp")
            copyProcess.arguments = ["-R", sourcePath, destinationPath]
            
            try copyProcess.run()
            copyProcess.waitUntilExit()
        }
    }
    
    func createArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "zip":
            try await createZipArchive(at: url, files: files, options: options)
        case "tar":
            try await createTarArchive(at: url, files: files, options: options)
        case "gz":
            try await createTarGzArchive(at: url, files: files, options: options)
        case "bz2":
            try await createTarBz2Archive(at: url, files: files, options: options)
        default:
            throw ArchiveError.unsupportedFormat
        }
    }
    
    // MARK: - ZIP Creation
    private func createZipArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/zip")
        process.arguments = ["-r", "-j", url.path]  // -j = junk paths (exclure l'arborescence)
        
        // Ajouter les fichiers
        for file in files {
            process.arguments?.append(file.path)
        }
        
        // Options de compression
        if options.compressionLevel > 0 {
            process.arguments?.append("-\(options.compressionLevel)")
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.creationFailed
        }
    }
    
    // MARK: - TAR Creation
    private func createTarArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        
        // Utiliser -C pour changer de répertoire et éviter l'arborescence parent
        if let firstFile = files.first {
            let parentDir = firstFile.deletingLastPathComponent()
            process.arguments = ["-cf", url.path, "-C", parentDir.path]
            
            // Ajouter seulement les noms de fichiers (pas les chemins complets)
            for file in files {
                process.arguments?.append(file.lastPathComponent)
            }
        } else {
            process.arguments = ["-cf", url.path]
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.creationFailed
        }
    }
    
    private func createTarGzArchive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        
        // Utiliser -C pour changer de répertoire et éviter l'arborescence parent
        if let firstFile = files.first {
            let parentDir = firstFile.deletingLastPathComponent()
            process.arguments = ["-czf", url.path, "-C", parentDir.path]
            
            // Ajouter seulement les noms de fichiers (pas les chemins complets)
            for file in files {
                process.arguments?.append(file.lastPathComponent)
            }
        } else {
            process.arguments = ["-czf", url.path]
        }
        
        // Variables d'environnement pour le niveau de compression GZIP
        process.environment = ["GZIP": "-\(options.compressionLevel)"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.creationFailed
        }
    }
    
    private func createTarBz2Archive(at url: URL, files: [URL], options: ArchiveOptions) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        
        // Utiliser -C pour changer de répertoire et éviter l'arborescence parent
        if let firstFile = files.first {
            let parentDir = firstFile.deletingLastPathComponent()
            process.arguments = ["-cjf", url.path, "-C", parentDir.path]
            
            // Ajouter seulement les noms de fichiers (pas les chemins complets)
            for file in files {
                process.arguments?.append(file.lastPathComponent)
            }
        } else {
            process.arguments = ["-cjf", url.path]
        }
        
        // Variables d'environnement pour le niveau de compression BZIP2
        process.environment = ["BZIP2": "-\(options.compressionLevel)"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.creationFailed
        }
    }
    
    
    func addFiles(to url: URL, files: [URL], options: ArchiveOptions) async throws {
        // Implementation à compléter
    }
    
    func deleteFiles(from url: URL, files: [String], options: ArchiveOptions) async throws {
        // Implementation à compléter
    }
    
    func testArchive(at url: URL, options: ArchiveOptions) async throws {
        // Pour les formats Apple natifs, on peut simplement essayer d'ouvrir l'archive
        do {
            _ = try await openArchive(at: url)
        } catch {
            throw ArchiveError.testFailed("L'archive est corrompue: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ZIP Support
    private func openZipArchive(at url: URL) async throws -> ArchiveInfo {
        // Utiliser la commande unzip native
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-l", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.invalidArchive
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseZipInfo(from: output, url: url)
    }
    
    private func listZipContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-l", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.listFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseZipContents(from: output, currentPath: path)
    }
    
    // MARK: - TAR Support
    private func openTarArchive(at url: URL) async throws -> ArchiveInfo {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-tf", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.invalidArchive
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseTarInfo(from: output, url: url)
    }
    
    private func listTarContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-tvf", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.listFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseTarContents(from: output, currentPath: path)
    }
    
    // MARK: - DMG Support
    private func openDmgArchive(at url: URL) async throws -> ArchiveInfo {
        // DMG nécessite hdiutil
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        process.arguments = ["info", "-plist", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.invalidArchive
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseDmgInfo(from: output, url: url)
    }
    
    private func listDmgContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        // Pour DMG, on doit d'abord monter l'image
        let mountPoint = "/tmp/mac7zip_dmg_\(UUID().uuidString)"
        
        let mountProcess = Process()
        mountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
        mountProcess.arguments = ["attach", url.path, "-mountpoint", mountPoint, "-nobrowse", "-quiet"]
        
        try mountProcess.run()
        mountProcess.waitUntilExit()
        
        defer {
            // Démontage
            let unmountProcess = Process()
            unmountProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            unmountProcess.arguments = ["detach", mountPoint, "-quiet"]
            try? unmountProcess.run()
        }
        
        if mountProcess.terminationStatus != 0 {
            throw ArchiveError.invalidArchive
        }
        
        // Lister le contenu
        let listProcess = Process()
        listProcess.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        listProcess.arguments = [mountPoint, "-type", "f", "-o", "-type", "d"]
        
        let pipe = Pipe()
        listProcess.standardOutput = pipe
        listProcess.standardError = pipe
        
        try listProcess.run()
        listProcess.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return parseDmgContents(from: output, currentPath: path, mountPoint: mountPoint)
    }
    
    // MARK: - Parsing Functions
    private func parseZipInfo(from output: String, url: URL) -> ArchiveInfo {
        let lines = output.components(separatedBy: .newlines)
        var fileCount = 0
        var compressedSize: Int64 = 0
        
        for line in lines {
            if line.contains(" files") && line.contains(" bytes") {
                let components = line.components(separatedBy: " ")
                if let countIndex = components.firstIndex(of: "files") {
                    if countIndex > 0, let count = Int(components[countIndex - 1]) {
                        fileCount = count
                    }
                }
                if let bytesIndex = components.firstIndex(of: "bytes") {
                    if bytesIndex > 0, let size = Int64(components[bytesIndex - 1]) {
                        compressedSize = size
                    }
                }
            }
        }
        
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: fileCount,
            compressedSize: compressedSize,
            isEncrypted: false
        )
    }
    
    private func parseZipContents(from output: String, currentPath: String) -> [ArchiveItem] {
        let lines = output.components(separatedBy: .newlines)
        var items: [ArchiveItem] = []
        
        for line in lines {
            if line.hasPrefix("  ") && line.contains(" ") {
                let components = line.components(separatedBy: " ")
                if components.count >= 4 {
                    let fileName = components.last ?? ""
                    if !fileName.isEmpty && fileName != "Name" {
                        let isDirectory = fileName.hasSuffix("/")
                        let name = isDirectory ? String(fileName.dropLast()) : fileName
                        
                        items.append(ArchiveItem(
                            name: name,
                            path: fileName,
                            size: 0,
                            compressedSize: 0,
                            isDirectory: isDirectory,
                            attributes: [:],
                            compressionMethod: "Deflate",
                            crc: nil,
                            modificationDate: nil
                        ))
                    }
                }
            }
        }
        
        return items
    }
    
    private func parseTarInfo(from output: String, url: URL) -> ArchiveInfo {
        let lines = output.components(separatedBy: .newlines)
        let fileCount = lines.filter { !$0.isEmpty }.count
        
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: fileCount,
            compressedSize: 0,
            isEncrypted: false
        )
    }
    
    private func parseTarContents(from output: String, currentPath: String) -> [ArchiveItem] {
        var items: [ArchiveItem] = []
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            // Format TAR: "-rw-r--r--  0 chris  staff  21 Sep 24 11:34 dossier1/fichier3.txt"
            let components = trimmedLine.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            
            if components.count >= 9 {
                let permissions = components[0]
                let sizeString = components[4]
                let size = Int64(sizeString) ?? 0
                
                // Le nom peut contenir des espaces, donc on prend tout après l'heure
                let nameComponents = Array(components[8...])
                let fullPath = nameComponents.joined(separator: " ")
                
                // Déterminer si c'est un dossier (permissions commencent par 'd')
                let isDirectory = permissions.starts(with: "d")
                
                // Extraire le nom (dernière partie du chemin)
                let name = fullPath.components(separatedBy: "/").last ?? fullPath
                
                let item = ArchiveItem(
                    name: name,
                    path: fullPath,
                    size: size,
                    compressedSize: size, // TAR ne compresse pas individuellement
                    isDirectory: isDirectory,
                    attributes: [
                        "Permissions": permissions,
                        "Owner": components.count > 2 ? components[2] : "",
                        "Group": components.count > 3 ? components[3] : ""
                    ],
                    compressionMethod: "TAR",
                    crc: nil,
                    modificationDate: parseTarDate(components: components)
                )
                
                items.append(item)
            }
        }
        
        NSLog("🔍 TAR parsing terminé - \(items.count) éléments trouvés")
        for item in items {
            NSLog("📁 TAR item: \(item.path) (isDir: \(item.isDirectory))")
        }
        
        return items
    }
    
    private func parseDmgInfo(from output: String, url: URL) -> ArchiveInfo {
        // Parsing simplifié pour DMG
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: 0,
            compressedSize: 0,
            isEncrypted: false
        )
    }
    
    private func parseDmgContents(from output: String, currentPath: String, mountPoint: String) -> [ArchiveItem] {
        let lines = output.components(separatedBy: .newlines)
        var items: [ArchiveItem] = []
        
        for line in lines {
            if line.hasPrefix(mountPoint) {
                let relativePath = String(line.dropFirst(mountPoint.count + 1))
                if !relativePath.isEmpty {
                    let isDirectory = line.hasSuffix("/")
                    let name = URL(fileURLWithPath: relativePath).lastPathComponent
                    
                    items.append(ArchiveItem(
                        name: name,
                        path: relativePath,
                        size: 0,
                        compressedSize: 0,
                        isDirectory: isDirectory,
                        attributes: [:],
                        compressionMethod: "DMG",
                        crc: nil,
                        modificationDate: nil
                    ))
                }
            }
        }
        
        return items
    }
    
    // MARK: - TAR.GZ Support
    private func openTarGzArchive(at url: URL) async throws -> ArchiveInfo {
        let items = try await listTarGzContents(of: url, path: "/")
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: items.count,
            compressedSize: 0, // TAR.GZ ne donne pas facilement la taille compressée
            isEncrypted: false
        )
    }
    
    private func listTarGzContents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-tvf", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        NSLog("🔍 Commande TAR.GZ: tar -tvf \(url.path)")
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            NSLog("❌ Erreur TAR.GZ: code \(process.terminationStatus)")
            throw ArchiveError.listFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        NSLog("🔍 Sortie TAR.GZ: \(output.prefix(200))...")
        
        return parseTarContents(from: output, currentPath: path)
    }
    
    private func extractTarGzArchive(at url: URL, to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xf", url.path, "-C", destination.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    private func extractTarGzFiles(from url: URL, files: [String], to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xf", url.path, "-C", destination.path] + files
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    // MARK: - TAR.BZ2 Support
    private func openTarBz2Archive(at url: URL) async throws -> ArchiveInfo {
        let items = try await listTarBz2Contents(of: url, path: "/")
        return ArchiveInfo(
            url: url,
            name: url.lastPathComponent,
            fileCount: items.count,
            compressedSize: 0, // TAR.BZ2 ne donne pas facilement la taille compressée
            isEncrypted: false
        )
    }
    
    private func listTarBz2Contents(of url: URL, path: String) async throws -> [ArchiveItem] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-tvjf", url.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        NSLog("🔍 Commande TAR.BZ2: tar -tvf \(url.path)")
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            NSLog("❌ Erreur TAR.BZ2: code \(process.terminationStatus)")
            throw ArchiveError.listFailed
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        NSLog("🔍 Sortie TAR.BZ2: \(output.prefix(200))...")
        
        return parseTarContents(from: output, currentPath: path)
    }
    
    private func extractTarBz2Archive(at url: URL, to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xjf", url.path, "-C", destination.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    private func extractTarBz2Files(from url: URL, files: [String], to destination: URL) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        process.arguments = ["-xjf", url.path, "-C", destination.path] + files
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            throw ArchiveError.extractionFailed
        }
    }
    
    // MARK: - TAR Date Parsing (utilisé par la fonction parseTarContents ci-dessus)
    
    private func parseTarDate(components: [String]) -> Date {
        // Format TAR: ["Sep", "24", "11:34"] ou ["Sep", "24", "2025"]
        if components.count >= 8 {
            let month = components[5]
            let day = components[6]
            let timeOrYear = components[7]
            
            let formatter = DateFormatter()
            let currentYear = Calendar.current.component(.year, from: Date())
            
            if timeOrYear.contains(":") {
                // Format avec heure (année courante)
                formatter.dateFormat = "MMM d HH:mm"
                let dateString = "\(month) \(day) \(timeOrYear)"
                if let date = formatter.date(from: dateString) {
                    // Ajouter l'année courante
                    let calendar = Calendar.current
                    let components = calendar.dateComponents([.month, .day, .hour, .minute], from: date)
                    return calendar.date(from: DateComponents(year: currentYear, month: components.month, day: components.day, hour: components.hour, minute: components.minute)) ?? Date()
                }
            } else {
                // Format avec année
                formatter.dateFormat = "MMM d yyyy"
                let dateString = "\(month) \(day) \(timeOrYear)"
                return formatter.date(from: dateString) ?? Date()
            }
        }
        
        return Date()
    }
}

