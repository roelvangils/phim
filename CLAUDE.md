# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Phim is a minimalistic macOS web viewer application built with Swift and SwiftUI, designed for focused reading with native macOS integration. It features intelligent vibrancy effects, clipboard monitoring, and privacy-focused browsing.

## Build and Run Commands

```bash
# Build the application
./build.sh

# Run from command line
./phim https://example.com
./phim /path/to/file.html

# Pipe URLs
echo "https://example.com" | ./phim
```

## Architecture

### Core Components

1. **PhimApp.swift** - Main app entry point handling:
   - Window configuration with borderless vibrancy
   - Clipboard monitoring for automatic URL loading
   - File opening support via "Open With"
   - Menu customization

2. **ContentView.swift** - UI container managing:
   - Floating toolbar with hover appearance
   - Keyboard shortcuts (O, R, C, X)
   - Loading animations
   - Fixed window dimensions (1280x832)

3. **WebView.swift** - WebKit wrapper implementing:
   - Non-persistent data store (incognito mode)
   - Dynamic vibrancy injection via JavaScript
   - Background transparency for light websites
   - Privacy-focused configuration

### Key Patterns

- **NSViewRepresentable**: Bridges WebKit to SwiftUI
- **Coordinator Pattern**: Handles WebView delegates
- **State Management**: Uses @State and environment objects
- **Observer Pattern**: Monitors clipboard and menu changes

### Vibrancy System

The app injects JavaScript to make light backgrounds transparent:
- Detects background colors dynamically
- Applies transparency to elements with light backgrounds
- Preserves dark content visibility
- Can be toggled with ⌘⇧V

## Development Notes

### Current Limitations

- No Xcode project files in repository (expects Phim/ subdirectory)
- No Git version control initialized
- No test suite or linting configuration
- Requires macOS 15.0+ and Swift 5.9+

### Distribution

The app is configured for:
- Developer ID signing and notarization
- Direct distribution outside App Store
- HTML/XHTML file associations
- HTTP/HTTPS URL scheme handling

### Testing Approach

Test locally using:
```bash
# Test with local HTML file
./phim test.html

# Test clipboard integration
# Copy URL to clipboard, then:
open Phim.app

# Test vibrancy with different websites
./phim https://github.com
```

### Code Style

- Follow Swift conventions with clear naming
- Maintain existing vibrancy injection patterns
- Preserve privacy-focused WebKit settings
- Keep UI minimalistic and keyboard-driven