# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "Pillow",
# ]
# ///

import os
from PIL import Image, ImageDraw, ImageFont

def draw_background():
    # 600x400 as per Taskfile window size
    img = Image.new('RGBA', (600, 400), color='#f3f4f6')
    d = ImageDraw.Draw(img)

    # Add a soft rect in the background or just keep it simple
    # App icon is at (175, 190)
    # Applications folder is at (425, 185)
    
    # Arrow coordinates pointing right from x=260 to x=340
    arrow_points = [
        (260, 185), (310, 185), (310, 175), 
        (340, 190), 
        (310, 205), (310, 195), (260, 195)
    ]
    d.polygon(arrow_points, fill='#9ca3af')

    try:
        font = ImageFont.truetype("/System/Library/Fonts/HelveticaNeue.ttc", 24)
    except Exception:
        font = ImageFont.load_default()

    text = "Drag to Install"
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.text((300 - w/2, 230), text, fill='#4b5563', font=font)
    
    # ensure assets dir exists
    os.makedirs('assets', exist_ok=True)
    img.save('assets/dmg-background.png', 'PNG')
    print("Background image created at assets/dmg-background.png")

if __name__ == "__main__":
    draw_background()
