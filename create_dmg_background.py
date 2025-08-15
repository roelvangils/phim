#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import os

# Create a 600x400 image with gradient background
width, height = 600, 400
img = Image.new('RGB', (width, height), color='white')
draw = ImageDraw.Draw(img)

# Create gradient background (purple to blue)
for y in range(height):
    # Gradient from purple (#764ba2) to blue (#667eea)
    r = int(118 + (102 - 118) * y / height)
    g = int(75 + (126 - 75) * y / height)
    b = int(162 + (234 - 162) * y / height)
    draw.rectangle([(0, y), (width, y + 1)], fill=(r, g, b))

# Add semi-transparent overlay circles for visual interest
overlay = Image.new('RGBA', (width, height), (255, 255, 255, 0))
overlay_draw = ImageDraw.Draw(overlay)

# Background circles
overlay_draw.ellipse([(-150, -150), (150, 150)], fill=(255, 255, 255, 25))
overlay_draw.ellipse([(width-100, height-100), (width+100, height+100)], fill=(255, 255, 255, 25))
overlay_draw.ellipse([(width-200, -50), (width-50, 100)], fill=(255, 255, 255, 20))

# Composite the overlay
img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
draw = ImageDraw.Draw(img)

# Try to use system font, fallback to default if not available
try:
    title_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 48)
    text_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
    arrow_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
except:
    # Use default font if system font not available
    title_font = ImageFont.load_default()
    text_font = ImageFont.load_default()
    arrow_font = ImageFont.load_default()

# Add text
title = "Install Phim"
instruction = "Drag Phim to your Applications folder"

# Calculate text positions for centering
title_bbox = draw.textbbox((0, 0), title, font=title_font)
title_width = title_bbox[2] - title_bbox[0]
title_x = (width - title_width) // 2

instruction_bbox = draw.textbbox((0, 0), instruction, font=text_font)
instruction_width = instruction_bbox[2] - instruction_bbox[0]
instruction_x = (width - instruction_width) // 2

# Draw text with shadow for better readability
# Shadow
draw.text((title_x + 2, 82), title, fill=(0, 0, 0, 100), font=title_font)
draw.text((instruction_x + 1, 152), instruction, fill=(0, 0, 0, 80), font=text_font)

# Main text
draw.text((title_x, 80), title, fill='white', font=title_font)
draw.text((instruction_x, 150), instruction, fill='white', font=text_font)

# Draw arrow pointing from left to right
arrow = "→"
arrow_bbox = draw.textbbox((0, 0), arrow, font=arrow_font)
arrow_width = arrow_bbox[2] - arrow_bbox[0]
arrow_x = (width - arrow_width) // 2
draw.text((arrow_x, 220), arrow, fill='white', font=arrow_font)

# Add icon placeholders
# Left icon (Phim app)
draw.rectangle([(150, 200), (200, 250)], fill=(255, 255, 255, 60), outline='white', width=2)
draw.text((165, 215), "📱", fill='white', font=text_font)

# Right icon (Applications folder)
draw.rectangle([(400, 200), (450, 250)], fill=(255, 255, 255, 60), outline='white', width=2)
draw.text((415, 215), "📁", fill='white', font=text_font)

# Save the image
img.save('dmg-background.png', 'PNG', quality=95)
print("✅ DMG background created: dmg-background.png")