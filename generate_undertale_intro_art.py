import math
import os
import random

from PIL import Image, ImageDraw

OUTPUT_DIR = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\intro"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# Native retro canvas resolution (16:9)
W, H = 480, 270

# Exact Undertale Sepia-Gold 7-step Palette
PALETTE = [
    (14, 9, 5),       # 0: Deepest Void / Near Black
    (38, 24, 12),     # 1: Deep Umber
    (74, 46, 20),     # 2: Dark Sepia
    (122, 80, 32),    # 3: Warm Ochre
    (178, 124, 48),   # 4: Amber Gold
    (230, 178, 78),   # 5: Bright Sunlight / Gold
    (254, 236, 168)   # 6: Pure Cream Specular
]

# 4x4 Bayer Matrix for authentic ordered dithering
BAYER4 = [
    [ 0/16,  8/16,  2/16, 10/16],
    [12/16,  4/16, 14/16,  6/16],
    [ 3/16, 11/16,  1/16,  9/16],
    [15/16,  7/16, 13/16,  5/16]
]

def get_dither_color(val, x, y, min_step=0, max_step=6):
    val = max(0.0, min(1.0, val))
    span = max_step - min_step
    scaled = val * span
    idx = int(scaled)
    frac = scaled - idx
    threshold = BAYER4[y % 4][x % 4]
    chosen = min_step + idx + (1 if frac > threshold else 0)
    chosen = min(max_step, max(min_step, chosen))
    return PALETTE[chosen]

def pnoise(x, y):
    xi = int(x)
    yi = int(y)
    xf = x - xi
    yf = y - yi
    def h(ix, iy):
        n = ix * 374761393 + iy * 668265263
        n = (n ^ (n >> 13)) * 1274126177
        return (n & 0x7fffffff) / 2147483647.0
    v00 = h(xi, yi)
    v10 = h(xi+1, yi)
    v01 = h(xi, yi+1)
    v11 = h(xi+1, yi+1)
    sx = xf * xf * (3 - 2 * xf)
    sy = yf * yf * (3 - 2 * yf)
    return (v00 * (1-sx) + v10 * sx) * (1-sy) + (v01 * (1-sx) + v11 * sx) * sy

def fbm(x, y, octaves=3):
    val = 0.0
    amp = 0.5
    freq = 1.0
    for _ in range(octaves):
        val += pnoise(x * freq, y * freq) * amp
        amp *= 0.5
        freq *= 2.0
    return val

# -------------------------------------------------------------
# PANEL 1: MT. DIMENSIONAL / THE ANCIENT SANCTUARY (Like Mt. Ebott)
# -------------------------------------------------------------
def render_panel_1():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    
    # 1. Sky with sunset gradient and cloud noise
    for y in range(H):
        for x in range(W):
            # Sun glow center at x=240, y=140
            dist_sun = math.hypot(x - 240, y - 140) / 260.0
            sky_grad = (1.0 - (y / float(H))) * 0.75 + (1.0 - min(1.0, dist_sun)) * 0.35
            cloud = fbm(x * 0.015, y * 0.02) * 0.18
            pixels[x, y] = get_dither_color(sky_grad + cloud, x, y, 0, 5)

    # 2. Distant mountain silhouette
    for x in range(W):
        nx = x / float(W)
        # Mountain peak profile
        m_y = int(95 + 65 * math.sin(nx * 3.14159) - 35 * math.exp(-((x - 240)/45.0)**2) + fbm(x * 0.03, 0) * 25)
        for y in range(m_y, H):
            ridge_light = max(0.0, 1.0 - (x - 240) / 180.0) if x > 240 else max(0.0, 1.0 + (x - 240) / 180.0)
            depth_val = 0.35 + 0.35 * ridge_light + fbm(x*0.04, y*0.04) * 0.15
            if y == m_y:
                pixels[x, y] = PALETTE[5] # Sunlit mountain ridge highlight
            elif y == m_y + 1:
                pixels[x, y] = PALETTE[4]
            else:
                pixels[x, y] = get_dither_color(depth_val, x, y, 1, 4)

    # 3. Floating Dimensional Geometry over the mountain peak
    draw = ImageDraw.Draw(im)
    cx, cy = 240, 60
    for r in [28, 48, 72]:
        for a in range(0, 360, 4):
            rad = math.radians(a)
            px = int(cx + r * math.cos(rad) * 1.5)
            py = int(cy + r * math.sin(rad) * 0.6)
            if 0 <= px < W and 0 <= py < H:
                pixels[px, py] = PALETTE[5] if a % 16 < 8 else PALETTE[6]
    # Pillar light beam
    for y in range(0, 95):
        alpha_b = (1.0 - (y / 95.0)) * 0.8
        for x in range(238, 243):
            if (x + y) % 2 == 0:
                pixels[x, y] = PALETTE[6]

    # 4. Foreground dark pine trees & jagged cliffs
    for x in range(W):
        tree_h = int(195 + 30 * math.sin(x * 0.25) * math.cos(x * 0.08) + fbm(x * 0.1, 0) * 15)
        for y in range(tree_h, H):
            pixels[x, y] = PALETTE[0] if (x + y) % 3 != 0 else PALETTE[1]
            if y == tree_h:
                pixels[x, y] = PALETTE[2] # Rim light on pines

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_1.png"))
    print("Rendered Panel 1")

