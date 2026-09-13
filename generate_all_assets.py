import math
import os
from PIL import Image, ImageDraw

SPRITES_DIR = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\sprites"
TEXTURES_DIR = r"c:\Users\USER\Desktop\game making\Degrees_of_Escape\assets\textures"
os.makedirs(SPRITES_DIR, exist_ok=True)
os.makedirs(TEXTURES_DIR, exist_ok=True)

# Pure Neutral Metallic Palette for John Rod (Zero Blue Tint)
DARK = (30, 32, 36, 255)         # Dark steel outline
BODY = (226, 228, 232, 255)      # Polished chrome/steel rod
HIGHLIGHT = (255, 255, 255, 255) # Pure specular shine
SHADOW = (152, 155, 162, 255)    # Underside metallic shadow
CORE_HOLE = (16, 18, 22, 255)    # Hollow opening
TRANS = (0, 0, 0, 0)

# -------------------------------------------------------------
# 1. 0D METALLIC POINT BEAD (NO BLUE BLOB)
# -------------------------------------------------------------
def generate_0d():
    size = 64
    im = Image.new("RGBA", (size, size), TRANS)
    draw = ImageDraw.Draw(im)
    cx, cy = size // 2, size // 2
    r = 15
    
    # Outer dark contour
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=DARK)
    # Metallic gradient body
    for y in range(cy - r + 2, cy + r - 1):
        for x in range(cx - r + 2, cx + r - 1):
            d = math.hypot(x - cx, y - cy)
            if d <= r - 2:
                # Top-left light source
                val = (x - (cx - 5)) + (y - (cy - 5))
                if val < -3:
                    c = HIGHLIGHT
                elif val < 8:
                    c = BODY
                else:
                    c = SHADOW
                im.putpixel((x, y), c)
    # Hollow center eyelet
    draw.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=DARK)
    draw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=CORE_HOLE)
    # Specular glint
    draw.point((cx - 8, cy - 8), HIGHLIGHT)
    draw.point((cx - 7, cy - 8), HIGHLIGHT)
    draw.point((cx - 8, cy - 7), HIGHLIGHT)
    
    p = os.path.join(SPRITES_DIR, "john_rod_0d_point.png")
    im.save(p)
    print("Saved:", p)

    # 0D Pulse Ring
    pulse_size = 128
    p_im = Image.new("RGBA", (pulse_size, pulse_size), TRANS)
    p_draw = ImageDraw.Draw(p_im)
    pcx, pcy = pulse_size // 2, pulse_size // 2
    for ring_r, col, width in [
        (18, (255, 255, 255, 240), 2),
        (32, (220, 230, 245, 180), 2),
        (46, (180, 200, 225, 120), 1),
        (58, (140, 170, 210, 60), 1)
    ]:
        p_draw.ellipse([pcx - ring_r, pcy - ring_r, pcx + ring_r, pcy + ring_r], outline=col, width=width)
    p_path = os.path.join(SPRITES_DIR, "john_rod_0d_pulse.png")
    p_im.save(p_path)
    print("Saved:", p_path)

