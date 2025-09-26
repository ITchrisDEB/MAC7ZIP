#!/bin/bash

# Mac7zip Build Script with Automatic Versioning
# This script compiles the Mac7zip application and creates versioned .app bundles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Mac7zip"
BUILD_DIR="build"
VERSION_FILE="version.txt"
BINARY_DIR="Mac7zip.app/Contents/Resources"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get current version
get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "1.0.0"
    fi
}

# Function to increment version
increment_version() {
    local version=$1
    local major=$(echo $version | cut -d. -f1)
    local minor=$(echo $version | cut -d. -f2)
    local patch=$(echo $version | cut -d. -f3)
    
    # Increment patch version
    patch=$((patch + 1))
    
    echo "$major.$minor.$patch"
}

# Function to create version file
create_version_file() {
    local version=$1
    echo "$version" > "$VERSION_FILE"
    print_status "Version file created: $version"
}

# Function to check if binaries exist
check_binaries() {
    print_status "Checking for required binaries..."
    
    local missing_binaries=()
    
    if [ ! -f "Source/7zz" ]; then
        missing_binaries+=("7zz")
    fi
    
    if [ ! -f "Source/rar" ]; then
        missing_binaries+=("rar")
    fi
    
    if [ ! -f "Source/unrar" ]; then
        missing_binaries+=("unrar")
    fi
    
    
    if [ ${#missing_binaries[@]} -gt 0 ]; then
        print_error "Missing binaries: ${missing_binaries[*]}"
        print_error "Please ensure all required binaries are in the Source/ directory"
        exit 1
    fi
    
    print_success "All required binaries found"
}

# Function to create build directory
create_build_dir() {
    if [ -d "$BUILD_DIR" ]; then
        print_status "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    mkdir -p "$BUILD_DIR"
    print_status "Build directory created: $BUILD_DIR"
}

# Function to compile Swift files
compile_swift() {
    print_status "Compiling Swift files..."
    
    local swift_files=(
        "Mac7zipApp.swift"
        "ContentView.swift"
        "ArchiveEngine.swift"
        "AppleArchiveEngine.swift"
        "ArchiveTreeItem.swift"
        "NewArchiveView.swift"
        "FileListView.swift"
        "ProgressTracker.swift"
        "LogManager.swift"
        "NotificationManager.swift"
        "CompressionMethods.swift"
        "UTTypeExtensions.swift"
        "WindowManager.swift"
        "VolumeManager.swift"
        "AdaptiveAdvancedOptionsView.swift"
        "FileRowView.swift"
        "AboutView.swift"
        "BenchmarkView.swift"
        "ExtractView.swift"
        "AddFilesView.swift"
        "PropertiesView.swift"
        "PreferencesView.swift"
        "AdvancedOptionsView.swift"
        "SecurityOptionsView.swift"
        "CompressionMethodsView.swift"
        "FilterOptionsView.swift"
        "VolumeOptionsView.swift"
        "RarOptionsView.swift"
        "ThemeManager.swift"
        "LocalizationManager.swift"
        "ErrorManager.swift"
        "ArchiveCreationManager.swift"
        "FilterManager.swift"
    )
    
    local existing_files=()
    for file in "${swift_files[@]}"; do
        if [ -f "$file" ]; then
            existing_files+=("$file")
        fi
    done
    
    if [ ${#existing_files[@]} -eq 0 ]; then
        print_error "No Swift files found to compile"
        exit 1
    fi
    
    print_status "Found ${#existing_files[@]} Swift files to compile"
    
    # Compile Swift files
    swiftc -o "$BUILD_DIR/$PROJECT_NAME" \
        -framework SwiftUI \
        -framework AppKit \
        -framework UserNotifications \
        -framework UniformTypeIdentifiers \
        -target arm64-apple-macos12.0 \
        "${existing_files[@]}" || {
        print_error "Swift compilation failed"
        exit 1
    }
    
    print_success "Swift compilation completed"
}

# Function to create app bundle
create_app_bundle() {
    local version=$1
    local app_name="${PROJECT_NAME}_${version}.app"
    local app_path="$BUILD_DIR/$app_name"
    
    print_status "Creating app bundle: $app_name"
    
    # Create app bundle structure
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"
    
    # Copy executable
    cp "$BUILD_DIR/$PROJECT_NAME" "$app_path/Contents/MacOS/"
    
    # Copy binaries
    cp Source/7zz "$app_path/Contents/Resources/"
    cp Source/rar "$app_path/Contents/Resources/"
    cp Source/unrar "$app_path/Contents/Resources/"
    
    # Copy application icon
    if [ -f "Mac7zip.icns" ]; then
        cp Mac7zip.icns "$app_path/Contents/Resources/"
        print_success "Application icon added"
    else
        print_status "No application icon found (Mac7zip.icns)"
    fi
    
    # Copy localization files
    if [ -d "Localizations" ]; then
        cp -r Localizations/* "$app_path/Contents/Resources/"
        print_success "Localization files added"
    else
        print_status "No localization files found (Localizations/)"
    fi
    
    # Make binaries executable
    chmod +x "$app_path/Contents/Resources/"*
    
    # Create Info.plist with ALL supported formats
    cat > "$app_path/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.mac7zip.app</string>
    <key>CFBundleName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$PROJECT_NAME</string>
    <key>CFBundleVersion</key>
    <string>$version</string>
    <key>CFBundleShortVersionString</key>
    <string>$version</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>CFBundleIconFile</key>
    <string>Mac7zip</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSArchitecturePriority</key>
    <array>
        <string>arm64</string>
    </array>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>7-Zip Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>7z</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>ZIP Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>zip</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>RAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Owner</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>rar</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>TAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>tar</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Gzipped TAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>gz</string><string>tgz</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Bzip2 TAR Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>bz2</string><string>tbz2</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>XZ Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>xz</string><string>txz</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>CAB Archive</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>cab</string></array>
        </dict>
        <dict>
            <key>CFBundleTypeName</key>
            <string>ISO Image</string>
            <key>CFBundleTypeRole</key>
            <string>Viewer</string>
            <key>CFBundleTypeExtensions</key>
            <array><string>iso</string></array>
        </dict>
    </array>
    <key>UTExportedTypeDeclarations</key>
    <array>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>org.7zip.7z-archive</string>
            <key>UTTypeDescription</key>
            <string>7-Zip Archive</string>
            <key>UTTypeConformsTo</key>
            <array><string>public.data</string><string>public.archive</string></array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array><string>7z</string></array>
                <key>public.mime-type</key>
                <array><string>application/x-7z-compressed</string></array>
            </dict>
        </dict>
        <dict>
            <key>UTTypeIdentifier</key>
            <string>com.rarlab.rar-archive</string>
            <key>UTTypeDescription</key>
            <string>RAR Archive</string>
            <key>UTTypeConformsTo</key>
            <array><string>public.data</string><string>public.archive</string></array>
            <key>UTTypeTagSpecification</key>
            <dict>
                <key>public.filename-extension</key>
                <array><string>rar</string></array>
                <key>public.mime-type</key>
                <array><string>application/x-rar-compressed</string></array>
            </dict>
        </dict>
    </array>
</dict>
</plist>
EOF
    
    # Create version file in app bundle
    echo "$version" > "$app_path/Contents/Resources/version.txt"
    
    print_success "App bundle created: $app_name"
    print_status "App bundle location: $app_path"
}

# Function to create symlink to latest version
create_latest_symlink() {
    local version=$1
    local app_name="${PROJECT_NAME}_${version}.app"
    local latest_name="${PROJECT_NAME}_latest.app"
    
    cd "$BUILD_DIR"
    if [ -L "$latest_name" ]; then
        rm "$latest_name"
    fi
    ln -s "$app_name" "$latest_name"
    cd ..
    
    print_success "Latest version symlink created: $latest_name"
}

# Function to display build summary
display_summary() {
    local version=$1
    local app_name="${PROJECT_NAME}_${version}.app"
    
    echo
    print_success "Build completed successfully!"
    echo
    echo "Version: $version"
    echo "App bundle: $BUILD_DIR/$app_name"
    echo "Latest symlink: $BUILD_DIR/${PROJECT_NAME}_latest.app"
    echo
    echo "To run the application:"
    echo "  open $BUILD_DIR/$app_name"
    echo
    echo "To install the application:"
    echo "  cp -r $BUILD_DIR/$app_name /Applications/"
    echo
}

# Main build process
main() {
    print_status "Starting Mac7zip build process..."
    
    # Get current version and increment
    local current_version=$(get_current_version)
    local new_version=$(increment_version "$current_version")
    
    print_status "Current version: $current_version"
    print_status "New version: $new_version"
    
    # Check for required binaries
    check_binaries
    
    # Create build directory
    create_build_dir
    
    # Compile Swift files
    compile_swift
    
    # Create app bundle
    create_app_bundle "$new_version"
    
    # Create latest symlink
    create_latest_symlink "$new_version"
    
    # Update version file
    create_version_file "$new_version"
    
    # Display summary
    display_summary "$new_version"
}

# Run main function
main "$@"
