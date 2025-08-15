#!/bin/bash

# Sign a Phim update for Sparkle
# Usage: ./sign_update.sh <version> <zip_file>

VERSION=$1
ZIP_FILE=$2

if [ -z "$VERSION" ] || [ -z "$ZIP_FILE" ]; then
    echo "Usage: $0 <version> <zip_file>"
    echo "Example: $0 1.0.1 Phim-1.0.1.zip"
    exit 1
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "Error: ZIP file '$ZIP_FILE' not found"
    exit 1
fi

if [ ! -f "dsa_priv.pem" ]; then
    echo "Error: Private key 'dsa_priv.pem' not found"
    echo "Run ./generate_sparkle_keys.sh first to generate keys"
    exit 1
fi

# Check for Sparkle tools in Homebrew location first
SPARKLE_BIN="/opt/homebrew/Caskroom/sparkle/2.7.1/bin"
if [ -f "$SPARKLE_BIN/sign_update" ]; then
    SIGN_UPDATE="$SPARKLE_BIN/sign_update"
elif command -v sign_update &> /dev/null; then
    SIGN_UPDATE="sign_update"
else
    echo "Error: Sparkle's sign_update tool is not found."
    echo "Install Sparkle tools first (see generate_sparkle_keys.sh for instructions)"
    exit 1
fi

echo "Signing $ZIP_FILE for version $VERSION..."

# Generate the signature
SIGNATURE=$("$SIGN_UPDATE" "$ZIP_FILE" dsa_priv.pem)

if [ $? -ne 0 ]; then
    echo "Error: Failed to sign the update"
    exit 1
fi

# Get file size
FILE_SIZE=$(stat -f%z "$ZIP_FILE" 2>/dev/null || stat -c%s "$ZIP_FILE" 2>/dev/null)

echo ""
echo "=================================="
echo "Update signed successfully!"
echo "=================================="
echo ""
echo "Add this to your appcast.xml:"
echo ""
cat << EOF
<item>
    <title>Version $VERSION</title>
    <description><![CDATA[
        <h2>What's New in Version $VERSION</h2>
        <ul>
            <li>Add your release notes here</li>
        </ul>
    ]]></description>
    <pubDate>$(date -R)</pubDate>
    <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
    <enclosure 
        url="https://github.com/yourusername/phim/releases/download/v$VERSION/$ZIP_FILE" 
        sparkle:version="$(echo $VERSION | sed 's/\.//g')"
        sparkle:shortVersionString="$VERSION"
        sparkle:edSignature="$SIGNATURE"
        length="$FILE_SIZE"
        type="application/octet-stream" />
</item>
EOF

echo ""
echo "Remember to:"
echo "1. Update the release notes in the description"
echo "2. Upload $ZIP_FILE to GitHub releases"
echo "3. Update appcast.xml with the above XML"
echo "4. Upload the updated appcast.xml"