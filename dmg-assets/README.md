# DMG Assets

This folder contains all assets and scripts related to creating the DMG installer for Phim.

## Files

- `dmg-background.html` - HTML source for the DMG background design
- `dmg-background.png` - Generated background image (1200x800 @ 2x for retina)
- `generate_background.sh` - Script to generate PNG from HTML using Chrome
- `create_background.py` - Legacy Python script (kept for reference)

## Generating the Background

The DMG background is designed in HTML/CSS for easy editing and then converted to PNG.

### Method 1: Chrome Headless (Recommended)
```bash
./generate_background.sh
```
This uses Chrome's headless mode to render the HTML to a high-quality PNG.

### Method 2: Just preview the HTML
```bash
open dmg-background.html
```
You can edit the HTML/CSS and preview changes directly in your browser.

## Why HTML instead of Python/PIL?

- **Better design control**: Full CSS capabilities (gradients, shadows, fonts)
- **Easy to preview**: Just open the HTML file in a browser
- **No Python dependencies**: Uses Chrome which most developers have
- **Single source of truth**: The HTML is both the design and the documentation
- **Modern workflow**: Similar to how web developers work

## Design Principles

- **Light and modern**: Light background with subtle gradients
- **No shadows**: Flat design for clean appearance
- **System fonts**: Uses macOS native SF Pro Display font
- **Clear instructions**: Visual representation of drag-and-drop action
- **Professional look**: Matches modern macOS aesthetic