# -------------------------------------------------------------
# PANEL 2: THE CAVERN ENTRANCE & LANTERN EXPLORATION (Like 00:35)
# -------------------------------------------------------------
def render_panel_2():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    
    # 1. Cavern interior background with depth haze
    for y in range(H):
        for x in range(W):
            bg_val = 0.18 + (y / float(H)) * 0.2 + fbm(x*0.02, y*0.02) * 0.12
            pixels[x, y] = get_dither_color(bg_val, x, y, 0, 2)

    # 2. Jagged cavern walls / entrance framing
    for y in range(H):
        left_wall = int(110 - (y / float(H)) * 45 + fbm(0, y * 0.06) * 35)
        right_wall = int(370 + (y / float(H)) * 40 - fbm(10, y * 0.06) * 35)
        for x in range(0, left_wall):
            c_val = 0.15 + fbm(x*0.05, y*0.05) * 0.25
            pixels[x, y] = get_dither_color(c_val, x, y, 0, 2)
            if x == left_wall - 1:
                pixels[x, y] = PALETTE[3] # Rim light
        for x in range(right_wall, W):
            c_val = 0.15 + fbm(x*0.05, y*0.05) * 0.25
            pixels[x, y] = get_dither_color(c_val, x, y, 0, 2)
            if x == right_wall:
                pixels[x, y] = PALETTE[3]

    # 3. Stalactites from ceiling
    for sx, sh in [(150, 65), (190, 48), (280, 75), (320, 52), (240, 38)]:
        for y in range(0, sh):
            w_at_y = int((1.0 - y / float(sh)) * 14)
            for x in range(sx - w_at_y, sx + w_at_y + 1):
                if 0 <= x < W:
                    pixels[x, y] = PALETTE[1] if x < sx else PALETTE[2]

    # 4. Lantern radial light glow (Lantern at x=252, y=175)
    lx, ly = 252, 175
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - lx, y - ly)
            if d < 125:
                intensity = (1.0 - (d / 125.0)) ** 1.6
                cur = pixels[x, y]
                # Light up stone floor and walls
                glow_val = intensity * 0.95 + fbm(x*0.05, y*0.05) * 0.1
                glow_col = get_dither_color(glow_val, x, y, 1, 6)
                # Blend with background
                if glow_val > 0.25:
                    pixels[x, y] = glow_col

    # 5. John Rod Stickman Silhouette with glowing lantern
    draw = ImageDraw.Draw(im)
    cx, cy = 220, 175
    # Head Loop
    draw.ellipse([cx - 14, cy - 65, cx + 14, cy - 37], outline=PALETTE[6], width=3)
    draw.ellipse([cx - 11, cy - 62, cx + 11, cy - 40], outline=PALETTE[0], width=2)
    # Torso
    draw.line([(cx, cy - 37), (cx - 26, cy - 12)], fill=PALETTE[6], width=3)
    draw.line([(cx - 26, cy - 12), (cx, cy + 12)], fill=PALETTE[6], width=3)
    draw.line([(cx, cy - 37), (cx + 26, cy - 12)], fill=PALETTE[6], width=3)
    draw.line([(cx + 26, cy - 12), (cx, cy + 12)], fill=PALETTE[6], width=3)
    # Arm holding lantern
    draw.line([(cx + 26, cy - 12), (lx, ly - 8)], fill=PALETTE[6], width=2)
    # Glowing lantern
    draw.rectangle([lx - 5, ly - 8, lx + 5, ly + 6], fill=PALETTE[5], outline=PALETTE[6])
    draw.ellipse([lx - 2, ly - 5, lx + 2, ly - 1], fill=PALETTE[6])
    # Legs & Bent Sliding Feet
    draw.line([(cx - 8, cy + 12), (cx - 8, cy + 50)], fill=PALETTE[6], width=3)
    draw.line([(cx - 8, cy + 50), (cx + 18, cy + 50)], fill=PALETTE[6], width=3)
    draw.line([(cx + 8, cy + 12), (cx + 8, cy + 50)], fill=PALETTE[6], width=3)
    draw.line([(cx + 8, cy + 50), (cx + 34, cy + 50)], fill=PALETTE[6], width=3)

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_2.png"))
    print("Rendered Panel 2")

