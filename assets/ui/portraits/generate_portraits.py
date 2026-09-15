"""
Generates 4 authentic Undertale-style pixel portraits for John Rod:
1. Dazed / Waking: Sitting up, rubbing head, dazed swirls/squint, messy hair.
2. Watch: Looking down at his raised wrist, chronometer glowing cyan with sparkles.
3. Revelation: Eyes wide with awe, dimensional geometric lines (1D, 2D, 3D) glowing.
4. Determined: Looking up towards the high ceiling with confident smirk.
"""
from PIL import Image, ImageDraw
import os

OUT_DIR = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\ui\portraits"
os.makedirs(OUT_DIR, exist_ok=True)

SIZE = 52
BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
CYAN_GLOW = (94, 240, 255, 255)
CYAN_DIM = (40, 140, 180, 255)
GREY = (180, 180, 190, 255)
DARK_GREY = (90, 90, 100, 255)

def create_base():
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)

def draw_head_outline(d, cx=26, cy=24, r=13):
    # Head circle & jaw
    d.ellipse([cx - r, cy - r, cx + r, cy + r - 2], outline=WHITE, fill=BLACK, width=2)
    # Jaw / chin
    chin = [(cx - 9, cy + 5), (cx - 4, cy + 15), (cx + 4, cy + 15), (cx + 9, cy + 5)]
    d.polygon(chin, outline=WHITE, fill=BLACK)
    d.line([(cx - 4, cy + 15), (cx + 4, cy + 15)], fill=WHITE, width=2)

def draw_adventurer_hair(d, cx=26, cy=14, messy=False):
    # Adventurer hair: messy explorer bangs and side tufts
    hair_top = [(cx - 15, cy + 5), (cx - 13, cy - 2), (cx - 6, cy - 6), (cx, cy - 7), (cx + 7, cy - 6), (cx + 14, cy - 2), (cx + 15, cy + 5)]
    d.polygon(hair_top + [(cx + 12, cy + 3), (cx + 8, cy - 1), (cx, cy - 2), (cx - 8, cy - 1), (cx - 12, cy + 3)], fill=WHITE)
    # Bangs
    d.polygon([(cx - 10, cy - 2), (cx - 5, cy + 4), (cx - 3, cy - 1)], fill=WHITE)
    d.polygon([(cx - 4, cy - 1), (cx + 1, cy + 5), (cx + 3, cy - 1)], fill=WHITE)
    d.polygon([(cx + 2, cy - 1), (cx + 8, cy + 4), (cx + 10, cy - 1)], fill=WHITE)
    if messy:
        # Extra cowlick / stray hair strands
        d.line([(cx - 6, cy - 6), (cx - 10, cy - 11), (cx - 7, cy - 9)], fill=WHITE, width=2)
        d.line([(cx + 4, cy - 6), (cx + 8, cy - 10), (cx + 6, cy - 8)], fill=WHITE, width=2)

def draw_shoulders(d, cx=26):
    # Collar / explorer jacket shoulders
    d.polygon([(cx - 18, 48), (cx - 10, 38), (cx - 5, 41), (cx - 7, 51), (cx - 18, 51)], outline=WHITE, fill=BLACK)
    d.polygon([(cx + 18, 48), (cx + 10, 38), (cx + 5, 41), (cx + 7, 51), (cx + 18, 51)], outline=WHITE, fill=BLACK)
    d.line([(cx - 10, 38), (cx - 5, 41)], fill=WHITE, width=2)
    d.line([(cx + 10, 38), (cx + 5, 41)], fill=WHITE, width=2)
    # Neck
    d.rectangle([cx - 4, 35, cx + 4, 40], outline=WHITE, fill=BLACK)

