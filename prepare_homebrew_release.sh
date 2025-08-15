#!/bin/bash

# Script to prepare a Homebrew release for Phim
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🍺 Preparing Homebrew release for Phim${NC}"

# Check if version is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a version number${NC}"
    echo "Usage: ./prepare_homebrew_release.sh <version>"
    echo "Example: ./prepare_homebrew_release.sh 0.3.0"
    exit 1
fi

VERSION=$1
ZIP_FILE="Phim-${VERSION}.zip"
RELEASE_DIR="releases"

# Create releases directory if it doesn't exist
mkdir -p "$RELEASE_DIR"

# Build the app
echo -e "${YELLOW}Building Phim...${NC}"
./build_with_spm.sh

# Create ZIP archive for release
echo -e "${YELLOW}Creating ZIP archive...${NC}"
ditto -c -k --sequesterRsrc --keepParent Phim.app "$RELEASE_DIR/$ZIP_FILE"

# Calculate SHA256
echo -e "${YELLOW}Calculating SHA256...${NC}"
SHA256=$(shasum -a 256 "$RELEASE_DIR/$ZIP_FILE" | awk '{print $1}')

# Update the Homebrew formula
echo -e "${YELLOW}Updating Homebrew formula...${NC}"
FORMULA_PATH="homebrew-tap/Casks/phim.rb"

# Use sed to update version and sha256
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed syntax
    sed -i '' "s/version \".*\"/version \"$VERSION\"/" "$FORMULA_PATH"
    sed -i '' "s/sha256 .*/sha256 \"$SHA256\"/" "$FORMULA_PATH"
else
    # GNU sed syntax
    sed -i "s/version \".*\"/version \"$VERSION\"/" "$FORMULA_PATH"
    sed -i "s/sha256 .*/sha256 \"$SHA256\"/" "$FORMULA_PATH"
fi

echo -e "${GREEN}✅ Homebrew release prepared successfully!${NC}"
echo ""
echo "Release details:"
echo "  Version: $VERSION"
echo "  File: $RELEASE_DIR/$ZIP_FILE"
echo "  SHA256: $SHA256"
echo ""
echo "Next steps:"
echo "1. Create a GitHub release with tag v${VERSION}"
echo "2. Upload $RELEASE_DIR/$ZIP_FILE to the release"
echo "3. Commit and push the updated Homebrew formula"
echo "4. Users can install with: brew tap roelvangils/phim && brew install --cask phim"