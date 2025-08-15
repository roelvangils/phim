#!/bin/bash

# Build script for Phim app
# This script builds the Phim app from the command line

set -e

echo "Building Phim..."

# Navigate to the project directory
cd "$(dirname "$0")/Phim"

# Clean previous builds
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/Phim-*

# Build the app using xcodebuild
xcodebuild -project Phim.xcodeproj \
           -scheme Phim \
           -configuration Release \
           -derivedDataPath build \
           clean build

# Find the built app
APP_PATH=$(find build -name "Phim.app" -type d | head -n 1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app"
    exit 1
fi

# Copy the app to the current directory
cp -R "$APP_PATH" ../Phim.app

# Create a wrapper script for command-line usage
cat > ../phim << 'EOF'
#!/bin/bash
# Wrapper script to run Phim from command line

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="$SCRIPT_DIR/Phim.app"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: Phim.app not found. Please run build.sh first."
    exit 1
fi

# Check if input is being piped
if [ ! -t 0 ]; then
    # Read from stdin and pass to app
    URL=$(cat)
    open -n "$APP_PATH" --args "$URL"
elif [ $# -gt 0 ]; then
    # Pass command line argument
    open -n "$APP_PATH" --args "$1"
else
    # Open with default blank page
    open -n "$APP_PATH"
fi
EOF

chmod +x ../phim

echo "Build complete!"
echo ""
echo "Phim has been built successfully. You can now:"
echo "1. Run the app directly: open Phim.app"
echo "2. Use from command line: ./phim <URL>"
echo "3. Pipe URLs to it: echo 'https://example.com' | ./phim"
echo "4. Open local files: ./phim /path/to/file.html"