# -------------------------------------------------------------
# 1. DAZED / WAKING PORTRAIT
# -------------------------------------------------------------
def make_portrait_dazed():
    im, d = create_base()
    cx, cy = 26, 24
    draw_shoulders(d, cx)
    draw_head_outline(d, cx, cy)
    draw_adventurer_hair(d, cx, cy - 10, messy=True)
    
    # Dazed swirl / spiral eyes
    # Left eye spiral
    d.arc([cx - 8, cy - 2, cx - 2, cy + 4], start=0, end=300, fill=WHITE, width=2)
    d.point((cx - 5, cy + 1), WHITE)
    # Right eye squint (>_< or spiral)
    d.line([(cx + 3, cy - 1), (cx + 6, cy + 1), (cx + 9, cy - 1)], fill=WHITE, width=2)
    d.line([(cx + 3, cy + 3), (cx + 6, cy + 1), (cx + 9, cy + 3)], fill=WHITE, width=2)
    
    # Wavy / dizzy mouth
    d.line([(cx - 4, cy + 9), (cx - 2, cy + 8), (cx + 1, cy + 10), (cx + 4, cy + 8)], fill=WHITE, width=2)
    
    # Sweat drop / scratch mark on cheek
    d.line([(cx + 9, cy + 4), (cx + 12, cy + 8)], fill=WHITE, width=1)
    d.line([(cx + 11, cy + 4), (cx + 14, cy + 8)], fill=WHITE, width=1)
    # Dazed stars around head
    d.point((cx - 15, cy - 6), WHITE)
    d.point((cx - 16, cy - 7), WHITE)
    d.point((cx + 16, cy - 8), WHITE)
    d.point((cx + 17, cy - 7), WHITE)

    path = os.path.join(OUT_DIR, "john_rod_portrait_dazed.png")
    im.save(path)
    print("Saved:", path)

# -------------------------------------------------------------
# 2. WATCH PORTRAIT (LOOKING DOWN AT GLOWING CHRONOMETER)
# -------------------------------------------------------------
def make_portrait_watch():
    im, d = create_base()
    cx, cy = 24, 22
    draw_shoulders(d, cx)
    draw_head_outline(d, cx, cy)
    draw_adventurer_hair(d, cx, cy - 10, messy=False)
    
    # Eyes looking sharply down-right toward wrist
    d.ellipse([cx - 8, cy - 2, cx - 3, cy + 4], outline=WHITE, fill=BLACK, width=2)
    d.point((cx - 4, cy + 2), WHITE)
    d.point((cx - 5, cy + 2), WHITE)
    
    d.ellipse([cx + 2, cy - 2, cx + 7, cy + 4], outline=WHITE, fill=BLACK, width=2)
    d.point((cx + 6, cy + 2), WHITE)
    d.point((cx + 5, cy + 2), WHITE)
    
    # Curious, slightly open mouth ("Oh?")
    d.ellipse([cx - 2, cy + 8, cx + 2, cy + 11], outline=WHITE, fill=BLACK, width=2)
    
    # Raised forearm with Ancient Watch glowing at bottom-right
    d.polygon([(36, 40), (46, 32), (50, 36), (40, 48)], outline=WHITE, fill=BLACK)
    # The Watch
    d.ellipse([41, 33, 49, 41], outline=WHITE, fill=BLACK, width=2)
    d.ellipse([43, 35, 47, 39], fill=CYAN_GLOW)
    d.point((45, 37), WHITE)
    
    # Cyan glow rays / sparkles emanating from watch
    d.line([(40, 31), (37, 28)], fill=CYAN_GLOW, width=2)
    d.line([(45, 30), (45, 25)], fill=CYAN_GLOW, width=2)
    d.line([(50, 32), (54, 29)], fill=CYAN_GLOW, width=2)
    d.point((38, 25), WHITE)
    d.point((52, 26), WHITE)

    path = os.path.join(OUT_DIR, "john_rod_portrait_watch.png")
    im.save(path)
    print("Saved:", path)

