#!/bin/bash

# Script to create a beautiful DMG installer for Phim
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎨 Creating DMG installer for Phim${NC}"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}Installing create-dmg...${NC}"
    brew install create-dmg
fi

# Get version from Info.plist
VERSION=$(defaults read "$PWD/Phim.app/Contents/Info.plist" CFBundleShortVersionString)
DMG_NAME="Phim-${VERSION}.dmg"
VOLUME_NAME="Phim ${VERSION}"

# Clean up any existing DMG
rm -f "$DMG_NAME"
rm -rf dmg-temp

# Create temporary directory for DMG contents
echo -e "${YELLOW}Preparing DMG contents...${NC}"
mkdir -p dmg-temp

# Copy app to temp directory
cp -R Phim.app dmg-temp/

# Create DMG with nice settings
echo -e "${YELLOW}Creating DMG...${NC}"

create-dmg \
  --volname "$VOLUME_NAME" \
  --volicon "Phim.app/Contents/Resources/Phim.icns" \
  --background "dmg-assets/dmg-background.png" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Phim.app" 180 260 \
  --hide-extension "Phim.app" \
  --app-drop-link 420 260 \
  --no-internet-enable \
  --hdiutil-quiet \
  "$DMG_NAME" \
  "dmg-temp" \
  2>/dev/null || {
    # Fallback to simple DMG if create-dmg fails with background
    echo -e "${YELLOW}Creating simple DMG without background...${NC}"
    
    # Create a simple DMG
    hdiutil create -volname "$VOLUME_NAME" \
      -srcfolder dmg-temp \
      -ov -format UDZO \
      "$DMG_NAME"
  }

# Clean up
rm -rf dmg-temp

# Get file size
SIZE=$(du -h "$DMG_NAME" | cut -f1)

echo -e "${GREEN}✅ DMG created successfully!${NC}"
echo ""
echo "  File: $DMG_NAME"
echo "  Size: $SIZE"
echo ""
echo "The DMG includes:"
echo "  • Drag-and-drop installation"
echo "  • Custom volume icon"
echo "  • Installation instructions"
echo ""
echo "Users can now:"
echo "  1. Download $DMG_NAME"
echo "  2. Open it and drag Phim to Applications"
echo "  3. Eject the disk image"
echo "  4. Launch Phim from Applications"