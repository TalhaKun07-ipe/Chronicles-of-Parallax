# Chamber 02 — The Axiom Sanctum

A playable Godot source prototype for Degrees of Escape. Short platforming leads into a six-strike encounter with the Axiom Warden, a genuinely volumetric, articulated stone-and-brass sentinel. John remains the faceless chrome wire figure. The room uses warm umber stone, antique gold trims and cyan dimensional energy.

**Validation status:** all new GDScript files passed `gdparse` syntax parsing. Resource references and packaging were checked locally. Godot runtime, graphics, physics and the automated encounter tests have NOT been executed. The local environment has no Godot binary; automatic approval review blocked uploading private source/assets to an external test service. Treat this as a source prototype awaiting an engine playtest, not a verified release.

## Play

Import `Standalone_Demo/project.godot` in Godot 4.4 or newer, then F6 the chamber or F5 the project. No plugins or external assets are required. Compatibility rendering is selected. The source is written for Godot 4.x; engine compatibility remains unverified.

| Input | Action |
|---|---|
| WASD / arrows | Move; in 3D, movement follows the angled camera's ground axes |
| Space | Jump in 2D or 3D |
| 1 / 2 / 3 | Select dimension |
| Q / E | Cycle dimensions |
| F | Swing the rod; a nearby exposed core accepts a 1D or 2D strike |
| Z / Space / Enter / click | Reveal dialogue, then advance |
| Esc | Skip dialogue; otherwise pause/resume |
| Enter after defeat | Retry at the arena checkpoint |

1D requires a grounded position within 0.48 world units of a cyan rail. It has horizontal movement but no jump. Expand into 2D to jump a low beam, or 3D to leave a locked depth lane. 2D freezes the depth at which you entered it. Switching between 2D and 3D in the air preserves jump velocity. There is no blanket dimension-change invulnerability.

## Layout and camera

Coordinates use X for progression, Y for height and Z for depth. A world unit is a gameplay scale, not a pixel.

| Area | X center | Width × depth | Top Y | Purpose |
|---|---:|---:|---:|---|
| Arrival | -33 | 8 × 5.5 | -2.4 | Safe start, camera-relative movement |
| Terrace 1 | -26 | 4 × 5.5 | -1.8 | First short jump |
| Terrace 2 | -21 | 4 × 5.5 | -1.2 | Repeat rising jump |
| Terrace 3 | -16 | 4 × 5.5 | -0.6 | Final approach |
| Arena | 1 | 28 × 14 | 0 | Spacious fight floor |
| Warden | 9 | Approximately 4 × 3 | 0 | Stationary attack origin |
| Exit arch | 14.5 | Across Z ±2.1 | 0 | Opens after the sixth strike |

Four gaps are approximately one unit wide with 0.6-unit rises. John moves at 5.4 units/sec and jumps with initial velocity 6.5 under gravity 18: ideal apex 1.17 units, enough for each rise. These analytic dimensions still need physics playtesting.

The approach camera follows John. The arena uses a fixed orthographic angled view, smoothly flattening into a side view for 2D. It frames the large floor rather than showing the entire approach as a distant diorama. Three rails cross the arena at Z = -4, 0 and 4. Rear pillars frame the arena; no foreground pillars hide the combat floor. The boss bar sits at the bottom. Dialogue temporarily occupies the lower screen.

## Encounter sequence

1. Cross the four terrace gaps. Falling returns John to his most recent landed terrace.
2. Enter the arena. A checkpoint restores health; John and the Warden exchange six pages of dialogue.
3. John draws a glowing rod from the Chrono-Lens over 1.4 seconds.
4. Survive the current pattern. The chest doors open and the HUD says `CORE OPEN — F`.
5. Approach within 2.8 units and press F in 1D or 2D. One successful strike closes the opening and advances the phase. A missed seven-second opening repeats that phase.
6. Strike five produces a false defeat. The Warden kneels, goes silent, then declares its last law.
7. Survive the last surge. Its final opening stays available until John lands strike six.
8. The Warden collapses, the exit seal disappears and `chamber_completed` emits. The prototype stops on a completion overlay. Rewind remains locked; there is no 4D reward sequence yet.

A core-opening window is intentional: standing beside the boss and repeatedly pressing F cannot skip its phases. F still swings whenever the weapon cooldown allows, with feedback explaining range, armor or the sealed core.

## Attack language

Amber means warning. Cyan means active energy. Every attack has at least 0.85 seconds of warning. Body contact alone only hurts 3D John; every explicit attack tests its world-space geometry against John's current shape.

