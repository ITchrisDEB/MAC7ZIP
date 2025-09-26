import Foundation
import SwiftUI

// MARK: - Volume Manager
class VolumeManager: ObservableObject {
    static let shared = VolumeManager()
    
    @Published var volumeSize: VolumeSize = .noSplit
    @Published var customVolumeSize: String = ""
    @Published var volumeUnit: VolumeUnit = .mb
    
    private init() {}
    
    // MARK: - Volume Size Options
    enum VolumeSize: String, CaseIterable, Identifiable {
        case noSplit = "no_split"
        case mb100 = "100m"
        case mb200 = "200m"
        case mb500 = "500m"
        case mb1000 = "1000m"
        case mb2000 = "2000m"
        case mb5000 = "5000m"
        case mb10000 = "10000m"
        case custom = "custom"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .noSplit: return "Aucune division"
            case .mb100: return "100 MB"
            case .mb200: return "200 MB"
            case .mb500: return "500 MB"
            case .mb1000: return "1 GB"
            case .mb2000: return "2 GB"
            case .mb5000: return "5 GB"
            case .mb10000: return "10 GB"
            case .custom: return "Personnalisé"
            }
        }
        
        var sizeInMB: Int {
            switch self {
            case .noSplit: return 0
            case .mb100: return 100
            case .mb200: return 200
            case .mb500: return 500
            case .mb1000: return 1000
            case .mb2000: return 2000
            case .mb5000: return 5000
            case .mb10000: return 10000
            case .custom: return 0
            }
        }
        
        var isCustom: Bool {
            return self == .custom
        }
    }
    
    // MARK: - Volume Unit Options
    enum VolumeUnit: String, CaseIterable, Identifiable {
        case b = "b"
        case kb = "k"
        case mb = "m"
        case gb = "g"
        case tb = "t"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .b: return "Bytes"
            case .kb: return "KB"
            case .mb: return "MB"
            case .gb: return "GB"
            case .tb: return "TB"
            }
        }
        
        var multiplier: Int64 {
            switch self {
            case .b: return 1
            case .kb: return 1024
            case .mb: return 1024 * 1024
            case .gb: return 1024 * 1024 * 1024
            case .tb: return 1024 * 1024 * 1024 * 1024
            }
        }
    }
    
    // MARK: - Volume Size String Generation
    func getVolumeSizeString() -> String? {
        if volumeSize == .noSplit {
            return nil
        } else if volumeSize == .custom {
            if !customVolumeSize.isEmpty {
                return "\(customVolumeSize)\(volumeUnit.rawValue)"
            }
            return nil
        } else {
            return "\(volumeSize.sizeInMB)m"
        }
    }
    
    // MARK: - Volume Size Validation
    func validateCustomVolumeSize() -> Bool {
        if volumeSize == .custom {
            guard let size = Int(customVolumeSize), size > 0 else {
                return false
            }
            return true
        }
        return true
    }
    
    // MARK: - Volume Size Parsing
    static func parseVolumeSize(_ sizeString: String) -> (size: VolumeSize, custom: String, unit: VolumeUnit)? {
        if sizeString.isEmpty {
            return (.noSplit, "", .mb)
        }
        
        // Check if it's a predefined size
        for volumeSize in VolumeSize.allCases {
            if volumeSize.rawValue == sizeString {
                return (volumeSize, "", .mb)
            }
        }
        
        // Parse custom size (e.g., "500m", "1g", "100k")
        let pattern = #"^(\d+)([bkmgt])$"#
        let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: sizeString.count)
        
        if let match = regex?.firstMatch(in: sizeString, options: [], range: range),
           let sizeRange = Range(match.range(at: 1), in: sizeString),
           let unitRange = Range(match.range(at: 2), in: sizeString) {
            
            let size = String(sizeString[sizeRange])
            let unitString = String(sizeString[unitRange]).lowercased()
            
            let unit: VolumeUnit
            switch unitString {
            case "b": unit = .b
            case "k": unit = .kb
            case "m": unit = .mb
            case "g": unit = .gb
            case "t": unit = .tb
            default: return nil
            }
            
            return (.custom, size, unit)
        }
        
        return nil
    }
    
    // MARK: - Volume Size Display
    func getVolumeSizeDisplayString() -> String {
        if volumeSize == .noSplit {
            return "Aucune division"
        } else if volumeSize == .custom {
            if !customVolumeSize.isEmpty {
                return "\(customVolumeSize) \(volumeUnit.displayName)"
            }
            return "Personnalisé"
        } else {
            return volumeSize.displayName
        }
    }
    
    // MARK: - Reset
    func reset() {
        volumeSize = .noSplit
        customVolumeSize = ""
        volumeUnit = .mb
    }
}