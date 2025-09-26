// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mac7zip",
    defaultLocalization: "fr",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Mac7zip",
            targets: ["Mac7zip"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Mac7zip",
            dependencies: [],
            path: ".",
            sources: [
                "Mac7zipApp.swift",
                "ContentView.swift",
                "ArchiveEngine.swift",
                "AppleArchiveEngine.swift",
                "AboutView.swift",
                "AddFilesView.swift",
                "AdvancedOptionsView.swift",
                "AdaptiveAdvancedOptionsView.swift",
                "ArchiveTreeItem.swift",
                "BenchmarkView.swift",
                "CompressionMethods.swift",
                "CompressionMethodsView.swift",
                "ErrorManager.swift",
                "ExtractView.swift",
                "FileListView.swift",
                "FileRowView.swift",
                "FilterManager.swift",
                "FilterOptionsView.swift",
                "FormatOptions.swift",
                "LocalizationManager.swift",
                "LogManager.swift",
                "NewArchiveView.swift",
                "NotificationManager.swift",
                "PreferencesView.swift",
                "ProgressTracker.swift",
                "PropertiesView.swift",
                "RarOptionsView.swift",
                "SecurityOptionsView.swift",
                "ThemeManager.swift",
                "UTTypeExtensions.swift",
                "VolumeManager.swift",
                "VolumeOptionsView.swift",
                "WindowManager.swift"
            ],
            resources: [
                .process("Mac7zip.app/Contents/Resources"),
                .process("Localizations")
            ]
        )
    ]
)
