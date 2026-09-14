# Integrating the first chamber

## Safest first review

Open the included standalone project and run `Demo.tscn`. The real current game project was not supplied: only the development log and the 123D reference pack were attached. Therefore this package does not assume the exact implementation of the logged components.

The standalone demo is complete within its scope. Direct integration requires the wiring below; replacing your arrival scene with this demo also replaces that scene's player/camera/HUD for the duration of the room.

## Copy into the existing project

Copy **only `chambers/broken_circuit/`** into the root of the existing Godot project. Its scripts and resources use that namespaced `res://` path. Keep your existing `project.godot`, autoloads, input map, intro, and assets.

Two options:

1. **Play this room immediately:** transition from the intro into `res://chambers/broken_circuit/Demo.tscn`. Connect the chamber's completion signal to the next real level. The demo owns its local inventory, input, camera, sound, and HUD.
2. **Keep your established systems:** instance `BrokenCircuit.tscn` inside your arrival scene and use its markers, geometry, and room logic with your controller. Configure the contracts below. Do not also spawn the demo player.

## Room API

`chamber.gd` has no dependency on `Global` or a particular player class.

| Method | Call site / behavior |
| --- | --- |
| `set_spatial_mode(mode)` | After an accepted dimension change. Pass the integer **1**, **2**, or **3**; map your enum explicitly. Toggles the runic steps. |
| `try_collect(player_global_position)` | Each physics frame or from a pickup trigger. Returns true only on the initial pickup. |
| `try_interact(player_global_position)` | On the existing F interaction action. Returns a displayable hint, or an empty string when out of reach. |
| `try_exit(player_global_position)` | Each physics frame or from an exit trigger. Emits completion only once and only after powering. |

| Signal | Suggested connection |
| --- | --- |
| `charge_collected` | Update your inventory / charge carrier visual and call the logged `Global.collect_charge()` if that API is still current. |
| `circuit_completed` | Consume the global carried charge once, save the room's solved state, play your unlock cue, and update HUD. |
| `echo_found` | Optional journal or discovery cue. |
| `chamber_completed` | Call your existing level manager's transition method. |

The room currently owns local booleans `carrying_charge`, `powered`, `found_echo`, and `completed`. Choose one inventory authority during integration. If Global owns inventory, adapt these checks to read/write Global instead of maintaining two independent truth sources. Restore `powered` and call `set_spatial_mode` when loading a saved room.

## Existing component replacements

- **ConduitRail:** the demo rail is mesh geometry plus marker endpoints, interpreted by the demo controller. If your controller discovers `ConduitRail` instances or groups, replace `Mechanisms/MainConduit` with your logged `ConduitRail.tscn`. Configure endpoints from `Markers/RailStart` and `Markers/RailEnd`: (-10,0.2,0) to (-2.4,0.2,0). Preserve the narrow slot and rail height. A visual line alone will not register with that controller.
- **EnergyCharge / EnergyReceiver:** you may replace local pickup/receiver logic with your existing components. Use the supplied markers. Disable the equivalent `try_collect` / `try_interact` path to avoid double collection or consumption.
- **RunicPlatform:** four current static bodies belong to `bc_steps`; room logic toggles their collisions. Replace them with your existing platform scenes if desired, preserving dimensions and top heights. Use only one collision-toggle authority.
- **ChamberDoor:** the initial slotted gate is deliberately a static architectural obstruction. It does not open; flattening solves it. The upper door seal lights when powered, and reaching the balcony completes the room.
- **MechanicalShutter / lever:** intentionally unnecessary in this chamber. Keep timed pressure for a later room once players understand switching.

## Controller assumptions

The tested demo uses a 1.14m-tall capsule, radius 0.16m, and a 0.58×0.12×0.12m rod. Humanoid positions are measured at the feet. A 64px sprite at `pixel_size=0.024`, Y offset 0.576, matches the documented v2 baseline.

Movement: 4m/s in 2D/3D, 3.5m/s on the rail, jump impulse 6.5m/s, gravity 18m/s². There is 0.10s coyote time and 0.12s jump buffering. If your current speeds or collider differ, recheck the slot and stair jumps.

1D entry accepts a small alignment tolerance and snaps Y/Z to the conduit. Expansion is rejected over the abyss and when the humanoid shape would intersect geometry. 2D freezes the current Z value. Changing mode zeroes velocity in the demo.

The demo uses physics layer/mask 1 for solid architecture. Map it to your world collision layer if different. Perimeter safety walls are invisible but have editable CollisionShape3D nodes. Only the designated rail spans the pit.

## Art and camera

The standalone scene owns lighting in `demo.gd`. If instancing the geometry-only scene, use equivalent sepia ambient/key light and a near-black environment; otherwise the material colors will look different. The capture images show the demo's lighting.

Every structural object is an editable node in `BrokenCircuit.tscn`. `tools/build_layout.py` is a reproducible starting point, not an editor plugin. Running it overwrites that generated scene. Keep a renamed copy of any manually edited layout.

The test/capture scripts are development tools, not gameplay dependencies. Do not include `docs/` or `tools/` in a release export unless desired.
