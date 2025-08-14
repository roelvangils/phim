# Phim Distribution Checklist

## Prerequisites
- [ ] Apple Developer Account ($99/year) for code signing
- [ ] Create app icon in all required sizes
- [ ] Write proper README with features and usage
- [ ] Add LICENSE file (MIT or similar)
- [ ] Generate EdDSA keys for Sparkle updates (run `./generate_sparkle_keys.sh`)

## Code Signing & Notarization
```bash
# Sign the app
codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" Phim.app

# Create DMG
create-dmg Phim.app

# Notarize
xcrun altool --notarize-app --primary-bundle-id "com.phim.app" --file Phim.dmg

# Staple the notarization
xcrun stapler staple Phim.dmg
```

## GitHub Release
1. Create repository structure:
   ```
   phim/
   ├── README.md
   ├── LICENSE
   ├── PhimSource/
   ├── releases/
   ├── screenshots/
   ├── appcast.xml         # Sparkle update feed
   ├── generate_sparkle_keys.sh
   └── sign_update.sh
   ```

2. Create release with:
   - Signed & notarized DMG
   - Release notes
   - Installation instructions
   - Updated appcast.xml for Sparkle

## Sparkle Auto-Update Process

### Initial Setup (One Time)
1. Generate EdDSA keys:
   ```bash
   ./generate_sparkle_keys.sh
   ```
2. Add public key to Info.plist under `SUPublicEDKey`
3. Keep private key (`dsa_priv.pem`) secure - NEVER commit it!

### For Each Release
1. Build and sign the app:
   ```bash
   ./build.sh
   codesign --deep --force --verify --verbose --sign "Developer ID Application: Your Name" Phim.app
   ```

2. Create a ZIP archive for Sparkle:
   ```bash
   ditto -c -k --sequesterRsrc --keepParent Phim.app Phim-1.0.1.zip
   ```

3. Sign the update:
   ```bash
   ./sign_update.sh 1.0.1 Phim-1.0.1.zip
   ```

4. Update appcast.xml with the output from sign_update.sh

5. Upload to GitHub Release:
   - Phim-1.0.1.zip (for Sparkle updates)
   - Phim.dmg (for manual downloads)
   - Updated appcast.xml

6. Users will automatically receive updates via Sparkle!

## Homebrew Cask (Optional)
1. Fork homebrew-cask
2. Create `Casks/phim.rb`:
   ```ruby
   cask "phim" do
     version "1.0"
     sha256 "YOUR_SHA"
     url "https://github.com/yourusername/phim/releases/download/v#{version}/Phim.dmg"
     name "Phim"
     desc "Minimalistic web viewer for macOS"
     homepage "https://github.com/yourusername/phim"
     
     app "Phim.app"
   end
   ```

## Marketing Assets
- [ ] App icon in multiple sizes
- [ ] Screenshots showing the minimal UI
- [ ] GIF/video demo of keyboard shortcuts
- [ ] Simple landing page or GitHub Pages site

## Why Not App Store?
- Apps that are "just web browsers" often get rejected
- Minimalistic utilities do better with direct distribution
- Your target audience (developers) prefer GitHub/Homebrew
- No App Store restrictions on functionality
- Faster updates and iterations