# -------------------------------------------------------------
# PANEL 3: THE PEDESTAL & THE ANCIENT WATCH (Grand Sanctuary)
# -------------------------------------------------------------
def render_panel_3():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    
    # 1. Grand vaulted chamber background
    for y in range(H):
        for x in range(W):
            arch_dist = abs(x - 240) / 240.0
            v = 0.15 + (1.0 - arch_dist) * 0.2 + fbm(x*0.02, y*0.02) * 0.1
            pixels[x, y] = get_dither_color(v, x, y, 0, 3)

    # 2. Vaulted pillars in perspective
    for px in [60, 110, 370, 420]:
        for y in range(0, 210):
            for x in range(px - 14, px + 15):
                shade = 0.35 + (0.35 if x < px else -0.15) + fbm(x*0.05, y*0.05)*0.15
                pixels[x, y] = get_dither_color(shade, x, y, 1, 4)

    # 3. Golden Divine Light Shaft beaming onto center pedestal
    for y in range(0, 210):
        # Beam width expands from 40px at top to 120px at bottom
        beam_w = int(25 + (y / 210.0) * 65)
        for x in range(240 - beam_w, 240 + beam_w + 1):
            beam_t = 1.0 - abs(x - 240) / float(beam_w)
            beam_val = beam_t * 0.75 + fbm(x*0.08, y*0.08) * 0.2
            pixels[x, y] = get_dither_color(beam_val, x, y, 2, 6)

    # 4. Stepped Stone Dais & Central Pedestal
    draw = ImageDraw.Draw(im)
    # Dais steps
    draw.polygon([(140, 235), (340, 235), (380, 265), (100, 265)], fill=PALETTE[3], outline=PALETTE[5])
    draw.polygon([(165, 212), (315, 212), (340, 235), (140, 235)], fill=PALETTE[4], outline=PALETTE[6])
    # Stone pedestal column
    draw.rectangle([226, 145, 254, 212], fill=PALETTE[2], outline=PALETTE[4])
    draw.rectangle([218, 136, 262, 146], fill=PALETTE[4], outline=PALETTE[6])
    # Glowing Ancient Watch
    draw.ellipse([231, 116, 249, 134], fill=PALETTE[6], outline=PALETTE[5])
    draw.ellipse([234, 119, 246, 131], fill=PALETTE[5], outline=PALETTE[6])
    # Watch hands
    draw.line([(240, 125), (240, 120)], fill=PALETTE[0], width=1)
    draw.line([(240, 125), (245, 127)], fill=PALETTE[0], width=1)
    # Sparkle stars
    for sx, sy in [(224, 115), (256, 118), (240, 105)]:
        draw.point((sx, sy), fill=PALETTE[6])
        draw.point((sx+1, sy), fill=PALETTE[5])

    # 5. John Rod standing at the bottom left observing
    cx, cy = 135, 185
    draw.ellipse([cx - 12, cy - 58, cx + 12, cy - 34], outline=PALETTE[6], width=3)
    draw.ellipse([cx - 9, cy - 55, cx + 9, cy - 37], fill=PALETTE[0])
    draw.line([(cx, cy - 34), (cx - 24, cy - 10)], fill=PALETTE[6], width=3)
    draw.line([(cx - 24, cy - 10), (cx, cy + 14)], fill=PALETTE[6], width=3)
    draw.line([(cx, cy - 34), (cx + 24, cy - 10)], fill=PALETTE[6], width=3)
    draw.line([(cx + 24, cy - 10), (cx, cy + 14)], fill=PALETTE[6], width=3)
    draw.line([(cx - 6, cy + 14), (cx - 6, cy + 46)], fill=PALETTE[6], width=3)
    draw.line([(cx - 6, cy + 46), (cx + 18, cy + 46)], fill=PALETTE[6], width=3)
    draw.line([(cx + 6, cy + 14), (cx + 6, cy + 46)], fill=PALETTE[6], width=3)
    draw.line([(cx + 6, cy + 46), (cx + 30, cy + 46)], fill=PALETTE[6], width=3)

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_3.png"))
    print("Rendered Panel 3")

