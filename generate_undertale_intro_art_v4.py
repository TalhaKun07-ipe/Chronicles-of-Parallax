import math
import random
import os
from PIL import Image, ImageDraw

W, H = 320, 180
SCALE = 2  # Scaled to 640x360 with nearest-neighbor for razor-sharp pixel art

# Authentic Undertale Palette:
C_VOID = (20, 10, 3)          # #140a03 Deepest shadow/black
C_DARKEST = (44, 21, 6)       # #2c1506 Outlines / dark tree trunk / dark shadow
C_SHADOW = (73, 39, 9)        # #492709 Deep shadow brown / rock shadow
C_MID_DARK = (99, 48, 20)     # #633014 Mid-dark brown / rock clefts
C_MID_WARM = (133, 73, 30)    # #85491e Warm caramel amber / illuminated rock
C_LIGHT_BASE = (190, 130, 39) # #be8227 Undertale iconic Sky & Golden Ground
C_HIGHLIGHT = (228, 175, 76)  # #e4af4c Warm pale gold highlight
C_BRIGHT = (248, 222, 140)    # #f8de8c Spark / star / lantern core
C_WHITE = (255, 248, 220)     # #fff8dc Pure specular highlight

# John Rod metallic wireframe palette (Neutral polished chrome steel, zero blue tint!):
C_STEEL_WHITE = (255, 255, 255)
C_STEEL_LIGHT = (225, 225, 230)
C_STEEL_MID = (160, 165, 175)
C_STEEL_DARK = (80, 85, 95)

# Cosmic reality fracture accents:
C_COSMIC_CYAN = (120, 235, 255)
C_COSMIC_GOLD = (255, 230, 120)

SCRATCH = r"C:\Users\USER\.gemini\antigravity-ide\brain\6096e224-c58f-43ce-8131-5a1ae572308a\scratch"

