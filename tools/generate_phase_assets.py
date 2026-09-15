"""
Generate crisp retro pixel art assets for Degrees of Escape:
1. heart_full.png (32x32 retro red heart with black border, specular gleam, dark shading)
2. heart_empty.png (32x32 empty dark heart container with crisp white/gold outline)
3. flat_guardian.png (64x64 paper-thin ancient dimensional sentinel with glowing eye and runic edge)
"""
from PIL import Image, ImageDraw
import os

os.makedirs(r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\ui", exist_ok=True)
os.makedirs(r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\chambers\broken_circuit\assets\sprites", exist_ok=True)

# 1. 32x32 Full Red Heart
img_full = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw = ImageDraw.Draw(img_full)

# Pixel grid 16x16 scaled 2x to 32x32
# Pattern: 1=black border, 2=bright red, 3=white highlight, 4=dark red shadow
heart_grid = [
    "................",
    "..111......111..",
    ".12321....12221.",
    "1233221..1222221",
    "1332222112222421",
    "1222222222224421",
    "1222222222244421",
    ".12222222244421.",
    ".1222222224421..",
    "..12222224421...",
    "...122224421....",
    "....1224421.....",
    ".....12421......",
    "......141.......",
    ".......1........",
    "................"
]

colors = {
    ".": (0, 0, 0, 0),
    "1": (20, 10, 5, 255),          # Dark outline
    "2": (235, 35, 45, 255),        # Vibrant retro red
    "3": (255, 200, 200, 255),      # Crisp specular highlight
    "4": (145, 15, 25, 255)         # Shaded inner rim
}

for y, row in enumerate(heart_grid):
    for x, ch in enumerate(row):
        col = colors.get(ch, (0, 0, 0, 0))
        if col[3] > 0:
            # 2x2 scale
            draw.rectangle([x*2, y*2, x*2+1, y*2+1], fill=col)

img_full.save(r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\ui\heart_full.png")
print("Saved heart_full.png")

# 2. 32x32 Empty Heart
img_empty = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
draw_e = ImageDraw.Draw(img_empty)

empty_colors = {
    ".": (0, 0, 0, 0),
    "1": (20, 10, 5, 255),          # Dark outline
    "2": (40, 20, 20, 220),         # Dark hollow fill
    "3": (90, 50, 50, 240),         # Faint upper inner rim
    "4": (25, 12, 12, 220)          # Hollow bottom shadow
}

for y, row in enumerate(heart_grid):
    for x, ch in enumerate(row):
        col = empty_colors.get(ch, (0, 0, 0, 0))
        if col[3] > 0:
            draw_e.rectangle([x*2, y*2, x*2+1, y*2+1], fill=col)

img_empty.save(r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\ui\heart_empty.png")
print("Saved heart_empty.png")

# 3. 64x64 Flat Guardian Sentinel Sprite
# A razor-sharp, paper-thin ancient dimensional blade-sentinel with an ominous glowing red/cyan eye
img_guard = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
draw_g = ImageDraw.Draw(img_guard)

# Base dark monolith body (blade shape)
# Symmetrical cutout with floating crown horns and central glowing slit
for y in range(8, 56):
    # Tapered blade silhouette
    if y < 16:
        w = (y - 8) * 1.8
    elif y < 38:
        w = 14 + (y - 16) * 0.4
    else:
        w = 22 - (y - 38) * 1.0
    w = max(2, int(w))
    cx = 32
    # Fill body
    draw_g.line([(cx - w, y), (cx + w, y)], fill=(35, 30, 25, 255), width=1)
    # Outline
    draw_g.point((cx - w - 1, y), fill=(15, 12, 10, 255))
    draw_g.point((cx + w + 1, y), fill=(15, 12, 10, 255))

# Golden runic trims and edge bevels
for y in range(12, 52, 2):
    t = int(10 + (y % 6) * 2)
    draw_g.point((32 - t, y), fill=(215, 175, 85, 255))
    draw_g.point((32 + t, y), fill=(215, 175, 85, 255))

# Floating horn crowns
draw_g.polygon([(18, 4), (22, 14), (26, 12)], fill=(45, 38, 30, 255), outline=(15, 12, 10, 255))
draw_g.polygon([(46, 4), (42, 14), (38, 12)], fill=(45, 38, 30, 255), outline=(15, 12, 10, 255))

# Central Ominous Glowing Eye (Crimson and Cyan dimensional core)
for r in range(7, 0, -1):
    alpha = int(255 * (1.0 - r / 8.0))
    c = (255, 60, 40, alpha) if r > 3 else (255, 230, 180, 255)
    draw_g.ellipse([32 - r, 26 - r, 32 + r, 26 + r], fill=c)

# Sharp lower dimensional blade tip
draw_g.polygon([(30, 56), (34, 56), (32, 62)], fill=(215, 175, 85, 255), outline=(15, 12, 10, 255))

img_guard.save(r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\chambers\broken_circuit\assets\sprites\flat_guardian.png")
print("Saved flat_guardian.png")
