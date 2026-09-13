import math
import random
import os
from PIL import Image, ImageDraw

# Target native retro resolution (16:9)
W, H = 320, 180
SCALE = 2  # Scaled to 640x360 with nearest neighbor for crisp pixel clarity

# Authentic Undertale warm sepia/amber palette:
C_VOID = (20, 10, 3)          # #140a03 Deep cavern shadow/black
C_DARKEST = (44, 21, 6)       # #2c1506 Outline / dark shadow
C_SHADOW = (73, 39, 9)        # #492709 Deep shadow brown
C_MID_DARK = (99, 48, 20)     # #633014 Mid-dark brown
C_MID_WARM = (133, 73, 30)    # #85491e Warm caramel amber
C_LIGHT_BASE = (190, 130, 39) # #be8227 Undertale iconic Sky / Base Amber
C_HIGHLIGHT = (228, 175, 76)  # #e4af4c Warm pale gold highlight
C_BRIGHT = (248, 222, 140)    # #f8de8c Glistening light / spark / star
C_WHITE = (255, 248, 220)     # #fff8dc Pure specular glint

# John Rod metallic wireframe palette (Neutral polished chrome/steel):
C_STEEL_WHITE = (255, 255, 255)
C_STEEL_LIGHT = (225, 225, 230)
C_STEEL_MID = (160, 165, 175)
C_STEEL_DARK = (80, 85, 95)

# Dimensional glow accents:
C_COSMIC_CYAN = (120, 235, 255)
C_COSMIC_PURPLE = (200, 140, 255)

BAYER_4X4 = [
    [ 0,  8,  2, 10],
    [12,  4, 14,  6],
    [ 3, 11,  1,  9],
    [15,  7, 13,  5]
]

def add_dither_transition(draw, x0, y0, x1, y1, c1, c2, direction="horizontal"):
    """Adds a controlled 4x4 Bayer dither transition between two colors."""
    dx = x1 - x0
    dy = y1 - y0
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if direction == "horizontal":
                t = (x - x0) / max(1, dx)
            elif direction == "vertical":
                t = (y - y0) / max(1, dy)
            elif direction == "radial":
                cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
                dist = math.hypot(x - cx, y - cy)
                max_d = max(dx, dy) / 2
                t = min(1.0, dist / max(1, max_d))
            threshold = BAYER_4X4[y % 4][x % 4] / 16.0
            col = c2 if t > threshold else c1
            draw.point((x, y), fill=col)

def add_stippled_noise(draw, x0, y0, x1, y1, col, density=0.08, cluster=False):
    """Undertale-style scattered pixel speckling for ground, foliage, and stone."""
    rng = random.Random(x0 * 31 + y0 * 17)
    area = (x1 - x0) * (y1 - y0)
    count = int(area * density)
    for _ in range(count):
        px = rng.randint(x0, x1)
        py = rng.randint(y0, y1)
        draw.point((px, py), fill=col)
        if cluster and rng.random() < 0.4:
            draw.point((px + rng.choice([-1, 1]), py), fill=col)
            if rng.random() < 0.3:
                draw.point((px, py + rng.choice([-1, 1])), fill=col)

