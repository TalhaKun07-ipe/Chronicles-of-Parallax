# Installing the expanded course into the Session 9 project

The current log reports an integrated first chamber with working Global/SceneTransition wiring, InputMap support, close camera and bounded dimension controls. This revision keeps that scene path and documented behavior, while changing the course geometry and its marker-driven traversal.

## Replace only the chamber folder

1. Back up your current `res://chambers/broken_circuit/` folder.
2. Copy the included `chambers/broken_circuit/` folder into the same path in your game.
3. Keep your existing `project.godot`, autoloads, intro and other scenes.
4. Open `Demo.tscn`, let Godot import the assets, and run it with F6.
5. Run the game from the intro and verify the transition into this same scene.

Replace the folder as a unit. The new course has two rails at different Y/Z coordinates and different platform locations; mixing its geometry with the old hardcoded controller will not work. The bridge and controller changes needed for this expanded layout are supplied.

If your latest local code has extra changes not described in the log, merge those changes into this revision. Only the log was attached, not the current source project; this package cannot preserve unseen edits automatically.

## Supported hooks

`integration.gd` is an optional bridge. It does nothing when `/root/Global` is absent, allowing the package to run standalone.

When the documented autoloads exist, it:

- Sets `current_chamber_id` to `broken_circuit` if that property exists.
- Reads the Global script's `Dimension` enum and calls `unlock_dimension` for DIM_1D, DIM_2D and DIM_3D when that API exists. It does not unlock rewind.
- Forwards accepted dimension changes to `Global.set_dimension` when the enum mapping is available.
- Synchronizes `carried_charge` and the zero- or one-argument `charge_state_changed` signal.
- Sets `receiver_powered` and `exit_open` when those are direct Global properties.
- Calls `SceneTransition.fade_in_from_black(0.4)` when available.
- On completion waits 1.6 seconds, then calls `SceneTransition.change_chamber("res://scenes/levels/Chamber1_DimensionalTrial.tscn")` if both the method and destination exist.

If your implementation stores room flags in a dictionary instead of direct properties, adapt `_set_existing` to that dictionary. The bridge deliberately does not guess an undocumented save structure. In the standalone package the next room does not exist, so completion stays visible at the exit.

## Input and movement

The controller accepts the logged InputMap action names: dimension_1/2/3, cycle_prev/next, jump, interact_strike, move_left/right/up/down. Physical keys also work. Q/Z and E/X stop at the dimensional endpoints instead of wrapping.

3D controls rotate −45° to match the camera. 2D preserves the current Z coordinate. 1D queries a live rail's marker endpoints and stores its height, depth and safe expansion intervals. The upper rail is at Y=2.75, Z=2; the lower rail is at Y=0.2, Z=0.

Keep the logged 4m/s ground speed, 3.5m/s rail speed, 6.5 jump impulse and gravity18 when evaluating the supplied jumps. Colliders use world layer/mask1. The camera uses size5.2 by default, size14 for M, and no opening wide-view delay.

## Main editable objects

- `Geometry/ArrivalEarth`, `SanctumEarth`, `FarEarth`: continuous terrain masses.
- `Geometry/FirstGate`, `Monolith`: early spatial obstructions.
- `Mechanisms/RunicTerrace1..3`: broad phase-dependent blocks.
- `Geometry/UpperGallery`, `GalleryDivider`: permanent upper floor and depth obstacle.
- `Mechanisms/UpperPlate`, `UpperConduit`, `Shutter`: final interaction and timing gate.
- `Geometry/ExitTerrace` and `Markers/Exit`: finish area.

Room signals remain charge_collected, circuit_completed, chamber_completed and echo_found. New signal: plate_activated(upper: bool). The course state is local; saving/restoring both plate states across application restarts requires your existing save system.

The generator is optional. Running `tools/build_layout.py` rebuilds the scene and overwrites manual edits, so duplicate the scene before hand-editing it.
