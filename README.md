# Chronicles of Parallax

*(Formerly Degrees of Escape)*  

**GameJam Submission for Intra BUET Robo Challenge 2026**  
**Theme:** *Degree of Freedom*  
**Engine:** Godot Engine 4.3+ / 4.7+ (Forward+ / GL Compatibility)  
**Target Resolution:** 1280×720 (HD CanvasItems with 4× MSAA 3D + Crisp Retro Pixel Art)  
**Repository:** [https://github.com/TalhaKun07-ipe/Degrees-of-Escape](https://github.com/TalhaKun07-ipe/Degrees-of-Escape)  

🛠️ **Technical Architecture & Engineering Manual:**  
👉 **[HOW_WE_CODE.md](file:///c:/Users/USER/Desktop/game%20making/Degrees_of_Escape/HOW_WE_CODE.md)** *(Complete technical guide on how this game is coded, dimensional kinematic engines, screen-filling axonometric camera, procedural shaders, UI systems, test suite, and coding conventions).*

📖 **Design Bible & Continuous Dev Log:**  
👉 **[GAME_DEV_LOG.md](file:///c:/Users/USER/Desktop/game%20making/Degrees_of_Escape/GAME_DEV_LOG.md)** *(Master narrative script, character design specifications, level progression, and session-by-session changelog).*

---

## 🎮 Core Concept & Revised Mechanics

> *"Learn to combine space; earn control over time."*

John Rod falls into an ancient subterranean vault. His Chrono-Lens is damaged—temporal rewind (4D) is locked. However, all three spatial dimensions are available from the start:
* **1D (Line):** Compress into pure forward/backward travel along glowing cyan conduit rails (`[A]` / `[D]`). Slip under barricades, through narrow gaps, and along power lines.
* **2D (Plane):** Flatten onto an orthographic vertical plane (`[A]/[D]` + `[SPACE]`). Jump on runic inscription platforms that are intangible in 3D. Position preserves your exact depth coordinate when exiting!
* **3D (Volume):** Unfold into full 3D space (`[WASD]` + `[SPACE]`). Walk around pillars, navigate cavern corridors, and carry heavy energy cores.
* **4D (Time Rewind):** Locked until defeating the ancient Guardian in the Crucible. Defeating the boss restores temporal control (`Hold [R]`) to escape the collapsing facility!

---

## 🕹️ Controls Guide
| Action | Keybinding | Notes |
| :--- | :--- | :--- |
| **Move / Navigate** | `W`, `A`, `S`, `D` / Arrow Keys | Moves along active dimensional constraints |
| **Jump** | `Space` | Jump on 2D runic ledges and 3D terrain |
| **1D Rail Dimension** | `1` | Enters conduit line (snaps to rail track) |
| **2D Plane Dimension** | `2` | Locks $Z$-depth; enables 2D platforming & runic solids |
| **3D Volume Dimension** | `3` | Full 3D exploration and pillar bypass |
| **Time Rewind (4D)** | **Hold `R`** | *Unlocked after defeating the Guardian* |
| **Interact / Toggle Info** | `F8` | Shows / hides on-screen dimensional debug guide |
| **Pause Menu** | `Escape` | In-game pause |

---

## 👥 How to Work with Friends via GitHub

Git and GitHub manage collaboration asynchronously rather than Google Docs style real-time editing. Here is how your team can work cleanly without corrupting scenes:

### 1. Clone the Project
```bash
git clone https://github.com/TalhaKun07-ipe/Degrees-of-Escape.git
```
Then open **Godot 4.3+**, click **Import**, select `project.godot`, and click **Import & Edit**.

### 2. Best Practice Workflow
* **Work in Feature Branches:**
  ```bash
  git checkout -b feature/chamber-1-design
  ```
* **Divide Work by Files:**
  * Friend A works on `scenes/levels/Chamber_1.tscn` & its script.
  * Friend B works on `scenes/objects/NewHazard.tscn` or audio.
  * *Tip:* Avoid having two people modify the exact same `.tscn` file at the same time to prevent scene merge conflicts.
* **Push & Pull Regularly:**
  ```bash
  git pull origin master
  git add .
  git commit -m "Added Chamber 1 logic"
  git push origin feature/chamber-1-design
  ```
* **Merge via Pull Requests on GitHub:** Review changes and merge cleanly into `master`.

---

## 📜 Credits & Disclosure (Per Rule 6)
* **Code & Architecture:** Antigravity AI & Human Team pair-programming.
* **Pixel Art & Textures:** Generated with AI image synthesis tools and custom procedural shaders.
* **Audio:** Procedural audio synthesis via Godot `AudioStreamWAV` and custom sound design.

