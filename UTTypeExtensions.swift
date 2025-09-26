import Foundation
import UniformTypeIdentifiers

// MARK: - UTType Extensions
extension UTType {
    // Archive types
    static let sevenZip = UTType(filenameExtension: "7z")!
    static let rar = UTType(filenameExtension: "rar")!
    static let bzip2 = UTType(filenameExtension: "bz2")!
    static let gzip = UTType(filenameExtension: "gz")!
    static let tar = UTType(filenameExtension: "tar")!
    static let tarGz = UTType(filenameExtension: "tar.gz")!
    static let tarBz2 = UTType(filenameExtension: "tar.bz2")!
    
    // System types
    static let dmg = UTType(filenameExtension: "dmg")!
    static let iso = UTType(filenameExtension: "iso")!
    static let cab = UTType(filenameExtension: "cab")!
    static let msi = UTType(filenameExtension: "msi")!
    static let wim = UTType(filenameExtension: "wim")!
    static let apfs = UTType(filenameExtension: "apfs")!
    static let udf = UTType(filenameExtension: "udf")!
    
    // macOS types
    static let pkg = UTType(filenameExtension: "pkg")!
    static let xip = UTType(filenameExtension: "xip")!
    static let xar = UTType(filenameExtension: "xar")!
    
    // Virtual machine types
    static let vdi = UTType(filenameExtension: "vdi")!
    static let vhd = UTType(filenameExtension: "vhd")!
    static let vhdx = UTType(filenameExtension: "vhdx")!
    static let vmdk = UTType(filenameExtension: "vmdk")!
    static let qcow = UTType(filenameExtension: "qcow")!
    static let qcow2 = UTType(filenameExtension: "qcow2")!
    
    // Other types
    static let chm = UTType(filenameExtension: "chm")!
    static let arj = UTType(filenameExtension: "arj")!
    static let lzh = UTType(filenameExtension: "lzh")!
    static let rpm = UTType(filenameExtension: "rpm")!
    static let deb = UTType(filenameExtension: "deb")!
    static let apk = UTType(filenameExtension: "apk")!
    static let jar = UTType(filenameExtension: "jar")!
    static let flv = UTType(filenameExtension: "flv")!
    static let swf = UTType(filenameExtension: "swf")!
    
    // Generic archive type
    static let archive = UTType(filenameExtension: "archive")!
}

// MARK: - Archive Format Detection
extension UTType {
    static func archiveTypes() -> [UTType] {
        return [
            .sevenZip, .zip, .rar, .bzip2, .gzip, .tar,
            .tarGz, .tarBz2, .dmg, .iso, .cab, .msi,
            .wim, .apfs, .udf, .pkg, .xip, .xar, .vdi, .vhd, .vhdx,
            .vmdk, .qcow, .qcow2, .chm, .arj, .lzh, .rpm, .deb, .apk, .jar
        ]
    }
    
    static func isArchiveType(_ type: UTType) -> Bool {
        return archiveTypes().contains(type)
    }
    
    static func archiveType(for url: URL) -> UTType? {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "7z": return .sevenZip
        case "zip": return .zip
        case "rar": return .rar
        case "bz2": return .bzip2
        case "gz": return .gzip
        case "tar": return .tar
        case "tar.gz": return .tarGz
        case "tar.bz2": return .tarBz2
        case "dmg": return .dmg
        case "iso": return .iso
        case "cab": return .cab
        case "msi": return .msi
        case "wim": return .wim
        case "apfs": return .apfs
        case "udf": return .udf
        case "pkg": return .pkg
        case "xip": return .xip
        case "xar": return .xar
        case "vdi": return .vdi
        case "vhd": return .vhd
        case "vhdx": return .vhdx
        case "vmdk": return .vmdk
        case "qcow": return .qcow
        case "qcow2": return .qcow2
        case "chm": return .chm
        case "arj": return .arj
        case "lzh": return .lzh
        case "rpm": return .rpm
        case "deb": return .deb
        case "apk": return .apk
        case "jar": return .jar
        case "flv": return .flv
        case "swf": return .swf
        default: return nil
        }
    }
}

// MARK: - Archive Format Mapping
extension ArchiveFormat {
    var utType: UTType {
        switch self {
        case .sevenZip: return .sevenZip
        case .zip: return .zip
        case .rar: return .rar
        case .tar: return .tar
        case .gzip: return .tarGz
        case .bzip2: return .tarBz2
        }
    }
    
    static func from(utType: UTType) -> ArchiveFormat? {
        switch utType {
        case .sevenZip: return .sevenZip
        case .zip: return .zip
        case .rar: return .rar
        case .tar: return .tar
        case .tarGz: return .gzip
        case .tarBz2: return .bzip2
        default: return nil
        }
    }
}