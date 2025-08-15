#!/bin/bash

# Generate DMG background from HTML using Chrome headless
# This is more reliable than webkit2png and doesn't require Python

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HTML_FILE="${SCRIPT_DIR}/dmg-background.html"
OUTPUT_FILE="${SCRIPT_DIR}/dmg-background.png"

# Check if Chrome is installed
if [ ! -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]; then
    echo "Error: Google Chrome is not installed"
    echo "Please install Chrome or use the existing PNG file"
    exit 1
fi

echo "Generating DMG background from HTML..."

# Generate PNG with Chrome headless
# --force-device-scale-factor=2 creates a retina-quality image
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --headless \
    --disable-gpu \
    --screenshot="${OUTPUT_FILE}" \
    --window-size=600,400 \
    --force-device-scale-factor=2 \
    "file://${HTML_FILE}" 2>/dev/null

echo "✅ Generated ${OUTPUT_FILE}"
echo ""
echo "To preview the HTML design, open:"
echo "  open ${HTML_FILE}"
echo ""
echo "The generated image is used by ../scripts/create_dmg.sh"