def draw_wireframe_john_rod(draw, cx, cy, scale=1.0, pose="stand", lantern=True):
    """Draws authentic John Rod wireframe stickman with hollow loop head, angular joints, and bent sliding feet."""
    s = scale
    head_r = int(7 * s)
    head_cy = int(cy - 22 * s)
    
    # Outer head ring (metallic highlight on top, shadow on bottom)
    for a in range(0, 360, 10):
        rad = math.radians(a)
        px = int(cx + head_r * math.cos(rad))
        py = int(head_cy + head_r * math.sin(rad))
        col = C_STEEL_WHITE if a > 200 and a < 340 else C_STEEL_LIGHT
        draw.point((px, py), fill=col)
        draw.point((px + 1, py), fill=col)
    
    # Neck & Spine
    neck_y = head_cy + head_r
    spine_len = int(14 * s)
    hip_y = neck_y + spine_len
    draw.line([(cx, neck_y), (cx, hip_y)], fill=C_STEEL_WHITE, width=2)
    
    # Legs with 90-degree bent sliding feet
    leg_len = int(16 * s)
    foot_len = int(8 * s)
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
        # Flailing legs
        draw.line([(cx, hip_y), (cx - int(8 * s), hip_y + int(12 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(8 * s), hip_y + int(12 * s)), (cx - int(14 * s), hip_y + int(8 * s))], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, hip_y), (cx + int(6 * s), hip_y + int(14 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(6 * s), hip_y + int(14 * s)), (cx + int(13 * s), hip_y + int(12 * s))], fill=C_STEEL_WHITE, width=2)

    elif pose == "reach":
        # Reaching towards dais
        draw.line([(cx, hip_y), (cx - int(3 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(3 * s), foot_y), (cx - int(3 * s) - foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)
        draw.line([(cx, hip_y), (cx + int(5 * s), foot_y)], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(5 * s), foot_y), (cx + int(5 * s) + foot_len, foot_y)], fill=C_STEEL_WHITE, width=2)

    # Arms
    shoulder_y = neck_y + int(3 * s)
    if pose == "stand" or pose == "walk":
        # Left arm bent
        draw.line([(cx, shoulder_y), (cx - int(7 * s), shoulder_y + int(7 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(7 * s), shoulder_y + int(7 * s)), (cx - int(5 * s), shoulder_y + int(13 * s))], fill=C_STEEL_WHITE, width=2)
        # Right arm holding lantern
        lantern_x = cx + int(12 * s)
        lantern_y = shoulder_y + int(11 * s)
        draw.line([(cx, shoulder_y), (cx + int(8 * s), shoulder_y + int(4 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(8 * s), shoulder_y + int(4 * s)), (lantern_x, lantern_y)], fill=C_STEEL_WHITE, width=2)
        
        if lantern:
            draw_vintage_lantern(draw, lantern_x, lantern_y + int(2 * s), scale=s)
            
    elif pose == "reach":
        # Reaching forward and upward towards artifact
        draw.line([(cx, shoulder_y), (cx + int(10 * s), shoulder_y - int(4 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx + int(10 * s), shoulder_y - int(4 * s)), (cx + int(18 * s), shoulder_y - int(10 * s))], fill=C_STEEL_WHITE, width=2)
        # Left arm balance
        draw.line([(cx, shoulder_y), (cx - int(8 * s), shoulder_y + int(6 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx - int(8 * s), shoulder_y + int(6 * s)), (cx - int(10 * s), shoulder_y + int(12 * s))], fill=C_STEEL_WHITE, width=2)
        
    elif pose == "fall":
        # Arms flailing upward
        draw.line([(cx, shoulder_y), (cx - int(12 * s), shoulder_y - int(10 * s))], fill=C_STEEL_LIGHT, width=2)
        draw.line([(cx, shoulder_y), (cx + int(14 * s), shoulder_y - int(12 * s))], fill=C_STEEL_WHITE, width=2)

def draw_vintage_lantern(draw, lx, ly, scale=1.0):
    """Draws a brass explorer lantern with radiant radial glow."""
    s = scale
    lw = max(3, int(4 * s))
    lh = max(5, int(7 * s))
    
    # Lantern housing
    draw.rectangle([lx - lw, ly, lx + lw, ly + lh], fill=C_DARKEST, outline=C_MID_WARM)
    draw.rectangle([lx - lw + 1, ly + 1, lx + lw - 1, ly + lh - 1], fill=C_BRIGHT)
    draw.point((lx, ly + lh // 2), fill=C_WHITE)
    # Lantern cap and handle loop
    draw.line([(lx - lw - 1, ly), (lx + lw + 1, ly)], fill=C_HIGHLIGHT, width=1)
    draw.line([(lx, ly - int(3 * s)), (lx, ly)], fill=C_MID_WARM, width=1)
    
    # Radiant glow dither rings
    for r, col in [(int(12 * s), C_HIGHLIGHT), (int(22 * s), C_LIGHT_BASE), (int(35 * s), C_MID_WARM)]:
        for a in range(0, 360, 18):
            rad = math.radians(a)
            gx = int(lx + r * math.cos(rad))
            gy = int(ly + lh // 2 + r * math.sin(rad))
            if 0 <= gx < W and 0 <= gy < H:
                if BAYER_4X4[gy % 4][gx % 4] > 6:
                    draw.point((gx, gy), fill=col)

def generate_panel_1():
    """Panel 1: Mt. Dimensional (Authentic Undertale Mt. Ebott style)."""
    img = Image.new("RGB", (W, H), C_LIGHT_BASE)
    draw = ImageDraw.Draw(img)
    
    # 1. Sky: Solid Undertale amber (#be8227) with light horizon band
    draw.rectangle([0, 0, W, 70], fill=C_LIGHT_BASE)
    for y in range(40, 75):
        # Subtle light horizon glow
        for x in range(W):
            if (x + y) % 3 == 0 and y > 50:
                draw.point((x, y), fill=C_HIGHLIGHT)

    # Floating Dimensional Geometric Artifact (Tesseract ring in sky)
    t_cx, t_cy = 160, 32
    # Outer square tilted 45 deg
    pts_outer = [(t_cx, t_cy - 16), (t_cx + 20, t_cy), (t_cx, t_cy + 16), (t_cx - 20, t_cy)]
    draw.polygon(pts_outer, outline=C_HIGHLIGHT)
    pts_inner = [(t_cx, t_cy - 9), (t_cx + 11, t_cy), (t_cx, t_cy + 9), (t_cx - 11, t_cy)]
    draw.polygon(pts_inner, outline=C_BRIGHT)
    for p1, p2 in zip(pts_outer, pts_inner):
        draw.line([p1, p2], fill=C_WHITE, width=1)
    # Radiating halo speckles
    add_stippled_noise(draw, t_cx - 30, t_cy - 22, t_cx + 30, t_cy + 22, C_WHITE, density=0.04)

    # 2. Background Towering Mountain: Mt. Dimensional
    # Defined with organic rock ridges and facets (Undertale style)
    # Left face (sunlit) vs Right face (shadow)
    peak_x, peak_y = 160, 48
    
    # Main mountain mass
    mountain_poly = [
        (40, 140), (80, 110), (120, 85), (peak_x, peak_y),
        (190, 72), (230, 95), (280, 140), (320, 145), (320, 180), (0, 180), (0, 140)
    ]
    draw.polygon(mountain_poly, fill=C_MID_DARK)
    
    # Left sunlit ridge facets
    sunlit_facet = [
        (peak_x, peak_y), (145, 68), (120, 85), (105, 100), (80, 110),
        (95, 130), (130, 130), (150, 110), (peak_x, 90)
    ]
    draw.polygon(sunlit_facet, fill=C_MID_WARM)
    
    # Sharp sunlit spine highlight
    spine_pts = [(peak_x, peak_y), (155, 65), (150, 80), (142, 95), (130, 115), (115, 135)]
    draw.line(spine_pts, fill=C_LIGHT_BASE, width=2)
    draw.line([(peak_x, peak_y), (155, 65)], fill=C_HIGHLIGHT, width=2)
    
    # Deep shadow gullies on right face
    gully_1 = [(peak_x, peak_y), (168, 62), (180, 85), (175, 115), (160, 135)]
    draw.line(gully_1, fill=C_SHADOW, width=3)
    gully_2 = [(190, 72), (205, 90), (210, 120)]
    draw.line(gully_2, fill=C_SHADOW, width=2)
    
    # Rock texture stippling across mountain
    add_stippled_noise(draw, 70, 75, 250, 135, C_DARKEST, density=0.06, cluster=True)
    add_stippled_noise(draw, 100, 60, 160, 110, C_HIGHLIGHT, density=0.04)

    # 3. Midground Rolling Foothills & Rock Ridges
    foothills = [
        (0, 130), (50, 122), (110, 128), (170, 118), (220, 124), (270, 116), (320, 122),
        (320, 180), (0, 180)
    ]
    draw.polygon(foothills, fill=C_SHADOW)
    # Stippled rock slope
    for y in range(120, 145):
        for x in range(W):
            if (x * 7 + y * 13) % 17 == 0 and y < 140:
                draw.point((x, y), fill=C_MID_WARM)

    # 4. Foreground Dark Pine Tree Silhouettes (Exact Undertale forest framing)
    # Draws dense jagged pine forest across bottom in C_DARKEST
    trees_y = 135
    for x in range(0, W, 4):
        # Varying tree heights with organic noise
        h_noise = int(math.sin(x * 0.15) * 8 + math.cos(x * 0.3) * 6 + (x % 7) * 2)
        th = 20 + h_noise
        tip_y = trees_y - th
        # Pine tree triangle
        draw.polygon([(x, tip_y), (x - 5, 180), (x + 5, 180)], fill=C_DARKEST)
        # Foliage needles speckling on tips
        if x % 8 == 0:
            draw.point((x, tip_y), fill=C_SHADOW)
            draw.point((x - 1, tip_y + 2), fill=C_SHADOW)
            draw.point((x + 1, tip_y + 2), fill=C_SHADOW)
            
    # Bottom solid framing bar
    draw.rectangle([0, 168, W, 180], fill=C_VOID)
    
    return img

def generate_panel_2():
    """Panel 2: John Rod Approaching the Dark Cavern (Undertale ut_frame_38 style)."""
    img = Image.new("RGB", (W, H), C_LIGHT_BASE)
    draw = ImageDraw.Draw(img)
    
    # 1. Background Cliff Face with Massive Arching Cave Mouth
    draw.rectangle([0, 0, W, H], fill=C_MID_DARK)
    
    # Cave entrance (Yawning dark archway)
    cave_cx, cave_cy = 160, 95
    cave_rx, cave_ry = 55, 65
    
    # Deep void inside cave
    cave_box = [cave_cx - cave_rx, cave_cy - cave_ry, cave_cx + cave_rx, cave_cy + cave_ry]
    draw.ellipse(cave_box, fill=C_VOID)
    draw.rectangle([cave_cx - cave_rx, cave_cy, cave_cx + cave_rx, H], fill=C_VOID)
    
    # Jagged rock overhangs & stalactites framing cave mouth
    for a in range(180, 360, 6):
        rad = math.radians(a)
        rx = cave_rx + int(math.sin(a * 4) * 6)
        ry = cave_ry + int(math.cos(a * 5) * 5)
        px = int(cave_cx + rx * math.cos(rad))
        py = int(cave_cy + ry * math.sin(rad))
        draw.line([(px, py), (px, py + random.randint(4, 12))], fill=C_DARKEST, width=2)
        draw.point((px, py), fill=C_MID_WARM) # edge highlight
        
    # Stalactites hanging from cave ceiling
    for sx in [cave_cx - 35, cave_cx - 15, cave_cx + 10, cave_cx + 30]:
        sh = random.randint(12, 22)
        draw.polygon([(sx, cave_cy - cave_ry + 10), (sx - 4, cave_cy - cave_ry + 10), (sx, cave_cy - cave_ry + 10 + sh)], fill=C_SHADOW)
        draw.line([(sx, cave_cy - cave_ry + 10), (sx, cave_cy - cave_ry + 10 + sh)], fill=C_MID_DARK, width=1)

    # 2. Forest Floor & Pathway Leading into Cave
    ground_y = 120
    path_poly = [
        (cave_cx - 40, ground_y), (cave_cx + 40, ground_y),
        (W - 20, H), (20, H)
    ]
    draw.polygon(path_poly, fill=C_LIGHT_BASE)
    
    # Undertale-style stippled noise on ground (grass blades, fallen leaves, pebble stipples)
    add_stippled_noise(draw, 20, ground_y, W - 20, H, C_MID_WARM, density=0.12, cluster=True)
    add_stippled_noise(draw, 30, ground_y + 10, W - 30, H, C_SHADOW, density=0.06, cluster=True)
    add_stippled_noise(draw, 40, ground_y + 15, W - 40, H - 10, C_HIGHLIGHT, density=0.04)

    # 3. Foreground Gnarled Ancient Trees Framing Left & Right (Rule of Framing!)
    # Left massive tree trunk
    draw.polygon([(0, 0), (32, 0), (24, 60), (38, 120), (55, H), (0, H)], fill=C_DARKEST)
    # Left tree bark texture & twisting roots
    draw.line([(8, 0), (12, 70), (22, 140), (45, H)], fill=C_SHADOW, width=2)
    draw.line([(20, 20), (22, 90), (32, 160)], fill=C_MID_DARK, width=1)
    
    # Right massive tree trunk
    draw.polygon([(W, 0), (W - 28, 0), (W - 22, 50), (W - 35, 110), (W - 50, H), (W, H)], fill=C_DARKEST)
    # Right tree bark texture
    draw.line([(W - 10, 0), (W - 15, 60), (W - 22, 130), (W - 40, H)], fill=C_SHADOW, width=2)
    
    # Hanging leaf canopy / creeping ivy vines across top
    for x in range(0, W, 8):
        vy = int(math.sin(x * 0.2) * 10 + 15)
        draw.line([(x, 0), (x, vy)], fill=C_SHADOW, width=2)
        # Leaves on vines
        draw.rectangle([x - 2, vy - 2, x + 2, vy + 2], fill=C_DARKEST)
        draw.point((x, vy), fill=C_MID_WARM)

    # 4. John Rod Walking Towards Cave with Lantern
    jr_x, jr_y = 145, 135
    # Cast shadow under feet
    draw.ellipse([jr_x - 14, jr_y - 2, jr_x + 18, jr_y + 5], fill=C_SHADOW)
    draw_wireframe_john_rod(draw, jr_x, jr_y, scale=1.1, pose="walk", lantern=True)
    
    # Surrounding cavern rim shadow
    add_stippled_noise(draw, 0, 0, W, 40, C_VOID, density=0.15)
    
    return img

def generate_panel_3():
    """Panel 3: The Sanctuary Dais & The Ancient Watch (Undertale Ruins/Pillars style)."""
    img = Image.new("RGB", (W, H), C_VOID)
    draw = ImageDraw.Draw(img)
    
    # 1. Distant Vaulted Chamber Wall with Carved Masonry
    for y in range(0, 110, 14):
        draw.line([(0, y), (W, y)], fill=C_DARKEST, width=1)
        shift = 15 if (y // 14) % 2 == 1 else 0
        for x in range(shift, W, 30):
            draw.line([(x, y), (x, y + 14)], fill=C_DARKEST, width=1)

    # 2. Celestial Divine Light Beam Cutting Through Sanctuary
    # Slanted translucent light beam from upper-center to dais
    beam_top_x1, beam_top_x2 = 135, 175
    beam_bot_x1, beam_bot_x2 = 100, 215
    beam_poly = [(beam_top_x1, 0), (beam_top_x2, 0), (beam_bot_x2, 160), (beam_bot_x1, 160)]
    
    # Fill beam with dithered warm highlight
    for y in range(0, 160):
        t = y / 160.0
        bx1 = int(beam_top_x1 + (beam_bot_x1 - beam_top_x1) * t)
        bx2 = int(beam_top_x2 + (beam_bot_x2 - beam_top_x2) * t)
        for x in range(bx1, bx2 + 1):
            edge_dist = min(x - bx1, bx2 - x)
            if edge_dist < 6:
                if BAYER_4X4[y % 4][x % 4] > 8:
                    draw.point((x, y), fill=C_MID_WARM)
            else:
                if BAYER_4X4[y % 4][x % 4] > 4:
                    draw.point((x, y), fill=C_LIGHT_BASE)
                else:
                    draw.point((x, y), fill=C_HIGHLIGHT)

    # 3. Fluted Ancient Classical Pillars on Left & Right (Undertale Ruins style)
    # Left Pillar
    lp_x = 35
    draw.rectangle([lp_x - 14, 0, lp_x + 14, 150], fill=C_SHADOW)
    draw.rectangle([lp_x - 18, 140, lp_x + 18, 155], fill=C_MID_DARK) # Capital base
    draw.rectangle([lp_x - 20, 150, lp_x + 20, 165], fill=C_DARKEST)
    # Fluting vertical grooves
    for gx in [lp_x - 8, lp_x, lp_x + 8]:
        draw.line([(gx, 0), (gx, 140)], fill=C_MID_WARM, width=1)
        draw.line([(gx + 1, 0), (gx + 1, 140)], fill=C_DARKEST, width=1)
    # Climbing ivy and cracked fissures on left pillar
    draw.line([(lp_x - 6, 40), (lp_x + 2, 70), (lp_x - 4, 110)], fill=C_VOID, width=1)
    add_stippled_noise(draw, lp_x - 12, 30, lp_x + 12, 130, C_MID_DARK, density=0.15, cluster=True)
    
    # Right Pillar
    rp_x = W - 35
    draw.rectangle([rp_x - 14, 0, rp_x + 14, 150], fill=C_SHADOW)
    draw.rectangle([rp_x - 18, 140, rp_x + 18, 155], fill=C_MID_DARK)
    draw.rectangle([rp_x - 20, 150, rp_x + 20, 165], fill=C_DARKEST)
    for gx in [rp_x - 8, rp_x, rp_x + 8]:
        draw.line([(gx, 0), (gx, 140)], fill=C_MID_WARM, width=1)
        draw.line([(gx + 1, 0), (gx + 1, 140)], fill=C_DARKEST, width=1)
    draw.line([(rp_x + 5, 50), (rp_x - 3, 85), (rp_x + 4, 125)], fill=C_VOID, width=1)
    add_stippled_noise(draw, rp_x - 12, 40, rp_x + 12, 130, C_MID_DARK, density=0.15, cluster=True)

    # 4. Flagstone Floor with Perspective Grid & Cracks
    floor_y = 145
    draw.rectangle([0, floor_y, W, H], fill=C_DARKEST)
    # Grid lines converging towards vanishing point
    for gx in range(0, W + 40, 35):
        draw.line([(gx, floor_y), (gx * 1.3 - 40, H)], fill=C_SHADOW, width=1)
    for gy in [152, 162, 172]:
        draw.line([(0, gy), (W, gy)], fill=C_SHADOW, width=1)
    add_stippled_noise(draw, 0, floor_y, W, H, C_MID_WARM, density=0.08, cluster=True)

    # 5. The Sacred Dais (Altar Pedestal) in Center Light
    dais_cx = 158
    # Bottom stepped tier
    draw.polygon([(dais_cx - 45, 148), (dais_cx + 45, 148), (dais_cx + 52, 160), (dais_cx - 52, 160)], fill=C_MID_DARK)
    draw.line([(dais_cx - 45, 148), (dais_cx + 45, 148)], fill=C_HIGHLIGHT, width=2)
    # Middle tier
    draw.polygon([(dais_cx - 30, 132), (dais_cx + 30, 132), (dais_cx + 38, 148), (dais_cx - 38, 148)], fill=C_MID_WARM)
    draw.line([(dais_cx - 30, 132), (dais_cx + 30, 132)], fill=C_HIGHLIGHT, width=2)
    # Top Pedestal Pillar
    draw.polygon([(dais_cx - 18, 110), (dais_cx + 18, 110), (dais_cx + 22, 132), (dais_cx - 22, 132)], fill=C_LIGHT_BASE)
    draw.line([(dais_cx - 18, 110), (dais_cx + 18, 110)], fill=C_BRIGHT, width=2)

    # 6. The Ancient Chrono-Lens Watch Glowing Atop the Pedestal!
    watch_x, watch_y = dais_cx, 102
    # Glowing energy aura
    draw.ellipse([watch_x - 12, watch_y - 12, watch_x + 12, watch_y + 12], fill=C_HIGHLIGHT)
    # Watch circular brass case
    draw.ellipse([watch_x - 7, watch_y - 7, watch_x + 7, watch_y + 7], fill=C_DARKEST, outline=C_BRIGHT)
    # Watch dial face
    draw.ellipse([watch_x - 5, watch_y - 5, watch_x + 5, watch_y + 5], fill=C_WHITE)
    # Watch hands & crown loop
    draw.line([(watch_x, watch_y), (watch_x + 3, watch_y - 2)], fill=C_DARKEST, width=1)
    draw.line([(watch_x, watch_y), (watch_x - 1, watch_y + 3)], fill=C_DARKEST, width=1)
    draw.rectangle([watch_x - 2, watch_y - 10, watch_x + 2, watch_y - 7], fill=C_BRIGHT)
    
    # 4-Point Specular Star Glint on Watch
    glint_len = 10
    draw.line([(watch_x - glint_len, watch_y), (watch_x + glint_len, watch_y)], fill=C_WHITE, width=1)
    draw.line([(watch_x, watch_y - glint_len), (watch_x, watch_y + glint_len)], fill=C_WHITE, width=1)
    draw.point((watch_x, watch_y), fill=C_WHITE)

    # 7. John Rod Gazing in Awe at the Base of the Dais
    jr_x, jr_y = dais_cx - 50, 150
    # Cast shadow
    draw.ellipse([jr_x - 12, jr_y, jr_x + 15, jr_y + 4], fill=C_VOID)
    draw_wireframe_john_rod(draw, jr_x, jr_y, scale=1.0, pose="reach", lantern=False)
    # Lantern set down on ground beside him
    draw_vintage_lantern(draw, jr_x - 16, jr_y - 8, scale=0.9)

    return img

def generate_panel_4():
    """Panel 4: The Touch & Reality Fracture (Undertale macro close-up style)."""
    img = Image.new("RGB", (W, H), C_VOID)
    draw = ImageDraw.Draw(img)
    
    # 1. Background: Cracked Stone Pedestal surface under intense ambient glow
    draw.rectangle([0, 0, W, H], fill=C_DARKEST)
    
    # Radial glow from center
    fc_x, fc_y = 150, 85
    for r in range(120, 20, -10):
        t = r / 120.0
        col = C_SHADOW if t > 0.6 else C_MID_DARK
        draw.ellipse([fc_x - r, fc_y - r, fc_x + r, fc_y + r], fill=col)

    # 2. The Ancient Watch - Dramatic Macro Close-Up!
    w_r = 46
    # Outer brass casing rim with bevels
    draw.ellipse([fc_x - w_r, fc_y - w_r, fc_x + w_r, fc_y + w_r], fill=C_MID_WARM, outline=C_HIGHLIGHT, width=3)
    draw.ellipse([fc_x - w_r + 4, fc_y - w_r + 4, fc_x + w_r - 4, fc_y + w_r - 4], fill=C_DARKEST, outline=C_BRIGHT, width=2)
    
    # Inner Dial Face (Ivory / Pale Gold)
    dial_r = w_r - 8
    draw.ellipse([fc_x - dial_r, fc_y - dial_r, fc_x + dial_r, fc_y + dial_r], fill=C_HIGHLIGHT)
    
    # Concentric Dimensional Rings (0D point, 1D line, 2D triangle, 3D cube symbols)
    draw.ellipse([fc_x - 22, fc_y - 22, fc_x + 22, fc_y + 22], outline=C_MID_WARM, width=1)
    draw.ellipse([fc_x - 12, fc_y - 12, fc_x + 12, fc_y + 12], outline=C_DARKEST, width=1)
    # Roman numeral tick marks around perimeter
    for a in range(0, 360, 30):
        rad = math.radians(a)
        tx1 = int(fc_x + (dial_r - 3) * math.cos(rad))
        ty1 = int(fc_y + (dial_r - 3) * math.sin(rad))
        tx2 = int(fc_x + (dial_r - 7) * math.cos(rad))
        ty2 = int(fc_y + (dial_r - 7) * math.sin(rad))
        draw.line([(tx1, ty1), (tx2, ty2)], fill=C_DARKEST, width=2)

    # Intricate Clockwork Gear Teeth visible through crystal face
    draw.arc([fc_x - 18, fc_y - 18, fc_x + 18, fc_y + 18], 45, 270, fill=C_MID_DARK, width=3)
    # Watch Hands
    draw.line([(fc_x, fc_y), (fc_x + 16, fc_y - 14)], fill=C_DARKEST, width=3)
    draw.line([(fc_x, fc_y), (fc_x - 8, fc_y + 18)], fill=C_DARKEST, width=2)
    draw.ellipse([fc_x - 3, fc_y - 3, fc_x + 3, fc_y + 3], fill=C_BRIGHT)

    # Top Crown & Winding Loop
    crown_y = fc_y - w_r - 8
    draw.rectangle([fc_x - 5, crown_y, fc_x + 5, fc_y - w_r], fill=C_HIGHLIGHT, outline=C_DARKEST)
    draw.ellipse([fc_x - 9, crown_y - 12, fc_x + 9, crown_y], outline=C_BRIGHT, width=2)

    # 3. John Rod's Sleek Metallic Rod Finger Touching the Crown!
    # Finger entering from upper-left
    hand_pts = [(40, 10), (95, 35), (fc_x - 1, crown_y - 2)]
    draw.line(hand_pts, fill=C_STEEL_WHITE, width=4)
    # Metallic joint knuckles
    draw.ellipse([92, 32, 98, 38], fill=C_STEEL_LIGHT, outline=C_STEEL_DARK)
    draw.ellipse([fc_x - 4, crown_y - 5, fc_x + 2, crown_y + 1], fill=C_STEEL_WHITE)

    # 4. Reality Fracture / Dimensional Shatter Lightning!
    # Cosmic crack lines bursting outward from point of contact
    contact_x, contact_y = fc_x, crown_y
    # Central blinding burst
    draw.ellipse([contact_x - 8, contact_y - 8, contact_x + 8, contact_y + 8], fill=C_WHITE)
    
    # Branching geometric lightning cracks
    random.seed(42)
    for angle in [15, 65, 125, 190, 240, 310, 350]:
        rad = math.radians(angle)
        cur_x, cur_y = contact_x, contact_y
        for step in range(5):
            dist = random.randint(12, 25)
            w_angle = rad + random.uniform(-0.4, 0.4)
            nxt_x = int(cur_x + dist * math.cos(w_angle))
            nxt_y = int(cur_y + dist * math.sin(w_angle))
            # Crack line
            draw.line([(cur_x, cur_y), (nxt_x, nxt_y)], fill=C_WHITE, width=2)
            draw.line([(cur_x + 1, cur_y), (nxt_x + 1, nxt_y)], fill=C_COSMIC_CYAN, width=1)
            # Fracture sub-branch
            if step == 2 and random.random() < 0.7:
                bx = int(cur_x + dist * 0.7 * math.cos(w_angle + 0.8))
                by = int(cur_y + dist * 0.7 * math.sin(w_angle + 0.8))
                draw.line([(cur_x, cur_y), (bx, by)], fill=C_BRIGHT, width=1)
            cur_x, cur_y = nxt_x, nxt_y
            
    # Concentric space-distortion rings
    for dr in [25, 50, 80, 115]:
        draw.arc([contact_x - dr, contact_y - dr, contact_x + dr, contact_y + dr], 0, 360, fill=C_HIGHLIGHT, width=1)

    # Shattered pedestal stone cracks in lower corners
    draw.line([(0, 150), (60, 135), (90, 160)], fill=C_VOID, width=3)
    draw.line([(W, 145), (W - 70, 130), (W - 110, 155)], fill=C_VOID, width=3)
    add_stippled_noise(draw, 0, 120, W, H, C_MID_WARM, density=0.07)

    return img

def generate_panel_5():
    """Panel 5: The Collapse & The Fall into the Abyss (Undertale ut_frame_58 style)."""
    img = Image.new("RGB", (W, H), C_VOID)
    draw = ImageDraw.Draw(img)
    
    # 1. Light from the Shattered Sanctuary Ceiling Above
    # Radiant hole at top-center
    hole_cx, hole_cy = 160, -10
    hole_rx, hole_ry = 70, 35
    draw.ellipse([hole_cx - hole_rx, hole_cy - hole_ry, hole_cx + hole_rx, hole_cy + hole_ry], fill=C_LIGHT_BASE)
    draw.ellipse([hole_cx - hole_rx + 15, hole_cy - hole_ry + 8, hole_cx + hole_rx - 15, hole_cy + hole_ry - 8], fill=C_WHITE)
    
    # Vertical light shaft descending down the chasm
    beam_poly = [(hole_cx - 45, 0), (hole_cx + 45, 0), (hole_cx + 80, 140), (hole_cx - 80, 140)]
    for y in range(0, 140):
        t = y / 140.0
        bx1 = int((hole_cx - 45) * (1 - t) + (hole_cx - 80) * t)
        bx2 = int((hole_cx + 45) * (1 - t) + (hole_cx + 80) * t)
        for x in range(bx1, bx2):
            if BAYER_4X4[y % 4][x % 4] > (t * 14):
                draw.point((x, y), fill=C_MID_WARM if t > 0.4 else C_HIGHLIGHT)

    # 2. Vertical Cavern Cliff Walls on Left & Right with Rock Strata (Undertale style)
    # Left cliff face
    left_cliff = [(0, 0), (55, 0), (45, 45), (60, 90), (40, 140), (65, H), (0, H)]
    draw.polygon(left_cliff, fill=C_DARKEST)
    # Horizontal rock strata lines & highlights
    for cy in [25, 55, 85, 115, 150]:
        draw.line([(0, cy), (50, cy - 3)], fill=C_SHADOW, width=2)
        draw.line([(45, cy - 10), (55, cy - 8)], fill=C_MID_WARM, width=1)
    add_stippled_noise(draw, 0, 0, 50, H, C_MID_DARK, density=0.1, cluster=True)
    
    # Right cliff face
    right_cliff = [(W, 0), (W - 50, 0), (W - 60, 50), (W - 45, 100), (W - 65, 150), (W - 40, H), (W, H)]
    draw.polygon(right_cliff, fill=C_DARKEST)
    for cy in [30, 65, 105, 140]:
        draw.line([(W - 55, cy), (W, cy + 4)], fill=C_SHADOW, width=2)
        draw.line([(W - 50, cy - 8), (W - 40, cy - 6)], fill=C_MID_WARM, width=1)
    add_stippled_noise(draw, W - 55, 0, W, H, C_MID_DARK, density=0.1, cluster=True)

    # 3. Shattered Debris & Dais Stone Blocks Tumbling Down in Perspective
    # Large foreground block tumbling
    draw.polygon([(85, 130), (115, 120), (125, 142), (95, 152)], fill=C_MID_WARM, outline=C_HIGHLIGHT)
    draw.polygon([(95, 152), (125, 142), (120, 155), (90, 165)], fill=C_DARKEST)
    # Medium blocks
    draw.polygon([(200, 105), (220, 98), (225, 115), (205, 122)], fill=C_MID_DARK, outline=C_LIGHT_BASE)
    draw.polygon([(140, 35), (155, 30), (160, 42), (145, 47)], fill=C_HIGHLIGHT, outline=C_WHITE)
    # Small stone pebbles
    for px, py in [(120, 70), (190, 60), (135, 110), (175, 130), (105, 95)]:
        draw.rectangle([px, py, px + 3, py + 3], fill=C_BRIGHT)

    # 4. Tumbling Lantern Casting Spinning Spark Trails
    lt_x, lt_y = 205, 80
    draw_vintage_lantern(draw, lt_x, lt_y, scale=0.8)
    # Spinning spark arc
    for a in range(0, 270, 30):
        rad = math.radians(a)
        sx = int(lt_x + 14 * math.cos(rad))
        sy = int(lt_y + 14 * math.sin(rad))
        draw.point((sx, sy), fill=C_WHITE)

    # 5. Dynamic Vertical Speed Lines (Rushing Downward Motion)
    for lx in [75, 90, 125, 195, 230, 245]:
        sy = random.randint(20, 70)
        sl = random.randint(30, 60)
        draw.line([(lx, sy), (lx, sy + sl)], fill=C_SHADOW, width=1)
        if random.random() < 0.5:
            draw.line([(lx, sy + sl // 2), (lx, sy + sl)], fill=C_MID_WARM, width=1)

    # 6. John Rod Tumbling Backwards Down the Abyss!
    # Central dynamic falling pose
    jr_x, jr_y = 155, 78
    draw_wireframe_john_rod(draw, jr_x, jr_y, scale=1.1, pose="fall", lantern=False)
    
    # Motion blur / trailing dimensional echo behind John Rod
    draw.ellipse([jr_x - 6, jr_y - 30, jr_x + 6, jr_y - 20], outline=C_MID_WARM, width=1)

    # Deep abyss pitch black at bottom
    draw.rectangle([0, 165, W, H], fill=C_VOID)

    return img

def generate_panel_6():
    """Panel 6: The 0D Point Bead in the Subterranean Ruins (Undertale ut_frame_65 style)."""
    img = Image.new("RGB", (W, H), C_VOID)
    draw = ImageDraw.Draw(img)
    
    # 1. Dark Subterranean Ruins Background
    draw.rectangle([0, 0, W, H], fill=C_VOID)
    
    # 2. Broken Fallen Pillars & Ancient Architecture (Exact Undertale Ruins style)
    # Left toppled pillar drum
    draw.polygon([(25, 115), (75, 100), (90, 130), (40, 145)], fill=C_DARKEST, outline=C_SHADOW)
    draw.polygon([(25, 115), (40, 145), (32, 150), (18, 120)], fill=C_VOID)
    # Fluting lines on toppled pillar
    draw.line([(38, 112), (53, 142)], fill=C_MID_DARK, width=1)
    draw.line([(55, 107), (70, 137)], fill=C_MID_DARK, width=1)
    # Ivy tendrils climbing on left pillar
    draw.line([(30, 120), (45, 125), (60, 118)], fill=C_MID_WARM, width=1)
    add_stippled_noise(draw, 30, 110, 80, 140, C_SHADOW, density=0.15, cluster=True)
    
    # Right upright broken pillar stump
    rp_x = 265
    draw.rectangle([rp_x - 18, 85, rp_x + 18, 150], fill=C_DARKEST)
    draw.polygon([(rp_x - 20, 85), (rp_x + 20, 85), (rp_x + 15, 75), (rp_x - 15, 75)], fill=C_SHADOW)
    draw.line([(rp_x - 6, 85), (rp_x - 6, 150)], fill=C_MID_DARK, width=1)
    draw.line([(rp_x + 6, 85), (rp_x + 6, 150)], fill=C_MID_DARK, width=1)
    add_stippled_noise(draw, rp_x - 18, 85, rp_x + 18, 150, C_MID_WARM, density=0.1, cluster=True)

    # 3. Shaft of Faint Heavenly Light Striking Cavern Floor
    spot_cx, spot_cy = 160, 130
    spot_rx, spot_ry = 65, 30
    
    # Vertical faint light cone descending from ceiling
    beam_poly = [(150, 0), (170, 0), (spot_cx + spot_rx, spot_cy), (spot_cx - spot_rx, spot_cy)]
    for y in range(0, spot_cy):
        t = y / float(spot_cy)
        bx1 = int(150 * (1 - t) + (spot_cx - spot_rx) * t)
        bx2 = int(170 * (1 - t) + (spot_cx + spot_rx) * t)
        for x in range(bx1, bx2):
            if BAYER_4X4[y % 4][x % 4] > (15 - int(t * 10)):
                draw.point((x, y), fill=C_MID_WARM if t < 0.5 else C_LIGHT_BASE)

    # 4. Circular Sunlit Patch on Cavern Floor (Undertale Flower Bed / Ruins style)
    # Glowing pool of light
    draw.ellipse([spot_cx - spot_rx, spot_cy - spot_ry, spot_cx + spot_rx, spot_cy + spot_ry], fill=C_MID_WARM)
    draw.ellipse([spot_cx - spot_rx + 15, spot_cy - spot_ry + 8, spot_cx + spot_rx - 15, spot_cy + spot_ry - 8], fill=C_LIGHT_BASE)
    
    # Rich ground texture noise (Grass/moss stippling, stone fissures, scattered petals)
    add_stippled_noise(draw, spot_cx - spot_rx, spot_cy - spot_ry, spot_cx + spot_rx, spot_cy + spot_ry, C_HIGHLIGHT, density=0.14, cluster=True)
    add_stippled_noise(draw, spot_cx - spot_rx + 5, spot_cy - spot_ry + 3, spot_cx + spot_rx - 5, spot_cy + spot_ry - 3, C_BRIGHT, density=0.06)
    add_stippled_noise(draw, 10, 110, W - 10, H, C_DARKEST, density=0.08, cluster=True)

    # 5. Impact Fissures & Radial Waves
    # Cracked stone lines radiating from center
    draw.line([(spot_cx, spot_cy), (spot_cx - 28, spot_cy + 8)], fill=C_DARKEST, width=2)
    draw.line([(spot_cx, spot_cy), (spot_cx + 25, spot_cy + 6)], fill=C_DARKEST, width=2)
    draw.line([(spot_cx, spot_cy), (spot_cx - 10, spot_cy - 12)], fill=C_DARKEST, width=1)
    draw.line([(spot_cx, spot_cy), (spot_cx + 14, spot_cy - 10)], fill=C_DARKEST, width=1)

    # 6. Concentric Glowing Dimensional Ripple Rings Expanding from the 0D Core
    for rip_r in [12, 24, 38, 54]:
        ry_scale = rip_r * 0.45
        draw.ellipse([spot_cx - rip_r, spot_cy - ry_scale, spot_cx + rip_r, spot_cy + ry_scale], outline=C_HIGHLIGHT, width=1)

    # 7. The 0D Point Core (Gleaming Polished Metallic Chrome Bead)
    # Neutral steel chrome: Pure specular white center, chrome metallic ring, zero blue tint!
    bead_r = 4
    # Ambient glow
    draw.ellipse([spot_cx - bead_r - 2, spot_cy - bead_r - 2, spot_cx + bead_r + 2, spot_cy + bead_r + 2], fill=C_WHITE)
    # Steel bead body
    draw.ellipse([spot_cx - bead_r, spot_cy - bead_r, spot_cx + bead_r, spot_cy + bead_r], fill=C_STEEL_WHITE, outline=C_STEEL_MID)
    # Specular glint
    draw.point((spot_cx - 1, spot_cy - 1), fill=(255, 255, 255))
    
    # 4-point Specular Star Sparkle on the 0D point
    spk = 7
    draw.line([(spot_cx - spk, spot_cy), (spot_cx + spk, spot_cy)], fill=C_WHITE, width=1)
    draw.line([(spot_cx, spot_cy - spk), (spot_cx, spot_cy + spk)], fill=C_WHITE, width=1)

    # Floating motes of dimensional chronos-dust in the light beam
    random.seed(99)
    for _ in range(18):
        dx = random.randint(spot_cx - 30, spot_cx + 30)
        dy = random.randint(20, spot_cy - 5)
        draw.point((dx, dy), fill=C_WHITE if random.random() < 0.5 else C_BRIGHT)

    return img

def main():
    generators = [
        ("intro_panel_1.png", generate_panel_1),
        ("intro_panel_2.png", generate_panel_2),
        ("intro_panel_3.png", generate_panel_3),
        ("intro_panel_4.png", generate_panel_4),
        ("intro_panel_5.png", generate_panel_5),
        ("intro_panel_6.png", generate_panel_6),
    ]
    
    out_dir = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\intro"
    os.makedirs(out_dir, exist_ok=True)
    
    for filename, gen_fn in generators:
        img_native = gen_fn()
        # Scale 2x with NEAREST filter for crisp pixel art preservation
        img_scaled = img_native.resize((W * SCALE, H * SCALE), Image.Resampling.NEAREST)
        path = os.path.join(out_dir, filename)
        img_scaled.save(path, "PNG")
        print(f"Generated {filename}: {img_scaled.size}")

if __name__ == "__main__":
    main()