| Attack | Warning | Threat | Counters |
|---|---:|---|---|
| Prism volley | 0.85 s | Three, later five, straight projectiles at torso height | Slide under in 1D, jump, or sidestep in 3D |
| High axe sweep | 1.05 s | Expanding ring at Y = 0.85 | Become 1D on a rail or time a jump |
| Low laser | 1.30 s | Horizontal beam locked to John's depth when warned | Expand and jump, or leave that depth in 3D; 1D is vulnerable |
| Depth lock | 1.45 s | Full-height strip at John's marked depth | Change to 3D and sidestep; jumping/1D alone cannot avoid it |

| Strike to earn | Phase | Pattern |
|---|---|---|
| 1 | The Measure | Volley → high sweep |
| 2 | The Edge | High sweep → low laser → volley |
| 3 | The Plane | Low laser → depth lock → high sweep |
| 4 | The Volume | Depth lock → volley → low laser → high sweep |
| 5 | The Fracture | High sweep → low laser → depth lock → volley → high sweep |
| 6 | Last Decree | High sweep → low laser → volley → depth lock → high sweep → low laser |

Pattern timings live in `events_for_phase()` in `encounter.gd`. Warning positions lock when the attack starts. Projectiles do not home. No random unavoidable combinations are generated. Final balance and dodge timing require playtesting.

## Story dialogue

**Warden:** That watch held this sanctuary together. You pulled it free.

**John:** I didn't know. I'm trying to find a way out.

**Warden:** Then return the Chrono-Lens. No stolen freedom passes this gate.

**John:** You want me to become a point again? ...No. I'm leaving on my own two feet.

**Warden:** Hide in a line. Flatten into a plane. My blade and my light will still find you.

**John:** The watch is shaping something... A rod of light. All right. Let's see what it can do.

After strike five:

**Warden:** Five seals broken... but my final law remains.

**John:** Of course it does.

**Warden:** LET EVERY DIMENSION BURN.

## Integration

Copy `Standalone_Demo/chambers/axiom_warden/` into your existing project's `chambers/` directory. Copy `Standalone_Demo/tools/verify_axiom_warden.gd` into your project's `tools/`. Keep your existing project settings and SoundManager.

From the existing repository root, apply `Project_Update/chamber_exit.patch` with `git apply`. It adds a 1.6-second transition from Chamber 1 completion to `res://chambers/axiom_warden/AxiomWarden.tscn`. The patch was based on repository revision `3f6710114b7bf800be7452bb51fde9c8d5b38d73`; if your local file has changed, use the small patch as a manual merge reference. Do not replace your whole project with this demo.

Append the two supplied documentation entries to the corresponding existing logs. The integration checks for optional `Global` and `SoundManager` autoloads. It synchronizes dimensions and health but avoids legacy `Global.take_damage()`, whose death handler reloads the entire scene. Arena retry is handled locally. Standalone audio uses six small synthesized cues.

The chamber's scene constructs its meshes at runtime; it is editable through its GDScript dimensions/materials. It is not a baked mesh scene or a rigged GLB asset. The Warden is procedural 3D geometry, with John rendered as a Sprite3D over a real collision body.

## Verification commands

In the standalone demo:

```sh
godot --headless --editor --import --quit
godot --headless --fixed-fps 60 --script tools/verify_axiom_warden.gd
```

After integrating into the full game, also run the repository's required checks:

```sh
godot --headless --script tools/verify_route.gd
godot --headless --script tools/verify_new_features.gd
godot --headless --script tools/verify_full_flow.gd
```

The new test exercises a real terrace jump, dimensional constraints, hazard collision, strike gating, all six hit transitions, actual final-surge spawning, retry and pause. Some earlier attack windows are set directly by the test to isolate hit transitions; it does not replace a complete human dodge playthrough. None of these engine tests were run in the authoring environment.

Before release, confirm: full-screen arena framing in both camera modes; visible John at all depths; jump/switch timing for overlapping attacks; near/far audio levels; correct transition from the live first chamber; no regressions in the three existing tests.

## One-patch installation alternative

Instead of the manual copy steps above, `Project_Update/complete_update.patch` includes all new source/assets, the first-chamber transition and both documentation updates in one local commit. From a clean checkout of your existing game, run `git apply --check /path/to/complete_update.patch`, then `git am /path/to/complete_update.patch`. If the check fails, merge the small changes manually; do not force it. Choose either the complete patch or the manual install, not both. The patch commit was created locally against a partial source baseline; it has not been pushed or tested inside the full repository.