# -------------------------------------------------------------
# PANEL 4: THE TOUCH & DIMENSIONAL FRACTURE (Close-up Climax)
# -------------------------------------------------------------
def render_panel_4():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    cx, cy = 240, 135
    
    # 1. Reality distortion ripple waves
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - cx, y - cy)
            ripple = math.sin(d * 0.12) * 0.25
            burst = (1.0 - min(1.0, d / 200.0)) * 0.75
            val = burst + ripple + fbm(x*0.04, y*0.04)*0.15
            pixels[x, y] = get_dither_color(val, x, y, 0, 5)

    # 2. Glowing Ancient Watch Face (Close-up)
    draw = ImageDraw.Draw(im)
    r_watch = 62
    # Outer casing with metallic gear teeth
    for a in range(0, 360, 15):
        rad = math.radians(a)
        tx = int(cx + (r_watch + 7) * math.cos(rad))
        ty = int(cy + (r_watch + 7) * math.sin(rad))
        draw.ellipse([tx - 4, ty - 4, tx + 4, ty + 4], fill=PALETTE[4], outline=PALETTE[6])
    draw.ellipse([cx - r_watch, cy - r_watch, cx + r_watch, cy + r_watch], fill=PALETTE[1], outline=PALETTE[6], width=4)
    draw.ellipse([cx - r_watch + 6, cy - r_watch + 6, cx + r_watch - 6, cy + r_watch - 6], fill=PALETTE[2], outline=PALETTE[5], width=2)
    
    # Clockwork hands & glowing core
    draw.line([(cx, cy), (cx, cy - 38)], fill=PALETTE[6], width=4)
    draw.line([(cx, cy), (cx + 28, cy + 18)], fill=PALETTE[6], width=3)
    draw.ellipse([cx - 8, cy - 8, cx + 8, cy + 8], fill=PALETTE[6], outline=PALETTE[5])
    
    # 3. John Rod tubular metallic wire finger touching the crown at top-left
    crown_x, crown_y = cx - 44, cy - 44
    draw.rectangle([crown_x - 6, crown_y - 6, crown_x + 6, crown_y + 6], fill=PALETTE[6], outline=PALETTE[4])
    # Slender tubular wire finger reaching in from top-left
    draw.line([(40, 20), (120, 50)], fill=PALETTE[6], width=6)
    draw.line([(120, 50), (crown_x, crown_y)], fill=PALETTE[6], width=5)
    
    # 4. Dimensional Reality Fracture Lightning / Cracks
    random.seed(42)
    for _ in range(12):
        angle = random.uniform(0, 2 * math.pi)
        dist = random.uniform(70, 220)
        curr_x, curr_y = cx, cy
        for seg in range(5):
            next_x = curr_x + math.cos(angle) * (dist / 5.0) + random.uniform(-10, 10)
            next_y = curr_y + math.sin(angle) * (dist / 5.0) + random.uniform(-10, 10)
            draw.line([(curr_x, curr_y), (next_x, next_y)], fill=PALETTE[6], width=2)
            curr_x, curr_y = next_x, next_y

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_4.png"))
    print("Rendered Panel 4")