def draw_wireframe_john_rod(draw, cx, cy, scale=1.0, pose="stand", lantern=True):
    """Draws authentic John Rod wireframe stickman with hollow loop head, angular joints, and bent sliding feet."""
    s = scale
    head_r = int(6 * s)
    head_cy = int(cy - 24 * s)
    
    # Outer head ring (metallic highlight on top, shadow on bottom)
    for a in range(0, 360, 15):
        rad = math.radians(a)
        px = int(cx + head_r * math.cos(rad))
        py = int(head_cy + head_r * math.sin(rad))
        col = C_STEEL_WHITE if 200 < a < 340 else C_STEEL_LIGHT
        draw.point((px, py), fill=col)
        draw.point((px + 1, py), fill=col)
    
    # Neck & Spine
    neck_y = head_cy + head_r
    spine_len = int(13 * s)
    hip_y = neck_y + spine_len
    draw.line([(cx, neck_y), (cx, hip_y)], fill=C_STEEL_WHITE, width=2)
    
    # Legs with 90-degree bent sliding feet
    leg_len = int(14 * s)
    foot_len = int(7 * s)
    foot_y = hip_y + leg_len
    
    if pose == "stand" or pose == "walk":
        # Left leg
        draw.line([(cx, hip_y), (cx - int(4 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(4 * s), foot_y), (cx - int(4 * s) - foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)
        # Right leg (sliding forward)
        draw.line([(cx, hip_y), (cx + int(4 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(4 * s), foot_y), (cx + int(4 * s) + foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)
        
        # Sliding spark particles at feet (ズッ)
        draw.point((cx + int(4 * s) + foot_len + 1, foot_y), fill=C_BRIGHT)
        draw.point((cx - int(4 * s) - foot_len - 1, foot_y), fill=C_BRIGHT)
        
    elif pose == "fall":
        draw.line([(cx, hip_y), (cx - int(7 * s), hip_y + int(10 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(7 * s), hip_y + int(10 * s)), (cx - int(12 * s), hip_y + int(7 * s))], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, hip_y), (cx + int(5 * s), hip_y + int(12 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(5 * s), hip_y + int(12 * s)), (cx + int(11 * s), hip_y + int(10 * s))], fill=C_STEEL_WHITE, width=2)

    elif pose == "reach":
        draw.line([(cx, hip_y), (cx - int(3 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(3 * s), foot_y), (cx - int(3 * s) - foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, hip_y), (cx + int(5 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(5 * s), foot_y), (cx + int(5 * s) + foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)

    # Arms
    shoulder_y = neck_y + int(3 * s)
    if pose == "stand" or pose == "walk":
        draw.line([(cx, shoulder_y), (cx - int(7 * s), shoulder_y + int(5 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(7 * s), shoulder_y + int(5 * s)), (cx - int(5 * s), shoulder_y + int(11 * s))], fill=C_STEEL_WHITE, width=2)
        lantern_x = cx + int(14 * s)
        lantern_y = shoulder_y + int(9 * s)
        draw.line([(cx, shoulder_y), (cx + int(8 * s), shoulder_y + int(3 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(8 * s), shoulder_y + int(3 * s)), (lantern_x, lantern_y)], fill=C_STEEL_WHITE, width=2)
        if lantern:
            draw_vintage_lantern(draw, lantern_x, lantern_y + int(2 * s), scale=s)
            
    elif pose == "reach":
        draw.line([(cx, shoulder_y), (cx + int(9 * s), shoulder_y - int(4 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(9 * s), shoulder_y - int(4 * s)), (cx + int(17 * s), shoulder_y - int(9 * s))], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, shoulder_y), (cx - int(7 * s), shoulder_y + int(5 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(7 * s), shoulder_y + int(5 * s)), (cx - int(8 * s), shoulder_y + int(10 * s))], fill=C_STEEL_WHITE, width=2)
        
    elif pose == "fall":
        draw.line([(cx, shoulder_y), (cx - int(10 * s), shoulder_y - int(8 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx, shoulder_y), (cx + int(12 * s), shoulder_y - int(10 * s))], fill=C_STEEL_WHITE, width=2)

def draw_vintage_lantern(draw, lx, ly, scale=1.0):
    """Draws vintage brass explorer lantern with warm radial glow."""
    s = scale
    lw = max(3, int(3 * s))
    lh = max(5, int(6 * s))
    
    draw.rectangle([lx - lw, ly, lx + lw, ly + lh], fill=C_DARKEST, outline=C_MID_WARM)
    draw.rectangle([lx - lw + 1, ly + 1, lx + lw - 1, ly + lh - 1], fill=C_BRIGHT)
    draw.point((lx, ly + lh // 2), fill=C_WHITE)
    draw.line([(lx - lw - 1, ly), (lx + lw + 1, ly)], fill=C_HIGHLIGHT, width=1)
    draw.line([(lx, ly - int(2 * s)), (lx, ly)], fill=C_MID_WARM, width=1)
    
    for r in [8, 15, 24]:
        for a in range(0, 360, 24):
            rad = math.radians(a)
            gx = int(lx + r * math.cos(rad))
            gy = int(ly + lh // 2 + r * math.sin(rad))
            if 0 <= gx < W and 0 <= gy < H:
                draw.point((gx, gy), fill=C_HIGHLIGHT if r < 15 else C_LIGHT_BASE)

# =========================================================================
# PANEL 1: Mt. Dimensional (Seamless edge extension & Glowing Tesseract)
# =========================================================================
def build_panel_1():
    ut33 = Image.open(os.path.join(SCRATCH, "ut_box_33.png"))
    crop = ut33.crop((7, 6, 292, 160))
    
    p1 = Image.new("RGB", (W, H), C_LIGHT_BASE)
    cx_off = (W - crop.width) // 2   # 17
    cy_off = (H - crop.height) // 2  # 13
    p1.paste(crop, (cx_off, cy_off))
    
    px = p1.load()
    crop_px = crop.load()
    
    # Seamlessly extend edge pixels left and right:
    for y in range(H):
        # Sample left edge of crop
        src_y = max(0, min(crop.height - 1, y - cy_off))
        left_col = crop_px[0, src_y]
        right_col = crop_px[crop.width - 1, src_y]
        for x in range(cx_off):
            px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            px[x, y] = right_col
            
    # Seamlessly fill top (sky) and bottom (ground)
    for y in range(cy_off):
        for x in range(W):
            px[x, y] = C_LIGHT_BASE
    for y in range(cy_off + crop.height, H):
        for x in range(W):
            px[x, y] = C_DARKEST

    d1 = ImageDraw.Draw(p1)
    
    # Floating Dimensional Hypercube / Tesseract above mountain peak
    tx, ty = W // 2, cy_off + 30
    for r in [26, 20, 14]:
        d1.ellipse([tx - r, ty - r, tx + r, ty + r], outline=C_HIGHLIGHT)

    outer_pts = [(tx, ty - 16), (tx + 16, ty), (tx, ty + 16), (tx - 16, ty)]
    d1.polygon(outer_pts, outline=C_BRIGHT)
    inner_pts = [(tx, ty - 9), (tx + 9, ty), (tx, ty + 9), (tx - 9, ty)]
    d1.polygon(inner_pts, outline=C_WHITE)
    for p_out, p_in in zip(outer_pts, inner_pts):
        d1.line([p_out, p_in], fill=C_WHITE, width=1)

    random.seed(42)
    for _ in range(35):
        px_pt = tx + random.randint(-28, 28)
        py_pt = ty + random.randint(-22, 22)
        if (px_pt - tx)**2 + (py_pt - ty)**2 > 50:
            d1.point((px_pt, py_pt), fill=C_WHITE if random.random() < 0.6 else C_BRIGHT)
            
    return p1

# =========================================================================
# PANEL 2: John Rod at Cavern Mouth (Seamless Natural Inpainting)
# =========================================================================
def build_panel_2():
    ut38 = Image.open(os.path.join(SCRATCH, "ut_box_38.png"))
    crop = ut38.crop((7, 6, 292, 162)).copy()
    crop_orig = ut38.crop((7, 6, 292, 162))
    px = crop.load()
    orig_px = crop_orig.load()
    
    # Cleanly inpaint Frisk without any horizontal artifacts:
    # 1. Rock wall above Frisk (y: 75..110) sampled from original rock at y-28
    for y in range(75, 110):
        for x in range(72, 115):
            src_y = max(35, y - 28)
            px[x, y] = orig_px[x, src_y]
            
    # 2. Dirt path under Frisk (y: 110..142) sampled from original path at x+42
    for y in range(110, 142):
        for x in range(70, 120):
            src_x = min(crop.width - 10, x + 42)
            px[x, y] = orig_px[src_x, y]
            
    # Draw John Rod standing on the path facing the cavern
    draw = ImageDraw.Draw(crop)
    jx, jy = 96, 134
    
    draw.ellipse([jx - 12, jy - 1, jx + 16, jy + 5], fill=C_SHADOW)
    draw_wireframe_john_rod(draw, jx, jy, scale=1.0, pose="walk", lantern=True)
    
    p2 = Image.new("RGB", (W, H), C_DARKEST)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p2.paste(crop, (cx_off, cy_off))
    
    # Seamless edge extension
    p2_px = p2.load()
    for y in range(H):
        src_y = max(0, min(crop.height - 1, y - cy_off))
        left_col = px[0, src_y]
        right_col = px[crop.width - 1, src_y]
        for x in range(cx_off):
            p2_px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            p2_px[x, y] = right_col
            
    for y in range(cy_off):
        for x in range(W):
            p2_px[x, y] = C_DARKEST
    for y in range(cy_off + crop.height, H):
        for x in range(W):
            p2_px[x, y] = C_DARKEST
            
    return p2

# =========================================================================
# PANEL 3: The Sanctuary Dais & The Ancient Watch
# =========================================================================
def build_panel_3():
    ut65 = Image.open(os.path.join(SCRATCH, "ut_box_65.png"))
    crop = ut65.crop((7, 6, 292, 162)).copy()
    crop_orig = ut65.crop((7, 6, 292, 162))
    px = crop.load()
    orig_px = crop_orig.load()
    
    # Inpaint only Frisk (avoiding any rectangular cutout lines):
    # Frisk's dark body pixels are replaced by the surrounding golden flower bed / stone floor:
    for y in range(85, 145):
        for x in range(65, 180):
            r, g, b = orig_px[x, y][:3]
            # Replace dark clothing/hair pixels with surrounding flower bed
            if (r < 60 and g < 35) or b > 60:
                # Sample from nearby illuminated floor
                src_x = x if x < 100 else (x + 25 if x + 25 < crop.width - 20 else x - 30)
                src_y = min(crop.height - 15, y + 12)
                px[x, y] = orig_px[src_x, src_y]
                
    draw = ImageDraw.Draw(crop)
    
    # Ancient Stone Dais in Center Sanctuary
    dais_cx = 135
    # Bottom tier
    draw.polygon([(dais_cx - 45, 134), (dais_cx + 45, 134), (dais_cx + 52, 148), (dais_cx - 52, 148)], fill=C_DARKEST)
    draw.line([(dais_cx - 45, 134), (dais_cx + 45, 134)], fill=C_HIGHLIGHT, width=2)
    # Middle tier
    draw.polygon([(dais_cx - 30, 118), (dais_cx + 30, 118), (dais_cx + 36, 134), (dais_cx - 36, 134)], fill=C_MID_DARK)
    draw.line([(dais_cx - 30, 118), (dais_cx + 30, 118)], fill=C_HIGHLIGHT, width=2)
    # Top pedestal altar
    draw.polygon([(dais_cx - 18, 98), (dais_cx + 18, 98), (dais_cx + 22, 118), (dais_cx - 22, 118)], fill=C_MID_WARM)
    draw.line([(dais_cx - 18, 98), (dais_cx + 18, 98)], fill=C_BRIGHT, width=2)

    # Celestial Light Shaft descending onto Dais
    for y in range(0, 105):
        t = y / 105.0
        bx1 = int(dais_cx - 18 - (1 - t) * 10)
        bx2 = int(dais_cx + 18 + (1 - t) * 10)
        for x in range(bx1, bx2):
            if (x + y) % 3 == 0:
                cur = px[x, y]
                if cur == C_VOID or cur == C_DARKEST:
                    px[x, y] = C_MID_WARM if t < 0.5 else C_HIGHLIGHT

    # Ancient Pocket Watch resting atop Pedestal
    wx, wy = dais_cx, 90
    draw.ellipse([wx - 10, wy - 10, wx + 10, wy + 10], fill=C_HIGHLIGHT)
    draw.ellipse([wx - 6, wy - 6, wx + 6, wy + 6], fill=C_DARKEST, outline=C_BRIGHT)
    draw.ellipse([wx - 4, wy - 4, wx + 4, wy + 4], fill=C_WHITE)
    draw.line([(wx, wy), (wx + 2, wy - 2)], fill=C_DARKEST, width=1)
    draw.rectangle([wx - 2, wy - 9, wx + 2, wy - 6], fill=C_BRIGHT)
    
    # 4-point Specular Star Glint on Watch
    glint = 9
    draw.line([(wx - glint, wy), (wx + glint, wy)], fill=C_WHITE, width=1)
    draw.line([(wx, wy - glint), (wx, wy + glint)], fill=C_WHITE, width=1)

    # John Rod standing at the base of the dais
    jx, jy = dais_cx - 48, 144
    draw.ellipse([jx - 10, jy - 1, jx + 14, jy + 4], fill=C_VOID)
    draw_wireframe_john_rod(draw, jx, jy, scale=0.95, pose="reach", lantern=False)
    draw_vintage_lantern(draw, jx - 14, jy - 6, scale=0.8)

    p3 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p3.paste(crop, (cx_off, cy_off))
    
    p3_px = p3.load()
    for y in range(H):
        src_y = max(0, min(crop.height - 1, y - cy_off))
        left_col = px[0, src_y]
        right_col = px[crop.width - 1, src_y]
        for x in range(cx_off):
            p3_px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            p3_px[x, y] = right_col
            
    return p3

# =========================================================================
# PANEL 4: The Touch & Reality Fracture (Macro Cinematic Close-Up)
# =========================================================================
def build_panel_4():
    p4 = Image.new("RGB", (W, H), C_DARKEST)
    draw = ImageDraw.Draw(p4)
    
    fc_x, fc_y = 155, 90
    
    # Ancient carved stone slab background with radial glow
    for r in range(140, 20, -10):
        t = r / 140.0
        col = C_SHADOW if t > 0.6 else C_MID_DARK
        draw.ellipse([fc_x - r, fc_y - r, fc_x + r, fc_y + r], fill=col)
        
    # Stone slab texture stippling & engraved circular runes
    random.seed(99)
    for _ in range(150):
        px_pt = random.randint(0, W)
        py_pt = random.randint(0, H)
        draw.point((px_pt, py_pt), fill=C_MID_WARM if random.random() < 0.6 else C_SHADOW)
        
    # Ancient concentric carved stone rings around watch
    for cr in [65, 85, 110]:
        draw.arc([fc_x - cr, fc_y - cr, fc_x + cr, fc_y + cr], 0, 360, fill=C_SHADOW, width=1)

    # The Ancient Chrono-Lens Watch (Macro Close-Up)
    w_r = 48
    draw.ellipse([fc_x - w_r, fc_y - w_r, fc_x + w_r, fc_y + w_r], fill=C_MID_WARM, outline=C_HIGHLIGHT, width=3)
    draw.ellipse([fc_x - w_r + 4, fc_y - w_r + 4, fc_x + w_r - 4, fc_y + w_r - 4], fill=C_DARKEST, outline=C_BRIGHT, width=2)
    
    dial_r = w_r - 8
    draw.ellipse([fc_x - dial_r, fc_y - dial_r, fc_x + dial_r, fc_y + dial_r], fill=C_HIGHLIGHT)
    
    # Concentric Dimensional Rings (0D, 1D, 2D, 3D compass tracks)
    draw.ellipse([fc_x - 24, fc_y - 24, fc_x + 24, fc_y + 24], outline=C_MID_WARM, width=1)
    draw.ellipse([fc_x - 14, fc_y - 14, fc_x + 14, fc_y + 14], outline=C_DARKEST, width=1)
    
    # Roman numeral tick marks
    for a in range(0, 360, 30):
        rad = math.radians(a)
        tx1 = int(fc_x + (dial_r - 3) * math.cos(rad))
        ty1 = int(fc_y + (dial_r - 3) * math.sin(rad))
        tx2 = int(fc_x + (dial_r - 8) * math.cos(rad))
        ty2 = int(fc_y + (dial_r - 8) * math.sin(rad))
        draw.line([(tx1, ty1), (tx2, ty2)], fill=C_DARKEST, width=2)

    # Clockwork Gears & Hands
    draw.arc([fc_x - 20, fc_y - 20, fc_x + 20, fc_y + 20], 30, 260, fill=C_MID_DARK, width=3)
    draw.line([(fc_x, fc_y), (fc_x + 18, fc_y - 15)], fill=C_DARKEST, width=3)
    draw.line([(fc_x, fc_y), (fc_x - 9, fc_y + 20)], fill=C_DARKEST, width=2)
    draw.ellipse([fc_x - 3, fc_y - 3, fc_x + 3, fc_y + 3], fill=C_BRIGHT)

    # Winding Crown & Loop
    crown_y = fc_y - w_r - 8
    draw.rectangle([fc_x - 5, crown_y, fc_x + 5, fc_y - w_r], fill=C_HIGHLIGHT, outline=C_DARKEST)
    draw.ellipse([fc_x - 9, crown_y - 12, fc_x + 9, crown_y], outline=C_BRIGHT, width=2)

    # John Rod's Chrome Finger Touching Crown
    finger_pts = [(40, 15), (95, 38), (fc_x - 2, crown_y - 2)]
    draw.line(finger_pts, fill=C_STEEL_WHITE, width=4)
    draw.ellipse([92, 35, 98, 41], fill=C_STEEL_LIGHT, outline=C_STEEL_DARK)
    draw.ellipse([fc_x - 5, crown_y - 5, fc_x + 1, crown_y + 1], fill=C_STEEL_WHITE)

    # Blinding Burst at Contact Point
    contact_x, contact_y = fc_x, crown_y
    draw.ellipse([contact_x - 9, contact_y - 9, contact_x + 9, contact_y + 9], fill=C_WHITE)
    
    # Reality Fracture Lightning Cracks (Cosmic Cyan & Pure White)
    random.seed(55)
    for angle in [10, 60, 120, 185, 235, 305, 350]:
        rad = math.radians(angle)
        cx, cy = contact_x, contact_y
        for _ in range(5):
            dist = random.randint(14, 28)
            w_ang = rad + random.uniform(-0.35, 0.35)
            nx = int(cx + dist * math.cos(w_ang))
            ny = int(cy + dist * math.sin(w_ang))
            draw.line([(cx, cy), (nx, ny)], fill=C_WHITE, width=2)
            draw.line([(cx + 1, cy), (nx + 1, ny)], fill=C_COSMIC_CYAN, width=1)
            cx, cy = nx, ny
            
    # Concentric Space Distortion Waves
    for dr in [30, 60, 95, 135]:
        draw.arc([contact_x - dr, contact_y - dr, contact_x + dr, contact_y + dr], 0, 360, fill=C_HIGHLIGHT, width=1)
        
    # Pedestal fracture lines
    draw.line([(0, 155), (70, 138), (110, 165)], fill=C_VOID, width=3)
    draw.line([(W, 150), (W - 80, 132), (W - 120, 160)], fill=C_VOID, width=3)

    return p4

# =========================================================================
# PANEL 5: The Collapse & Fall into the Abyss
# =========================================================================
def build_panel_5():
    ut58 = Image.open(os.path.join(SCRATCH, "ut_box_58.png"))
    crop = ut58.crop((7, 6, 292, 162)).copy()
    px = crop.load()
    
    for y in range(90, 128):
        for x in range(100, 132):
            px[x, y] = px[x + 30, y]
            
    draw = ImageDraw.Draw(crop)
    
    jx, jy = 135, 92
    draw_wireframe_john_rod(draw, jx, jy, scale=1.1, pose="fall", lantern=False)
    
    # Tumbling stone flagstones / dais fragments in forced perspective
    draw.polygon([(75, 125), (105, 115), (115, 138), (85, 148)], fill=C_MID_WARM, outline=C_HIGHLIGHT)
    draw.polygon([(85, 148), (115, 138), (110, 150), (80, 160)], fill=C_DARKEST)
    draw.polygon([(185, 100), (205, 92), (210, 110), (190, 118)], fill=C_MID_DARK, outline=C_LIGHT_BASE)
    draw.polygon([(125, 40), (140, 35), (145, 48), (130, 53)], fill=C_HIGHLIGHT, outline=C_WHITE)

    # Tumbling Brass Lantern with spinning golden sparks
    lx, ly = 175, 118
    draw_vintage_lantern(draw, lx, ly, scale=0.85)
    for a in range(0, 360, 40):
        rad = math.radians(a)
        sx = int(lx + 15 * math.cos(rad))
        sy = int(ly + 15 * math.sin(rad))
        draw.point((sx, sy), fill=C_WHITE)

    # Dynamic vertical rushing air / speed lines
    for sx in [65, 85, 155, 205, 225]:
        sy = random.randint(30, 70)
        sl = random.randint(30, 60)
        draw.line([(sx, sy), (sx, sy + sl)], fill=C_SHADOW, width=1)
        draw.line([(sx, sy + sl // 2), (sx, sy + sl)], fill=C_MID_WARM, width=1)

    p5 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p5.paste(crop, (cx_off, cy_off))
    
    p5_px = p5.load()
    for y in range(H):
        src_y = max(0, min(crop.height - 1, y - cy_off))
        left_col = px[0, src_y]
        right_col = px[crop.width - 1, src_y]
        for x in range(cx_off):
            p5_px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            p5_px[x, y] = right_col
            
    return p5

# =========================================================================
# PANEL 6: Awakening as a 0D Point in the Ruins (Seamless Flower Bed)
# =========================================================================
def build_panel_6():
    ut65 = Image.open(os.path.join(SCRATCH, "ut_box_65.png"))
    crop = ut65.crop((7, 6, 292, 162)).copy()
    crop_orig = ut65.crop((7, 6, 292, 162))
    px = crop.load()
    orig_px = crop_orig.load()
    
    # Inpaint only Frisk (replacing Frisk's dark clothing/hair with the surrounding flower bed):
    for y in range(80, 150):
        for x in range(60, 185):
            r, g, b = orig_px[x, y][:3]
            if (r < 60 and g < 35) or b > 60:
                # Sample from nearby illuminated flower bed
                src_x = min(crop.width - 15, x + 25)
                src_y = min(crop.height - 12, y + 10)
                px[x, y] = orig_px[src_x, src_y]

    draw = ImageDraw.Draw(crop)
    
    # Central impact point on the ruins floor
    spot_cx, spot_cy = 135, 126
    
    # Impact fracture cracks in stone floor
    draw.line([(spot_cx, spot_cy), (spot_cx - 24, spot_cy + 8)], fill=C_DARKEST, width=2)
    draw.line([(spot_cx, spot_cy), (spot_cx + 22, spot_cy + 6)], fill=C_DARKEST, width=2)
    draw.line([(spot_cx, spot_cy), (spot_cx - 8, spot_cy - 10)], fill=C_DARKEST, width=1)
    draw.line([(spot_cx, spot_cy), (spot_cx + 12, spot_cy - 8)], fill=C_DARKEST, width=1)

    # Concentric Glowing Dimensional Ripple Rings expanding from 0D Core
    for rip_r in [14, 28, 44, 62]:
        ry_scale = rip_r * 0.45
        draw.ellipse([spot_cx - rip_r, spot_cy - ry_scale, spot_cx + rip_r, spot_cy + ry_scale], outline=C_HIGHLIGHT, width=1)

    # The 0D Point Core (Gleaming polished neutral metallic chrome bead)
    bead_r = 4
    draw.ellipse([spot_cx - bead_r - 2, spot_cy - bead_r - 2, spot_cx + bead_r + 2, spot_cy + bead_r + 2], fill=C_WHITE)
    draw.ellipse([spot_cx - bead_r, spot_cy - bead_r, spot_cx + bead_r, spot_cy + bead_r], fill=C_STEEL_WHITE, outline=C_STEEL_MID)
    crop.putpixel((spot_cx - 1, spot_cy - 1), (255, 255, 255))
    
    # 4-point Specular Star Sparkle
    spk = 7
    draw.line([(spot_cx - spk, spot_cy), (spot_cx + spk, spot_cy)], fill=C_WHITE, width=1)
    draw.line([(spot_cx, spot_cy - spk), (spot_cx, spot_cy + spk)], fill=C_WHITE, width=1)

    # Floating motes of chronos-dust in light
    for _ in range(25):
        dx = spot_cx + random.randint(-35, 35)
        dy = spot_cy + random.randint(-45, 12)
        crop.putpixel((dx, dy), C_WHITE if random.random() < 0.5 else C_BRIGHT)

    p6 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p6.paste(crop, (cx_off, cy_off))
    
    p6_px = p6.load()
    for y in range(H):
        src_y = max(0, min(crop.height - 1, y - cy_off))
        left_col = px[0, src_y]
        right_col = px[crop.width - 1, src_y]
        for x in range(cx_off):
            p6_px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            p6_px[x, y] = right_col
            
    return p6

def main():
    generators = [
        ("intro_panel_1.png", build_panel_1),
        ("intro_panel_2.png", build_panel_2),
        ("intro_panel_3.png", build_panel_3),
        ("intro_panel_4.png", build_panel_4),
        ("intro_panel_5.png", build_panel_5),
        ("intro_panel_6.png", build_panel_6),
    ]
    
    out_dir = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\intro"
    os.makedirs(out_dir, exist_ok=True)
    
    for filename, gen_fn in generators:
        img_native = gen_fn()
        img_scaled = img_native.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
        path = os.path.join(out_dir, filename)
        img_scaled.save(path, "PNG")
        print(f"Perfection rendered {filename}: {img_scaled.size}")

if __name__ == "__main__":
    main()
