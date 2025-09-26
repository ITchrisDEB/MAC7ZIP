import Foundation

// MARK: - Format Options Protocol
protocol FormatOptions {
    var compressionMethods: [CompressionMethod] { get }
    var supportsEncryption: Bool { get }
    var supportsSolid: Bool { get }
    var supportsMultithreading: Bool { get }
    var supportsVolumes: Bool { get }
    var supportsSFX: Bool { get }
    var supportsAdvancedOptions: Bool { get }
    var defaultCompressionLevel: Int { get }
    var maxCompressionLevel: Int { get }
    var minCompressionLevel: Int { get }
}

// MARK: - SevenZip Format Options
struct SevenZipFormatOptions: FormatOptions {
    var compressionMethods: [CompressionMethod] {
        return CompressionMethod.methodsForFormat(.sevenZip)
    }
    
    var supportsEncryption: Bool { true }
    var supportsSolid: Bool { true }
    var supportsMultithreading: Bool { true }
    var supportsVolumes: Bool { true }
    var supportsSFX: Bool { true }
    var supportsAdvancedOptions: Bool { true }
    var defaultCompressionLevel: Int { 5 }
    var maxCompressionLevel: Int { 9 }
    var minCompressionLevel: Int { 0 }
}

// MARK: - RAR Format Options
struct RarFormatOptions: FormatOptions {
    var compressionMethods: [CompressionMethod] {
        return CompressionMethod.methodsForFormat(.rar)
    }
    
    var supportsEncryption: Bool { true }
    var supportsSolid: Bool { true }
    var supportsMultithreading: Bool { false }
    var supportsVolumes: Bool { true }
    var supportsSFX: Bool { true }
    var supportsAdvancedOptions: Bool { true }
    var defaultCompressionLevel: Int { 3 }
    var maxCompressionLevel: Int { 5 }
    var minCompressionLevel: Int { 0 }
}


// MARK: - ZIP Format Options
struct ZipFormatOptions: FormatOptions {
    var compressionMethods: [CompressionMethod] {
        return CompressionMethod.methodsForFormat(.zip)
    }
    
    var supportsEncryption: Bool { true }
    var supportsSolid: Bool { false }
    var supportsMultithreading: Bool { true }
    var supportsVolumes: Bool { false }
    var supportsSFX: Bool { false }
    var supportsAdvancedOptions: Bool { false }
    var defaultCompressionLevel: Int { 5 }
    var maxCompressionLevel: Int { 9 }
    var minCompressionLevel: Int { 0 }
}

// MARK: - TAR Format Options
struct TarFormatOptions: FormatOptions {
    var compressionMethods: [CompressionMethod] {
        return CompressionMethod.methodsForFormat(.tar)
    }
    
    var supportsEncryption: Bool { false }
    var supportsSolid: Bool { false }
    var supportsMultithreading: Bool { false }
    var supportsVolumes: Bool { false }
    var supportsSFX: Bool { false }
    var supportsAdvancedOptions: Bool { false }
    var defaultCompressionLevel: Int { 0 }
    var maxCompressionLevel: Int { 0 }
    var minCompressionLevel: Int { 0 }
}

// MARK: - Format Options Factory
class FormatOptionsFactory {
    static func getOptions(for format: ArchiveFormat) -> FormatOptions {
        switch format {
        case .sevenZip:
            return SevenZipFormatOptions()
        case .rar:
            return RarFormatOptions()
        case .zip:
            return ZipFormatOptions()
        case .tar, .gzip, .bzip2:
            return TarFormatOptions()
        }
    }
}