# -------------------------------------------------------------
# PANEL 5: THE FALL INTO THE CHASM (Like 00:54)
# -------------------------------------------------------------
def render_panel_5():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    
    # 1. Abyss vertical gradient (shaft of light fading downwards)
    for y in range(H):
        for x in range(W):
            light_beam = max(0.0, 1.0 - abs(x - 240) / (80.0 + y * 0.4)) * (1.0 - (y / float(H)) * 0.7)
            cave_val = light_beam * 0.75 + fbm(x*0.03, y*0.03)*0.18
            pixels[x, y] = get_dither_color(cave_val, x, y, 0, 4)

    # 2. Sheer rock walls on left and right
    for y in range(H):
        left_rock = int(120 - (y / float(H)) * 25 + fbm(1, y * 0.05) * 45)
        right_rock = int(360 + (y / float(H)) * 25 - fbm(5, y * 0.05) * 45)
        for x in range(0, left_rock):
            pixels[x, y] = get_dither_color(0.25 + fbm(x*0.04, y*0.04)*0.2, x, y, 0, 2)
            if x == left_rock - 1:
                pixels[x, y] = PALETTE[3] # Rim highlight on wall
        for x in range(right_rock, W):
            pixels[x, y] = get_dither_color(0.25 + fbm(x*0.04, y*0.04)*0.2, x, y, 0, 2)
            if x == right_rock:
                pixels[x, y] = PALETTE[3]

    # 3. Top chamber trapdoor opening (bright golden rectangular portal)
    draw = ImageDraw.Draw(im)
    draw.polygon([(170, 0), (310, 0), (335, 42), (145, 42)], fill=PALETTE[6], outline=PALETTE[5])
    # Tumbled stone trapdoor slabs
    draw.polygon([(175, 75), (215, 68), (220, 85), (180, 92)], fill=PALETTE[3], outline=PALETTE[5])
    draw.polygon([(265, 115), (310, 105), (315, 122), (270, 132)], fill=PALETTE[2], outline=PALETTE[4])

    # 4. John Rod tumbling in perspective
    jx, jy = 240, 145
    # Angled head loop
    draw.ellipse([jx - 14, jy - 42, jx + 14, jy - 14], outline=PALETTE[6], width=3)
    draw.ellipse([jx - 11, jy - 39, jx + 11, jy - 17], fill=PALETTE[0])
    # Wire torso in freefall
    draw.line([(jx, jy - 14), (jx - 28, jy + 8)], fill=PALETTE[6], width=3)
    draw.line([(jx - 28, jy + 8), (jx, jy + 28)], fill=PALETTE[6], width=3)
    draw.line([(jx, jy - 14), (jx + 28, jy + 12)], fill=PALETTE[6], width=3)
    draw.line([(jx + 28, jy + 12), (jx, jy + 28)], fill=PALETTE[6], width=3)
    # Flailing legs
    draw.line([(jx - 8, jy + 28), (jx - 24, jy + 65)], fill=PALETTE[6], width=3)
    draw.line([(jx - 24, jy + 65), (jx - 8, jy + 82)], fill=PALETTE[6], width=3)
    draw.line([(jx + 8, jy + 28), (jx + 22, jy + 58)], fill=PALETTE[6], width=3)
    draw.line([(jx + 22, jy + 58), (jx + 45, jy + 62)], fill=PALETTE[6], width=3)

    # Speed lines
    for lx in [195, 220, 260, 285]:
        draw.line([(lx, jy - 70), (lx, jy + 90)], fill=PALETTE[4], width=1)

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_5.png"))
    print("Rendered Panel 5")

