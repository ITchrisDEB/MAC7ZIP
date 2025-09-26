import Foundation

// MARK: - Compression Method
struct CompressionMethod: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let isAvailable: Bool
    let supportsEncryption: Bool
    let supportsSolid: Bool
    let supportsMultithreading: Bool
    let defaultLevel: Int
    let maxLevel: Int
    let minLevel: Int
    
    static let allMethods: [CompressionMethod] = [
        // 7-Zip methods - SEULEMENT LES 6 STANDARD
        CompressionMethod(
            id: "LZMA2",
            name: "LZMA2",
            description: "Méthode de compression moderne et rapide (recommandée)",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: true,
            defaultLevel: 5,
            maxLevel: 9,
            minLevel: 0
        ),
        CompressionMethod(
            id: "LZMA",
            name: "LZMA",
            description: "Méthode de compression LZMA classique",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 5,
            maxLevel: 9,
            minLevel: 0
        ),
        CompressionMethod(
            id: "PPMd",
            name: "PPMd",
            description: "Méthode de compression PPMd (bonne pour le texte)",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 6,
            maxLevel: 16,
            minLevel: 0
        ),
        CompressionMethod(
            id: "BZip2",
            name: "BZip2",
            description: "Méthode de compression BZip2 (bonne compression)",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: true,
            defaultLevel: 5,
            maxLevel: 9,
            minLevel: 1
        ),
        CompressionMethod(
            id: "Deflate",
            name: "Deflate",
            description: "Méthode de compression Deflate (compatible ZIP)",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: false,
            supportsMultithreading: true,
            defaultLevel: 5,
            maxLevel: 9,
            minLevel: 0
        ),
        CompressionMethod(
            id: "Copy",
            name: "Copy",
            description: "Aucune compression (copie simple)",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: false,
            supportsMultithreading: false,
            defaultLevel: 0,
            maxLevel: 0,
            minLevel: 0
        ),
        // RAR methods
        CompressionMethod(
            id: "RAR Store",
            name: "RAR Store",
            description: "Aucune compression RAR",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 0,
            maxLevel: 0,
            minLevel: 0
        ),
        CompressionMethod(
            id: "RAR Fastest",
            name: "RAR Fastest",
            description: "Compression RAR la plus rapide",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 1,
            maxLevel: 1,
            minLevel: 1
        ),
        CompressionMethod(
            id: "RAR Fast",
            name: "RAR Fast",
            description: "Compression RAR rapide",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 2,
            maxLevel: 2,
            minLevel: 2
        ),
        CompressionMethod(
            id: "RAR Normal",
            name: "RAR Normal",
            description: "Compression RAR normale",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 3,
            maxLevel: 3,
            minLevel: 3
        ),
        CompressionMethod(
            id: "RAR Good",
            name: "RAR Good",
            description: "Compression RAR avancée",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 4,
            maxLevel: 4,
            minLevel: 4
        ),
        CompressionMethod(
            id: "RAR Best",
            name: "RAR Best",
            description: "Compression RAR maximale",
            isAvailable: true,
            supportsEncryption: true,
            supportsSolid: true,
            supportsMultithreading: false,
            defaultLevel: 5,
            maxLevel: 5,
            minLevel: 5
        ),
        // GZip methods
        CompressionMethod(
            id: "GZip",
            name: "GZip",
            description: "Méthode de compression GZip",
            isAvailable: true,
            supportsEncryption: false,
            supportsSolid: false,
            supportsMultithreading: true,
            defaultLevel: 6,
            maxLevel: 9,
            minLevel: 1
        )
    ]
    
    // MARK: - Helper Methods
    static func method(named name: String) -> CompressionMethod? {
        return allMethods.first { $0.name == name }
    }
    
    static func availableMethods() -> [CompressionMethod] {
        return allMethods.filter { $0.isAvailable }
    }
    
    static func defaultMethodForFormat(_ format: ArchiveFormat) -> CompressionMethod {
        switch format {
        case .sevenZip:
            return CompressionMethod.method(named: "LZMA2") ?? methodsForFormat(format).first!
        case .zip:
            return CompressionMethod.method(named: "Deflate") ?? methodsForFormat(format).first!
        case .rar:
            return CompressionMethod.method(named: "RAR Normal") ?? methodsForFormat(format).first!
        case .tar:
            return CompressionMethod.method(named: "Copy") ?? methodsForFormat(format).first!
        case .gzip:
            return CompressionMethod.method(named: "GZip") ?? methodsForFormat(format).first!
        case .bzip2:
            return CompressionMethod.method(named: "BZip2") ?? methodsForFormat(format).first!
        }
    }
    
    static func methodsForFormat(_ format: ArchiveFormat) -> [CompressionMethod] {
        switch format {
        case .sevenZip:
            // SEULEMENT LES 6 MÉTHODES STANDARD 7Z
            return availableMethods().filter { 
                ["LZMA2", "LZMA", "PPMd", "BZip2", "Deflate", "Copy"].contains($0.name) 
            }
        case .zip:
            return availableMethods().filter { ["Deflate", "Copy", "BZip2"].contains($0.name) }
        case .rar:
            return [
                CompressionMethod(
                    id: "RAR Store",
                    name: "RAR Store",
                    description: "Aucune compression",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 0,
                    maxLevel: 0,
                    minLevel: 0
                ),
                CompressionMethod(
                    id: "RAR Fastest",
                    name: "RAR Fastest",
                    description: "Compression la plus rapide",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 1,
                    maxLevel: 1,
                    minLevel: 1
                ),
                CompressionMethod(
                    id: "RAR Fast",
                    name: "RAR Fast",
                    description: "Compression rapide",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 2,
                    maxLevel: 2,
                    minLevel: 2
                ),
                CompressionMethod(
                    id: "RAR Normal",
                    name: "RAR Normal",
                    description: "Compression normale",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 3,
                    maxLevel: 3,
                    minLevel: 3
                ),
                CompressionMethod(
                    id: "RAR Good",
                    name: "RAR Good",
                    description: "Compression avancée",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 4,
                    maxLevel: 4,
                    minLevel: 4
                ),
                CompressionMethod(
                    id: "RAR Best",
                    name: "RAR Best",
                    description: "Compression maximale",
                    isAvailable: true,
                    supportsEncryption: true,
                    supportsSolid: true,
                    supportsMultithreading: false,
                    defaultLevel: 5,
                    maxLevel: 5,
                    minLevel: 5
                )
            ]
        case .gzip:
            return availableMethods().filter { ["GZip"].contains($0.name) }
        case .bzip2:
            return availableMethods().filter { ["BZip2"].contains($0.name) }
        case .tar:
            return [
                CompressionMethod(
                    id: "Copy",
                    name: "Copy",
                    description: "Aucune compression (TAR)",
                    isAvailable: true,
                    supportsEncryption: false,
                    supportsSolid: false,
                    supportsMultithreading: false,
                    defaultLevel: 0,
                    maxLevel: 0,
                    minLevel: 0
                )
            ]
        }
    }
}