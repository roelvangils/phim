# Homebrew Tap for Phim

This is the official Homebrew tap for [Phim](https://github.com/roelvangils/phim), a minimalistic web viewer for macOS.

## Installation

```bash
# Add the tap
brew tap roelvangils/phim

# Install Phim
brew install --cask phim

# If you get a "damaged app" warning (unsigned app), you can either:
# Option 1: Install with quarantine disabled (if you trust the source)
brew install --cask --no-quarantine phim

# Option 2: Remove quarantine after installation
xattr -cr /Applications/Phim.app
```

## Updating

```bash
brew update
brew upgrade --cask phim
```

## Uninstallation

```bash
brew uninstall --cask phim
```

## Requirements

- macOS 15.0 (Sonoma) or later
- Homebrew installed

## Features

Phim includes:
- 🪟 Vibrancy effects that adapt to system appearance
- ⌨️ Keyboard-driven interface
- 🔒 Privacy-focused browsing (non-persistent data)
- 📋 Smart clipboard URL detection
- 📖 Zen Mode for distraction-free reading
- 🔄 Automatic updates via Sparkle

## License

Phim is open source software licensed under the MIT License.