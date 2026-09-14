# Degrees of Escape — Chamber 01: The Broken Circuit

A playable, editable Godot 4 first chamber for John Rod. Built around the latest **Session 7** revision in the supplied GAME_DEV_LOG.md: all spatial forms available at the start; rewind earned after the boss.

## Open and play

1. Extract this entire folder.
2. Import `project.godot` in Godot 4.3 or later.
3. Press **F6** with `chambers/broken_circuit/Demo.tscn` open, or **F5** to run the project.

| Input | Action |
| --- | --- |
| WASD / arrow keys | Move; ground controls follow the angled camera in 3D |
| 1 / 2 / 3 | Line / plane / volume |
| Q / E | Cycle spatial forms |
| Space | Jump in 2D or 3D |
| F | Use the receiver or read the optional watch echo |
| M | Toggle the whole-room view |
| Backspace | Return to the current safe checkpoint |
| F5 while playing | Restart the standalone chamber |

**Solution:** reach the conduit socket → press 1 and slide below the gate → collect the spark → expand into 3D → follow the gold line behind the monolith → press F at the receiver → walk around the socket to the rear staircase → press 2 → jump up the four runic steps to the upper doorway.

## Package contents

- `chambers/broken_circuit/BrokenCircuit.tscn` — editable geometry, collisions, named markers, and chamber logic.
- `chambers/broken_circuit/Demo.tscn` — standalone player, camera, lighting, HUD, and sound.
- `chambers/broken_circuit/assets/sprites/` — your approved John Rod v2 sprites, 64px version.
- `docs/CHAMBER_DESIGN.md` — layout, puzzle flow, palette, and tuning.
- `docs/INTEGRATION.md` — connect this room to the existing game.
- `docs/first_chamber_layout.svg` and `.png` — annotated plan and climb elevation.
- `docs/chamber_overview.png`, `chamber_arrival.png`, `chamber_plane.png` — actual 320×180 Godot captures.
- `docs/layout.json` — geometry dimensions in meters.
- `tools/build_layout.py` — optional standard-library Python scene generator. Running it overwrites the generated geometry scene; keep manual edits in a duplicate first.
- `tools/verify_route.gd` — automated traversal using the real player physics.

## Validation and scope

Imported and exercised with **Godot 4.3 stable**, using the Compatibility renderer. The complete solution passed **32 physics and state checks**, including every jump, unsafe expansion, depth preservation, and checkpoint recovery. Actual OpenGL captures were reviewed. See `docs/VALIDATION.md`.

This is a standalone chamber package. The existing game source was not attached, so its `Global`, controller, and level manager have not been modified or integration-tested. The demo ends at the upper doorway and emits `chamber_completed`; connect that signal to your next room.

The 123D pack was inspected as a mechanics reference. Its scripts, art, music, and scenes are not included in this package. Environment geometry and chamber scripts here are newly authored.
