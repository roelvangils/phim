#!/bin/bash

# Complete release preparation script for Phim
# Creates both Homebrew ZIP and user-friendly DMG

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}🚀 Preparing Phim Release${NC}"
echo ""

# Check if version is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a version number${NC}"
    echo "Usage: ./prepare_release.sh <version>"
    echo "Example: ./prepare_release.sh 0.3.1"
    exit 1
fi

VERSION=$1
ZIP_FILE="Phim-${VERSION}.zip"
DMG_FILE="Phim-${VERSION}.dmg"
RELEASE_DIR="releases"

echo -e "${BLUE}📦 Preparing release v${VERSION}${NC}"
echo ""

# Create releases directory
mkdir -p "$RELEASE_DIR"

# Step 1: Build the app
echo -e "${YELLOW}1. Building Phim...${NC}"
scripts/build_with_spm.sh

# Step 2: Create ZIP for Homebrew
echo -e "${YELLOW}2. Creating ZIP archive for Homebrew...${NC}"
ditto -c -k --sequesterRsrc --keepParent Phim.app "$RELEASE_DIR/$ZIP_FILE"

# Calculate SHA256 for Homebrew
SHA256=$(shasum -a 256 "$RELEASE_DIR/$ZIP_FILE" | awk '{print $1}')

# Step 3: Create DMG for direct download
echo -e "${YELLOW}3. Creating DMG installer...${NC}"
scripts/create_dmg.sh
mv "$DMG_FILE" "$RELEASE_DIR/"

# Step 4: Update Homebrew formula
echo -e "${YELLOW}4. Updating Homebrew formula...${NC}"
FORMULA_PATH="homebrew-tap/Casks/phim.rb"

if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$FORMULA_PATH"
    sed -i '' "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_PATH"
else
    sed -i "s/version \".*\"/version \"$VERSION\"/" "$FORMULA_PATH"
    sed -i "s/sha256 \".*\"/sha256 \"$SHA256\"/" "$FORMULA_PATH"
fi

# Step 5: Update Info.plist version
echo -e "${YELLOW}5. Updating Info.plist version...${NC}"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" Phim.app/Contents/Info.plist
BUILD_NUMBER=$(echo $VERSION | sed 's/\.//g')
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER}" Phim.app/Contents/Info.plist

# Get file sizes
ZIP_SIZE=$(du -h "$RELEASE_DIR/$ZIP_FILE" | cut -f1)
DMG_SIZE=$(du -h "$RELEASE_DIR/$DMG_FILE" | cut -f1)

# Print summary
echo ""
echo -e "${GREEN}✅ Release v${VERSION} prepared successfully!${NC}"
echo ""
echo "📊 Release Summary:"
echo "  • Version: ${VERSION}"
echo "  • ZIP: $RELEASE_DIR/$ZIP_FILE ($ZIP_SIZE)"
echo "  • DMG: $RELEASE_DIR/$DMG_FILE ($DMG_SIZE)"
echo "  • SHA256: $SHA256"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Commit changes:"
echo -e "   ${BLUE}git add -A && git commit -m \"Prepare release v${VERSION}\"${NC}"
echo ""
echo "2. Create GitHub release:"
echo -e "   ${BLUE}gh release create v${VERSION} \\
      $RELEASE_DIR/$ZIP_FILE \\
      $RELEASE_DIR/$DMG_FILE \\
      --title \"Phim v${VERSION}\" \\
      --notes \"Download the DMG for easy installation or ZIP for manual installation.\"${NC}"
echo ""
echo "3. Update Homebrew tap:"
echo -e "   ${BLUE}cd homebrew-tap && git add -A && git commit -m \"Update to v${VERSION}\" && git push${NC}"
echo ""
echo "4. Users can install via:"
echo "   • Homebrew: brew tap roelvangils/phim && brew install --cask phim"
echo "   • DMG: Download and drag to Applications"
echo "   • ZIP: Download and extract to Applications"