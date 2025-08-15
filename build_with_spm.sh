#!/bin/bash

# Alternative build script using Swift Package Manager
# This builds Phim with Sparkle dependency

set -e

echo "Building Phim with Swift Package Manager..."

# Clean previous builds
rm -rf .build/
rm -rf Phim.app

# Build the app using swift build
swift build --configuration release

# Create the app bundle structure
mkdir -p Phim.app/Contents/MacOS
mkdir -p Phim.app/Contents/Resources
mkdir -p Phim.app/Contents/Frameworks

# Copy the executable
cp .build/release/Phim Phim.app/Contents/MacOS/Phim

# Add rpath for Frameworks directory
install_name_tool -add_rpath @executable_path/../Frameworks Phim.app/Contents/MacOS/Phim

# Copy the Info.plist
cp Info.plist Phim.app/Contents/Info.plist

# Copy the icon if it exists
if [ -f "Phim.icns" ]; then
    cp Phim.icns Phim.app/Contents/Resources/Phim.icns
fi

# Copy the welcome.html
if [ -f "PhimSource/welcome.html" ]; then
    cp PhimSource/welcome.html Phim.app/Contents/Resources/welcome.html
fi

# Copy Sparkle framework from SPM artifacts
if [ -d ".build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework" ]; then
    echo "Copying Sparkle framework..."
    cp -R .build/artifacts/sparkle/Sparkle/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework Phim.app/Contents/Frameworks/
    echo "Sparkle framework copied successfully"
else
    echo "Warning: Sparkle framework not found in expected location"
fi

# Sign the app if a developer identity is available
if security find-identity -p codesigning | grep -q "Developer ID Application"; then
    echo "Signing the app..."
    IDENTITY=$(security find-identity -p codesigning | grep "Developer ID Application" | head -1 | awk '{print $2}')
    
    # Sign the Sparkle framework first
    if [ -d "Phim.app/Contents/Frameworks/Sparkle.framework" ]; then
        codesign --force --verify --verbose --sign "$IDENTITY" Phim.app/Contents/Frameworks/Sparkle.framework/Versions/Current/Sparkle
        codesign --force --verify --verbose --sign "$IDENTITY" Phim.app/Contents/Frameworks/Sparkle.framework
    fi
    
    # Then sign the entire app
    codesign --deep --force --verify --verbose --sign "$IDENTITY" --options runtime Phim.app
    echo "App signed with identity: $IDENTITY"
else
    echo "Warning: No Developer ID found. App will not be signed."
fi

echo ""
echo "Build complete!"
echo ""
echo "Phim has been built successfully. You can now:"
echo "1. Run the app directly: open Phim.app"
echo "2. Use from command line: ./phim <URL>"
echo "3. Generate Sparkle keys: ./generate_sparkle_keys.sh"
echo "4. Sign updates: ./sign_update.sh <version> <zip_file>"