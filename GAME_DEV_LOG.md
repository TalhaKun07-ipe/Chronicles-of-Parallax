# 📖 Degrees of Escape — Master Game Design & Technical Development Log

> **Project:** *Degrees of Escape*  
> **Event:** Intra BUET Robo Challenge 2026 GameJam  
> **Theme:** *Degree of Freedom* (0D → 1D → 2D → 2.5D → 3D → 4D)  
> **Engine:** Godot Engine 4.3+ (GL Compatibility / Forward+)  
> **Target Viewport:** 320×180 (Scaled with integer pixel precision)  
> **Protagonist:** John Rod (Wireframe stickman inspired by *JoJo's Bizarre Adventure: Part 9 - The JOJOLands*)  
> **Status:** Active Pair-Programming & Autonomous Production  

---

## 📑 Table of Contents
1. [Core Concept & Design Philosophy](#1-core-concept--design-philosophy)
2. [Narrative Lore & Intro Cutscene](#2-narrative-lore--intro-cutscene)
3. [Character Design Specification: John Rod](#3-character-design-specification-john-rod)
4. [Dimensional Gameplay Mechanics (0D to 4D)](#4-dimensional-gameplay-mechanics-0d-to-4d)
5. [Complete Architecture & Script Index](#5-complete-architecture--script-index)
6. [Visual Aesthetics, Camera & Rendering System](#6-visual-aesthetics-camera--rendering-system)
7. [Audio Architecture & Sound Synthesis](#7-audio-architecture--sound-synthesis)
8. [Asset & Sprite Generation Pipelines](#8-asset--sprite-generation-pipelines)
9. [Controls & Input Mapping Reference](#9-controls--input-mapping-reference)
10. [Project Directory Layout](#10-project-directory-layout)
11. [Chambers & Level Progression Roadmap](#11-chambers--level-progression-roadmap)
12. [Changelog & Session History (Continuously Maintained)](#12-changelog--session-history)

---

## 1. Core Concept & Design Philosophy

### 1.1 High Concept
*Degrees of Escape* is a perspective-shifting, dimension-unlocking puzzle platformer built for the **Intra BUET Robo Challenge 2026 GameJam** under the theme **"Degree of Freedom"**. 

The player controls **John Rod**, an eccentric wireframe explorer who ventures into an ancient subterranean vault seeking the legendary **Chrono-Lens** (The Ancient Degrees Watch). Upon touching the artifact, a dimensional cataclysm occurs: John Rod is stripped of all spatial and temporal degrees of freedom and cast into the dimensional singularity at the floor of the cavern.

Reduced to a helpless **0-dimensional point**, the player must progressively reclaim their spatial and temporal degrees of freedom:
* **0D (Point):** No translational movement. The player can only pulse the relic's core with rhythmic shockwaves to awaken ancient resonant relays.
* **1D (Line):** 1 Degree of Freedom. Traversal locked onto gleaming energetic conduit rails forwards and backwards.
* **2D (Plane):** 2 Degrees of Freedom. Classic 2D side-scrolling platformer with horizontal running and vertical jumping on a planar slice of reality.
* **2.5D (Layers):** Discrete depth stepping. Shifting between foreground and background tracks across depth pads.
* **3D (Volume):** 3 Degrees of Freedom. Full volumetric continuous movement in 3D space around ancient monoliths and pillars.
* **4D (Time):** The temporal dimension. Rewinding history by up to 4 seconds to rebuild fractured bridges and outmaneuver the time-resistant Dungeon Guardian.

### 1.2 Design Pillars
1. **Mechanical Fluidity over Surface Clutter:** Inspired by *1 2 3D* and *FEZ*, the geometry and environment remain clean, sharp, and readable. Puzzles derive from topological perspective shifts rather than visual visual noise.
2. **Nostalgic Cinematic Pacing:** Inspired by the legendary opening of *Undertale*, narrative exposition uses high-contrast sepia pixel art, typewriter text animations, vintage framing borders, and sound effects that immerse the player before a single room is entered.
3. **Asymmetric Causality:** Time rewind is not a simple game-state reload. It operates asymmetrically: while John Rod and specific resonant structures (e.g. `RewindableBridge`) travel backwards in time, environmental hazards and boss entities exist outside temporal loops and move in real time.

---

## 2. Narrative Lore & Intro Cutscene

### 2.1 The Lore
Deep beneath the tectonic shelf lies the **Sanctum of Degrees**, a construct erected by a forgotten civilization that mastered hyper-dimensional physics. At its epicenter sat the **Chrono-Lens Watch**, a balance wheel that maintained the boundary constraints of physical dimensions.

When John Rod disturbs the watch from its pedestal, the temporal and spatial bounds collapse inward. The sanctuary collapses, sending John Rod plunging down a bottomless void where length, width, and height dissolve into a dimensionless point.

### 2.2 Cinematic Script & Panel Breakdown
The opening cutscene is implemented in `scripts/ui/IntroCutscene.gd` and uses 6 master pixel-art panels generated via `generate_undertale_intro_master.py`.

```
+-------------------------------------------------------------------------+
|                                                                         |
|   +-----------------------------------------------------------------+   |
|   | ############################################################### |   |
|   | #                  ANTIQUE GOLD FRAME BORDER                  # |   |
|   | #  [ 640x360 Sepia Pixel Art Panel with Authentic Bayer Noise ] # |   |
|   | ############################################################### |   |
|   +-----------------------------------------------------------------+   |
|                                                                         |
|      "Long ago, the fabric of reality was anchored by an relic..."      |
|                                                                         |
|                  [SPACE / ENTER / CLICK to continue]                    |
+-------------------------------------------------------------------------+
```

#### Cutscene Script Table
| Panel Index | Art Asset | Narrative Subtitle Text | Audio / SFX |
| :---: | :--- | :--- | :--- |
| **0** | `intro_panel_1.png` | *"Long ago, the fabric of reality was anchored by an ancient relic..."* | Typewriter Blip (`SoundManager.play_sfx("typewriter")`) |
| **0** | `intro_panel_1.png` | *"The Chrono-Lens, forged beyond the boundaries of known dimensions."* | Typewriter Blip |
| **1** | `intro_panel_2.png` | *"Drawn by whispers of lost dimensions, John Rod sought the forgotten vault."* | Ambient Cave Tone |
| **1** | `intro_panel_2.png` | *"Armed with only a lantern, he ventured deep into the silent chasm."* | Footstep Echo |
| **2** | `intro_panel_3.png` | *"At the heart of the inner sanctum, he discovered the Dais."* | Resonant Hum |
| **2** | `intro_panel_3.png` | *"Upon the pedestal rested the Ancient Watch, humming with mysterious power."* | Clockwork Gear Whir |
| **3** | `intro_panel_4.png` | *"Unable to resist the cosmic calling, John Rod reached out to touch the crown."* | Tension Rising |
| **3** | `intro_panel_4.png` | *"In an instant... reality began to fracture!"* | Glass Crack / Energy Arc |
| **4** | `intro_panel_5.png` | *"The sanctuary groaned! The floor gave way beneath his sliding feet!"* | Thunderous Rumble |
| **4** | `intro_panel_5.png` | *"Plunging down the bottomless chasm, his dimensions unraveled one by one..."* | Descending Pitch Shift |
| **5** | `intro_panel_6.png` | *"Depth vanished... height dissolved..."* | Muffled Silence |
| **5** | `intro_panel_6.png` | *"Until upon the cold cavern floor, only a 0-dimensional point remained."* | Solitary Heartbeat Pulse |
| **6** | `Title Screen` | *"DEGREES OF ESCAPE — Break the Dimension Lock"* | Grand Opening Chime |

---

## 3. Character Design Specification: John Rod

### 3.1 Visual Anatomy & Inspiration
John Rod is explicitly based on the wireframe character from **JoJo's Bizarre Adventure: Part 9 - The JOJOLands**.
* **Head:** A clean, hollow metallic wire loop. No human eyes or nose; expression is conveyed through head tilts, bobbing, and torso squash-and-stretch.
* **Torso & Limbs:** Thin, bent cylindrical wire tubing with sharp, angular elbows and knees.
* **Feet:** Signature 90-degree flat planar sliding foot-bars that slide smoothly along floors and conduits.
* **Materials & Shading:** Pure neutral polished steel and chrome (`#DCDDE1`, `#718093`, `#2F3640`). **Zero blue or cyan body tinting**, ensuring extreme contrast against glowing dimensional elements.

```
            O          <-- Hollow wire loop head
           /|
          / | \        <-- Sharp bent-rod arms & tubular torso
            |
           / \         <-- Angular knees
         _L   L_       <-- 90° flat planar sliding feet
```

### 3.2 Dimensional Form Variations
John Rod's visual representation shifts dynamically across each degree of freedom:

| Dimension | Sprite Asset | Dimensions (px) | Description & Behavior |
| :--- | :--- | :---: | :--- |
| **0D (Point)** | `john_rod_0d_point.png`<br>`john_rod_0d_pulse.png` | 128×128 (64×64 avail.) | Concentric metallic bead singularity, centered in frame. Pulses in place; produces expanding rings on `[SPACE]` via `$PulseEffect`. |
| **1D (Line)** | `john_rod_1d_rod.png`<br>`john_rod_1d_rod_active.png` | 128×128 (64×64 avail.) | Horizontal chrome line segment centered in frame that slides along glowing conduit rails with active vibration. |
| **2D (Plane)** | `john_rod_2d_idle.png`<br>`john_rod_2d_walk_1..4.png`<br>`john_rod_2d_crouch.png`<br>`john_rod_2d_jump.png`<br>`john_rod_2d_land.png` | 128×128 (64×64 avail.) | Full wireframe side silhouette. 4-frame fluid walk cycle with 90° sliding step; squash on landing, stretch on jumping, crouch anticipation. Ground baseline at $y = 112$ ($y = 56$ in 64px). |
| **2.5D (Layers)** | `john_rod_25d_idle.png`<br>`john_rod_25d_front.png`<br>`john_rod_25d_back.png`<br>`john_rod_25d_turn.png`<br>`john_rod_25d_walk_1..2.png` | 128×128 (64×64 avail.) | Planar silhouette with specialized turning sprites when stepping toward (foreground) or away from (background) the camera. |
| **3D (Volume)** | `john_rod_3d_front_*`<br>`john_rod_3d_back_*`<br>`john_rod_3d_side_*`<br>`john_rod_3d_iso_*` | 128×128 (64×64 avail.) | 4-angle isometric sprite set (front, back, profile, 45° isometric) with idle and 2-frame walk cycles per view. |
| **4D (Rewind)** | Replays spatial frames backwards + golden aura | 128×128 (64×64 avail.) | Historical state buffer replayed in reverse with pulsating golden chrono-glow (`Color(1.3, 1.15, 0.6)`) and time-warp audio drone. |

---

## 4. Dimensional Gameplay Mechanics (0D to 4D)

### 4.1 Dimension State Matrix
```
   [0D Point]  ===(Relay Activated)===>  [1D Rail]
        ||                                    ||
   (Pulse Wave)                        (Linear Slide)
        ||                                    ||
        v                                     v
   [4D Rewind] <--- [3D Volume] <--- [2.5D Layers] <--- [2D Plane]
  (Time Loop)     (Volumetric)     (Depth Shifting)   (Platforming)
```

### 4.2 Mathematical & Kinematic Specifications

#### 0D — Point Singularity
* **Degrees of Freedom:** 0
* **Kinematics:** `velocity = Vector3.ZERO`. Vertical gravity applies if in mid-air (`velocity.y -= GRAVITY * delta`) until touching the floor.
* **Core Interaction:** Pressing `[SPACE]` triggers `trigger_0d_pulse()`:
  * Scales sprite by 1.4× and snaps back using `Tween.TRANS_BACK`.
  * Emits an expanding concentric ring (`$PulseEffect`) from scale 0.3 to 2.4 while fading alpha to 0.0 over 0.35s.
  * Pulses trigger nearby `ResonantRelays` to power conduit rails and unlock the 1D dimension.

#### 1D — Conduit Rail
* **Degrees of Freedom:** 1 (Translational X along rail vector)
* **Kinematics:**
  $$\vec{v} = \text{Input.get\_axis}("move\_left", "move\_right") \times \text{SPEED\_1D} \times \hat{u}_{rail}$$
  $$\text{SPEED\_1D} = 3.5\text{ m/s}, \quad v_y = 0, \quad v_z = 0$$
* **Mechanic:** Player cannot jump or fall. Sliding along the rail bypasses ground pits.

#### 2D — Planar Platformer
* **Degrees of Freedom:** 2 (X Translation + Y Jump/Gravity)
* **Kinematics:**
  $$v_x = \text{Input.get\_axis}("move\_left", "move\_right") \times \text{SPEED\_2D}$$
  $$v_y(t) = v_y(t-1) - g \cdot \Delta t \quad (g = 18.0\text{ m/s}^2)$$
  $$\text{Jump Impulse: } v_{y,0} = 6.5\text{ m/s}, \quad v_z = 0\text{ (Constrained to plane)}$$
* **Mechanic:** Classic 2D platforming. Horizontal obstacles can be jumped over; gaps must be cleared.

#### 2.5D — Discrete Layer Stepping
* **Degrees of Freedom:** 2 continuous + 1 discrete (Depth lanes)
* **Lane Coordinates:** $Z \in \{-1.5, 0.0, +1.5\}$ (Back, Mid, Front)
* **Kinematics:** Horizontal movement and jump identical to 2D mode.
* **Mechanic:** When standing atop a `LayerSwitchPad`, pressing `[W]` (up/back) or `[S]` (down/forward) transitions the player smoothly across Z lanes via a quad tween ($t = 0.22\text{ s}$). Allows navigating around impassable 2D barricades by stepping behind or in front of them.

#### 3D — Continuous Volumetric Space
* **Degrees of Freedom:** 3 (Continuous X, Y, Z)
* **Kinematics:**
  $$\vec{v}_{ground} = R_{-45^\circ} \cdot \vec{u}_{input} \times \text{SPEED\_3D} \quad (\text{SPEED\_3D} = 4.0\text{ m/s})$$
* **Mechanic:** Full ground freedom. Movement vectors are rotated by $45^\circ$ to match the camera's isometric viewpoint, so `[W]` moves visually "up-right", `[A]` moves "up-left", etc., with complete fluid control.

#### 4D — Temporal Rewind
* **Degrees of Freedom:** +1 Temporal ($t \in [t - 4.0\text{ s}, t]$)
* **Buffer Size:** 240 samples at 60 Hz = 4.0 seconds of historical tracking.
* **Recorded State Vector:**
  $$\mathbf{S}(t) = \left\{ \vec{P}, \vec{V}, \text{Dimension}, \text{FlipH}, \text{Anim} \right\}$$
* **Mechanic:** Holding `[R]` pops states in reverse order ($O(1)$ per tick), playing historical positions backwards with a low-frequency procedural time-warp drone.
* **Environmental Coupling:** The `RewindableBridge` records its breakdown states. When the player rewinds, collapsed bridge blocks fly backward through space and reassemble into an intact walkway.

---

## 5. Complete Architecture & Script Index

The project follows a modular, decoupled architecture adhering to Godot 4 best practices:

```
Degrees_of_Escape/
├── scripts/
│   ├── autoload/
│   │   ├── Global.gd                  <-- Central Game State & Signals
│   │   └── SoundManager.gd            <-- Procedural SFX Engine
│   ├── player/
│   │   ├── Player.gd                  <-- Master Dimensional Controller
│   │   └── RewindController.gd        <-- 4D Ring-Buffer Engine
│   ├── camera/
│   │   └── CameraRig.gd               <-- Dual-Gimbal Perspective Rig
│   ├── levels/
│   │   ├── LevelManager.gd            <-- Chamber Director & Triggers
│   │   └── Prologue_PedestalRoom.gd   <-- Opening Pedestal Sequence
│   ├── boss/
│   │   └── GuardianBoss.gd            <-- Time-Resistant Boss AI
│   ├── mechanics/
│   │   ├── RewindableBridge.gd        <-- 4D Reconstructible Structure
│   │   ├── RailConduit.gd             <-- 1D Linear Track
│   │   └── LayerSwitchPad.gd          <-- 2.5D Depth Switcher
│   ├── objects/
│   │   ├── Pedestal.gd                <-- Artifact Pedestal Node
│   │   └── Torch.gd                   <-- Dungeon Lighting & Particles
│   └── ui/
│       ├── IntroCutscene.gd           <-- Undertale-Style Narrative Intro
│       └── HUD.gd                     <-- Vintage Watch UI & Gauge
```

### 5.1 Autoload Systems

#### `Global.gd` (`res://scripts/autoload/Global.gd`)
* **Role:** Single source of truth for dimensional status, health, and cross-system events.
* **Key Properties:**
  * `active_dimension: Dimension` (Default `DIM_0D`)
  * `unlocked_dimensions: Dictionary` (Tracks `DIM_0D` through `DIM_3D`)
  * `rewind_unlocked: bool`, `is_rewinding: bool`
  * `max_health: int = 3`, `current_health: int = 3`
* **Key Signals:**
  * `dimension_changed(new_dim, old_dim)`
  * `rewind_started()`, `rewind_ended()`
  * `ability_unlocked(dim)`
  * `health_changed(new_hp)`
* **Core Methods:**
  * `unlock_dimension(dim)`: Grants new degree of freedom and fires audio/visual alert.
  * `set_dimension(dim)`: Validates unlocks, updates active dimension, triggers transition effects.
  * `cycle_dimension(dir)`: Cycles through currently unlocked dimensions (`[Q]` / `[E]`).

#### `SoundManager.gd` (`res://scripts/autoload/SoundManager.gd`)
* **Role:** Fully procedural audio synthesizer. Generates dynamic audio streams via raw `AudioStreamWAV` sample buffers without external heavy sound files.
* **Key Sounds:**
  * `"jump"`: Exponential frequency rise (200 Hz → 600 Hz over 0.15s).
  * `"transform"`: Dual harmonic descent (600 Hz → 250 Hz with 4× overtone).
  * `"pulse"`: Sub-bass metallic gong (120 Hz damped sine wave).
  * `"rewind_loop"`: Continuous phasing oscillation modulated at 8 Hz.
  * `"typewriter"`: Randomized micro-click (1800 Hz–2400 Hz burst over 12ms).
  * `"hurt"`, `"unlock"`, `"error"`: Distinct tonal signals.

### 5.2 Player & Temporal Controller

#### `Player.gd` (`res://scripts/player/Player.gd`)
* **Role:** Unified CharacterBody3D implementing state-specific physics for 0D, 1D, 2D, 2.5D, and 3D.
* **Key Components:**
  * `$Sprite3D`: Billboarding 2D/3D sprite displaying John Rod's current animation.
  * `$PulseEffect`: Concentric ring sprite animated during 0D pulses.
  * `$CollisionShape3D`: Dynamically resizes collision bounding box per dimension (compact 0.3m sphere in 0D; tall 1.2m cylinder in 2D/3D).
  * `$RewindController`: Handles 4D historical recording and playback.
  * `$Shadow`: Dynamically scaled ground contact shadow.
* **Key Features:**
  * Juice / Game Feel: Programmatic squash-and-stretch on jumps (`0.82x, 1.25y, 0.82z`) and landings (`1.25x, 0.78y, 1.25z`).
  * Automatic Z-Snapping: Snaps player back to `Z = 0.0` when transitioning from 3D back into 2D or 1D.

#### `RewindController.gd` (`res://scripts/player/RewindController.gd`)
* **Role:** 4D time-loop controller.
* **Buffer Management:** Fixed circular buffer of 240 ticks (`MAX_HISTORY = 240`). Drops oldest frames once capacity is exceeded.
* **State Restitution:** On reverse playback, restores position, resets velocity, restores previous active dimension, sprite flip direction, and animation pose.

### 5.3 Camera & Perspective

#### `CameraRig.gd` (`res://scripts/camera/CameraRig.gd`)
* **Role:** Dual-gimbal orthogonal camera rig mirroring the perspective mechanism of *1 2 3D* and *FEZ*.
* **Gimbal Structure:**
  * `cam_root_1 (self)`: Controls Y yaw rotation.
  * `cam_root_2 ($CamRoot2)`: Controls X pitch rotation.
  * `camera_3d ($CamRoot2/Camera3D)`: Orthogonal camera (`PROJECTION_ORTHOGONAL`, `size = 6.5`).
* **Rotation Presets:**
  * **2D / 1D / 0D Mode:** `Yaw = 0.0°`, `Pitch = 0.0°` (True flat orthogonal side elevation).
  * **3D Mode:** `Yaw = -45.0°`, `Pitch = -30.0°` (True isometric 3D projection).
* **Smooth Interpolation:** Cubic easing tween over 0.45s creates a mind-bending perspective rotation when shifting between 2D and 3D.

### 5.4 Levels, Boss & Interactive Objects

#### `LevelManager.gd` (`res://scripts/levels/LevelManager.gd`)
* Coordinates chamber gates, trigger volumes (`Chamber1Unlock` through `Chamber4Unlock`), unlocks, and boss progression.

#### `GuardianBoss.gd` (`res://scripts/boss/GuardianBoss.gd`)
* Multi-phase dungeon guardian designed to test all acquired degrees of freedom.
* **Attack Phases:**
  1. `ATTACK_SWEEP`: Sweeps across the X plane; must be jumped over in 2D or dodged laterally in 3D.
  2. `ATTACK_LANE`: Smashes a specific Z depth lane; must be avoided by lane shifting in 2.5D.
  3. `ATTACK_COLLAPSE`: Destroys the central bridge, forcing the player to use 4D time rewind to rebuild the path to the boss's exposed core.
* **Exposed Core Phase:** Following a collapse, the boss enters `EXPOSED_RECOVERY` for 5.0 seconds. The player must rewind time, run across the reconstructed bridge, and strike the glowing core.

#### `RewindableBridge.gd` (`res://scripts/mechanics/RewindableBridge.gd`)
* Segmented bridge that shatters when triggered. It maintains its own local state buffer and reconstructs seamlessly when the player activates temporal rewind.

---

## 6. Visual Aesthetics, Camera & Rendering System

### 6.1 Viewport & Pixel-Perfect Pipeline
* **Base Virtual Resolution:** 320 × 180 (16:9 native retro aspect).
* **Display Stretch Mode:** `viewport`, Aspect: `keep`.
* **Filtering:** Nearest Neighbor texture filtering on all pixel art sprites and world textures to prevent bilinear blur and maintain razor-sharp retro edges.
* **Godot 4 Rendering Method:** `gl_compatibility` ensuring high frame rate performance across all hardware.

### 6.2 Environment & Dungeon Palette
* **Floor & Pavers:** Dark slate gray with subtle edge highlights (`#22252A`, `#343A40`).
* **Ancient Columns:** Weathered stone with carved runic grooves (`#495057`, `#6C757D`).
* **Glowing Conduits (1D):** Vibrant cyan emissive glow (`#00F5D4`).
* **Depth Pads (2.5D):** Rich amber runic glyphs (`#F1C40F`).
* **Watch UI & Accents:** Antique brass and gold (`#D4AF37`, `#AA7C11`).

---

## 7. Audio Architecture & Sound Synthesis

The audio subsystem is 100% self-contained, requiring zero external audio file dependencies.
* **Synthesis Method:** Godot `AudioStreamWAV` generating 16-bit mono buffers at 22,050 Hz sampling rate.
* **Tone Formulas:** Procedural combinations of pure sine waves, frequency sweeps, white noise burst modulation, and harmonic overtones.
* **Dedicated Rewind Audio Bus:** The temporal rewind sound uses an active procedural loop that seamlessly synchronizes with the `[HOLD R]` input.

---

## 8. Asset & Sprite Generation Pipelines

The repository includes dedicated Python generator scripts leveraging Pillow (PIL) to procedurally synthesize game-ready pixel art assets:

### 8.1 Generator Scripts
1. **`generate_undertale_intro_master.py`:**
   * Generates the 6 Undertale intro panels (`assets/intro/intro_panel_1.png` to `intro_panel_6.png`).
   * Implements 4x4 Bayer ordered dithering, noise perturbation, high-contrast silhouettes, and the authentic Undertale gold/sepia 5-color palette:
     * Deep Void: `#140C04`
     * Shadow Brown: `#3B220B`
     * Mid Sepia: `#7D5523`
     * Warm Ochre: `#C29F5C`
     * Antique Parchment: `#EBD8B0`
2. **`generate_all_assets.py`:**
   * Generates world texture atlases: `floor_pavers.png`, `wall_stone.png`, `conduit_rail.png`, `bridge_intact.png`, `bridge_cracked.png`, `ancient_watch_hud.png`.
   * Generates John Rod character sheets for all dimensions.

---

## 9. Controls & Input Mapping Reference

All inputs are configured in `project.godot`:

| Action ID | Keybinding | In-Game Function | Available In |
| :--- | :--- | :--- | :--- |
| `move_left` / `move_right` | `A` / `D` or `Left` / `Right` | Move along X axis / rail | 1D, 2D, 2.5D, 3D |
| `move_up` / `move_down` | `W` / `S` or `Up` / `Down` | Shift depth lane / Move Z | 2.5D (at pads), 3D |
| `jump` | `Space` | Jump (2D/3D) / Pulse Watch (0D) | All dimensions |
| `rewind` | **Hold `R`** | Rewind time up to 4.0s | Unlocked at Boss |
| `interact_strike` | `F` | Strike exposed boss core | Boss arena |
| `dimension_1` | `1` | Direct select 1D Rail | When unlocked |
| `dimension_2` | `2` | Direct select 2D Plane | When unlocked |
| `dimension_3` | `3` | Direct select 2.5D Layers | When unlocked |
| `dimension_4` | `4` | Direct select 3D Volume | When unlocked |
| `cycle_prev` / `cycle_next` | `Q` / `E` | Cycle unlocked dimensions | When >1 unlocked |
| `ui_cancel` | `Escape` | Skip intro cutscene / Pause | Everywhere |

---

## 10. Project Directory Layout

```
Degrees_of_Escape/
├── project.godot                          # Main Godot 4.3 project configuration
├── README.md                              # Public project summary & Jam info
├── GAME_DEV_LOG.md                        # Master Technical & Design Bible (This File)
├── generate_undertale_intro_master.py     # Master PIL pixel art generator for Intro
├── generate_all_assets.py                 # Procedural texture atlas & sprite generator
├── assets/
│   ├── intro/                             # 6 Intro cutscene panels (640x360 pixel art)
│   │   ├── intro_panel_1.png ... intro_panel_6.png
│   ├── sprites/                           # John Rod character sprite sheets
│   │   ├── john_rod_0d_point.png
│   │   ├── john_rod_1d_rod.png
│   │   ├── john_rod_2d_*.png (idle, jump, walk_1..4)
│   │   ├── john_rod_25d_*.png (idle, front, back)
│   │   └── john_rod_3d_*.png (iso, front, back, side walk cycles)
│   ├── textures/                          # Modular dungeon floor, wall, and bridge textures
│   └── ui/                                # Antique watch bezel and HUD assets
├── scenes/
│   ├── camera/
│   │   └── CameraRig.tscn                 # Dual-gimbal camera rig scene
│   ├── entities/
│   │   └── GuardianBoss.tscn              # Boss battle entity scene
│   ├── levels/
│   │   ├── Main.tscn                      # Primary multi-chamber level scene
│   │   └── Prologue_PedestalRoom.tscn     # Pedestal room scene
│   ├── objects/
│   │   ├── Pedestal.tscn
│   │   ├── RewindableBridge.tscn
│   │   └── Torch.tscn
│   ├── player/
│   │   └── Player.tscn                    # Player CharacterBody3D with Sprite3D & Rewind
│   └── ui/
│       ├── HUD.tscn                       # Active watch bezel, HP, and control hint overlay
│       └── IntroCutscene.tscn             # Typewriter narrative intro scene
└── scripts/                               # Full GDScript architecture (Section 5)
```

---

## 11. Chambers & Level Progression Roadmap

```
+-------------------------------------------------------------------------------+
|  CHAMBER 0: THE SINGULARITY (0D)                                              |
|  - Wake up at cavern floor as a 0D metallic point.                            |
|  - Pulse [SPACE] to energize acoustic floor crystal.                          |
|  - Unlocks: 1D Conduit Rail.                                                  |
+-------------------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------------------+
|  CHAMBER 1: CONDUIT LINE (1D)                                                 |
|  - Slide along X axis [A/D] across an abyss of spikes.                        |
|  - Avoid ceiling crushers by timing slides.                                   |
|  - Reach 2D Prismatic Gateway. Unlocks: 2D Plane.                             |
+-------------------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------------------+
|  CHAMBER 2: THE PLANAR LEAP (2D)                                              |
|  - Classic side-scrolling platforming with jumping [SPACE].                   |
|  - Leap across moving stone blocks and crumbling ledges.                      |
|  - Encounter an impassable towering iron gate. Unlocks: 2.5D Layers.          |
+-------------------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------------------+
|  CHAMBER 3: DEPTH WEAVING (2.5D)                                              |
|  - Step between Foreground (Z = +1.5) and Background (Z = -1.5) at pads.     |
|  - Bypass the iron gate by walking behind it on the background track.         |
|  - Unlocks: 3D Volumetric Movement.                                           |
+-------------------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------------------+
|  CHAMBER 4: MONOLITH LABYRINTH (3D)                                           |
|  - Camera shifts into full 45° isometric perspective.                         |
|  - Continuous [WASD] volumetric traversal around ancient round pillars.       |
|  - Solve 3-pillar spatial alignment puzzle to open the Boss Sanctum door.      |
+-------------------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------------------+
|  CHAMBER 5: TEMPORAL SINGULARITY (BOSS BATTLE: THE GUARDIAN)                 |
|  - Confront the ancient Time-Anchor Guardian.                                 |
|  - Dodge sweeping beams (2D/3D) and lane strikes (2.5D).                     |
|  - Boss smashes central bridge and exposes glowing core.                      |
|  - Hold [R] to rewind time: reconstructed bridge forms under your feet!       |
|  - Sprint forward in real-time, strike the exposed core [F], defeat guardian! |
+-------------------------------------------------------------------------------+
```

---

## 12. Changelog & Session History

### Session 1: Foundation & Core Systems
* **Architecture:** Established Godot 4.3 project structure with `Global.gd` autoload and signal hub.
* **Player Controller:** Built `Player.gd` supporting kinematic state switches for 0D, 1D, 2D, 2.5D, and 3D.
* **Juice & Feel:** Added programmatic jump stretch, landing squash, and 0D pulse wave animation.
* **Camera Rig:** Created dual-gimbal orthogonal camera rig in `CameraRig.gd` that smoothly interpolates between flat 2D elevation and 45° isometric 3D projection.
* **4D Rewind Engine:** Implemented `RewindController.gd` with 240-tick circular history buffer for player and objects.
* **Procedural Sound:** Developed `SoundManager.gd` synthesizing audio waves dynamically without external audio assets.
* **Boss AI:** Programmed `GuardianBoss.gd` with asymmetric time immunity, multi-phase attacks, and bridge smash mechanic.
* **HUD:** Created `HUD.gd` featuring an antique watch bezel, active dimension indicator, rewind gauge, and dynamic keybinding hints.

### Session 2: Character Identity & Visual Alignment
* **Protagonist Specification:** Fully defined **John Rod** wireframe stickman design from *JoJo's Bizarre Adventure: Part 9 - The JOJOLands* (hollow wire head, 90° planar sliding feet, polished chrome steel material).
* **Sprite Generation:** Generated dedicated sprite sheets for 0D point, 1D rod, 2D walk/jump, 2.5D lane shifts, and 3D isometric walk cycles.
* **Texture Atlases:** Synthesized dungeon tiles (pavers, walls, conduit rails, fractured/intact bridges).

### Session 3: Undertale Cinematic Intro System
* **Cutscene Framework:** Built `IntroCutscene.tscn` and `IntroCutscene.gd` featuring typewriter text display, sound blip synchronization, antique gold framing border, and smooth scene transitions.
* **Master Art Generation:** Created `generate_undertale_intro_master.py` with 4x4 Bayer dithering and authentic 5-color sepia/gold palette, producing all 6 master narrative panels (`intro_panel_1.png` through `intro_panel_6.png`).
* **Story Script:** Authored complete 12-page narrative sequence detailing John Rod's expedition, discovery of the Chrono-Lens, spatial unraveling, and descent into 0D.

### Session 4: Master Documentation & Continuous Log System
* **Log Creation:** Initialized `GAME_DEV_LOG.md` as the unified technical and design bible for the entire project.
* **Cross-References:** Linked `GAME_DEV_LOG.md` from `README.md` to ensure all ongoing and future development turns maintain an exhaustive, continuous record.

### Session 5: Master Sprite & High-Resolution Intro Art Integration
* **Folder Integration (`assets/use this instead`):**
  * Integrated the 6 custom Undertale-style cinematic narrative illustrations into `assets/intro/intro_panel_1.png` through `intro_panel_6.png` with 1:1 thematic alignment to the 12 story beats.
  * Extracted, keyed, speckle-filtered, and anchored all 48 character animations from the master sheet `ChatGPT Image Sep 13, 2026, 12_37_09 PM.png`.
* **Sprite Catalog Expansion:**
  * **0D:** Added `john_rod_0d_point.png`, `john_rod_0d_sphere.png`, and `john_rod_0d_pulse.png`.
  * **1D:** Added `john_rod_1d_rod.png` and `john_rod_1d_rod_active.png`.
  * **2D:** Added `john_rod_2d_idle.png`, `walk_1..4.png`, `crouch.png`, `jump.png`, and `land.png`.
  * **2.5D:** Added `john_rod_25d_idle.png`, `front.png`, `back.png`, `walk_1..2.png`, and `turn.png`.
  * **3D:** Added full 8-directional isometric animations (`front_idle/walk`, `iso_idle/walk`, `side_idle/walk`, `back_idle/walk`).
  * **Chrono-Lens Watch:** Extracted 8 watch-equipped walk, pose, and run frames (`john_rod_watch_1..8.png`).
  * **4D Time Rewind:** Extracted 8-frame golden temporal afterimage sprint cycle (`john_rod_rewind_1..8.png`).
* **Engine Script & Kinematic Tuning:**
  * Updated `Player.gd` with `TEX_REWIND` animation cycle, `TEX_2D_CROUCH`, `TEX_2D_LAND`, and adjusted sprite sizing/positioning (`pixel_size = 0.007`, `position.y = 0.60`).
  * Added `process_rewind_visuals()` to `Player.gd` for dynamic temporal afterimages when holding `[R]`.
  * Fixed indentation bug in `Prologue_PedestalRoom.gd`.
  * Validated complete asset import and compilation in Godot 4.7 headless with 0 errors.

### Session 6: John Rod Sprite Pack v2 & Dual-Resolution Architecture
* **Source Integration (`sprites/John_Rod_Sprites_v2`):**
  * Evaluated and deployed the full 30-design John Rod v2 sprite collection provided in `sprites/John_Rod_Sprites_v2` (containing both `sprites_128/` and `sprites_64/`).
  * Deployed `sprites_128/` directly into `res://assets/sprites/` as the primary active character model set (31 transparent PNGs including the `john_rod_idle.png` compatibility alias).
  * Maintained full subdirectories `res://assets/sprites/sprites_128/` and `res://assets/sprites/sprites_64/` with all 62 textures for seamless resolution switching.
* **Dual-Resolution System:**
  * Added `Global.SpriteResolution { RES_64, RES_128 }`, `Global.sprite_resolution`, and `Global.sprite_resolution_changed` signal in `Global.gd`.
  * Configured active in-game runtime toggle via `[F8]` key in `Player.gd`, allowing instant hot-swapping between crisp 128px HD wireframes and authentic 64px retro pixel art.
  * Mathematical scaling calibration:
    * **128px mode:** Humanoid feet at $y=112$ (distance from center $y=64$ is $48\text{ px}$). At `pixel_size = 0.012`, offset is $48 \times 0.012 = 0.576\text{ m}$. With `Sprite3D` at $y=0.58$, feet rest exactly at $y \approx 0.0\text{ m}$ (on the floor).
    * **64px mode:** Humanoid feet at $y=56$ (distance from center $y=32$ is $24\text{ px}$). At `pixel_size = 0.024`, offset is $24 \times 0.024 = 0.576\text{ m}$, maintaining identical physical ground alignment and collision bounds across resolutions.
    * **0D/1D centering:** Positioned at $y=0.22$ and $y=0.20$ respectively, centered on rail and pulse geometry.
* **Expanded Kinematic & Pose Features:**
  * **0D:** Employs `john_rod_0d_point.png` for resting singularity and `john_rod_0d_pulse.png` for the expanding concentric shockwave.
  * **1D:** Dynamic active rail friction using `john_rod_1d_rod_active.png` during horizontal slide, resting back to `john_rod_1d_rod.png`.
  * **2D:** Implemented 4-frame walk cycle (`walk_1..4`), jump stretch (`jump`), floor landing squash (`land`), and down-input ducking (`crouch`).
  * **2.5D:** Dedicated depth-layer animations with `walk_1..2`, forward lane step (`front`), backward lane step (`back`), and mid-transition angle (`turn`).
  * **3D:** 4-angle isometric direction-matching locomotion (iso diagonal, front, back, profile side) with idle and 2-frame walk cycles per perspective.
  * **4D Rewind:** Synchronized golden chrono-aura modulation (`Color(1.3, 1.15, 0.6)`) during history buffer unwinding.
* **Engine Verification:**
  * Headless editor scan and compilation verified with Godot 4.7.2 with 0 errors.

### Session 7: Implementation of Revised Design Architecture (Combine Space, Earn Time)
* **Core Paradigm Shift:**
  * Adopted the design manifesto from `Degrees_of_Escape_Revised_Plan.md`: *"Learn to combine space; earn control over time."*
  * Replaced the linear single-dimension unlocking ladder with simultaneous access to **1D, 2D, and 3D from the start of playable exploration**.
  * 0D Point Singularity repurposed into a brief narrative state during the crash landing; the Chrono-Lens flickers back to life, expanding John into Line, Plane, and Volume.
  * 4D Time Rewind reserved as the climactic reward earned upon defeating the Guardian boss.
* **Component Architecture Built & Deployed:**
  * **`ConduitRail` (`scenes/objects/ConduitRail.tscn` / `scripts/objects/ConduitRail.gd`):** Glowing cyan rail for 1D sliding. Detects player alignment, constrains movement strictly along rail line, and passes beneath low blast doors.
  * **`EnergyCharge` (`scenes/objects/EnergyCharge.tscn` / `scripts/objects/EnergyCharge.gd`):** Floating crystalline power core collected on touch (`Global.collect_charge()`), surviving spatial dimension shifts.
  * **`EnergyReceiver` (`scenes/objects/EnergyReceiver.tscn` / `scripts/objects/EnergyReceiver.gd`):** Ancient power socket that accepts carried charge to energize linked mechanisms, runic platforms, and doors.
  * **`RunicPlatform` (`scenes/objects/RunicPlatform.tscn` / `scripts/objects/RunicPlatform.gd`):** Dimension-dependent architecture: solid and brightly glowing in 2D mode; faint non-colliding outlines in 3D/1D mode.
  * **`ChamberDoor` (`scenes/objects/ChamberDoor.tscn` / `scripts/objects/ChamberDoor.gd`):** Vertical stone blast door with bottom slot clearance for 1D passage.
  * **`MechanicalShutter` (`scenes/objects/MechanicalShutter.tscn` / `scripts/objects/MechanicalShutter.gd`):** Timed pulsing barrier with warning flash and safe pushback.
  * **`MechanicalLever` (`scenes/objects/MechanicalLever.tscn` / `scripts/objects/MechanicalLever.gd`):** Interactive switch operable with `[F]` or touch.
* **Kinematic & Player Rules Updated (`Player.gd`):**
  * Direct form selection via keys `[1]` (1D Rail), `[2]` (2D Plane), `[3]` (3D Volume).
  * **1D Alignment Rule:** Player can only enter 1D when aligned with or touching an active conduit; snaps $Y$ and $Z$ to rail line.
  * **2D Depth Lock Rule:** Entering 2D freezes John's current depth coordinate ($Z$), preserving world position without teleportation. Returning to 3D restores free depth movement from that exact coordinate.
  * **Solid Clearance Check:** Physics shape query prevents expanding into solid geometry (rejects with watch flicker and error cue).
  * **Charge Carrier Visual:** Added `$ChargeOrb` sprite hovering above John Rod's head when holding an energy core.
* **Boss Encounter Overhaul (`GuardianBoss.gd`):**
  * Rebuilt into a 2-cycle spatial puzzle battle under pressure with rewind strictly locked.
  * Cycle: Guardian slam exposes low conduit $\rightarrow$ 1D slide to safe rear recess $\rightarrow$ 3D flank behind boss to pull lever $\rightarrow$ reveals 2D runic footholds $\rightarrow$ 2D climb and strike core.
  * On defeat: Guardian falls, shattering the time seal (`Global.unlock_rewind()`), triggering the collapse of the escape staircase.
* **First Playable Chamber Built (`Arrival_BrokenCircuit.tscn` / `Arrival_BrokenCircuit.gd`):**
  * Fully realized first puzzle room: sealed door with low conduit $\rightarrow$ 3D pillar bypass to hidden receiver $\rightarrow$ activates 2D runic ledges leading to upper doorway.
  * Updated `IntroCutscene.gd` story pages with the Chrono-Lens reactivation and seamless scene transition directly into `Arrival_BrokenCircuit.tscn`.
* **Engine Verification:**
  * Complete project scan and class registration in Godot 4.7.2 headless mode passed with exit code 0 and zero errors.

### Session 8: Full Integration of Chamber 01 — The Broken Circuit (`chambers/broken_circuit`)
* **Package Integration (`1st chamber gameplay/Broken_Circuit_Godot`):**
  * Integrated the complete, 32-check verified **Chamber 01: The Broken Circuit** package into `res://chambers/broken_circuit/`.
  * Preserved full namespaced directory structure: `BrokenCircuit.tscn` (geometry, lighting, mechanisms, materials), `Demo.tscn` (master chamber controller with player, camera, and HUD), `scripts/` (`chamber.gd`, `demo.gd`, `player.gd`), and `assets/sprites/` (approved John Rod v2 64px sprites).
* **Cinematic Flow & Transition Wiring:**
  * Updated `IntroCutscene.gd` (`start_game()` and `skip_to_game()`) to cleanly transition directly from the Undertale-style opening story into `res://chambers/broken_circuit/Demo.tscn`.
  * Connected `chamber_completed` in `demo.gd` to `SceneTransition.change_chamber("res://scenes/levels/Chamber1_DimensionalTrial.tscn")` with a 1.6s delay for victory audio and completion message display.
* **Global Game State & Input Synchronization:**
  * In `demo.gd`: Initialized `Global.current_chamber_id = "broken_circuit"`, spatial dimensions (1D, 2D, 3D), and `SceneTransition.fade_in_from_black(0.4)`.
  * Synchronized charge collection (`Global.carried_charge = true`, `charge_state_changed`), receiver powering (`receiver_powered = true`), and exit unlocking (`exit_open = true`).
  * In `player.gd`: Updated controller input processing to support both Godot InputMap actions (`dimension_1..3`, `cycle_prev/next`, `jump`, `interact_strike`, `move_left/right/up/down`) and raw physical keyboard keys for total flexibility.
* **Automated & Manual Verification:**
  * Ran `tools/verify_route.gd` under Godot 4.7.2 headless in the main project: **All 32 physics and state checks passed** (conduit 1D entry, pit transit, expansion clearance rejection, charge pickup, monolith obstruction, 3D flank, receiver interaction, 2D depth preservation at $Z=-2.5$, runic step collision activation, 4 consecutive step jumps, and exit completion).
  * Authored and executed `tools/verify_integration_flow.gd`: **100% passed** verifying instantiation of `IntroCutscene.tscn`, triggering skip/continue, smooth scene replacement to `BrokenCircuitDemo`, and presence of Player, Chamber, Camera3D, and HUD nodes.

### Session 9: Mechanics, Perspective & Screen-Filling Platforming Overhaul
* **Reference Alignment (`game reference video.mp4` / `123D`):**
  * Dissected gameplay capture and unpacked PCK reference: confirmed block-based level design, intimate camera framing (`size ≈ 5.2`), true isometric perspective (`Yaw = -45.0°`, `Pitch = -30.0°`), and flat orthogonal 2D platforming (`Yaw = 0.0°`, `Pitch = 0.0°`).
* **Camera System Calibration (`demo.gd`, `CameraRig.gd`, `CameraRig.tscn`):**
  * Reduced default camera orthogonal size from wide `8.0`–`18.8` to intimate **`size = 5.2`**, ensuring platforms and John Rod fill the screen prominently.
  * Removed wide-view establishing shot delay so gameplay opens immediately in the screen-filling framing.
  * Updated camera target tracking to dynamically follow John Rod across $X$, $Y$, and depth $Z$ (`focus.y = player.position.y + 0.85`, following depth $Z$ in 3D mode).
  * Retained `[M]` key map toggle: expands camera to `14.0` for whole-room view and returns smoothly to `5.2` on toggle off.
* **Dimensional Controls & Locomotion (`player.gd`):**
  * Configured `[Q]` to Count DOWN dimensions ($3\text{D} \rightarrow 2\text{D} \rightarrow 1\text{D}$) and `[E]` to Count UP dimensions ($1\text{D} \rightarrow 2\text{D} \rightarrow 3\text{D}$).
  * Retained direct keys `[1]`, `[2]`, `[3]` and aliases `[Z]` / `[X]`.
  * Calibrated 3D ground controls with $-45^\circ$ rotation to match the camera's isometric diagonal orientation.
* **HUD Refinement:**
  * Updated top bar with active dimension, charge state, and dynamic `[Q]` / `[E]` cycling prompts.
* **Automated Verification:**
  * Created and executed `tools/verify_mechanisms.gd`: validated camera angles (-45°/-30° in 3D, 0°/0° in 2D), camera size (5.2), Q count down, E count up, 1D conduit constraints, and dynamic Z/Y tracking with 100% pass rate.
  * Re-ran `tools/verify_route.gd`: all 32 route and physics checks passed with exit code 0.




