# Chamber 01 — The Broken Circuit

## Design intent

John lands in the bottom of the same sepia sanctum seen in the intro. His watch restores line, plane, and volume before exploration begins. A doorway above the courtyard promises a way back up, but its staircase has lost its physical form.

**Player question:** “How do I bring that path back?”

**Answer:** carry one spark through a low conduit, find its socket using depth movement, then flatten at the correct depth to climb the restored steps.

Target first-play duration: **about 2–4 minutes**, a design estimate to tune with new players. There are no mandatory timed hazards in this first room. The challenge is understanding the relationships between the three forms. Timed shutters can become the next chamber's complication.

## Source of truth

The supplied GAME_DEV_LOG.md contains earlier designs alongside later revisions. This chamber follows **Session 7: Combine Space, Earn Time**, which supersedes the old single-dimension unlock ladder, automatic Z=0 snapping, and boss-time rewind unlock. In this room:

- 1D, 2D, and 3D are available immediately.
- 1D requires a nearby conduit.
- 2D preserves current depth.
- Expanding requires clearance and a valid exit from the rail.
- The carried spark survives dimension changes.
- The receiver latches on, revealing solid ledges in 2D.
- 4D and separate 2.5D progression are absent.

The user specifically requested continuity with the intro. The room therefore uses the intro's sepia environment palette instead of the older gray dungeon palette in section 6.2. A desaturated teal rail keeps the established conduit color cue distinct.

## Room and coordinates

Godot coordinates: X moves along the main route, Y is height, negative Z is the rear of the room. Floor height is Y=0. The walkable footprint is **26m × 8m** with an elevated exit at Y=4.25m. See `first_chamber_layout.svg` for the plan and climb elevation.

| Feature | Position or extent | Purpose |
| --- | --- | --- |
| John / spawn | (-11.3, 0.05, 0) | Safe introduction and view of the first socket |
| Landing platform | X -13 to -7.8; Z -4 to 4 | Space to experiment with 2D/3D |
| Conduit | X -10 to -2.4; Y 0.20; Z 0 | A single horizontal degree of freedom |
| Abyss | X -7.8 to -4.3; full room depth | Makes the rail useful; too wide for a normal jump |
| Slotted gate | X -6.45 to -5.65; Z -4 to 4 | Bottom clearance 0.46m; tall enough to prevent jumping over |
| Spark | (-3.1, 0.65, 0) | Picked up automatically near the far end of the rail |
| Courtyard | X -4.3 to 13; Z -4 to 4 | Main exploration and safe landing space |
| Monolith | X -0.8 to 1.8; Z -1.2 to 1.2; height 4.3 | Stops progress in the initial flat plane |
| Receiver | (0.5, 0.60, -2.5) | Behind the monolith; press F within reach |
| Climb approach | (2.4, 0, -2.5) | Stand at this depth before selecting 2D |
| Runic step 1 | X 3.4; top Y 0.85; Z -2.5 | First safe demonstration |
| Runic step 2 | X 5.3; top Y 1.70; Z -2.5 | Repeat the learned jump |
| Runic step 3 | X 7.2; top Y 2.55; Z -2.5 | Continue toward the visible doorway |
| Runic step 4 | X 9.1; top Y 3.40; Z -2.5 | Final floating foothold |
| Upper balcony | X 10.3 to 13; top Y 4.25; Z -3.55 to -1.45 | Permanent safe finish surface |
| Exit trigger | (11.6, 4.3, -2.5), radius 0.95 | Emits completion once powered |
| Optional watch echo | (3.8, 0.65, 2.65) | Rewards exploring the courtyard's front side |

All four runic steps are 1.35m wide and 1.4m deep, with 0.85m rises. Their collision boxes are 0.28m thick. The monolith foot extends slightly beyond the main shaft; allow room when walking around it.

## Puzzle sequence and feedback

### 1. The low gate — choose less space

A 2.4-second establishing view shows the room and upper exit. The camera then closes in on John. The first rail is the only cool-colored line in the scene and sits inside a brass-marked floor socket.