# -------------------------------------------------------------
# 3. REVELATION / DIMENSIONAL SHIFTING PORTRAIT
# -------------------------------------------------------------
def make_portrait_revelation():
    im, d = create_base()
    cx, cy = 26, 23
    draw_shoulders(d, cx)
    draw_head_outline(d, cx, cy)
    draw_adventurer_hair(d, cx, cy - 10, messy=False)
    
    # Wide, amazed eyes
    d.ellipse([cx - 9, cy - 3, cx - 2, cy + 5], outline=WHITE, fill=BLACK, width=2)
    d.ellipse([cx - 7, cy - 1, cx - 4, cy + 3], fill=CYAN_GLOW)
    d.point((cx - 6, cy), WHITE)
    
    d.ellipse([cx + 2, cy - 3, cx + 9, cy + 5], outline=WHITE, fill=BLACK, width=2)
    d.ellipse([cx + 4, cy - 1, cx + 7, cy + 3], fill=CYAN_GLOW)
    d.point((cx + 5, cy), WHITE)
    
    # Wondering / excited smile
    d.arc([cx - 4, cy + 6, cx + 4, cy + 12], start=0, end=180, fill=WHITE, width=2)
    
    # Floating dimensional geometric symbols around him:
    # 1D Line on top-left
    d.line([(4, 10), (14, 10)], fill=CYAN_GLOW, width=2)
    d.point((4, 10), WHITE)
    d.point((14, 10), WHITE)
    
    # 2D Square on top-right
    d.rectangle([38, 6, 46, 14], outline=CYAN_GLOW, width=2)
    d.point((38, 6), WHITE)
    
    # 3D Isometric Cube wireframe on bottom-left
    ox, oy = 6, 24
    d.polygon([(ox+4, oy), (ox+8, oy+2), (ox+4, oy+4), (ox, oy+2)], outline=WHITE)
    d.line([(ox, oy+2), (ox, oy+7)], fill=WHITE)
    d.line([(ox+8, oy+2), (ox+8, oy+7)], fill=WHITE)
    d.line([(ox+4, oy+4), (ox+4, oy+9)], fill=WHITE)
    d.line([(ox, oy+7), (ox+4, oy+9)], fill=WHITE)
    d.line([(ox+4, oy+9), (ox+8, oy+7)], fill=WHITE)

    path = os.path.join(OUT_DIR, "john_rod_portrait_revelation.png")
    im.save(path)
    print("Saved:", path)

# -------------------------------------------------------------
# 4. DETERMINED PORTRAIT (LOOKING UP TOWARD EXIT)
# -------------------------------------------------------------
def make_portrait_determined():
    im, d = create_base()
    cx, cy = 26, 23
    draw_shoulders(d, cx)
    draw_head_outline(d, cx, cy)
    draw_adventurer_hair(d, cx, cy - 10, messy=False)
    
    # Sharp, determined eyes angled upwards
    # Left eye
    d.line([(cx - 9, cy - 3), (cx - 2, cy - 1)], fill=WHITE, width=2) # brow
    d.polygon([(cx - 8, cy - 1), (cx - 2, cy), (cx - 4, cy + 4), (cx - 8, cy + 3)], outline=WHITE, fill=BLACK)
    d.ellipse([cx - 6, cy, cx - 4, cy + 3], fill=WHITE)
    
    # Right eye
    d.line([(cx + 2, cy - 1), (cx + 9, cy - 3)], fill=WHITE, width=2) # brow
    d.polygon([(cx + 2, cy), (cx + 8, cy - 1), (cx + 8, cy + 3), (cx + 4, cy + 4)], outline=WHITE, fill=BLACK)
    d.ellipse([cx + 4, cy, cx + 6, cy + 3], fill=WHITE)
    
    # Confident smirk / smile
    d.line([(cx - 3, cy + 9), (cx + 2, cy + 9), (cx + 6, cy + 7)], fill=WHITE, width=2)
    d.point((cx + 6, cy + 6), WHITE) # smirk tick
    
    # Light glint in hair
    d.point((cx - 1, cy - 8), WHITE)
    d.point((cx + 1, cy - 8), WHITE)

    path = os.path.join(OUT_DIR, "john_rod_portrait_determined.png")
    im.save(path)
    print("Saved:", path)

if __name__ == "__main__":
    make_portrait_dazed()
    make_portrait_watch()
    make_portrait_revelation()
    make_portrait_determined()
    print("All Undertale portraits generated successfully!")
