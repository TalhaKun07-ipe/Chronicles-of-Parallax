# Degrees of Escape

**GameJam Submission for Intra BUET Robo Challenge 2026**  
**Theme:** *Degree of Freedom*  
**Engine:** Godot Engine 4.3+ (GL Compatibility)  
**Target Viewport:** 320×180 (Crisp Retro Pixel Scaling)

📖 **Full Technical Documentation & Continuous Dev Log:**  
👉 **[GAME_DEV_LOG.md](file:///c:/Users/USER/Desktop/game%20making/Degrees_of_Escape/GAME_DEV_LOG.md)** *(Contains the master game design bible, GDScript architecture index, narrative script, sprite specifications, mathematical formulas, and session-by-session changelog).*

---

## 🎮 Concept & How the Theme is Used
An explorer is stripped of all movement, reduced to a **0D point** inside an ancient cavern. By activating an ancient mystical watch, you progressively recover spatial and temporal **Degrees of Freedom**:
* **0D (Point):** No directional movement. Pulse the watch core with `[SPACE]`.
* **1D (Line):** Forward/backward travel on glowing cyan conduit rails with `[A]` / `[D]`.
* **2D (Plane):** Classic 2D platformer movement + jumping (`[A]/[D]` + `[SPACE]`) on a fixed 2D plane.
* **2.5D (Layers):** Discrete depth lanes. Step between foreground and background tracks at marked pads using `[W]` / `[S]`.
* **3D (Volume):** Full continuous 3D movement (`[WASD]` + `[SPACE]`) around massive pillars and geometry.
* **4D (Time Rewind):** Hold `[R]` to rewind recent history (up to 4.0 seconds) to restore collapsed bridges while the time-resistant Guardian continues in real-time.

---

## 🕹️ Controls Guide
| Action | Keybinding | Notes |
| :--- | :--- | :--- |
| **Move / Navigate** | `W`, `A`, `S`, `D` / Arrow Keys | Moves along the active dimension's constraints |
| **Jump / Pulse** | `Space` | Jumps in 2D/3D; pulses watch core in 0D |
| **Cycle Dimensions** | `Q` (Prev) / `E` (Next) | Cycles unlocked dimensions |
| **Direct Select** | `1`, `2`, `3`, `4` | 1D, 2D, 2.5D, 3D |
| **Time Rewind** | **Hold `R`** | Rewinds player and bridge states |
| **Strike Core** | `F` | Strikes the exposed Guardian core |
| **Pause Menu** | `Escape` | In-game pause |

---

## 🚀 How to Run and Edit in Godot
1. Open **Godot 4.3+**.
2. Click **Import** and browse to this folder: `c:\Users\USER\Desktop\game making\Degrees_of_Escape`.
3. Select `project.godot` and click **Import & Edit**.
4. Press **F5** to play!

---

## 📜 Credits & Disclosure (Per Rule 6)
* **Code & Architecture:** Antigravity AI & Human Team pair-programming.
* **Pixel Art & Textures:** Generated with AI image synthesis tools and custom procedural shaders.
* **Audio:** Procedural audio synthesis via Godot `AudioStreamWAV` and custom sound design.
