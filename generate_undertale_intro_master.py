import math
import random
import os
from PIL import Image, ImageDraw

W, H = 320, 180
SCALE = 2  # Scaled to 640x360 with nearest-neighbor for crisp retro presentation

# =========================================================================
# Authentic Undertale Palette & Tones
# =========================================================================
C_VOID = (20, 10, 3)          # #140a03 Deepest shadow / cavern dark
C_DARKEST = (44, 21, 6)       # #2c1506 Deepest brown / outline / silhouette
C_SHADOW = (73, 39, 9)        # #492709 Deep rock shadow / dark earth
C_MID_DARK = (99, 48, 20)     # #633014 Mid-dark brown / rock clefts / shadow stone
C_MID_WARM = (133, 73, 30)    # #85491e Warm caramel amber / illuminated stone
C_LIGHT_BASE = (190, 130, 39) # #be8227 Undertale Sky & Golden Amber Base
C_HIGHLIGHT = (228, 175, 76)  # #e4af4c Warm pale gold highlight / buttercup petal
C_BRIGHT = (248, 222, 140)    # #f8de8c Sparkle / sunlit petal tip / lantern core
C_WHITE = (255, 248, 220)     # #fff8dc Pure specular highlight / bright beam

# John Rod metallic wireframe palette (Neutral polished chrome steel, ZERO blue tint):
C_STEEL_WHITE = (255, 255, 255)
C_STEEL_BRIGHT = (225, 228, 235)
C_STEEL_MID = (155, 160, 170)
C_STEEL_DARK = (75, 80, 90)
C_STEEL_SHADOW = (35, 38, 45)

# Cosmic reality fracture accents:
C_COSMIC_CYAN = (120, 235, 255)
C_COSMIC_CYAN_LIGHT = (190, 248, 255)
C_COSMIC_GOLD = (255, 235, 130)

SCRATCH = r"C:\Users\USER\.gemini\antigravity-ide\brain\6096e224-c58f-43ce-8131-5a1ae572308a\scratch"

# =========================================================================
# Drawing Utilities for Authentic Pixel Art
# =========================================================================

