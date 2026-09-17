# 🛠️ HOW WE CODE — Degrees of Escape: Technical Architecture & Development Manual

> **Project:** *Degrees of Escape*  
> **Event:** Intra BUET Robo Challenge 2026 GameJam  
> **Theme:** *Degree of Freedom* (0D → 1D → 2D → 2.5D → 3D → 4D)  
> **Engine:** Godot Engine 4.3+ / 4.7.2 (Forward+ / GL Compatibility)  
> **Target Resolution:** 1280×720 (HD CanvasItems with 4× MSAA 3D + Crisp Nearest-Neighbor Sprites)  
> **Protagonist:** John Rod (Polished steel wireframe explorer inspired by *JoJo's Bizarre Adventure: The JOJOLands*)  
> **Git Repository:** `https://github.com/TalhaKun07-ipe/Degrees-of-Escape.git`  
> **Status:** Authoritative Codebase & Engineering Reference  

---

## 📑 Table of Contents
1. [Core Architectural Philosophy & Vision](#1-core-architectural-philosophy--vision)
2. [Project Topology & File Ownership](#2-project-topology--file-ownership)
3. [Engine Configuration & Rendering Pipeline](#3-engine-configuration--rendering-pipeline)
4. [Global Singletons & State Management](#4-global-singletons--state-management)
5. [The Dimensional Kinematic Engine](#5-the-dimensional-kinematic-engine)
6. [Camera, Perspective & Screen-Filling Axonometric Rig](#6-camera-perspective--screen-filling-axonometric-rig)
7. [Chamber Construction & Environmental Systems](#7-chamber-construction--environmental-systems)
8. [Entity & Dimensional AI Systems](#8-entity--dimensional-ai-systems)
9. [UI, Dialogue & Audiovisual Architecture](#9-ui-dialogue--audiovisual-architecture)
10. [Automated Testing & Verification Suite](#10-automated-testing--verification-suite)
11. [Procedural Asset Generation Toolchain](#11-procedural-asset-generation-toolchain)
12. [GDScript Coding Standards & Best Practices](#12-gdscript-coding-standards--best-practices)
13. [The Golden Rule: Continuous Development & Git Protocol](#13-the-golden-rule-continuous-development--git-protocol)

---

## 1. Core Architectural Philosophy & Vision

### 1.1 The "Degree of Freedom" Concept
*Degrees of Escape* is designed around the progressive reclamation of physical and temporal degrees of freedom:
* **0D (Point Singularity):** Zero translational axes ($X=0, Y=0, Z=0$). Player emits stationary resonant shockwaves to trigger awakenings.
* **1D (Linear Rail):** One axis of motion ($X$). Constrained to gleaming conduit rails; lateral and vertical axes locked.
* **2D (Planar Slice):** Two axes of motion ($X, Y$). Classic 2D side-scrolling platformer with running, gravity, and jumping. The depth axis ($Z$) is pinned to a fixed plane.
* **2.5D (Discrete Layer Switching):** Planar traversal with stepped transitions across parallel $Z$-planes at designated pads.
* **3D (Volumetric Freedom):** Full three-dimensional Cartesian continuous motion ($X, Y, Z$) through courtyards, around pillars, and across walkways.
* **4D (Temporal Rewind):** The temporal axis ($T$). Ring-buffer recording allows rewind up to 4.0 seconds into the past to reconstruct collapsed structures and outplay hazards.

### 1.2 Design Pillars
1. **Geometric Readability Over Surface Clutter:** Mechanics are driven by topological constraints and dimensional transitions, inspired by *1 2 3D* and *FEZ*. The environment is sharp, clean, and immediately readable.
2. **Asymmetric Causality in Time Manipulation:** Time rewind does not reset the entire game state. Only John Rod and resonant chrono-structures (e.g. `RewindableBridge`) travel back in time. Hazards and boss sentinels operate in real-time.
3. **Nostalgic Cinematic Pacing:** Inspired by *Undertale*, narrative beats, cutscenes, and dialogues use high-contrast sepia pixel art, typewriter text crawls, character portraits, and vintage framing.
4. **Resilient, Decoupled Code Architecture:** Autoload singletons manage shared state via signals. Kinematics, rendering, chamber logic, and UI communicate strictly through loose coupling.

---

## 2. Project Topology & File Ownership

```
Degrees_of_Escape/
├── project.godot                  # Engine project configuration & input maps
├── HOW_WE_CODE.md                 # This authoritative technical manual
├── GAME_DEV_LOG.md                # Comprehensive changelog of every session
├── README.md                      # Public project overview & team guide
├── AGENTS.md                      # Permanent agent workflow instructions
│
├── assets/                        # Shared binary & static assets
│   ├── audio/                     # Synthesized & sample audio effects
│   ├── fonts/                     # Retro pixel typography (Early GameBoy, Undertale style)
│   ├── sprites/                   # Master sprite collections for John Rod & props
│   └── ui/                        # HUD hearts, portraits, borders, icons
│
├── chambers/                      # Self-contained chamber packages
│   └── broken_circuit/            # Chamber 01: The Broken Circuit
│       ├── BrokenCircuit.tscn     # 3D level geometry, lighting, colliders, & materials
│       ├── Demo.tscn              # Master runtime scene with Player, Camera3D, & HUD
│       ├── stone.gdshader         # Procedural architectural masonry shader
│       ├── assets/sprites/        # Dedicated chamber sprites (John Rod v2, Flat Guardian)
│       └── scripts/               # Chamber-specific logic
│           ├── chamber.gd         # Chamber environment, materials & trigger coordinator
│           ├── demo.gd            # Session controller, HUD orchestrator, map manager
│           ├── flat_guardian.gd   # Dimensional sentinel AI (3D pursuit vs 2D ethereal)
│           ├── integration.gd     # Test flow coordinator
│           └── player.gd          # Chamber player controller with dual-input mapping
│   └── axiom_warden/              # Chamber 02: Axiom Warden Sanctum
│       ├── AxiomWarden.tscn       # Master boss encounter scene
│       ├── assets/                # Boss pack portraits, textures, and sprites
│       └── scripts/               # Sanctum logic & encounter systems
│           ├── encounter.gd       # World builder, state machine, 6 phases, camera rig
│           ├── geometry.gd        # Architectural blocks, columns, and torch sconces
│           ├── hazard.gd          # Sweeps, beams, bolts, lanes, slams & nova hazards
│           ├── hud.gd             # Pixel hearts, dialogue portraits, health bars
│           ├── player.gd          # Dimension-switching combat controller
│           └── warden.gd          # Visual rig, articulated limbs, and core exposure
│
├── scenes/                        # Shared scene templates
│   ├── levels/                    # Master scene compositions (Main.tscn)
│   ├── objects/                   # Prefabricated gameplay entities (RewindableBridge.tscn)
│   └── ui/                        # UI templates (HUD.tscn, UndertaleDialogueBox.tscn)
│
├── scripts/                       # Core system & engine logic
│   ├── autoload/                  # Project-wide singletons
│   │   ├── Global.gd              # State manager, dimensions, health, charges, signals
│   │   ├── SoundManager.gd        # Procedural sound synthesis, audio buses, SFX
│   │   └── SceneTransition.gd     # Screen fades, async scene loading & transitions
│   ├── boss/                      # Boss AI implementations (GuardianBoss.gd)
│   ├── camera/                    # Camera controllers (CameraRig.gd)
│   ├── mechanics/                 # Generic interactive mechanics (LayerSwitchPad, RewindableBridge)
│   ├── objects/                   # Interactive world objects (ConduitRail, EnergyReceiver, etc.)
│   ├── player/                    # Master player kinematics & rewind controllers
│   └── ui/                        # HUD, IntroCutscene, UndertaleDialogueBox
│
└── tools/                         # Automated testing, verification & procedural tools
    ├── build_layout.py            # Generates procedural 3D chamber layouts
    ├── verify_route.gd            # 61-point headless route & mechanics verification
    ├── verify_new_features.gd     # 20-point UI, dialogue, & map verification
    ├── verify_full_flow.gd        # End-to-end cutscene to chamber integration test
    └── capture_showcase.gd        # Headless high-definition screenshot renderer
```

---

## 3. Engine Configuration & Rendering Pipeline

### 3.1 Display Settings (`project.godot`)
To eliminate pixel-crawl and visual blur while maintaining authentic retro character art, we use a hybrid high-definition rendering pipeline:
* **Viewport Size:** `1280 × 720` (Native HD 16:9).
* **Stretch Mode:** `canvas_items` with `stretch/aspect = "expand"`.
* **Anti-Aliasing:** `rendering/anti_aliasing/quality/msaa_3d = 2` (4× MSAA 3D). This ensures geometric 3D edges, masonry block silhouettes, and shadow borders render with silky smooth clarity.
* **Sprite Texture Filter:** `textures/canvas_textures/default_texture_filter = 0` (Nearest Neighbor). All 2D sprites (John Rod, Flat Guardian, HUD pixel hearts, dialogue portraits) render razor-sharp without bilinear interpolation blur.

### 3.2 Lighting & Tonemapping
* **Tonemapping:** Filmic tonemapping (`Environment.TONE_MAPPER_FILMIC`) preserves contrast in dark cavern settings while giving neon energy conduits and golden runes a luminous glow without blown-out whites.
* **Directional Shadows:** Orthogonal directional sun with `SHADOW_ORTHOGONAL` calibrated to match the axonometric camera angle, preventing shadow-edge shimmering during movement.
* **Atmospheric Omnis:** Warm architectural omni torches (`Color(1.0, 0.75, 0.45)`) positioned along masonry piers, complemented by cool cyan conduits (`Color(0.2, 0.8, 1.0)`).

### 3.3 The Procedural Masonry Shader (`stone.gdshader`)
To prevent the visual noise and texture grain that plagues low-resolution textures, masonry blocks use `stone.gdshader`:
* Mathematical mortar grid with configurable brick width, height, and mortar line thickness.
* Subtle block bevel highlights along horizontal and vertical seams.
* Zero procedural pseudo-random noise (`fract(sin(dot(...)))`) to avoid visual grain or flickering.
* Fully anti-aliased seam transitions evaluated in world coordinates for consistent density across any block size.

---

## 4. Global Singletons & State Management

All shared state flows through three autoload singletons registered in `project.godot`:

```
[autoload]
Global="*res://scripts/autoload/Global.gd"
SoundManager="*res://scripts/autoload/SoundManager.gd"
SceneTransition="*res://scripts/autoload/SceneTransition.gd"
```

### 4.1 `Global.gd` — Master Game State
Acts as the central event bus and data store:
* **Dimension State:**
  ```gdscript
  enum Dimension { DIM_0D, DIM_1D, DIM_2D, DIM_2_5D, DIM_3D }
  var active_dimension: Dimension = Dimension.DIM_2D
  var unlocked_dimensions: Dictionary = { ... }
  ```
* **Vital Statistics & Inventory:**
  ```gdscript
  var max_health: int = 3
  var current_health: int = 3
  var carried_charge: bool = false
  var rewind_unlocked: bool = false
  var is_rewinding: bool = false
  ```
* **Core Event Signals:**
  * `dimension_changed(new_dim: Dimension, old_dim: Dimension)`
  * `health_changed(new_hp: int)`
  * `charge_state_changed(has_charge: bool)`
  * `rewind_started()` / `rewind_ended()`
  * `checkpoint_reached(chamber_id: String)`
* **Damage & Defeat Handling:**
  `take_damage(amount: int)` decrements health, plays SFX, emits `health_changed`, and handles respawn at the active checkpoint when HP hits zero.

### 4.2 `SoundManager.gd` — Procedural Audio Engine
Generates synthesized 8-bit/16-bit sound effects procedurally using Godot's `AudioStreamWAV` and playback nodes:
* `play_sfx("jump")`: Upward frequency sweep (150 Hz → 450 Hz).
* `play_sfx("land")`: Low dampening thud.
* `play_sfx("typewriter")`: Ultra-short 800 Hz noise blip for Undertale dialogue and cutscenes.
* `play_sfx("hurt")`: Dual descending square-wave crunch.
* `play_sfx("transform")`: Shimmering dimensional frequency arpeggio.
* `play_sfx("victory")`: Resonant pentatonic fanfare on chamber completion.

### 4.3 `SceneTransition.gd` — Seamless Room Coordinator
* Implements full-screen smooth color fades using a dedicated high-priority `CanvasLayer` (layer 100).
* `fade_in_from_black(duration: float)` & `fade_out_to_black(duration: float)`.
* `change_chamber(scene_path: String, delay: float)` manages timing, prevents input double-triggers, and cleans up old nodes.

---

## 5. The Dimensional Kinematic Engine

The player controller (`chambers/broken_circuit/scripts/player.gd` and `scripts/player/Player.gd`) implements a multi-dimensional kinematic state machine.

### 5.1 Dimensional State Breakdown
```
                                +-------------------+
                                |    0D: POINT      | -> Stationary; Space pulses core
                                +-------------------+
                                          |
                                +-------------------+
                        +-----> |     1D: LINE      | -> Locked to conduit (X-only)
                        |       +-------------------+
                        |                 |
                        |       +-------------------+
                        |-----> |    2D: PLANE      | -> Platformer (X, Y; Z locked)
                        |       +-------------------+
                        |                 |
                        |       +-------------------+
                        +-----> |    3D: VOLUME     | -> Free 3-Axis (X, Y, Z)
                                +-------------------+
                                          |
                                +-------------------+
                                |    4D: TIME       | -> Rewinds John Rod & Bridge
                                +-------------------+
```

#### Detailed Dimensional Behaviors & Jump Rules
1. **0D Mode (Point Singularity):**
   * Velocity strictly zeroed: `velocity = Vector3.ZERO`.
   * Directional movement inputs disabled.
   * `[SPACE]` triggers `$PulseEffect` (concentric glowing rings) that awaken dormant energy relays within proximity.
2. **1D Mode (Linear Rail):**
   * Snaps and locks player position to the active conduit rail ($Z$ and $Y$ coordinates fixed).
   * Traversal along $X$ axis: `velocity.x = input_dir.x * rail_speed`.
   * Cannot jump: Space produces zero upward impulse.
   * Collisions with full-volume blocks disabled; allows passage through narrow 0.45m conduit slits and lintels.
3. **2D Mode (Planar Slice):**
   * The $Z$ coordinate is locked to the active plane (e.g. $Z = -4.0$ for runic terrace scaling or $Z = 0.0$ for the main corridor).
   * `velocity.z = 0.0`.
   * **Only 2D can initiate a jump:** Space triggers upward jump impulse (`JUMP = 6.5`, `GRAVITY = 18.0`).
   * Runic terraces and broken stair piers become jumpable stepping platforms.
   * Flat Guardian sentinel collapses into a paper-thin ethereal form that John Rod can slip through.
4. **3D Mode (Volumetric Continuous):**
   * Free movement across depth: `velocity.x = dir.x * speed`, `velocity.z = dir.z * speed`.
   * **No Jumping:** Space produces zero jump impulse. John Rod can only fall naturally when walking off an edge.
   * **Grounded Depth Steering Lock:** Depth movement (`velocity.z`) strictly requires `is_on_floor()`. If airborne in 3D, `velocity.z = 0.0`, preventing midair lane hopping or puzzle bypass.
   * Flat Guardian sentinel becomes a physical chaser in 3D.
5. **Dimension Switch Kinematic Integrity:**
   * Switching dimensions clears `jump_buffer = 0.0` immediately, preventing buffered 3D jumps from triggering in 2D.
   * Switching dimensions midair preserves vertical velocity (`velocity.y`) and gravity without extra height, jump reset, or double jumps.
6. **2D Foreground Occlusion Handling (`chamber.gd`):**
   * When switching to 2D, `update_occlusion()` hides visual meshes of foreground walls situated at $Z > \text{player\_z} + 0.6$ (`fg_walls` group).
   * Physics collision remains 100% solid at all times, preventing unintended shortcuts or physics anomalies.
   * Major front perimeter walls are designed as low stone curbs ($0.45\text{m}$), ensuring the 3D isometric camera has an unobstructed line of sight into all courtyards.
7. **Clean HUD & Subtitle Architecture (`demo.gd`):**
   * No brown background bars or banners across top or bottom.
   * Clean floating retro pixel hearts in the top-left margin.
   * Large, readable gameplay subtitles (30px, white text, 6px black outline, soft shadow, centered in lower safe area above controls, queued one at a time, shown once per milestone).
   * Contextual bottom controls (23px white text with black outline, accurately advertising "SPACE Jump" only in 2D).
   * Implemented via a continuous ring-buffer storing snapshot states at 60 Hz:
     ```gdscript
     struct HistoryState {
         var position: Vector3
         var velocity: Vector3
         var dimension: int
         var facing: bool
         var timestamp: float
     }
     ```
   * Holding `[R]` or `[SHIFT]` unwinds the ring buffer backwards at 1.5× speed.
   * Asymmetric causality: John Rod and `RewindableBridge` rewind in time; enemies and hazards move forward in real time.

### 5.2 Dual Input Mapping Strategy
To ensure maximum reliability across both standard play and automated headless test harnesses, player input handlers check both Godot `InputMap` actions and physical key scancodes:
```gdscript
func _is_action(event: InputEvent, action_name: String, fallback_keys: Array[Key]) -> bool:
    if event.is_action_pressed(action_name):
        return true
    if event is InputEventKey and event.pressed and not event.echo:
        return event.keycode in fallback_keys
    return false
```
* **Dimension Switching:** Keys `[1]`, `[2]`, `[3]` or `[Q]`/`[E]` to cycle.
* **Movement:** `[A]`/`[D]` (Left/Right), `[W]`/`[S]` (Forward/Back in 3D).
* **Jump / Advance:** `[SPACE]`, `[Z]`, or `[ENTER]`.
* **Map Overview:** `[M]`.
* **Interact / Strike:** `[E]` or `[F]`.

---

## 6. Camera, Perspective & Screen-Filling Axonometric Rig

The camera system in `chambers/broken_circuit/scripts/demo.gd` and `scripts/camera/CameraRig.gd` uses a screen-filling orthogonal axonometric projection.

```
                           Y (Up)
                           |   / Z (Depth)
                           |  /
                           | /
                           +-------- X (Run)
                         /
                       /  Camera Angle: Pitch -30°, Yaw +45°
                      Camera3D (Orthogonal Axonometric)
```

### 6.1 Camera Specifications
* **Projection Mode:** `Camera3D.PROJECTION_ORTHOGONAL`. Eliminates vanishing-point perspective distortion, ensuring 2D planar distances and 3D volumetric alignments match on screen.
* **Orientation:**
  * Pitch: `-30.0°` (elevated look-down).
  * Yaw: `+45.0°` (true isometric diagonal viewing angle).
  * Roll: `0.0°`.
* **Tracking & Smoothing:**
  * Close Tracking Mode: Orthogonal `size = 5.2`.
  * Camera target smoothly interpolates (`lerp`) toward John Rod's position with an elevated look-ahead offset of `Vector3(0.0, 1.2, 0.0)`.

### 6.2 Full Map Mode & Movement Auto-Reset
* **Full Map Toggle (`[M]` or HUD button):** Smoothly transitions orthogonal size from `5.2` to `24.0` and centers the camera on the entire 64-meter course at `Vector3(18.5, 2.6, -1.0)`.
* **Movement Auto-Reset Logic:** If the player provides any movement or jump input while viewing the full map, the camera automatically and instantly resets back to close tracking mode, preventing disorienting control mismatches.

---

## 7. Chamber Construction & Environmental Systems

### 7.1 Permanent Solid 3D Masonry Architecture
In earlier iterations, terrace blocks were rendered semi-transparent in 3D, causing confusion. The codebase now strictly adheres to **Permanent Solid Masonry**:
* Terrace blocks maintain their solid `stone.gdshader` material across all dimensional states.
* Visual coping (golden runic trims) highlights valid jump surfaces.
* Visual cutaway perimeters prevent background walls from occluding the isometric viewpoint.

### 7.2 Chamber 01: The Broken Circuit Flow
The canonical Chamber 01 course consists of 253 modular pieces generated via `tools/build_layout.py`:
1. **Conduit Slide:** John Rod collapses to 1D to traverse the lower rail ($Y = 0.2, Z = 0.0$) across a toxic abyss, collecting the glowing Energy Charge.
2. **Pedestal Connection:** John Rod expands to 3D, walks around the central monolith, and deposits the charge into the Energy Receiver pedestal ($X = 11.5, Z = -4.0$).
3. **Runic Terrace Ascent (2D):** Receiver activation powers the runic ledges. John Rod aligns to the rear wall ($Z = -4.0$), collapses to 2D, and jumps up the stepping terraces ($Y = 0.85, Y = 1.70$).
4. **3D Walkway Forward:** Standing on the upper landing, John Rod expands to 3D and walks forward along the masonry pier from $Z = -4.0$ to the front dock at $Z = 0.0$.
5. **High Rail Crossing (1D):** John Rod enters the high conduit rail ($Y = 1.05, Z = 0.0$) in 1D, sliding across a 6-meter chasm through a narrow lintel into Guardian Hall.
6. **Flat Guardian Sentinel Arena:** John Rod enters Guardian Hall in 3D. The Flat Guardian detects and pursues him.
7. **2D Ethereal Phase Bypass:** John Rod collapses to 2D. The Guardian becomes paper-thin and ethereal; John Rod slips through unharmed.
8. **Exit Portal:** John Rod reaches the Exit Archway at $X = 36.0$, triggering the completion sequence.

---

## 8. Entity & Dimensional AI Systems

### 8.1 The Flat Guardian Sentinel (`flat_guardian.gd`)
An enemy designed to test dimensional understanding:
* **In 3D Mode:**
  * `collision_layer = 1`, `collision_mask = 1`.
  * Fully solid, opaque character body with glowing red eye omni light (`energy = 1.35`).
  * Detects John Rod within `8.0m`, pursues at `2.8 m/s`.
  * Strikes when within `1.35m`, dealing 1 heart damage, inflicting knockback, and activating 1.2s invulnerability blinking.
* **In 2D Mode:**
  * `collision_layer = 0`, `collision_mask = 0`.
  * Collapses into a paper-thin cyan ethereal silhouette (`modulate = Color(0.4, 0.8, 1.0, 0.22)`).
  * Eye light dims to `0.25`, movement halts, and player can walk right through its body.

### 8.2 Interactive Mechanics
* **`RewindableBridge.gd`:** Collapses upon stepped weight; records its fracture state. When player rewinds time (4D), the bridge's fragments float back up and reassemble.
* **`EnergyReceiver.gd`:** Detects player with `carried_charge`, latches on, plays sound, emits `receiver_powered`, and illuminates circuit conduit emissives.
* **`ConduitRail.gd`:** Area3D detecting 1D player, locking axes and boosting speed.

### 8.3 Axiom Warden Boss Mechanics & Attack States (`encounter.gd` & `hazard.gd`)
The Chamber 02 boss fight serves as the ultimate test of dimensional rules established in Chamber 01:
* **Dimensional Kinematics Consistency:**
  * **2D Mode:** X/Y movement + Jumping (`[SPACE]` initiates jump).
  * **3D Mode:** X/Z ground navigation only. Jumping is strictly prohibited (`velocity.y` impulse = 0, Space ignored, `jump_buffer = 0.0`). Depth movement (`velocity.z`) requires `is_on_floor()`.
* **Hazard Design Rules & 3D Lateral Navigation:**
  * Because 3D mode has no jumping, 3D hazards never require jumping over, jumping onto, or crouching under.
  * **Rising Wall (`"rising_wall"`):** Floor runes telegraph wall position for 1.44s. A solid stone barrier ($1.8\text{m} \times 2.4\text{m} \times 1.4\text{m}$) erupts with active `StaticBody3D` collision. Evaded entirely through lateral 3D navigation (moving around it in X/Z).
  * **Flat Guardian Projectiles (`"guardian"`):** Warden hurls Flat Guardians as linear projectiles towards the player. In 3D, the projectile is solid and deals 1 heart damage. In 2D, it becomes a non-solid, paper-thin cyan ethereal phantom (`collision_layer = 0`, `collision_mask = 0`, `damage_enabled = false`), allowing the player to reactively switch to 2D and phase through unharmed.
  * **Ground Shockwave (`"slam"`):** Expanding seismic ground ring telegraphed for 1.44s. Hits grounded players across the arena; player must switch to 2D and jump over it.
  * **Depth-Locked Beam (`"lane"`):** Telegraphed laser beam locking down a specific Z lane. Player side-steps in 3D to adjacent lanes.
  * **Sweeps, Beams, Bolts, Nova:** Balanced with +20% telegraph warning durations, -15% projectile speeds, and 10% reduced hitbox tolerances.
* **Parkour Entrance & Fragile Bridge Arena Entry:**
  * Chamber 01-style approach platforming with `ApproachMonolith` requiring 3D depth routing and 2D pier jumps across gaps.
  * `FragileBridge` at $X \in [-12.5, -8.0]$ fractures when stepped on at $X \ge -12.0$. Dropping through into the chasm triggers `_fall()`, restoring full 3-heart health, checkpointing at `(-8.0, 0.06, 0.0)`, sealing the sanctum gate, and locking player input for dialogue.
* **2D Foreground Occlusion Management:**
  * Foreground boundary walls and columns are tagged into `"fg_walls"`. In 2D mode, `update_occlusion()` hides visual meshes blocking the active 2D plane ($Z > \text{player\_z} + 0.6$) while keeping static collisions solid.
* **Final Phase (Phase 6 - Final Surge):**
  * Synthesizes all hazard mechanics (`rising_wall`, `guardian`, `slam`, `lane`, `nova`), forcing the player to analyze incoming attacks and shift between 3D lateral evasion and 2D vertical jump/phase avoidance.

---

## 9. UI, Dialogue & Audiovisual Architecture

### 9.1 Undertale Dialogue System (`UndertaleDialogueBox.gd`)
* **Visual Style:** High-contrast pitch-black window with 4px double white border and authentic pixel corners.
* **Character Portraits (`res://assets/ui/portraits/`):**
  1. `john_rod_portrait_dazed.png`: Groggy wake-up expression with spiral eyes.
  2. `john_rod_portrait_watch.png`: Examining the glowing Ancient Watch.
  3. `john_rod_portrait_revelation.png`: Realizing he can shift dimensions.
  4. `john_rod_portrait_determined.png`: Looking forward to the ascent.
* **Text Crawl:** Typewriter crawl at 28 chars/sec with natural delays on punctuation (`.` `,` `!` `?`).
* **Input Control:** `[Z]`, `[SPACE]`, `[ENTER]`, or Click to fast-forward active line or advance to next. `[ESC]` skips entire cutscene. Locks player kinematics during dialogue, then restores controls cleanly.

### 9.2 Heads-Up Display (`hud.gd` & `CleanHUD.gd`)
* **Red Pixel Hearts:** 32×32 retro pixel hearts (`heart_full.png` and `heart_empty.png`) in top-left corner (`Vector2(32 + i * 36, 24)`), dynamically updating via `Global.health_changed` or local encounter health.
* **Minimalist Non-Intrusive Layout:** Brown background banners and title headers are strictly removed. Hearts float cleanly over the upper-left viewport margin.
* **Floating Contextual Control Hints:** Crisp, readable keybinding hints rendered at the screen bottom with text drop shadows, dynamically adjusting to active dimension (e.g. WASD in 3D, Space Jump in 2D, Conduit Slide in 1D).

---

## 10. Automated Testing & Verification Suite

Our testing suite runs completely headless via Godot CLI, allowing instant verification without manual playthroughs:

### 10.1 Running Test Scripts
```powershell
# In PowerShell from the Degrees_of_Escape directory:
godot --headless -s tools/verify_axiom_warden.gd
godot --headless -s tools/verify_route.gd
godot --headless -s tools/verify_new_features.gd
godot --headless -s tools/verify_chamber_transition.gd
godot --headless -s tools/verify_full_flow.gd
```

### 10.2 Verification Coverage
* **`tools/verify_axiom_warden.gd` (77 automated checks):**
  * Spawns player, validates stepped 5-obstacle platforming approach, 3D depth routing around `ApproachMonolith`.
  * Validates 2D pure side-view camera angle (`yaw = 0.0, pitch = 0.0`) and 3D isometric angle (`yaw = -45.0, pitch = -30.0`).
  * Validates bottom abyss has no collision shapes (true void drop).
  * Validates falling off approach piers revives player at the very beginning (`START = Vector3(-35, -2.35, 0)`).
  * Validates 3D jump rejection (`velocity.y = 0`, Space ignored) and 2D jump execution.
  * Validates fragile bridge collapse on step, gap fall, and checkpoint respawn inside arena with 3 full hearts.
  * Validates entrance gate sealing and input locking during boss dialogue.
  * Validates 2D foreground wall occlusion hiding meshes blocking the 2D plane.
  * Validates 1D/2D/3D dimension switching during combat and midair momentum preservation.
  * Validates Flat Guardian projectile: non-solid / zero damage in 2D, solid / deals damage in 3D.
  * Validates Rising Wall floor warning, solid obstacle emergence, and 3D lateral evasion.
  * Validates Ground Shockwave damage in 3D and 2D jump evasion.
  * Validates hazard collision geometry: sweeps, low beams, bolts, lanes, slams, and rising walls.
  * Validates 5 core strikes, phase transitions, false defeat, revival dialogue, final surge synthesis, and sixth finishing hit collapse.
  * Validates retry from checkpoint, pause toggle, and health restoration.
* **`tools/verify_route.gd` (101 automated checks):**
  * Spawns player, validates 1D conduit slide & speed boost.
  * Verifies pit crossing and dimensional expansion rejection in narrow gaps.
  * Validates airtight 1D containment alcove preventing 3D/2D bypass.
  * Validates 0D Point pulse awakening of Ancient Relay Terminal.
  * Validates Energy Charge pickup and delivery to Receiver.
  * Validates submerged bridge chasm, dynamic reconstruction sequence, trauma shake, SFX, and solid collision enablement.
  * Validates runic terrace 2D jumps, 3D walkway forward transit, high rail crossing.
  * Validates Flat Guardian 3D pursuit, melee strike, damage & knockback, 2D ethereal pass-through, and sealed exit vestibule.
* **`tools/verify_new_features.gd` (27 automated checks):**
  * Validates Undertale dialogue queue, portraits, skip handling, and kinematic lock/unlock.
  * Validates clean HUD floating hearts, large gameplay subtitles, and contextual controls.
  * Validates continuous camera look-ahead tracking and screen shake.
* **`tools/verify_chamber_transition.gd`:**
  * Validates seamless progression from Chamber 01 exit into Chamber 02 (Axiom Warden Sanctum).
* **`tools/verify_full_flow.gd`:**
  * Validates seamless handoff from Intro Cutscene into Chamber 01.

---

## 11. Procedural Asset Generation Toolchain

All retro pixel art and chamber layouts are generated using Python scripts:
* **`generate_all_assets.py`:** Generates John Rod 64px and 128px dimensional sprites, HUD icons, and prop textures.
* **`generate_undertale_intro_master.py`:** Produces the 6 high-contrast sepia narrative panels with Bayer matrix dithering and antique gold borders.
* **`tools/build_layout.py`:** Assembles the 306-piece 3D chamber geometry into `BrokenCircuit.tscn` from geometric specifications.

---

## 12. GDScript Coding Standards & Best Practices

1. **Static Typing Everywhere:** Always declare static types for variables, exports, function parameters, and return types:
   ```gdscript
   var speed: float = 4.0
   func calculate_trajectory(origin: Vector3, target: Vector3) -> Vector3:
   ```
2. **Decoupled Architecture via Signals:** Never access deep foreign node paths directly (e.g. avoid `get_parent().get_parent().get_node("HUD")`). Connect signals through `Global` or parent orchestrators.
3. **Clean Separation of Concerns in Nodes:**
   * Visuals (`Sprite3D`, `MeshInstance3D`) handle rendering only.
   * `CollisionShape3D` handles physics boundaries.
   * `Area3D` handles interactive triggers and damage volumes.
4. **Deterministic Physics:** All velocity changes, movement calculations, and raycasts must execute in `_physics_process(delta: float)`. Reserve `_process(delta: float)` strictly for UI animations, camera smoothing, and decorative effects.
5. **Safe Instance Validation:** Always guard external node references with `is_instance_valid()` before accessing properties.

---

## 13. The Golden Rule: Continuous Development & Git Protocol

> [!IMPORTANT]
> ### 🚨 THE MANDATORY WORKFLOW RULE FOR ALL CODING SESSIONS
> Every single time code, features, or assets are modified or created in this project, you **MUST** follow this exact 4-step protocol:
>
> 1. **Update `GAME_DEV_LOG.md`:**  
>    Append a new session entry documenting the task, files modified, mechanics added, bugs fixed, and architectural choices.
> 2. **Update `HOW_WE_CODE.md`:**  
>    Keep this technical manual in lockstep with the codebase. If a script, singleton, mechanic, camera setting, shader, or standard is changed, update the relevant section here.
> 3. **Execute Automated Verification:**  
>    Run `tools/verify_route.gd` and related test scripts under Godot headless mode to confirm zero regressions.
> 4. **Commit & Push to Git:**  
>    Stage all changes, create a clear, descriptive Git commit, and run:
>    ```bash
>    git push origin master
>    ```
>    Never leave code uncommitted or unpushed to the remote repository.