# -------------------------------------------------------------
# PANEL 6: THE CAVERN FLOOR / 0D BEAD (Like 01:00)
# -------------------------------------------------------------
def render_panel_6():
    im = Image.new("RGB", (W, H), PALETTE[0])
    pixels = im.load()
    
    # 1. Dark underground cavern floor with cracked stone tiles
    for y in range(H):
        for x in range(W):
            # Spotlight cone centered at x=240, floor at y=210
            d_spot = math.hypot((x - 240) * 1.5, (y - 210) * 3.5)
            spot = max(0.0, 1.0 - (d_spot / 175.0)) ** 1.4
            tile_noise = fbm(x * 0.05, y * 0.05) * 0.15
            pixels[x, y] = get_dither_color(spot * 0.85 + tile_noise, x, y, 0, 4)

    # 2. Giant broken pillars lying in the deep shadows
    draw = ImageDraw.Draw(im)
    draw.polygon([(25, 170), (135, 160), (150, 235), (15, 245)], fill=PALETTE[1], outline=PALETTE[2])
    draw.polygon([(345, 155), (460, 175), (470, 240), (330, 230)], fill=PALETTE[1], outline=PALETTE[2])

    # 3. Floor stone tile cracks
    draw.line([(180, 210), (300, 210)], fill=PALETTE[2], width=1)
    draw.line([(240, 185), (240, 235)], fill=PALETTE[2], width=1)

    # 4. Spotlight shaft beaming down from above
    for y in range(0, 210):
        beam_hw = int(12 + (y / 210.0) * 45)
        for x in range(240 - beam_hw, 240 + beam_hw + 1):
            edge_f = 1.0 - abs(x - 240) / float(beam_hw)
            val = edge_f * 0.65 + fbm(x*0.06, y*0.06)*0.15
            if (x + y) % 2 == 0:
                pixels[x, y] = get_dither_color(val, x, y, 1, 5)

    # 5. The 0D Metallic Bead resting on the floor
    bx, by = 240, 210
    # Expanding concentric ripple shockwave rings
    draw.ellipse([bx - 32, by - 12, bx + 32, by + 12], outline=PALETTE[4], width=1)
    draw.ellipse([bx - 60, by - 22, bx + 60, by + 22], outline=PALETTE[3], width=1)
    draw.ellipse([bx - 95, by - 35, bx + 95, by + 35], outline=PALETTE[2], width=1)
    
    # Polished chrome steel bead
    draw.ellipse([bx - 14, by - 14, bx + 14, by + 14], fill=PALETTE[0], outline=PALETTE[6], width=2)
    draw.ellipse([bx - 10, by - 10, bx + 10, by + 10], fill=PALETTE[5], outline=PALETTE[6])
    draw.ellipse([bx - 4, by - 4, bx + 4, by + 4], fill=PALETTE[0])
    # Star glint
    draw.line([(bx - 12, by - 12), (bx - 2, by - 2)], fill=PALETTE[6], width=2)
    draw.line([(bx - 2, by - 12), (bx - 12, by - 2)], fill=PALETTE[6], width=2)
    draw.point((bx - 7, by - 7), fill=PALETTE[6])

    im.save(os.path.join(OUTPUT_DIR, "intro_panel_6.png"))
    print("Rendered Panel 6")

if __name__ == "__main__":
    render_panel_1()
    render_panel_2()
    render_panel_3()
    render_panel_4()
    render_panel_5()
    render_panel_6()
    print("ALL 6 UNDERTAIL-STYLE ART PANELS RENDERED WITH AUTHENTIC BAYER DITHERING & DEPTH!")