def draw_wireframe_john_rod_art(draw, cx, cy, scale=1.0, pose="stand", lantern=True, light_dir=(-1, -1)):
    """
    Renders John Rod (JoJo Part 9) as a stylized metallic wireframe figure
    with distinct volumetric depth, metallic highlights, and hollow loop head.
    """
    s = scale
    head_r = max(4, int(5.5 * s))
    head_cy = int(cy - 23 * s)
    
    # 1. Cast shadow on ground (if standing/walking/reaching)
    if pose in ("stand", "walk", "reach"):
        sh_w = int(14 * s)
        sh_h = max(2, int(3.5 * s))
        sh_y = int(cy + 1)
        draw.ellipse([cx - sh_w, sh_y - sh_h, cx + sh_w, sh_y + sh_h], fill=C_DARKEST)
        draw.ellipse([cx - sh_w // 2, sh_y - sh_h + 1, cx + sh_w // 2, sh_y], fill=C_VOID)

    # 2. Hollow Torus Loop Head with 3D metallic shading
    for a in range(0, 360, 10):
        rad = math.radians(a)
        nx = math.cos(rad)
        ny = math.sin(rad)
        
        px = int(cx + head_r * nx)
        py = int(head_cy + head_r * ny)
        
        ldot = -(nx * light_dir[0] + ny * light_dir[1])
        if ldot > 0.6:
            col = C_STEEL_WHITE
        elif ldot > 0.1:
            col = C_STEEL_BRIGHT
        elif ldot > -0.4:
            col = C_STEEL_MID
        else:
            col = C_STEEL_DARK
            
        draw.point((px, py), fill=col)
        draw.point((px + 1, py), fill=col)
        
    # Specular glint on top curve of head
    glint_ang = math.atan2(light_dir[1], light_dir[0]) + math.pi
    gx = int(cx + head_r * math.cos(glint_ang))
    gy = int(head_cy + head_r * math.sin(glint_ang))
    draw.point((gx, gy), fill=C_STEEL_WHITE)
    draw.point((gx + 1, gy), fill=C_STEEL_WHITE)
    draw.point((gx, gy + 1), fill=C_STEEL_WHITE)

    # 3. Neck & Spine
    neck_y = head_cy + head_r
    spine_len = int(12 * s)
    hip_y = neck_y + spine_len
    
    draw.line([(cx, neck_y), (cx, hip_y)], fill=C_STEEL_BRIGHT, width=1)
    draw.line([(cx + 1, neck_y), (cx + 1, hip_y)], fill=C_STEEL_DARK, width=1)
    draw.line([(cx - 1, neck_y + 2), (cx - 1, hip_y - 2)], fill=C_STEEL_WHITE, width=1)

    # 4. Pelvis & Sliding Legs
    leg_len = int(13 * s)
    foot_len = int(6.5 * s)
    foot_y = hip_y + leg_len
    
    if pose in ("stand", "walk"):
        # Left leg (rear)
        lx = cx - int(4 * s)
        draw.line([(cx, hip_y), (lx, foot_y)], fill=C_STEEL_MID, width=2)
        draw.line([(lx, foot_y), (lx - foot_len, foot_y)], fill=C_STEEL_BRIGHT, width=2)
        
        # Right leg (front, sliding forward)
        rx = cx + int(4 * s)
        draw.line([(cx, hip_y), (rx, foot_y)], fill=C_STEEL_BRIGHT, width=2)
        draw.line([(rx, foot_y), (rx + foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)
        
        # Sliding spark particles at heel/toe (ズッ)
        draw.point((rx + foot_len + 1, foot_y), fill=C_BRIGHT)
        draw.point((lx - foot_len - 1, foot_y), fill=C_HIGHLIGHT)

    elif pose == "reach":
        lx = cx - int(3 * s)
        draw.line([(cx, hip_y), (lx, foot_y)], fill=C_STEEL_MID, width=2)
        draw.line([(lx, foot_y), (lx - foot_len, foot_y)], fill=C_STEEL_BRIGHT, width=2)
        
        rx = cx + int(5 * s)
        draw.line([(cx, hip_y), (rx, foot_y)], fill=C_STEEL_BRIGHT, width=2)
        draw.line([(rx, foot_y), (rx + foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)

    elif pose == "fall":
        # Flailing legs in mid-air
        draw.line([(cx, hip_y), (cx - int(7 * s), hip_y + int(9 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx - int(7 * s), hip_y + int(9 * s)), (cx - int(12 * s), hip_y + int(6 * s))], fill=C_STEEL_BRIGHT, width=2)
        draw.line([(cx, hip_y), (cx + int(6 * s), hip_y + int(11 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx + int(6 * s), hip_y + int(11 * s)), (cx + int(13 * s), hip_y + int(9 * s))], fill=C_STEEL_WHITE, width=2)

    # 5. Shoulders & Arms
    shoulder_y = neck_y + int(2.5 * s)
    
    if pose in ("stand", "walk"):
        draw.line([(cx, shoulder_y), (cx - int(6 * s), shoulder_y + int(4 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx - int(6 * s), shoulder_y + int(4 * s)), (cx - int(4 * s), shoulder_y + int(9 * s))], fill=C_STEEL_BRIGHT, width=2)
        
        elbow_x = cx + int(7 * s)
        elbow_y = shoulder_y + int(3 * s)
        hand_x = cx + int(13 * s)
        hand_y = shoulder_y + int(8 * s)
        draw.line([(cx, shoulder_y), (elbow_x, elbow_y)], fill=C_STEEL_BRIGHT, width=2)
        draw.line([(elbow_x, elbow_y), (hand_x, hand_y)], fill=C_STEEL_WHITE, width=2)
        
        if lantern:
            draw_brass_lantern(draw, hand_x, hand_y + int(2 * s), scale=s)

    elif pose == "reach":
        draw.line([(cx, shoulder_y), (cx - int(6 * s), shoulder_y + int(5 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx - int(6 * s), shoulder_y + int(5 * s)), (cx - int(7 * s), shoulder_y + int(10 * s))], fill=C_STEEL_BRIGHT, width=2)
        
        hand_x = cx + int(17 * s)
        hand_y = shoulder_y - int(9 * s)
        draw.line([(cx, shoulder_y), (cx + int(8 * s), shoulder_y - int(3 * s))], fill=C_STEEL_BRIGHT, width=2)
        draw.line([(cx + int(8 * s), shoulder_y - int(3 * s)), (hand_x, hand_y)], fill=C_STEEL_WHITE, width=2)
        draw.point((hand_x + 1, hand_y), fill=C_STEEL_WHITE)

    elif pose == "fall":
        draw.line([(cx, shoulder_y), (cx - int(10 * s), shoulder_y - int(7 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx - int(10 * s), shoulder_y - int(7 * s)), (cx - int(15 * s), shoulder_y - int(4 * s))], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, shoulder_y), (cx + int(11 * s), shoulder_y - int(9 * s))], fill=C_STEEL_MID, width=2)
        draw.line([(cx + int(11 * s), shoulder_y - int(9 * s)), (cx + int(17 * s), shoulder_y - int(7 * s))], fill=C_STEEL_WHITE, width=2)

def draw_brass_lantern(draw, lx, ly, scale=1.0, glow=True):
    """
    Renders detailed vintage brass lantern with glowing core and warm dithered light.
    """
    s = scale
    lw = max(2, int(3 * s))
    lh = max(4, int(5.5 * s))
    
    # 1. Warm radial illumination on surrounding area
    if glow:
        radii = [int(22 * s), int(14 * s), int(8 * s)]
        cols = [C_MID_WARM, C_HIGHLIGHT, C_BRIGHT]
        for r, col in zip(radii, cols):
            for a in range(0, 360, 15):
                rad = math.radians(a)
                for dr in range(max(1, r - 3), r + 1):
                    if (dr + int(a)) % 2 == 0:
                        gx = int(lx + dr * math.cos(rad))
                        gy = int(ly + lh // 2 + dr * 0.7 * math.sin(rad))
                        if 0 <= gx < W and 0 <= gy < H:
                            draw.point((gx, gy), fill=col)

    # 2. Hanging brass loop
    draw.ellipse([lx - 2, ly - 3, lx + 2, ly - 1], outline=C_HIGHLIGHT)
    
    # 3. Lantern Cap (brass dome)
    draw.polygon([(lx - lw - 1, ly), (lx + lw + 1, ly), (lx + lw, ly - 1), (lx - lw, ly - 1)], fill=C_HIGHLIGHT)
    draw.line([(lx - lw - 1, ly), (lx + lw + 1, ly)], fill=C_BRIGHT)
    
    # 4. Glass Chamber & Brass Ribs
    draw.rectangle([lx - lw, ly + 1, lx + lw, ly + lh - 1], fill=C_DARKEST, outline=C_MID_WARM)
    draw.rectangle([lx - lw + 1, ly + 2, lx + lw - 1, ly + lh - 2], fill=C_HIGHLIGHT)
    
    # Glowing flame core
    draw.rectangle([lx - 1, ly + 2, lx + 1, ly + lh - 2], fill=C_BRIGHT)
    draw.point((lx, ly + lh // 2), fill=C_WHITE)
    
    # 5. Lantern Base
    draw.rectangle([lx - lw - 1, ly + lh, lx + lw + 1, ly + lh + 1], fill=C_MID_WARM, outline=C_DARKEST)

def restore_ut65_floor_seamlessly(crop):
    """
    Seamlessly inpaints Frisk from ut_box_65 without any rectangular seams,
    leaving the pillars, ivy, stone path, and flower beds 100% authentic Undertale.
    """
    px = crop.load()
    
    mask = set()
    for y in range(86, 164):
        for x in range(60, 205):
            r, g, b = px[x, y]
            if r < 155 or g < 105:
                mask.add((x, y))

    dilated = set(mask)
    for x, y in mask:
        for dx in range(-3, 4):
            for dy in range(-3, 4):
                nx, ny = x + dx, y + dy
                if 0 <= nx < crop.width and 0 <= ny < crop.height:
                    dilated.add((nx, ny))

    for x, y in dilated:
        if 105 <= x <= 165:
            src_y = 55 + (y % 28)
            src_x = 118 + (x % 48)
            px[x, y] = px[src_x, src_y]
        elif x < 105:
            src_y = 85 + (y % 55)
            src_x = 18 + (x % 38)
            px[x, y] = px[src_x, src_y]
        else:
            src_y = 85 + (y % 55)
            src_x = 205 + (x % 38)
            px[x, y] = px[src_x, src_y]


# =========================================================================
# PANEL 1: Mt. Dimensional & The Anomaly
# =========================================================================
def generate_panel_1():
    ut33 = Image.open(os.path.join(SCRATCH, "ut_box_33.png"))
    # The art is 300x163
    crop = ut33.crop((0, 0, 300, 163))
    
    p1 = Image.new("RGB", (W, H), C_LIGHT_BASE)
    cx_off = 10
    cy_off = 17  # 17 + 163 = 180 (mountain base aligns with bottom canvas!)
    p1.paste(crop, (cx_off, cy_off))
    
    px = p1.load()
    crop_px = crop.load()
    
    # 1. Seamlessly extend sky to top & sides
    for y in range(cy_off):
        for x in range(W):
            px[x, y] = C_LIGHT_BASE
            
    for y in range(cy_off, H):
        left_col = crop_px[0, y - cy_off]
        right_col = crop_px[crop.width - 1, y - cy_off]
        for x in range(cx_off):
            px[x, y] = left_col
        for x in range(cx_off + crop.width, W):
            px[x, y] = right_col

    d1 = ImageDraw.Draw(p1)
    
    # 2. The Dimensional Anomaly: Floating 4D Tesseract above Mt. Dimensional
    tx, ty = W // 2, cy_off + 26
    
    # Celestial light cone descending onto mountain summit
    summit_x, summit_y = tx, cy_off + 68
    for y in range(ty + 16, summit_y):
        prog = (y - (ty + 16)) / float(summit_y - (ty + 16))
        half_w = int(5 + prog * 16)
        for x in range(tx - half_w, tx + half_w + 1):
            if (x * 3 + y * 2) % 3 == 0:
                dist_c = abs(x - tx) / float(half_w + 1)
                if dist_c < 0.35 and prog > 0.4:
                    px[x, y] = C_BRIGHT
                elif dist_c < 0.7:
                    px[x, y] = C_HIGHLIGHT
                else:
                    px[x, y] = C_MID_WARM

    # Concentric orbital astrolabe rings
    for r in [32, 24, 16]:
        for a in range(0, 360, 12):
            if (a // 12) % 4 != 0:
                rad = math.radians(a)
                rx = int(tx + r * math.cos(rad))
                ry = int(ty + (r * 0.65) * math.sin(rad))
                if 0 <= rx < W and 0 <= ry < H:
                    d1.point((rx, ry), fill=C_BRIGHT if r == 24 else C_HIGHLIGHT)

    # 4D Hypercube (Tesseract) with shaded isometric facets
    s = 14
    v_top = (tx, ty - s)
    v_tr = (tx + int(s * 1.1), ty - int(s * 0.5))
    v_br = (tx + int(s * 1.1), ty + int(s * 0.6))
    v_bot = (tx, ty + int(s * 1.1))
    v_bl = (tx - int(s * 1.1), ty + int(s * 0.6))
    v_tl = (tx - int(s * 1.1), ty - int(s * 0.5))
    v_mid = (tx, ty)
    
    d1.polygon([v_top, v_tr, v_mid, v_tl], fill=C_BRIGHT)    # Top facet
    d1.polygon([v_mid, v_tr, v_br, v_bot], fill=C_HIGHLIGHT) # Right facet
    d1.polygon([v_tl, v_mid, v_bot, v_bl], fill=C_MID_WARM)  # Left facet
    
    d1.line([v_top, v_tr, v_br, v_bot, v_bl, v_tl, v_top], fill=C_WHITE, width=2)
    d1.line([v_mid, v_top], fill=C_WHITE, width=2)
    d1.line([v_mid, v_br], fill=C_WHITE, width=2)
    d1.line([v_mid, v_bl], fill=C_WHITE, width=2)
    
    # Inner hypercube rotated 45 degrees glowing intensely
    is_r = 6
    in_pts = [(tx, ty - is_r), (tx + is_r, ty), (tx, ty + is_r), (tx - is_r, ty)]
    d1.polygon(in_pts, fill=C_WHITE, outline=C_BRIGHT)
    d1.point((tx, ty), fill=C_WHITE)
    
    for p_out, p_in in zip([v_top, v_tr, v_bot, v_bl], in_pts):
        d1.line([p_out, p_in], fill=C_WHITE, width=1)

    gl = 20
    d1.line([(tx - gl, ty), (tx + gl, ty)], fill=C_WHITE, width=1)
    d1.line([(tx, ty - gl // 2), (tx, ty + gl // 2)], fill=C_WHITE, width=1)

    rng_star = random.Random(42)
    for _ in range(45):
        sx = tx + rng_star.randint(-42, 42)
        sy = ty + rng_star.randint(-28, 38)
        if (sx - tx)**2 + (sy - ty)**2 > 60:
            d1.point((sx, sy), fill=C_WHITE if rng_star.random() < 0.6 else C_BRIGHT)

    return p1


# =========================================================================
# PANEL 2: John Rod at the Cavern Mouth
# =========================================================================
def generate_panel_2():
    ut38 = Image.open(os.path.join(SCRATCH, "ut_box_38.png"))
    crop = ut38.crop((0, 0, 300, 165)).copy()
    px = crop.load()
    
    # Seamless inpainting of Frisk from right offset (x + 42):
    for y in range(88, 136):
        for x in range(74, 118):
            src_x = min(285, x + 42)
            px[x, y] = px[src_x, y]
            
    # Soft blend on upper rim (y: 86..92) with surrounding rock tones
    for x in range(80, 115):
        px[x, 87] = C_MID_WARM
        if x % 3 == 0:
            px[x, 88] = C_MID_WARM

    draw = ImageDraw.Draw(crop)
    
    # Draw John Rod on the trail, advancing toward the cavern
    jx, jy = 98, 128
    draw_wireframe_john_rod_art(draw, jx, jy, scale=1.05, pose="walk", lantern=True, light_dir=(-1, -1))
    
    # Fit into 320x180 canvas with dark forest framing
    p2 = Image.new("RGB", (W, H), C_DARKEST)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p2.paste(crop, (cx_off, cy_off))
    
    d2 = ImageDraw.Draw(p2)
    d2.rectangle([0, 0, cx_off, H], fill=C_DARKEST)
    d2.rectangle([cx_off + crop.width, 0, W, H], fill=C_DARKEST)
    d2.rectangle([0, 0, W, cy_off], fill=C_DARKEST)
    d2.rectangle([0, cy_off + crop.height, W, H], fill=C_DARKEST)

    return p2


# =========================================================================
# PANEL 3: The Sanctuary Hall & The Dais
# =========================================================================
def generate_panel_3():
    ut65 = Image.open(os.path.join(SCRATCH, "ut_box_65.png"))
    crop = ut65.crop((0, 0, 300, 165)).copy()
    
    # 1. Seamlessly restore the central floor
    restore_ut65_floor_seamlessly(crop)
    
    draw = ImageDraw.Draw(crop)
    
    # 2. Build Classical Carved Stone DAIS & PEDESTAL in Center
    dais_cx = 142
    
    # Tier 1 (Bottom Stepped Stone Base): y: 132 to 144
    draw.polygon([(dais_cx - 46, 132), (dais_cx + 46, 132), (dais_cx + 52, 144), (dais_cx - 52, 144)], fill=C_DARKEST)
    draw.polygon([(dais_cx - 44, 132), (dais_cx + 44, 132), (dais_cx + 50, 142), (dais_cx - 50, 142)], fill=C_MID_DARK)
    draw.line([(dais_cx - 45, 132), (dais_cx + 45, 132)], fill=C_HIGHLIGHT, width=2)
    draw.line([(dais_cx - 15, 132), (dais_cx - 18, 140)], fill=C_DARKEST, width=1)
    draw.line([(dais_cx + 22, 134), (dais_cx + 26, 142)], fill=C_DARKEST, width=1)
    
    # Tier 2 (Middle Stepped Plinth): y: 118 to 132
    draw.polygon([(dais_cx - 30, 118), (dais_cx + 30, 118), (dais_cx + 35, 132), (dais_cx - 35, 132)], fill=C_DARKEST)
    draw.polygon([(dais_cx - 28, 118), (dais_cx + 28, 118), (dais_cx + 33, 130), (dais_cx - 33, 130)], fill=C_MID_WARM)
    draw.line([(dais_cx - 29, 118), (dais_cx + 29, 118)], fill=C_BRIGHT, width=2)
    # Ivy tendril climbing up left side of plinth
    draw.line([(dais_cx - 32, 132), (dais_cx - 28, 124), (dais_cx - 25, 118)], fill=C_DARKEST, width=2)
    draw.line([(dais_cx - 32, 132), (dais_cx - 28, 124), (dais_cx - 25, 118)], fill=C_SHADOW, width=1)
    draw.point((dais_cx - 27, 122), fill=C_HIGHLIGHT)
    draw.point((dais_cx - 24, 117), fill=C_HIGHLIGHT)

    # Tier 3 (Carved Pedestal Altar Pillar): y: 96 to 118
    draw.polygon([(dais_cx - 16, 96), (dais_cx + 16, 96), (dais_cx + 20, 118), (dais_cx - 20, 118)], fill=C_DARKEST)
    draw.polygon([(dais_cx - 14, 96), (dais_cx + 14, 96), (dais_cx + 18, 116), (dais_cx - 18, 116)], fill=C_LIGHT_BASE)
    draw.line([(dais_cx - 15, 96), (dais_cx + 15, 96)], fill=C_WHITE, width=2)
    draw.line([(dais_cx - 6, 98), (dais_cx - 7, 115)], fill=C_MID_WARM, width=1)
    draw.line([(dais_cx + 6, 98), (dais_cx + 7, 115)], fill=C_MID_WARM, width=1)

    # 3. Translucent Celestial Light Shaft descending onto Dais
    px = crop.load()
    for y in range(0, 100):
        t = y / 100.0
        lx_start = int(115 - (1 - t) * 15 + t * 5)
        rx_start = int(140 + (1 - t) * 5 + t * 25)
        for x in range(lx_start, rx_start):
            if (x * 2 + y * 3) % 4 == 0:
                cur = px[x, y]
                if cur in (C_VOID, C_DARKEST, C_SHADOW):
                    px[x, y] = C_MID_WARM if t < 0.4 else C_HIGHLIGHT
                elif cur == C_MID_DARK:
                    px[x, y] = C_HIGHLIGHT if t > 0.5 else C_LIGHT_BASE

    # 4. The Ancient Watch resting atop the Altar Plinth
    wx, wy = dais_cx, 88
    draw.ellipse([wx - 10, wy + 5, wx + 10, wy + 9], fill=C_DARKEST)
    draw.ellipse([wx - 9, wy - 9, wx + 9, wy + 7], fill=C_HIGHLIGHT, outline=C_DARKEST)
    draw.ellipse([wx - 7, wy - 7, wx + 7, wy + 5], fill=C_BRIGHT)
    draw.ellipse([wx - 4, wy - 5, wx + 4, wy + 3], fill=C_WHITE)
    draw.line([(wx, wy - 9), (wx, wy - 13)], fill=C_HIGHLIGHT, width=2)
    draw.ellipse([wx - 3, wy - 15, wx + 3, wy - 11], outline=C_BRIGHT)
    draw.line([(wx - 10, wy - 1), (wx + 10, wy - 1)], fill=C_WHITE, width=1)
    draw.line([(wx, wy - 11), (wx, wy + 9)], fill=C_WHITE, width=1)

    rng_dust = random.Random(555)
    for _ in range(30):
        dx = dais_cx + rng_dust.randint(-30, 30)
        dy = wy + rng_dust.randint(-70, 10)
        if 0 <= dx < crop.width and 0 <= dy < crop.height:
            crop.putpixel((dx, dy), C_WHITE if rng_dust.random() < 0.5 else C_BRIGHT)

    # 5. John Rod standing at the base of the dais in breathless wonder
    jx, jy = dais_cx - 48, 142
    draw_wireframe_john_rod_art(draw, jx, jy, scale=0.98, pose="reach", lantern=False, light_dir=(1, -1))
    draw_brass_lantern(draw, jx - 16, jy - 6, scale=0.85, glow=True)

    # 6. Fit into 320x180 canvas
    p3 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p3.paste(crop, (cx_off, cy_off))
    
    d3 = ImageDraw.Draw(p3)
    d3.rectangle([0, 0, cx_off, H], fill=C_VOID)
    d3.rectangle([cx_off + crop.width, 0, W, H], fill=C_VOID)
    d3.rectangle([0, 0, W, cy_off], fill=C_VOID)
    d3.rectangle([0, cy_off + crop.height, W, H], fill=C_VOID)

    return p3


# =========================================================================
# PANEL 4: The Touch & Reality Fracture (Dramatic Macro Close-Up)
# =========================================================================
def generate_panel_4():
    p4 = Image.new("RGB", (W, H), C_DARKEST)
    draw = ImageDraw.Draw(p4)
    px = p4.load()
    
    fc_x, fc_y = 160, 98
    
    # 1. Ancient carved stone altar background with stone texture & vignette
    rng_bg = random.Random(404)
    for y in range(H):
        for x in range(W):
            d2 = (x - fc_x)**2 + (y - fc_y)**2
            dist = math.sqrt(d2)
            noise = rng_bg.randint(-8, 8)
            eff_dist = dist + noise
            if eff_dist > 140:
                px[x, y] = C_VOID
            elif eff_dist > 110:
                px[x, y] = C_DARKEST if (x + y) % 2 == 0 else C_VOID
            elif eff_dist > 80:
                px[x, y] = C_SHADOW if (x + y) % 3 == 0 else C_DARKEST
            else:
                px[x, y] = C_MID_DARK if (x * 2 + y) % 4 == 0 else C_SHADOW

    # Heavy stone masonry block seams
    draw.line([(0, 145), (105, 138), (170, 155), (W, 142)], fill=C_VOID, width=2)
    draw.line([(105, 138), (105, H)], fill=C_VOID, width=2)
    draw.line([(0, 50), (90, 62), (W, 45)], fill=C_VOID, width=2)

    # 2. The Ancient Watch (Macro Chrono-Lens)
    w_r = 54
    draw.ellipse([fc_x - w_r, fc_y - w_r, fc_x + w_r, fc_y + w_r], fill=C_MID_WARM, outline=C_HIGHLIGHT, width=3)
    draw.ellipse([fc_x - w_r + 4, fc_y - w_r + 4, fc_x + w_r - 4, fc_y + w_r - 4], fill=C_DARKEST, outline=C_BRIGHT, width=2)
    
    for a in range(0, 360, 10):
        rad = math.radians(a)
        bx1 = int(fc_x + (w_r - 2) * math.cos(rad))
        by1 = int(fc_y + (w_r - 2) * math.sin(rad))
        bx2 = int(fc_x + (w_r - 4) * math.cos(rad))
        by2 = int(fc_y + (w_r - 4) * math.sin(rad))
        draw.line([(bx1, by1), (bx2, by2)], fill=C_BRIGHT if a % 30 == 0 else C_HIGHLIGHT, width=1)

    dial_r = w_r - 8
    draw.ellipse([fc_x - dial_r, fc_y - dial_r, fc_x + dial_r, fc_y + dial_r], fill=C_HIGHLIGHT)
    
    skel_r = 28
    draw.ellipse([fc_x - skel_r, fc_y - skel_r, fc_x + skel_r, fc_y + skel_r], fill=C_DARKEST, outline=C_MID_WARM, width=2)
    
    # Interlocking clockwork gear wheels
    g1_x, g1_y = fc_x - 10, fc_y + 6
    g1_r = 14
    draw.ellipse([g1_x - g1_r, g1_y - g1_r, g1_x + g1_r, g1_y + g1_r], fill=C_MID_WARM, outline=C_HIGHLIGHT)
    for ga in range(0, 360, 30):
        grad = math.radians(ga)
        draw.line([(int(g1_x + (g1_r - 2) * math.cos(grad)), int(g1_y + (g1_r - 2) * math.sin(grad))),
                   (int(g1_x + (g1_r + 2) * math.cos(grad)), int(g1_y + (g1_r + 2) * math.sin(grad)))], fill=C_BRIGHT, width=2)
    draw.ellipse([g1_x - 4, g1_y - 4, g1_x + 4, g1_y + 4], fill=C_DARKEST)

    g2_x, g2_y = fc_x + 12, fc_y - 8
    g2_r = 9
    draw.ellipse([g2_x - g2_r, g2_y - g2_r, g2_x + g2_r, g2_y + g2_r], fill=C_LIGHT_BASE, outline=C_BRIGHT)
    draw.ellipse([g2_x - 2, g2_y - 2, g2_x + 2, g2_y + 2], fill=C_DARKEST)

    # Roman Numerals along chapter ring
    numerals = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
    for i, num in enumerate(numerals):
        ang = math.radians(i * 30 - 90)
        draw.line([(int(fc_x + (dial_r - 3) * math.cos(ang)), int(fc_y + (dial_r - 3) * math.sin(ang))),
                   (int(fc_x + (dial_r - 9) * math.cos(ang)), int(fc_y + (dial_r - 9) * math.sin(ang)))],
                  fill=C_DARKEST, width=2 if i % 3 == 0 else 1)

    # Clockwork Hands
    draw.line([(fc_x, fc_y), (fc_x + 2, fc_y - 32)], fill=C_DARKEST, width=3)
    draw.line([(fc_x, fc_y), (fc_x + 2, fc_y - 32)], fill=C_MID_DARK, width=2)
    draw.line([(fc_x, fc_y), (fc_x + 18, fc_y + 14)], fill=C_DARKEST, width=2)
    draw.ellipse([fc_x - 4, fc_y - 4, fc_x + 4, fc_y + 4], fill=C_BRIGHT, outline=C_DARKEST)

    # Top Winding Crown & Bow Ring
    crown_y = fc_y - w_r - 10
    draw.rectangle([fc_x - 7, crown_y, fc_x + 7, fc_y - w_r + 2], fill=C_HIGHLIGHT, outline=C_DARKEST)
    draw.line([(fc_x - 7, crown_y), (fc_x + 7, crown_y)], fill=C_WHITE, width=2)
    draw.ellipse([fc_x - 12, crown_y - 14, fc_x + 12, crown_y], outline=C_BRIGHT, width=3)

    # 3. John Rod's Chrome Finger (Enters dynamically from top-left)
    finger_joint1 = (40, 8)
    finger_joint2 = (100, 32)
    finger_tip = (fc_x - 1, crown_y - 1)
    
    draw.line([finger_joint1, finger_joint2], fill=C_STEEL_DARK, width=6)
    draw.line([finger_joint1, finger_joint2], fill=C_STEEL_MID, width=4)
    draw.line([finger_joint1, finger_joint2], fill=C_STEEL_WHITE, width=2)
    
    draw.line([finger_joint2, finger_tip], fill=C_STEEL_DARK, width=6)
    draw.line([finger_joint2, finger_tip], fill=C_STEEL_BRIGHT, width=4)
    draw.line([finger_joint2, finger_tip], fill=C_STEEL_WHITE, width=2)
    
    draw.ellipse([finger_joint2[0] - 5, finger_joint2[1] - 5, finger_joint2[0] + 5, finger_joint2[1] + 5],
                 fill=C_STEEL_BRIGHT, outline=C_STEEL_DARK)
    draw.ellipse([finger_tip[0] - 5, finger_tip[1] - 5, finger_tip[0] + 5, finger_tip[1] + 5], fill=C_STEEL_WHITE)

    # 4. THE REALITY FRACTURE (Cosmic Lightning & Space Cracks)
    contact_x, contact_y = finger_tip[0], finger_tip[1]
    
    draw.ellipse([contact_x - 12, contact_y - 12, contact_x + 12, contact_y + 12], fill=C_WHITE)
    draw.ellipse([contact_x - 7, contact_y - 7, contact_x + 7, contact_y + 7], fill=C_COSMIC_CYAN_LIGHT)
    draw.point((contact_x, contact_y), fill=C_WHITE)

    rng_bolt = random.Random(111)
    angles = [25, 75, 130, 195, 240, 290, 340]
    for ang in angles:
        bx, by = contact_x, contact_y
        rad = math.radians(ang)
        for seg in range(6):
            step = rng_bolt.randint(15, 30)
            cur_rad = rad + rng_bolt.uniform(-0.35, 0.35)
            nx = int(bx + step * math.cos(cur_rad))
            ny = int(by + step * math.sin(cur_rad))
            draw.line([(bx, by), (nx, ny)], fill=C_COSMIC_CYAN, width=3)
            draw.line([(bx, by), (nx, ny)], fill=C_STEEL_WHITE, width=1)
            
            if rng_bolt.random() < 0.45:
                sub_rad = cur_rad + rng_bolt.choice([-0.7, 0.7])
                sub_nx = int(nx + (step * 0.7) * math.cos(sub_rad))
                sub_ny = int(ny + (step * 0.7) * math.sin(sub_rad))
                draw.line([(nx, ny), (sub_nx, sub_ny)], fill=C_COSMIC_CYAN, width=2)
                draw.line([(nx, ny), (sub_nx, sub_ny)], fill=C_STEEL_WHITE, width=1)
                
            bx, by = nx, ny

    for r in [28, 55, 90, 130]:
        for a in range(0, 360, 8):
            rad = math.radians(a)
            sx = int(contact_x + r * math.cos(rad))
            sy = int(contact_y + r * math.sin(rad))
            if 0 <= sx < W and 0 <= sy < H:
                if (a // 8) % 3 != 0:
                    draw.point((sx, sy), fill=C_COSMIC_CYAN if r > 60 else C_WHITE)

    for _ in range(80):
        sx = contact_x + rng_bolt.randint(-120, 120)
        sy = contact_y + rng_bolt.randint(-70, 100)
        if 0 <= sx < W and 0 <= sy < H:
            draw.point((sx, sy), fill=C_WHITE if rng_bolt.random() < 0.5 else C_COSMIC_GOLD)

    return p4


# =========================================================================
# PANEL 5: The Collapse & Plunge
# =========================================================================
def generate_panel_5():
    ut58 = Image.open(os.path.join(SCRATCH, "ut_box_58.png"))
    crop = ut58.crop((0, 0, 300, 165)).copy()
    px = crop.load()
    orig_px = ut58.crop((0, 0, 300, 165)).load()
    
    # Cleanly restore vertical rock strata where Frisk fell
    for y in range(80, 130):
        for x in range(105, 145):
            src_x = min(285, x + 50)
            px[x, y] = orig_px[src_x, y]

    draw = ImageDraw.Draw(crop)
    
    # Upward rushing wind & speed streak lines along cavern rock walls
    rng_speed = random.Random(77)
    for sx in [45, 70, 95, 165, 210, 245]:
        sy = rng_speed.randint(20, 60)
        sl = rng_speed.randint(35, 75)
        draw.line([(sx, sy), (sx, sy + sl)], fill=C_SHADOW, width=1)
        draw.line([(sx, sy + sl // 3), (sx, sy + sl)], fill=C_MID_WARM, width=1)

    # Tumbling Broken Stone Floor Masonry Blocks with realistic 3D facets
    # Block 1 (Large tumbled tile): top sunlit face, shaded side
    b1_top = [(72, 134), (105, 120), (115, 135), (82, 148)]
    b1_side = [(82, 148), (115, 135), (111, 146), (78, 158)]
    draw.polygon(b1_top, fill=C_MID_WARM, outline=C_HIGHLIGHT)
    draw.polygon(b1_side, fill=C_DARKEST, outline=C_SHADOW)
    draw.line([(88, 128), (95, 142)], fill=C_DARKEST, width=1) # Crack

    # Block 2 (Middle crumbling chunk)
    b2_top = [(186, 94), (212, 85), (217, 98), (191, 107)]
    b2_side = [(191, 107), (217, 98), (214, 108), (188, 116)]
    draw.polygon(b2_top, fill=C_HIGHLIGHT, outline=C_BRIGHT)
    draw.polygon(b2_side, fill=C_MID_DARK, outline=C_DARKEST)

    # Block 3 (Small stone fragment)
    draw.polygon([(128, 40), (145, 34), (150, 48), (133, 54)], fill=C_HIGHLIGHT, outline=C_WHITE)

    # Tumbling Brass Lantern
    lx, ly = 185, 115
    draw_brass_lantern(draw, lx, ly, scale=0.9, glow=True)
    for a in range(-60, 140, 25):
        rad = math.radians(a)
        ex = int(lx + 20 * math.cos(rad))
        ey = int(ly + 20 * math.sin(rad))
        draw.point((ex, ey), fill=C_WHITE if a % 50 == 0 else C_BRIGHT)

    # John Rod Falling Dynamically into the Abyss
    jx, jy = 135, 90
    
    # "Dimensional Unraveling" Echo Afterimages
    # Far echo (gold)
    draw_wireframe_john_rod_art(draw, jx + 10, jy - 20, scale=1.02, pose="fall", lantern=False, light_dir=(0, 1))
    for ey in range(jy - 50, jy + 15):
        for ex in range(jx - 20, jx + 40):
            if 0 <= ex < crop.width and 0 <= ey < crop.height:
                if (ex + ey) % 2 == 0 and px[ex, ey] == C_STEEL_WHITE:
                    px[ex, ey] = C_HIGHLIGHT

    # Near echo (cyan)
    draw_wireframe_john_rod_art(draw, jx + 5, jy - 10, scale=1.06, pose="fall", lantern=False, light_dir=(0, 1))
    for ey in range(jy - 40, jy + 25):
        for ex in range(jx - 25, jx + 35):
            if 0 <= ex < crop.width and 0 <= ey < crop.height:
                if (ex + ey) % 2 == 0 and px[ex, ey] == C_STEEL_WHITE:
                    px[ex, ey] = C_COSMIC_CYAN

    # Main Falling Figure
    draw_wireframe_john_rod_art(draw, jx, jy, scale=1.1, pose="fall", lantern=False, light_dir=(0, -1))

    # Fit into 320x180 canvas
    p5 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p5.paste(crop, (cx_off, cy_off))
    
    d5 = ImageDraw.Draw(p5)
    d5.rectangle([0, 0, cx_off, H], fill=C_VOID)
    d5.rectangle([cx_off + crop.width, 0, W, H], fill=C_VOID)
    d5.rectangle([0, 0, W, cy_off], fill=C_VOID)
    d5.rectangle([0, cy_off + crop.height, W, H], fill=C_VOID)

    return p5


# =========================================================================
# PANEL 6: Awakening as a 0D Point in the Ruins
# =========================================================================
def generate_panel_6():
    ut65 = Image.open(os.path.join(SCRATCH, "ut_box_65.png"))
    crop = ut65.crop((0, 0, 300, 165)).copy()
    
    # 1. Seamlessly restore the floor (ZERO trace of Frisk, ZERO seams!)
    restore_ut65_floor_seamlessly(crop)
    
    draw = ImageDraw.Draw(crop)
    px = crop.load()
    
    # 2. Celestial shaft of light descending between ruined pillars
    spot_cx, spot_cy = 138, 124
    for y in range(0, 125):
        t = y / 125.0
        lx_cone = int(105 - (1 - t) * 10 + t * 5)
        rx_cone = int(145 + (1 - t) * 5 + t * 25)
        for x in range(lx_cone, rx_cone):
            if (x * 3 + y * 2) % 4 == 0:
                cur = px[x, y]
                if cur in (C_VOID, C_DARKEST, C_SHADOW):
                    px[x, y] = C_MID_WARM if t < 0.4 else C_HIGHLIGHT
                elif cur == C_MID_DARK:
                    px[x, y] = C_HIGHLIGHT

    # Soft golden petal ripples around impact center
    draw.ellipse([spot_cx - 24, spot_cy - 12, spot_cx + 24, spot_cy + 12], outline=C_MID_WARM, width=1)
    rng_petals = random.Random(123)
    for _ in range(16):
        px_p = spot_cx + rng_petals.randint(-32, 32)
        py_p = spot_cy + rng_petals.randint(-18, 16)
        draw.point((px_p, py_p), fill=C_BRIGHT if rng_petals.random() < 0.5 else C_WHITE)

    # 3. Concentric Dimensional Ripple Rings
    for rip_r in [18, 36, 56, 78]:
        ry_scale = rip_r * 0.42
        for a in range(0, 360, 6):
            if (a // 6) % 2 == 0:
                rad = math.radians(a)
                rx = int(spot_cx + rip_r * math.cos(rad))
                ry = int(spot_cy + ry_scale * math.sin(rad))
                if 0 <= rx < crop.width and 0 <= ry < crop.height:
                    draw.point((rx, ry), fill=C_BRIGHT if rip_r < 40 else C_HIGHLIGHT)

    # 4. The 0D Point Core (Gleaming polished neutral chrome metallic bead)
    bead_r = 5
    draw.ellipse([spot_cx - bead_r, spot_cy - bead_r, spot_cx + bead_r, spot_cy + bead_r],
                 fill=C_STEEL_MID, outline=C_STEEL_DARK)
    draw.ellipse([spot_cx - bead_r + 1, spot_cy - bead_r + 1, spot_cx + bead_r - 1, spot_cy + bead_r - 1],
                 fill=C_STEEL_BRIGHT)
    draw.ellipse([spot_cx - 3, spot_cy - 3, spot_cx, spot_cy], fill=C_STEEL_WHITE)
    draw.point((spot_cx - 2, spot_cy - 2), fill=C_STEEL_WHITE)

    # Radiant 4-Point Specular Star Glint
    glint_len = 10
    draw.line([(spot_cx - glint_len, spot_cy), (spot_cx + glint_len, spot_cy)], fill=C_WHITE, width=1)
    draw.line([(spot_cx, spot_cy - glint_len), (spot_cx, spot_cy + glint_len)], fill=C_WHITE, width=1)
    draw.line([(spot_cx - 4, spot_cy - 4), (spot_cx + 4, spot_cy + 4)], fill=C_WHITE, width=1)
    draw.line([(spot_cx - 4, spot_cy + 4), (spot_cx + 4, spot_cy - 4)], fill=C_WHITE, width=1)

    # Golden chronos-dust motes in light beam
    rng_motes = random.Random(888)
    for _ in range(35):
        mx = spot_cx + rng_motes.randint(-35, 35)
        my = spot_cy + rng_motes.randint(-65, 8)
        if 0 <= mx < crop.width and 0 <= my < crop.height:
            crop.putpixel((mx, my), C_WHITE if rng_motes.random() < 0.6 else C_BRIGHT)

    # Dented brass lantern resting extinguished in shadows on the left
    lx, ly = 72, 138
    draw.ellipse([lx - 8, ly + 2, lx + 8, ly + 6], fill=C_DARKEST)
    draw.polygon([(lx - 5, ly), (lx + 5, ly), (lx + 4, ly - 4), (lx - 4, ly - 4)], fill=C_MID_DARK)
    draw.rectangle([lx - 4, ly - 4, lx + 4, ly + 2], fill=C_MID_WARM, outline=C_DARKEST)
    draw.ellipse([lx - 2, ly - 6, lx + 2, ly - 4], outline=C_HIGHLIGHT)

    # Fit into 320x180 canvas
    p6 = Image.new("RGB", (W, H), C_VOID)
    cx_off = (W - crop.width) // 2
    cy_off = (H - crop.height) // 2
    p6.paste(crop, (cx_off, cy_off))
    
    d6 = ImageDraw.Draw(p6)
    d6.rectangle([0, 0, cx_off, H], fill=C_VOID)
    d6.rectangle([cx_off + crop.width, 0, W, H], fill=C_VOID)
    d6.rectangle([0, 0, W, cy_off], fill=C_VOID)
    d6.rectangle([0, cy_off + crop.height, W, H], fill=C_VOID)

    return p6


# =========================================================================
# Main Execution Pipeline
# =========================================================================
def main():
    panels = [
        ("intro_panel_1.png", generate_panel_1),
        ("intro_panel_2.png", generate_panel_2),
        ("intro_panel_3.png", generate_panel_3),
        ("intro_panel_4.png", generate_panel_4),
        ("intro_panel_5.png", generate_panel_5),
        ("intro_panel_6.png", generate_panel_6),
    ]
    
    out_dir = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\intro"
    os.makedirs(out_dir, exist_ok=True)
    
    for filename, gen_fn in panels:
        img_native = gen_fn()
        img_scaled = img_native.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
        path = os.path.join(out_dir, filename)
        img_scaled.save(path, "PNG")
        print(f"Masterfully rendered {filename} at {img_scaled.size} (2x crisp pixel scale)")

if __name__ == "__main__":
    main()
