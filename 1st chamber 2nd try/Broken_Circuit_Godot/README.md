# The Broken Circuit — Expanded obstacle course / Revision 2

This revision replaces the small first-chamber layout with a **64 × 16 metre obstacle course**, roughly five times the original footprint. It follows Sessions 8–9 of `GAME_DEV_LOG(2).md` and the supplied reference video.

**Open:** import `project.godot` in Godot 4.3+, then press F5. The main scene remains `res://chambers/broken_circuit/Demo.tscn`.

## What changed

- Broad 4.5m, 5m and 5.5m masonry terraces with generous landings.
- Substantial foundations, brick faces, perimeter ruins and a cavern backdrop.
- Close tracking camera: **5.2**, **−45° yaw / −30° pitch** in 3D; flat 0°/0° in 2D. No opening overview shot.
- Two pressure plates, two conduit crossings, a rear receiver court, a terrace climb, a depth-blocking gallery divider, and a timed upper shutter.
- Neutral chrome John Rod, sepia masonry, brass switches and teal conduits.
- The course is traversed in several camera views. M opens a local overview; it does not shrink the entire level into the screen.

## Play

| Control | Action |
| --- | --- |
| WASD / arrows | Move |
| Space | Jump |
| 1 / 2 / 3 | Select line / plane / volume |
| Q / Z | Count down a dimension, stopping at 1D |
| E / X | Count up a dimension, stopping at 3D |
| F | Use receiver / read echo |
| M | Toggle local overview, size 14 |
| Backspace | Recover to checkpoint |
| F5 while running | Restart this course |

Configured InputMap actions from the current log are also accepted.

**Route:** step on the arrival plate → flatten at the first dock → collect the spark across the rift → expand and walk behind the central masonry → power the receiver → enter 2D on the rear path and jump across three broad terraces → expand on the upper gallery → walk around the divider to its pressure plate → enter the upper conduit and time the shutter → expand on the exit terrace and enter the doorway.

## Contents

- `chambers/broken_circuit/BrokenCircuit.tscn`: editable terrain, platforms, walls, mechanisms, markers and collisions.
- `chambers/broken_circuit/stone.gdshader`: world-space pixel masonry; rendered geometry, not a painted backdrop standing in for platforms.
- `chambers/broken_circuit/scripts/`: marker-driven room/controller, close camera, HUD, sound and optional integration bridge.
- `docs/first_chamber_layout.png` / `.svg`: course plan and platform dimensions.
- `docs/course_*.png`: actual 320×180 Godot gameplay captures.
- `docs/COURSE_DESIGN.md`, `INTEGRATION.md`, `VALIDATION.md`: design and installation details.
- `tools/build_layout.py`: rebuilds the editable scene from the authored layout. Running this overwrites manual scene edits.
- `tools/verify_route.gd`: full traversal through actual player physics.

## Existing project

Your log reports that the first package is already integrated. **Back up the existing `chambers/broken_circuit/` folder, then replace it as a unit after reviewing `docs/INTEGRATION.md`.** Do not overwrite your project's `project.godot`, Global, SceneTransition, intro or subsequent chambers.

The main scene path is unchanged. The included bridge recognizes the documented autoload names and connects supported state/transition hooks. Your actual modified source files were not attached, so custom changes beyond the log need to be merged into this revision.

The full course passed **45 checks in Godot 4.3**, including the broad terrace jumps, depth bypass, elevated rail and timed crossing. This package does not implement later chambers or 4D.
