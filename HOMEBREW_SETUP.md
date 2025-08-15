# Homebrew Distribution Setup

This document explains how to set up and maintain Homebrew distribution for Phim.

## Setting Up the Homebrew Tap

A Homebrew tap is a separate Git repository that contains your formula. For Phim, you'll need to create a new repository called `homebrew-phim`.

### 1. Create the Tap Repository

1. Create a new GitHub repository named `homebrew-phim`
2. Clone it locally:
   ```bash
   git clone https://github.com/roelvangils/homebrew-phim.git
   cd homebrew-phim
   ```

3. Copy the tap files from this repository:
   ```bash
   cp -R /path/to/phim/homebrew-tap/* .
   ```

4. Commit and push:
   ```bash
   git add .
   git commit -m "Initial Homebrew tap for Phim"
   git push origin main
   ```

### 2. Releasing a New Version

When you want to release a new version of Phim:

1. Update the version in `Phim.app/Contents/Info.plist`
2. Build and prepare the release:
   ```bash
   ./prepare_homebrew_release.sh 0.3.0  # Replace with your version
   ```

3. Create a GitHub release:
   - Go to https://github.com/roelvangils/phim/releases/new
   - Create a new tag (e.g., `v0.3.0`)
   - Upload the `releases/Phim-0.3.0.zip` file
   - Publish the release

4. Update the tap repository:
   - The `prepare_homebrew_release.sh` script has already updated the formula
   - Push the changes to your tap repository:
     ```bash
     cd homebrew-tap
     git add Casks/phim.rb
     git commit -m "Update Phim to version 0.3.0"
     git push origin main
     ```

### 3. Testing the Installation

Test that your tap works correctly:

```bash
# Remove any existing installation
brew uninstall --cask phim 2>/dev/null
brew untap roelvangils/phim 2>/dev/null

# Add your tap and install
brew tap roelvangils/phim
brew install --cask phim

# Verify it works
phim https://example.com
```

## File Structure

Your repositories should be organized as follows:

```
github.com/roelvangils/
├── phim/                    # Main application repository
│   ├── PhimSource/         # Swift source code
│   ├── Phim.app/           # Built application
│   ├── releases/           # Release artifacts
│   │   └── Phim-X.Y.Z.zip  # Zipped app for distribution
│   └── prepare_homebrew_release.sh
│
└── homebrew-phim/          # Homebrew tap repository
    ├── README.md
    └── Casks/
        └── phim.rb         # Homebrew formula
```

## Homebrew Formula Details

The formula (`Casks/phim.rb`) contains:
- **version**: The current version number
- **sha256**: SHA-256 hash of the release ZIP file
- **url**: Direct link to the GitHub release asset
- **dependencies**: macOS version requirements
- **auto_updates**: Enabled for Sparkle updates

## User Installation Instructions

Users can install Phim via Homebrew with:

```bash
# First time installation
brew tap roelvangils/phim
brew install --cask phim

# Updating
brew update
brew upgrade --cask phim

# Uninstalling
brew uninstall --cask phim
```

## Troubleshooting

### Formula Validation
Before pushing, validate your formula:
```bash
brew audit --strict --online phim
```

### Common Issues

1. **SHA256 mismatch**: Make sure you're using the correct hash from the actual release file
2. **URL not found**: Ensure the GitHub release is published and the asset is uploaded
3. **Tap not found**: Check that the repository name is exactly `homebrew-phim`

## Benefits of Homebrew Distribution

- ✅ Easy installation for users
- ✅ Automatic dependency management
- ✅ Simple updates via `brew upgrade`
- ✅ Works alongside Sparkle auto-updates
- ✅ Professional distribution method
- ✅ Integration with other Homebrew tools

## Next Steps

1. Create the `homebrew-phim` repository on GitHub
2. Set up the initial tap structure
3. Create your first release
4. Test the installation process
5. Add the Homebrew badge to your README