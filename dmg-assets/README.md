# DMG Assets

This folder contains all assets and scripts related to creating the DMG installer for Phim.

## Files

- `create_background.py` - Python script that generates the DMG background image
- `dmg-background.png` - Generated background image (600x400) with installation instructions
- `dmg-background.html` - HTML template (for reference/preview)

## Regenerating the Background

To regenerate the DMG background image with a different design:

```bash
cd dmg-assets
python3 create_background.py
```

The script creates a modern, light background with:
- Clean, minimal design with light gray gradient
- macOS system font (SF Pro Display)
- Visual drag-and-drop instructions
- Proper arrow rendering without Unicode issues

## Design Principles

- **Light and modern**: Light background with subtle gradients
- **No shadows**: Flat design without text shadows
- **System fonts**: Uses macOS native SF Pro Display font
- **Clear instructions**: Visual representation of drag-and-drop action
- **Professional look**: Matches modern macOS aesthetic