Walking into the gate or trying to jump the chasm does not work. Pressing 1 on the socket folds John into a rod. A/D slides him beneath the gate and over the abyss. He automatically collects the spark at the far dock.

Feedback: a short transformation tone; the spark visibly follows John; the watch status changes from DORMANT to SPARK. Selecting 1D away from the conduit gives a contextual hint without moving John. Expansion over the abyss is rejected. There is no punishing gate timer while the player learns.

### 2. The hidden socket — restore depth

After expanding, a tall monolith blocks the route at Z=0. A broken gold floor trace bends around its left side. In 3D, the player can follow it into a rear aisle and find the empty receiver.

Pressing F near the receiver consumes the carried spark, lights the socket and upper door seal, and permanently powers the circuit. The rear aisle continues around the receiver pedestal to the stair approach. This small bend provides a real exploration route instead of an automatic depth teleport.

Feedback: a higher chime, lit socket, lit doorway, and the hint “The stairs remember their shape. Press 2.” Returning to the receiver confirms that it is already powered.

### 3. The remembered staircase — choose the correct plane

From the rear gold line, press 2. The faint floating slabs become solid, bright footholds. Jump across four steps onto the upper balcony. The plane remains at the depth where John transformed; selecting 2D from the front courtyard does not teleport him onto the staircase.

Each rise is comfortably below the documented jump apex: 6.5² / (2 × 18) ≈ 1.17m. With 4m/s movement, the tested 1.9m center spacing is reachable. The final balcony is wider than a step to make completion forgiving.

Changing to 3D removes the runic footholds. John falls to the ordinary courtyard floor and can try again; the receiver remains powered. This reinforces that the structures depend on his dimensional state.

### Optional discovery

A small plinth toward the front contains a watch echo: “Less space can reveal another way.” Press F to discover it. It is not a key, currency grind, or progression requirement. It provides a reason to explore depth beyond the shortest route.

## Visual and camera direction

| Role | Color |
| --- | --- |
| Cavern void | #140C04 |
| Deep perimeter stone | #261708 |
| Recesses / monolith base | #3B220B |
| Main stone | #66421F |
| Pavers | #785026 |
| Worn stone edges | #9E743B |
| Ochre capitals | #C29F5C |
| Gold circuit | #D4AF67 |
| Parchment highlights | #EBD8B0 |
| Conduit accent | #70B9AF |

Stepped column capitals, rectangular carvings, worn pavers, and a black cavern background connect the room to the intro's sanctum. Perimeter rubble stays away from landing surfaces. John retains neutral chrome coloring.

The demo renders at **320×180**, uses nearest-filtered sprites, integer window scaling, and the Compatibility renderer. The 3D camera uses -32° yaw and -28° pitch, a framing adjustment from the log's -45°/-30° preset to keep the long first chamber readable. Flat forms use zero yaw and pitch. The camera follows John; M restores the overview. Camera interpolation is exponential smoothing, not an exact-duration tween.

## Recovery and progression

- Spawn checkpoint: before the rail.
- Courtyard checkpoint: acquired after leaving the rail.
- Climb checkpoint: acquired when the receiver is powered.
- Falling below Y=-2.8 returns John to the current checkpoint in 3D.
- Ordinary stair misses land on the courtyard floor without a reset.
- Charge and receiver state persist during recovery.
- No health loss, boss fight, time rewind, or next chamber is included here.
- The upper doorway emits `chamber_completed`; the game chooses the next scene.

## 123D reference interpretation

Inspection of the supplied PCK found an exported main scene with modular blocks, under-blocks, stair blocks, fences, button doors, and 2D snap/block areas. Readable tutorial strings describe encountering a ladder that is too flat, reducing dimensions with Z, reducing again for a blocked route, and increasing with X. Compiled player identifiers include dimension budget changes, stair activation/deactivation, safe spots, and a two-axis camera rig.

The borrowed design principle is **obstacle → dimensional change → immediate spatial payoff**. This room uses original sanctum geometry, different story objects, and the project's current 1/2/3 controls. The PCK was inspected as packaged data; its complete gameplay was not played or reconstructed, and no reference-game assets or compiled scripts are redistributed.
