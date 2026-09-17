# 🌌 Chronicles of Parallax

> **Official GameJam Submission for Intra BUET Robo Challenge 2026**  
> **Event:** Intra BUET Robo Challenge 2026 — GameJam  
> **Theme:** *Degrees of Freedom*  
> **Engine:** Godot Engine 4.7.2 / 4.3+ (Forward+ / GL Compatibility)  
> **Platform:** Windows PC (64-bit Standalone) & itch.io  
> **Repository:** [https://github.com/TalhaKun07-ipe/Degrees-of-Escape](https://github.com/TalhaKun07-ipe/Degrees-of-Escape)  
> **Official Release Tag:** `submission-v1`  

---

## 📖 Table of Contents
1. [Executive Summary & Story](#-executive-summary--story)
2. [Theme Integration: Degrees of Freedom](#-theme-integration-degrees-of-freedom)
3. [Core Gameplay & Dimensional Mechanics](#-core-gameplay--dimensional-mechanics)
4. [Chamber Breakdown & Progression](#-chamber-breakdown--progression)
5. [Controls & Keybindings](#-controls--keybindings)
6. [Judges Quick-Start & Launch Instructions](#-judges-quick-start--launch-instructions)
7. [Audiovisual & Dynamic Music System](#-audiovisual--dynamic-music-system)
8. [Technical Architecture & Quality Assurance](#-technical-architecture--quality-assurance)
9. [Rulebook Compliance & Asset Attribution (Rule 6)](#-rulebook-compliance--asset-attribution-rule-6)

---

## 📜 Executive Summary & Story

> *"Learn to combine space; earn control over time."*

In **Chronicles of Parallax**, the explorer **John Rod** awakens trapped within an ancient subterranean sanctum of forgotten geometry. His prized temporal relic—the **Chrono-Lens**—has been fractured, locking the **4th Degree of Freedom (Time)**.

To escape the crushing depths, John cannot rely on conventional traversal alone. He must master the fundamental dimensions of space itself:
* Collapsing into a **1-Dimensional line** to slip through conduit slits and bypass impenetrable bulkheads;
* Flattening into a **2-Dimensional plane** to leap across intangible runic platforms and phase harmlessly through lethal guardians;
* Expanding into **3-Dimensional volume** to navigate lateral depth, explore cavern aisles, and manipulate ancient power circuits;
* And ultimately confronting the colossal guardian of spatial law—the **Axiom Warden**—to restore the Chrono-Lens and unlock the **4th Dimension (Time)** to escape back to the surface.

---

## 🎯 Theme Integration: Degrees of Freedom

The core mechanic of *Chronicles of Parallax* directly embodies the GameJam theme **"Degrees of Freedom"** through both gameplay systems and narrative design:

| Degree | Dimensional Form | Mathematical Freedom | In-Game Mechanic & Function |
| :--- | :--- | :--- | :--- |
| **1D** | **Line (Conduit)** | 1 Axis of Motion ($X$) | Player collapses into a 1D line along energized conduit rails. Allows slipping through narrow security slits, bypassing heavy barricades, and crossing deep rifts. Cannot jump; lateral depth is locked. |
| **2D** | **Plane (Orthographic)** | 2 Axes of Motion ($X, Y$) | Player flattens onto a vertical orthographic plane. Depth ($Z$) is locked. Enables running, jumping, and landing on runic platforms that are ethereal in 3D. 3D flat hazards pass harmlessly through the paper-thin player. |
| **3D** | **Volume (Cartesian)** | 3 Axes of Motion ($X, Y, Z$) | Player expands into full volumetric space. Enables lateral depth navigation around pillars, exploring courtyards, aligning with mechanisms, and carrying energy cores. Jumping is restricted to maintain spatial contrast. |
| **4D** | **Time (Chrono-Lens)** | 4th Axis ($T$) | Narrative culmination: Upon shattering the Axiom Warden, John restores the Chrono-Lens, discovering that time itself is the ultimate degree of freedom needed to escape the collapsing sanctum. |

---

## 🎮 Core Gameplay & Dimensional Mechanics

### 1. Seamless Dimensional Shifting
The player can freely shift dimensions in real-time by pressing `[1]`, `[2]`, or `[3]`:
* **Preserved Coordinates:** Switching into 2D locks John's exact $Z$-depth coordinate, enabling him to choose *which* depth lane he flattens into.
* **Midair Momentum Conservation:** Shifting dimensions mid-jump preserves vertical velocity and arc physics.
* **Occlusion & Readability:** In 2D mode, foreground geometry that would obstruct the player's view becomes transparent, ensuring pristine readability.

### 2. Dimensional Hazard Counterplay
Enemies and obstacles obey the laws of dimension:
* **The Flat Guardian:** A monolithic sentinel that charges in 3D with active depth-tracking homing. While lethal in 3D, shifting into 2D renders the Guardian a paper-thin phantom that John phases through with zero damage.
* **Axiom Warden Multi-Dimensional Attacks:**
  * *High Sweeps:* Clearable by ducking in 1D or jumping in 2D.
  * *Low Lasers:* Avoidable by stepping across depth in 3D or timing a 2D jump.
  * *Ground Shockwaves:* Dodged exclusively by jumping in 2D plane mode.
  * *Rising Eruption Walls:* Sidestepped by utilizing 3D depth corridors.

---

## 🗺️ Chamber Breakdown & Progression

### 🎬 Chapter 0: Nostalgic Prologue Cutscene
* **Format:** Undertale-inspired vintage story sequence featuring custom pixel-art illustration panels, typewriter dialogue crawl with acoustic typewriter blips, and an evocative melodic theme (`intro_and_outro_tune.ogg`).
* **Narrative:** Establishes John Rod's fall into the subterranean ruins and the fracturing of his temporal watch.

### ⚡ Chamber 1: The Broken Circuit
* **Setting:** An ancient subterranean relay complex spanning **8 meticulously designed topological sections (A through H)**.
* **Puzzles & Flow:**
  1. *Terrace A & B:* Basic volumetric navigation and dimensional ledge ascent.
  2. *Barrier Monolith C:* A solid stone barrier blocking the 2D plane; player must expand into 3D to walk through the rear aisle.
  3. *Conduit D:* Narrow bulkhead slit across a deep rift; requires collapsing into 1D along the conduit rail.
  4. *Relay Court & Sealed Alcove F:* Discovering the Ancient Relay Terminal, awakening the circuit, and sliding in 1D through a high-voltage containment slit to retrieve the **Energy Charge**.
  5. *Runic Bridge Reconstruction:* Depositing the Energy Charge into the receiver triggers an ancient circuit, elevating submerged runic bridges out of the 6-meter chasm.
  6. *Guardian Arena H:* Encountering the active Flat Guardian and executing a paper-thin 2D phase bypass to reach the sanctum archway.

### ⚔️ Chamber 2: The Axiom Sanctum & Boss Encounter
* **The Abyss Approach:** A 5-obstacle precision parkour route across suspended stone terraces over a bottomless void.
* **The Axiom Warden Boss Fight:** A 6-phase climactic encounter against a colossal geometric deity:
  * *Phases 1–4:* Dodge progressive syntheses of laser beams, sweep swings, and depth strikes. When the Warden's core flashes open, switch into 2D and strike with `[F]`.
  * *Phase 5 (False Defeat & Revival):* Landing the 5th strike collapses the Warden. The music volume ducks down to `-16 dB` as the sanctum distorts. A dialogue scene triggers, culminating in the Warden's roar: *"LET EVERY DIMENSION BURN."*
  * *Phase 6 (The Final Surge):* The Warden re-ignites in an ultimate dimensional surge. Music immediately seeks to **38.0s** and loops the high-energy battle climax. John must survive simultaneous multi-hazard barrages before delivering the decisive final blow.

### 🌅 Epilogue: The Outro Cutscene
* **Narrative:** 5 custom nostalgic panels depicting the collapse of the sanctum, the rewinding hands of the Chrono-Lens, John's ascent through the temporal rift, and his triumphant emergence onto the emerald clifftops at dawn.

---

## 🕹️ Controls & Keybindings

| Action | Keybinding | Notes |
| :--- | :--- | :--- |
| **Move Left / Right** | `A` / `D` or `←` / `→` | Horizontal navigation along active rail or plane |
| **Depth Navigation** | `W` / `S` or `↑` / `↓` | Stepping forward/backward across lateral depth (3D mode only) |
| **Jump** | `Space` | Jump across terrain and runic platforms (2D plane mode) |
| **1D Line Mode** | `1` | Collapses into 1D along glowing conduit rails; slips under barricades |
| **2D Plane Mode** | `2` | Flattens onto vertical orthographic plane; unlocks jumping & ethereal phasing |
| **3D Volume Mode** | `3` | Expands into full 3D Cartesian space; navigates depth corridors |
| **Interact / Strike** | `F` | Awakens relay terminals, deposits charges, and strikes exposed boss core |
| **Advance Dialogue** | `Space` / `Enter` / Click | Fast-forwards typewriter text or advances to the next story panel |
| **Pause Game** | `Escape` | Toggles pause menu |

---

## 🚀 Judges Quick-Start & Launch Instructions

### Option A: Standalone Windows PC Build (Recommended)
1. Download or locate `build/Chronicles_of_Parallax.zip`.
2. Extract the `.zip` archive to any directory on a standard 64-bit Windows PC.
3. Double-click **`Chronicles_of_Parallax.exe`** to launch immediately (no installation, third-party frameworks, or engine editors required).

### Option B: Running from Source in Godot Engine
1. Clone this repository:
   ```bash
   git clone https://github.com/TalhaKun07-ipe/Degrees-of-Escape.git
   ```
2. Open **Godot Engine 4.3+** or **4.7.2**.
3. Click **Import**, browse to the repository folder, and select `project.godot`.
4. Press **F5** (or click the Play icon in the top-right corner) to run the full game from the Intro Cutscene.

---

## 🎵 Audiovisual & Dynamic Music System

All soundtrack assets are authored in OGG Vorbis format with custom loop headers to provide uninterrupted, seamless musical accompaniment:

| Track File | Duration | Placement | Dynamic Behavior |
| :--- | :--- | :--- | :--- |
| **`intro_and_outro_tune.ogg`** | 70.2s | Intro & Ending Cutscenes | Warm arpeggiated melodic narrative theme. Loops seamlessly while reading; fades out smoothly on scene transitions. |
| **`gameplay_background_tune.ogg`** | 83.5s | Chamber 1 (*Broken Circuit*) | Immersive ambient puzzle electronic theme. Loops indefinitely so players can solve spatial puzzles at their own pace. |
| **`boss_fight_tune.ogg`** | 68.6s | Chamber 2 (*Axiom Warden*) | **Dynamic Adaptive Boss Music Engine:**<br>• *Phase 1:* Starts at 0.0s (`-6.0 dB`).<br>• *False Defeat:* Ducks to `-16.0 dB` over 1.2s during collapse dialogue.<br>• *Phase 2 Revival:* Seeks to **38.0s**, sets loop offset to **38.0s**, and restores volume to `-6.0 dB`. When the song reaches 68.6s, it loops back to 38.0s to sustain the climax indefinitely! |

---

## 🛠️ Technical Architecture & Quality Assurance

### Engineering Documentation
* 📐 **[`HOW_WE_CODE.md`](file:///c:/Users/USER/Desktop/game%20making/Degrees_of_Escape/HOW_WE_CODE.md)** — Comprehensive technical architecture manual detailing the kinematic engine, camera projection math, shader pipelines, and decoupled signals.
* 📝 **[`GAME_DEV_LOG.md`](file:///c:/Users/USER/Desktop/game%20making/Degrees_of_Escape/GAME_DEV_LOG.md)** — Complete chronological engineering and narrative changelog.

### Automated Test Verification Suite
The repository includes automated headless test scripts that validate game mechanics, physics, and state machines directly in the Godot engine:
* **Chamber 1 Full Route Verification** (`tools/verify_route.gd`): **100/100 checks passed (100%)**
  * Validates all 8 topological sections, height clearances, 1D conduit locking, energy charge collection, runic bridge ascent, and 2D Guardian pass-through.
* **Axiom Warden Boss Verification** (`tools/verify_axiom_warden.gd`): **81/81 checks passed (100%)**
  * Validates subtitle layout, 5-obstacle parkour, 3D armor deflection, 1D/2D/3D hazard dodging, false defeat transition, surge revival, and defeat state.
* **Music System Verification** (`tools/verify_music_system.gd`): **31/31 checks passed (100%)**
  * Validates stream loading, loop configuration, volume ducking, 38.0s seek, loop offset updates, and retry resets.

---

## 📜 Rulebook Compliance & Asset Attribution (Rule 6)

In strict accordance with **Rule 6 (Assets, Copyright and AI)** of the Intra BUET Robo Challenge 2026 GameJam Rulebook:

* **Game Engine:** Godot Engine 4.7.2 / 4.3 (MIT License).
* **Development Window:** All game code, level layouts, boss fight logic, cutscene sequences, and scene files were developed during the official GameJam development window (10–17 September 2026).
* **AI-Assisted Tools Disclosure:**
  * **Pair-Programming & Architecture:** Google Antigravity AI assistant paired with human developers for rapid prototyping, kinematic mathematics, and automated test authoring.
  * **Visual Assets & Art:** Cutscene illustration panels and UI concept art synthesized with AI image generation tools, hand-framed and converted into pixel art textures; procedural GLSL/Godot shaders authored for environment materials.
  * **Audio & Music:** Procedural audio synthesis engine implemented in GDScript via `AudioStreamWAV`; royalty-free OGG Vorbis musical compositions integrated with custom loop points.
* **Known Bugs or Limitations:** None. The game runs stably at 60 FPS on standard Windows hardware with zero dependencies.

---

*Built with passion for Intra BUET Robo Challenge 2026 GameJam.*