# -------------------------------------------------------------
# 2. 1D STRAIGHT METALLIC ROD (LINE)
# -------------------------------------------------------------
def generate_1d():
    w, h = 160, 24
    im = Image.new("RGBA", (w, h), TRANS)
    draw = ImageDraw.Draw(im)
    cy = h // 2
    start_x, end_x = 12, w - 12
    thickness = 8
    
    # Outer dark contour
    draw.rounded_rectangle([start_x - 2, cy - thickness//2 - 2, end_x + 2, cy + thickness//2 + 2], radius=4, fill=DARK)
    # Cylindrical metallic gradient
    for y in range(cy - thickness//2, cy + thickness//2 + 1):
        rel = (y - (cy - thickness//2)) / float(thickness)
        if rel < 0.25:
            col = HIGHLIGHT
        elif rel < 0.65:
            col = BODY
        else:
            col = SHADOW
        draw.line([(start_x, y), (end_x, y)], fill=col)
    
    # End caps with eyelets
    for cap_x in [start_x, end_x]:
        draw.ellipse([cap_x - 6, cy - 6, cap_x + 6, cy + 6], fill=DARK)
        draw.ellipse([cap_x - 4, cy - 4, cap_x + 4, cy + 4], fill=BODY)
        draw.ellipse([cap_x - 2, cy - 2, cap_x + 2, cy + 2], fill=CORE_HOLE)
        draw.point((cap_x - 2, cy - 3), HIGHLIGHT)

    p = os.path.join(SPRITES_DIR, "john_rod_1d_rod.png")
    im.save(p)
    print("Saved:", p)

# -------------------------------------------------------------
# 3. 2D / 2.5D / 3D WIREFRAME JOHN ROD GENERATOR
# -------------------------------------------------------------
def draw_tubular_line(draw, p1, p2, thickness=6):
    # Draw dark backing outline
    draw.line([p1, p2], fill=DARK, width=thickness + 4)
    # Draw body
    draw.line([p1, p2], fill=BODY, width=thickness)
    # Specular highlight down core
    draw.line([p1, p2], fill=HIGHLIGHT, width=max(1, thickness // 3))

def draw_tubular_circle(draw, center, radius, thickness=5):
    cx, cy = center
    # Outer dark
    draw.ellipse([cx - radius - thickness//2 - 2, cy - radius - thickness//2 - 2,
                  cx + radius + thickness//2 + 2, cy + radius + thickness//2 + 2], fill=DARK)
    # Inner dark hole
    draw.ellipse([cx - radius + thickness//2 - 1, cy - radius + thickness//2 - 1,
                  cx + radius - thickness//2 + 1, cy + radius - thickness//2 + 1], fill=TRANS)
    # Body ring
    for r in range(radius - thickness//2, radius + thickness//2 + 1):
        rel = (r - (radius - thickness//2)) / float(thickness)
        c = HIGHLIGHT if rel < 0.4 else BODY
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], outline=c)
    # Clear center hole
    draw.ellipse([cx - (radius - thickness//2 - 1), cy - (radius - thickness//2 - 1),
                  cx + (radius - thickness//2 - 1), cy + (radius - thickness//2 - 1)], fill=TRANS)

def make_john_rod_frame(mode="2d", frame=0, facing="front"):
    size = 256
    im = Image.new("RGBA", (size, size), TRANS)
    draw = ImageDraw.Draw(im)
    
    cx = 128
    base_y = 230
    
    if mode == "2d":
        # 2D Flat View
        leg_offset = 0
        body_tilt = 0
        if frame == 1: # Walk 1
            leg_offset = 12
            body_tilt = 3
        elif frame == 2: # Walk 2
            leg_offset = 0
            body_tilt = 0
        elif frame == 3: # Walk 3
            leg_offset = -12
            body_tilt = -3
        elif frame == 4: # Walk 4
            leg_offset = 0
            body_tilt = 0
        elif frame == -1: # Jump
            base_y = 210
            body_tilt = 0

        torso_top = (cx + body_tilt, 75)
        head_center = (cx + body_tilt, 52)
        head_r = 20
        
        elbow_l = (cx - 52 + body_tilt, 126)
        elbow_r = (cx + 52 + body_tilt, 126)
        hip = (cx + body_tilt, 175)
        
        # Legs and bent sliding feet
        hip_l = (cx - 15 + body_tilt, 175)
        hip_r = (cx + 15 + body_tilt, 175)
        
        foot_l_y = base_y
        foot_r_y = base_y
        
        foot_l_heel = (hip_l[0] + leg_offset, foot_l_y)
        foot_r_heel = (hip_r[0] - leg_offset, foot_r_y)
        
        # 90-degree bent flat wire feet that slide along ground ("ズッ")
        foot_l_toe = (foot_l_heel[0] + 36, foot_l_y)
        foot_r_toe = (foot_r_heel[0] + 36, foot_r_y)
        
        # Draw legs and sliding feet
        draw_tubular_line(draw, hip_l, foot_l_heel, thickness=5)
        draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
        draw_tubular_line(draw, hip_r, foot_r_heel, thickness=5)
        draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=5)
        
        # Draw torso outline
        draw_tubular_line(draw, torso_top, elbow_l, thickness=5)
        draw_tubular_line(draw, elbow_l, hip_l, thickness=5)
        draw_tubular_line(draw, torso_top, elbow_r, thickness=5)
        draw_tubular_line(draw, elbow_r, hip_r, thickness=5)
        draw_tubular_line(draw, hip_l, hip_r, thickness=5)
        
        # Draw hollow circle head loop
        draw_tubular_circle(draw, head_center, head_r, thickness=5)

    elif mode == "25d":
        # 2.5D with depth extrusion and lane shift
        offset_z = 6
        # Under shadow layer (simulating depth rod)
        for offset_x in [3, 2, 1]:
            draw_tubular_line(draw, (cx - 15 + offset_x, 175 + offset_z), (cx - 15 + offset_x, base_y + offset_z), thickness=4)
        
        # Main 2D body
        torso_top = (cx, 75)
        head_center = (cx, 52)
        elbow_l = (cx - 50, 126)
        elbow_r = (cx + 50, 126)
        hip_l = (cx - 15, 175)
        hip_r = (cx + 15, 175)
        
        foot_l_heel = (hip_l[0], base_y)
        foot_r_heel = (hip_r[0], base_y)
        foot_l_toe = (foot_l_heel[0] + 36, base_y)
        foot_r_toe = (foot_r_heel[0] + 36, base_y)
        
        if facing == "front": # Stepping forward lane
            foot_l_toe = (foot_l_heel[0] + 20, base_y + 8)
            foot_r_toe = (foot_r_heel[0] + 20, base_y + 8)
        elif facing == "back": # Stepping back lane
            foot_l_toe = (foot_l_heel[0] + 20, base_y - 8)
            foot_r_toe = (foot_r_heel[0] + 20, base_y - 8)

        draw_tubular_line(draw, hip_l, foot_l_heel, thickness=5)
        draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
        draw_tubular_line(draw, hip_r, foot_r_heel, thickness=5)
        draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=5)
        
        draw_tubular_line(draw, torso_top, elbow_l, thickness=5)
        draw_tubular_line(draw, elbow_l, hip_l, thickness=5)
        draw_tubular_line(draw, torso_top, elbow_r, thickness=5)
        draw_tubular_line(draw, elbow_r, hip_r, thickness=5)
        draw_tubular_line(draw, hip_l, hip_r, thickness=5)
        draw_tubular_circle(draw, head_center, 20, thickness=5)

    elif mode == "3d":
        # 3D Directional
        if facing == "side":
            # Profile view
            walk_dx = 14 if frame == 1 else (-14 if frame == 2 else 0)
            torso_top = (cx - 5, 75)
            head_center = (cx - 5, 52)
            elbow = (cx + 28, 126)
            hip = (cx - 5, 175)
            
            foot_l_heel = (hip[0] + walk_dx, base_y)
            foot_l_toe = (foot_l_heel[0] + 42, base_y)
            foot_r_heel = (hip[0] - walk_dx, base_y)
            foot_r_toe = (foot_r_heel[0] + 42, base_y)
            
            draw_tubular_line(draw, hip, foot_r_heel, thickness=5)
            draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=5)
            draw_tubular_line(draw, hip, foot_l_heel, thickness=5)
            draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
            
            draw_tubular_line(draw, torso_top, elbow, thickness=5)
            draw_tubular_line(draw, elbow, hip, thickness=5)
            draw_tubular_line(draw, torso_top, (cx - 18, 126), thickness=5)
            draw_tubular_line(draw, (cx - 18, 126), hip, thickness=5)
            
            # Head oval in profile
            draw.ellipse([head_center[0] - 8, head_center[1] - 20, head_center[0] + 8, head_center[1] + 20], outline=DARK, width=6)
            draw.ellipse([head_center[0] - 6, head_center[1] - 18, head_center[0] + 6, head_center[1] + 18], outline=HIGHLIGHT, width=3)

        elif facing == "iso":
            # 3/4 Isometric ARAKI MANGA POSE
            walk_dx = 10 if frame == 1 else (-10 if frame == 2 else 0)
            torso_top = (cx, 75)
            head_center = (cx, 52)
            
            elbow_l = (cx - 42, 126)
            elbow_r = (cx + 58, 122)
            hip_l = (cx - 18, 175)
            hip_r = (cx + 12, 175)
            
            # Staggered legs in perspective
            foot_l_heel = (hip_l[0] - 10 + walk_dx, base_y - 6)
            foot_l_toe = (foot_l_heel[0] + 28, base_y + 10)
            
            foot_r_heel = (hip_r[0] + 8 - walk_dx, base_y + 4)
            foot_r_toe = (foot_r_heel[0] + 44, base_y + 20)
            
            # Back leg first
            draw_tubular_line(draw, hip_l, foot_l_heel, thickness=5)
            draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
            
            # Torso
            draw_tubular_line(draw, torso_top, elbow_l, thickness=5)
            draw_tubular_line(draw, elbow_l, hip_l, thickness=5)
            draw_tubular_line(draw, torso_top, elbow_r, thickness=5)
            draw_tubular_line(draw, elbow_r, hip_r, thickness=5)
            draw_tubular_line(draw, hip_l, hip_r, thickness=5)
            
            # Front leg in foreground
            draw_tubular_line(draw, hip_r, foot_r_heel, thickness=5)
            draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=6)
            
            # Head angled
            draw_tubular_circle(draw, head_center, 20, thickness=5)

        elif facing == "back":
            # Back view
            walk_dx = 10 if frame == 1 else (-10 if frame == 2 else 0)
            torso_top = (cx, 75)
            head_center = (cx, 52)
            elbow_l = (cx - 50, 126)
            elbow_r = (cx + 50, 126)
            hip_l = (cx - 15, 175)
            hip_r = (cx + 15, 175)
            
            foot_l_heel = (hip_l[0] + walk_dx, base_y)
            foot_r_heel = (hip_r[0] - walk_dx, base_y)
            # Toes pointing slightly away
            foot_l_toe = (foot_l_heel[0] + 15, base_y - 10)
            foot_r_toe = (foot_r_heel[0] + 15, base_y - 10)
            
            draw_tubular_line(draw, hip_l, foot_l_heel, thickness=5)
            draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
            draw_tubular_line(draw, hip_r, foot_r_heel, thickness=5)
            draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=5)
            
            draw_tubular_line(draw, torso_top, elbow_l, thickness=5)
            draw_tubular_line(draw, elbow_l, hip_l, thickness=5)
            draw_tubular_line(draw, torso_top, elbow_r, thickness=5)
            draw_tubular_line(draw, elbow_r, hip_r, thickness=5)
            draw_tubular_line(draw, hip_l, hip_r, thickness=5)
            draw_tubular_circle(draw, head_center, 20, thickness=5)

        else: # facing == "front"
            walk_dx = 12 if frame == 1 else (-12 if frame == 2 else 0)
            torso_top = (cx, 75)
            head_center = (cx, 52)
            elbow_l = (cx - 52, 126)
            elbow_r = (cx + 52, 126)
            hip_l = (cx - 15, 175)
            hip_r = (cx + 15, 175)
            
            foot_l_heel = (hip_l[0] + walk_dx, base_y)
            foot_r_heel = (hip_r[0] - walk_dx, base_y)
            foot_l_toe = (foot_l_heel[0] + 28, base_y + 12)
            foot_r_toe = (foot_r_heel[0] + 28, base_y + 12)
            
            draw_tubular_line(draw, hip_l, foot_l_heel, thickness=5)
            draw_tubular_line(draw, foot_l_heel, foot_l_toe, thickness=5)
            draw_tubular_line(draw, hip_r, foot_r_heel, thickness=5)
            draw_tubular_line(draw, foot_r_heel, foot_r_toe, thickness=5)
            
            draw_tubular_line(draw, torso_top, elbow_l, thickness=5)
            draw_tubular_line(draw, elbow_l, hip_l, thickness=5)
            draw_tubular_line(draw, torso_top, elbow_r, thickness=5)
            draw_tubular_line(draw, elbow_r, hip_r, thickness=5)
            draw_tubular_line(draw, hip_l, hip_r, thickness=5)
            draw_tubular_circle(draw, head_center, 20, thickness=5)

    return im

def generate_all_john_rod_sprites():
    # 2D Sprites
    make_john_rod_frame("2d", frame=0).save(os.path.join(SPRITES_DIR, "john_rod_2d_idle.png"))
    make_john_rod_frame("2d", frame=0).save(os.path.join(SPRITES_DIR, "john_rod_idle.png"))
    make_john_rod_frame("2d", frame=-1).save(os.path.join(SPRITES_DIR, "john_rod_2d_jump.png"))
    make_john_rod_frame("2d", frame=-1).save(os.path.join(SPRITES_DIR, "john_rod_jump.png"))
    for f in range(1, 5):
        im = make_john_rod_frame("2d", frame=f)
        im.save(os.path.join(SPRITES_DIR, f"john_rod_2d_walk_{f}.png"))
        im.save(os.path.join(SPRITES_DIR, f"john_rod_walk_{f}.png"))

    # 2.5D Sprites
    make_john_rod_frame("25d", facing="idle").save(os.path.join(SPRITES_DIR, "john_rod_25d_idle.png"))
    make_john_rod_frame("25d", facing="front").save(os.path.join(SPRITES_DIR, "john_rod_25d_front.png"))
    make_john_rod_frame("25d", facing="back").save(os.path.join(SPRITES_DIR, "john_rod_25d_back.png"))

    # 3D Sprites
    # Front
    make_john_rod_frame("3d", frame=0, facing="front").save(os.path.join(SPRITES_DIR, "john_rod_3d_front_idle.png"))
    make_john_rod_frame("3d", frame=1, facing="front").save(os.path.join(SPRITES_DIR, "john_rod_3d_front_walk_1.png"))
    make_john_rod_frame("3d", frame=2, facing="front").save(os.path.join(SPRITES_DIR, "john_rod_3d_front_walk_2.png"))

    # 3/4 Iso (Araki Pose)
    make_john_rod_frame("3d", frame=0, facing="iso").save(os.path.join(SPRITES_DIR, "john_rod_3d_iso_idle.png"))
    make_john_rod_frame("3d", frame=1, facing="iso").save(os.path.join(SPRITES_DIR, "john_rod_3d_iso_walk_1.png"))
    make_john_rod_frame("3d", frame=2, facing="iso").save(os.path.join(SPRITES_DIR, "john_rod_3d_iso_walk_2.png"))

    # Side
    make_john_rod_frame("3d", frame=0, facing="side").save(os.path.join(SPRITES_DIR, "john_rod_3d_side_idle.png"))
    make_john_rod_frame("3d", frame=1, facing="side").save(os.path.join(SPRITES_DIR, "john_rod_3d_side_walk_1.png"))
    make_john_rod_frame("3d", frame=2, facing="side").save(os.path.join(SPRITES_DIR, "john_rod_3d_side_walk_2.png"))

    # Back
    make_john_rod_frame("3d", frame=0, facing="back").save(os.path.join(SPRITES_DIR, "john_rod_3d_back_idle.png"))
    make_john_rod_frame("3d", frame=1, facing="back").save(os.path.join(SPRITES_DIR, "john_rod_3d_back_walk_1.png"))
    make_john_rod_frame("3d", frame=2, facing="back").save(os.path.join(SPRITES_DIR, "john_rod_3d_back_walk_2.png"))
    print("Generated all John Rod dimensional frames!")

# -------------------------------------------------------------
# 4. 123D-STYLE RETRO-PIXEL ENVIRONMENT TEXTURES (32x32)
# -------------------------------------------------------------
def generate_environment_textures():
    # 1. Slate-Teal Brick (Wall) - Exactly like 123D brick.png
    # Palette: Mortar (38, 32, 28), Dark Teal (32, 101, 93), Mid Teal (37, 113, 104), Light Teal (59, 127, 119)
    brick_im = Image.new("RGB", (32, 32), (38, 32, 28))
    b_draw = ImageDraw.Draw(brick_im)
    
    MORTAR = (38, 32, 28)
    TEAL_DARK = (32, 101, 93)
    TEAL_MID = (37, 113, 104)
    TEAL_LIGHT = (59, 127, 119)
    
    # 4 rows of bricks (8px high each)
    # Row 0: y=1..6
    b_draw.rectangle([1, 1, 15, 6], fill=TEAL_MID)
    b_draw.line([(1, 1), (15, 1)], fill=TEAL_LIGHT)
    b_draw.line([(1, 6), (15, 6)], fill=TEAL_DARK)
    
    b_draw.rectangle([17, 1, 30, 6], fill=TEAL_MID)
    b_draw.line([(17, 1), (30, 1)], fill=TEAL_LIGHT)
    b_draw.line([(17, 6), (30, 6)], fill=TEAL_DARK)
    
    # Row 1: y=9..14 (staggered)
    b_draw.rectangle([1, 9, 7, 14], fill=TEAL_MID)
    b_draw.line([(1, 9), (7, 9)], fill=TEAL_LIGHT)
    
    b_draw.rectangle([9, 9, 23, 14], fill=TEAL_MID)
    b_draw.line([(9, 9), (23, 9)], fill=TEAL_LIGHT)
    b_draw.line([(9, 14), (23, 14)], fill=TEAL_DARK)
    
    b_draw.rectangle([25, 9, 30, 14], fill=TEAL_MID)
    b_draw.line([(25, 9), (30, 9)], fill=TEAL_LIGHT)
    
    # Row 2: y=17..22
    b_draw.rectangle([1, 17, 15, 22], fill=TEAL_MID)
    b_draw.line([(1, 17), (15, 17)], fill=TEAL_LIGHT)
    b_draw.line([(1, 22), (15, 22)], fill=TEAL_DARK)
    
    b_draw.rectangle([17, 17, 30, 22], fill=TEAL_MID)
    b_draw.line([(17, 17), (30, 17)], fill=TEAL_LIGHT)
    b_draw.line([(17, 22), (30, 22)], fill=TEAL_DARK)
    
    # Row 3: y=25..30 (staggered)
    b_draw.rectangle([1, 25, 7, 30], fill=TEAL_MID)
    b_draw.line([(1, 25), (7, 25)], fill=TEAL_LIGHT)
    
    b_draw.rectangle([9, 25, 23, 30], fill=TEAL_MID)
    b_draw.line([(9, 25), (23, 25)], fill=TEAL_LIGHT)
    b_draw.line([(9, 30), (23, 30)], fill=TEAL_DARK)
    
    b_draw.rectangle([25, 25, 30, 30], fill=TEAL_MID)
    b_draw.line([(25, 25), (30, 25)], fill=TEAL_LIGHT)
    
    brick_path = os.path.join(TEXTURES_DIR, "retro_brick_slate.png")
    brick_im.save(brick_path)
    # Also overwrite wall_stone.png so existing scenes automatically update cleanly!
    brick_im.save(os.path.join(TEXTURES_DIR, "wall_stone.png"))
    print("Saved:", brick_path)

    # 2. Checkered Floor Grid (Floor) - High contrast spatial grid for 2D/3D flattening
    floor_im = Image.new("RGB", (32, 32), (45, 52, 60))
    f_draw = ImageDraw.Draw(floor_im)
    
    TILE_A = (68, 80, 92)
    TILE_B = (58, 68, 78)
    GRID_LINE = (30, 35, 42)
    GRID_HIGHLIGHT = (85, 100, 115)
    
    # 2x2 large tile subdivision in 32x32
    # Quadrant 1 (top-left)
    f_draw.rectangle([1, 1, 14, 14], fill=TILE_A)
    f_draw.line([(1, 1), (14, 1)], fill=GRID_HIGHLIGHT)
    f_draw.line([(1, 1), (1, 14)], fill=GRID_HIGHLIGHT)
    
    # Quadrant 2 (top-right)
    f_draw.rectangle([17, 1, 30, 14], fill=TILE_B)
    f_draw.line([(17, 1), (30, 1)], fill=GRID_HIGHLIGHT)
    f_draw.line([(17, 1), (17, 14)], fill=GRID_HIGHLIGHT)
    
    # Quadrant 3 (bottom-left)
    f_draw.rectangle([1, 17, 14, 30], fill=TILE_B)
    f_draw.line([(1, 17), (14, 17)], fill=GRID_HIGHLIGHT)
    f_draw.line([(1, 17), (1, 30)], fill=GRID_HIGHLIGHT)
    
    # Quadrant 4 (bottom-right)
    f_draw.rectangle([17, 17, 30, 30], fill=TILE_A)
    f_draw.line([(17, 17), (30, 17)], fill=GRID_HIGHLIGHT)
    f_draw.line([(17, 17), (17, 30)], fill=GRID_HIGHLIGHT)
    
    # Central and outer grid lines
    f_draw.line([(0, 0), (31, 0)], fill=GRID_LINE)
    f_draw.line([(0, 15), (31, 15)], fill=GRID_LINE)
    f_draw.line([(0, 16), (31, 16)], fill=GRID_LINE)
    f_draw.line([(0, 31), (31, 31)], fill=GRID_LINE)
    f_draw.line([(0, 0), (0, 31)], fill=GRID_LINE)
    f_draw.line([(15, 0), (15, 31)], fill=GRID_LINE)
    f_draw.line([(16, 0), (16, 31)], fill=GRID_LINE)
    f_draw.line([(31, 0), (31, 31)], fill=GRID_LINE)
    
    floor_path = os.path.join(TEXTURES_DIR, "retro_floor_grid.png")
    floor_im.save(floor_path)
    # Also overwrite floor_pavers.png so existing scenes automatically update!
    floor_im.save(os.path.join(TEXTURES_DIR, "floor_pavers.png"))
    print("Saved:", floor_path)

    # 3. Clean Pillar Texture
    pillar_im = Image.new("RGB", (32, 64), (38, 32, 28))
    p_draw = ImageDraw.Draw(pillar_im)
    # Capital (top)
    p_draw.rectangle([1, 1, 30, 8], fill=(130, 140, 145))
    p_draw.line([(1, 1), (30, 1)], fill=(180, 190, 195))
    p_draw.line([(1, 8), (30, 8)], fill=(70, 75, 80))
    # Column shaft (fluted vertical bands)
    p_draw.rectangle([3, 9, 28, 54], fill=TEAL_MID)
    for fx in [6, 12, 18, 24]:
        p_draw.line([(fx, 9), (fx, 54)], fill=TEAL_LIGHT)
        p_draw.line([(fx + 1, 9), (fx + 1, 54)], fill=TEAL_DARK)
    # Base (bottom)
    p_draw.rectangle([1, 55, 30, 62], fill=(130, 140, 145))
    p_draw.line([(1, 55), (30, 55)], fill=(180, 190, 195))
    p_draw.line([(1, 62), (30, 62)], fill=(70, 75, 80))
    
    pillar_path = os.path.join(TEXTURES_DIR, "retro_pillar_column.png")
    pillar_im.save(pillar_path)
    pillar_im.save(os.path.join(TEXTURES_DIR, "pillar_trim.png"))
    print("Saved:", pillar_path)

    # 4. Clean Dais Block (with warm gold edge)
    dais_im = Image.new("RGB", (32, 32), (38, 32, 28))
    d_draw = ImageDraw.Draw(dais_im)
    GOLD_LIGHT = (235, 185, 75)
    GOLD_DARK = (150, 110, 35)
    SLATE_INNER = (55, 65, 75)
    
    d_draw.rectangle([1, 1, 30, 30], fill=SLATE_INNER)
    # Golden perimeter inlay
    d_draw.rectangle([3, 3, 28, 28], outline=GOLD_DARK, width=2)
    d_draw.line([(3, 3), (28, 3)], fill=GOLD_LIGHT)
    d_draw.line([(3, 3), (3, 28)], fill=GOLD_LIGHT)
    # Center emblem diamond
    d_draw.polygon([(16, 8), (24, 16), (16, 24), (8, 16)], outline=GOLD_LIGHT, fill=TEAL_DARK)
    
    dais_path = os.path.join(TEXTURES_DIR, "retro_dais_block.png")
    dais_im.save(dais_path)
    print("Saved:", dais_path)

if __name__ == "__main__":
    generate_0d()
    generate_1d()
    generate_all_john_rod_sprites()
    generate_environment_textures()
    print("ALL ASSETS GENERATED SUCCESSFULLY!")
