#!/usr/bin/env python3

from PIL import Image, ImageDraw, ImageFont
import os
import sys

# Create a 600x400 image with modern light background
width, height = 600, 400
img = Image.new('RGB', (width, height), color='white')
draw = ImageDraw.Draw(img)

# Create a light gradient background (light gray to white)
for y in range(height):
    # Very subtle gradient from light gray to white
    gray = int(245 + (250 - 245) * y / height)
    draw.rectangle([(0, y), (width, y + 1)], fill=(gray, gray, gray))

# Add subtle geometric shapes for visual interest
overlay = Image.new('RGBA', (width, height), (255, 255, 255, 0))
overlay_draw = ImageDraw.Draw(overlay)

# Light purple accent circles (very subtle)
overlay_draw.ellipse([(-100, -100), (100, 100)], fill=(147, 112, 219, 15))
overlay_draw.ellipse([(width-80, height-80), (width+80, height+80)], fill=(147, 112, 219, 10))
overlay_draw.ellipse([(width-150, 50), (width-50, 150)], fill=(100, 149, 237, 10))

# Composite the overlay
img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
draw = ImageDraw.Draw(img)

# Use SF Pro Display (macOS system font)
font_paths = [
    "/System/Library/Fonts/Supplemental/SF Pro Display.ttf",
    "/System/Library/Fonts/SF-Pro-Display-Regular.otf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/Library/Fonts/SF-Pro-Display-Regular.otf"
]

title_font = None
text_font = None
small_font = None

for font_path in font_paths:
    if os.path.exists(font_path):
        try:
            title_font = ImageFont.truetype(font_path, 42)
            text_font = ImageFont.truetype(font_path, 18)
            small_font = ImageFont.truetype(font_path, 14)
            break
        except:
            continue

# Fallback to default if no system font found
if not title_font:
    title_font = ImageFont.load_default()
    text_font = ImageFont.load_default()
    small_font = ImageFont.load_default()

# Add text with no shadow (modern flat design)
title = "Install Phim"
instruction = "Drag Phim to your Applications folder"

# Calculate text positions for centering
title_bbox = draw.textbbox((0, 0), title, font=title_font)
title_width = title_bbox[2] - title_bbox[0]
title_x = (width - title_width) // 2

instruction_bbox = draw.textbbox((0, 0), instruction, font=text_font)
instruction_width = instruction_bbox[2] - instruction_bbox[0]
instruction_x = (width - instruction_width) // 2

# Draw text in dark gray for better contrast on light background
text_color = (51, 51, 51)  # Dark gray
secondary_color = (102, 102, 102)  # Medium gray

draw.text((title_x, 90), title, fill=text_color, font=title_font)
draw.text((instruction_x, 145), instruction, fill=secondary_color, font=text_font)

# Draw visual elements for drag and drop
# App icon placeholder (left)
icon_size = 80
left_icon_x = 180
icon_y = 220

# Draw rounded rectangle for app icon
draw.rounded_rectangle(
    [(left_icon_x, icon_y), (left_icon_x + icon_size, icon_y + icon_size)],
    radius=18,
    fill=(240, 240, 245),
    outline=(200, 200, 210),
    width=1
)

# Add "Phim" text in icon
phim_bbox = draw.textbbox((0, 0), "Phim", font=small_font)
phim_width = phim_bbox[2] - phim_bbox[0]
phim_height = phim_bbox[3] - phim_bbox[1]
draw.text(
    (left_icon_x + (icon_size - phim_width) // 2, 
     icon_y + (icon_size - phim_height) // 2),
    "Phim", 
    fill=text_color, 
    font=small_font
)

# Applications folder icon (right)
right_icon_x = 340
draw.rounded_rectangle(
    [(right_icon_x, icon_y), (right_icon_x + icon_size, icon_y + icon_size)],
    radius=15,
    fill=(240, 240, 245),
    outline=(200, 200, 210),
    width=1
)

# Add "Applications" text in folder icon
apps_text = "Apps"
apps_bbox = draw.textbbox((0, 0), apps_text, font=small_font)
apps_width = apps_bbox[2] - apps_bbox[0]
apps_height = apps_bbox[3] - apps_bbox[1]
draw.text(
    (right_icon_x + (icon_size - apps_width) // 2,
     icon_y + (icon_size - apps_height) // 2),
    apps_text,
    fill=text_color,
    font=small_font
)

# Draw an arrow between the icons
arrow_start_x = left_icon_x + icon_size + 20
arrow_end_x = right_icon_x - 20
arrow_y = icon_y + icon_size // 2

# Draw arrow line
draw.line(
    [(arrow_start_x, arrow_y), (arrow_end_x - 10, arrow_y)],
    fill=secondary_color,
    width=2
)

# Draw arrow head (triangle)
arrow_points = [
    (arrow_end_x, arrow_y),  # Tip
    (arrow_end_x - 10, arrow_y - 8),  # Top
    (arrow_end_x - 10, arrow_y + 8),  # Bottom
]
draw.polygon(arrow_points, fill=secondary_color)

# Save the image
output_path = 'dmg-assets/dmg-background.png'
os.makedirs('dmg-assets', exist_ok=True)
img.save(output_path, 'PNG', quality=95, dpi=(144, 144))
print(f"✅ DMG background created: {output_path}")