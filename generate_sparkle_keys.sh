#!/bin/bash

# Generate EdDSA keys for Sparkle update signing
# This script requires Sparkle's generate_keys tool

echo "Generating EdDSA keys for Sparkle..."
echo "=================================="
echo ""

# Check for Sparkle tools in Homebrew location first
SPARKLE_BIN="/opt/homebrew/Caskroom/sparkle/2.7.1/bin"
if [ -f "$SPARKLE_BIN/generate_keys" ]; then
    GENERATE_KEYS="$SPARKLE_BIN/generate_keys"
elif command -v generate_keys &> /dev/null; then
    GENERATE_KEYS="generate_keys"
else
    echo "Error: Sparkle's generate_keys tool is not found."
    echo ""
    echo "To install Sparkle tools:"
    echo "1. If you have Homebrew:"
    echo "   brew install --cask sparkle"
    echo ""
    echo "2. Or download Sparkle from: https://github.com/sparkle-project/Sparkle/releases"
    echo "   Extract and find the 'generate_keys' tool in the bin/ directory"
    echo "   Copy it to /usr/local/bin/ or add to PATH"
    echo ""
    exit 1
fi

# Generate the keys
echo "Generating new EdDSA key pair..."
"$GENERATE_KEYS"

echo ""
echo "=================================="
echo "IMPORTANT: Key Storage Instructions"
echo "=================================="
echo ""
echo "1. PRIVATE KEY (dsa_priv.pem):"
echo "   - Store this file SECURELY - never commit to repository"
echo "   - Keep it in a safe location (password manager, encrypted drive)"
echo "   - You'll need this to sign updates"
echo ""
echo "2. PUBLIC KEY:"
echo "   - Copy the public key shown above"
echo "   - Add it to Info.plist under the SUPublicEDKey key"
echo "   - This key can be safely committed to the repository"
echo ""
echo "3. Update Info.plist:"
echo "   Replace 'YOUR_EDDSA_PUBLIC_KEY_HERE' with the public key"
echo ""
echo "4. Sign your updates:"
echo "   Use the sign_update tool with your private key when releasing"
echo ""

# Create a .gitignore entry for the private key
if [ -f "dsa_priv.pem" ]; then
    echo "# Sparkle private key - NEVER commit this!" >> .gitignore
    echo "dsa_priv.pem" >> .gitignore
    echo "Added dsa_priv.pem to .gitignore"
fi