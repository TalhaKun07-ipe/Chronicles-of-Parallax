# Time rewind foundation — The Unwound Sanctum

The first playable expansion restores the Chrono-Lens after the Warden and makes time a gameplay ability. The route is now Intro → Broken Circuit → Axiom Warden → Daylight Escape → Ending. The first-chamber split and miniboss progression are future work; this level supplies reusable mechanics for that redesign.

## Player-facing rules

Hold **R** to rewind John and resonant mechanisms together. The controller stores 240 physics snapshots: four seconds at the project's 60 Hz physics rate. Release R to resume from the restored velocity and leave one golden echo. The echo plays the discarded actions in chronological order, then holds its final pose for three seconds. Beginning another rewind replaces it.

The Chrono-Lens has four seconds of energy and restores 0.8 seconds per second outside rewind. Empty energy/history stops both clocks and requires releasing R before another rewind. The energy budget uses physics delta; the HUD only reads it. Pause freezes movement, mechanisms, history and energy. Time anchors refill energy and discard obsolete history; retry restores floors and mechanisms, clears echoes, and starts John at the last anchor. Solved gates remain solved.

**2D** is the jump form; **3D** is the depth-navigation form. **1D** requires the final cyan conduit and can pass the low stone seal. Switching between plane and volume preserves vertical momentum. Historical snapshots restore the actual form, depth lane, collider and rail without re-running a present-day clearance query.

Controls: A/D or arrows move, W/S navigate depth in 3D, Space jumps in 2D, 1/2/3 change form, F operates the monolith lever, Escape pauses, Backspace retries. Existing character sprites, watch HUD art, floor-paver texture, stone/conduit/shadow shaders and ambient music are reused.

## Route and floor geometry

| Sector | Floor route | Ability and purpose | Safe anchor |
| --- | --- | --- | --- |
| I. Fractured Stair | X −4…27; top heights 0 → 0.6 → 1.2 → 1.8 → 2.4 | Permanent landing, two cyan-edged floors with 0.9-second collapse delay, and a safe landing teach recovery with rewind. | (25, 2.45, 0) |
| II. Echo Court | X 24…44; top height 2.4, depth ±3.5 | Seals A=(29, −1.45 depth) and B=(33.6, +1.45 depth) require John and his replay. The gate at X=37.5 spans the entire court and has real collision. | (42, 2.45, 0), committed when gate is solved |
| III. Clockwork Span | X 43…79; top heights 2.4 → 3.0 → 3.6 → 5.4 | F tips a five-metre monolith into a physical bridge. A rear-lane lift cycles through 1.8 metres of travel over five seconds. Both restore their phase/pose on rewind. | (76, 5.45, 0) |
| IV. Daylight Run | X 79.5…107; top heights 6.0 → 6.6 → 7.2 → 7.8 → 8.4 | Five reachable jumps include a third crumbling slab. A rising void starts after leaving the final anchor. A 1D slit and expansion beyond it lead to daylight. | Reuses the final anchor |

Jumps use speed 4.8, impulse 6.5 and gravity 18: maximum rise is about 1.17 metres. Normal rises are 0.6 metres and gaps are deliberately inside the tested movement envelope. The lift supplies the larger rise. The route suite traverses the course through actual movement and collision; it does not teleport between landings.

The masonry has warm structural faces against a cool, dark backdrop. Cyan edges identify time-sensitive structures, gold identifies echo seals and mechanisms, and the paver texture identifies permanent landings. Foreground boundary meshes are cut away without removing their physics. Top coping sits above the body's surface to avoid coplanar z-fighting. The renderer remains GL Compatibility; this room does not enable unsupported volumetric fog or depth-of-field.

## Code ownership

| File | Responsibility |
| --- | --- |
| `scenes/levels/DaylightEscape.tscn` | Minimal canonical scene referencing the room builder. Run this scene directly for mechanics playtesting. |
| `scripts/levels/DaylightEscape.gd` | Four sector builders, static floors/decorations, interaction wiring, anchors/retry, camera, void activation and ending transition. |
| `scripts/player/ChronoPlayer.gd` | Consistent 1D/2D/3D movement for this route; physics input overrides for route verification; snapshot capture/restore; death signal. |
| `scripts/player/RewindController.gd` | Shared clock, bounded player history, energy, release gating, chronological echo creation and cleanup. Supports both ChronoPlayer's snapshot interface and the legacy shared Player. |
| `scripts/mechanics/ChronoEntity3D.gd` | Bounded world histories with subclass custom-state hooks and complete initial-state reset. |
| `scripts/mechanics/ChronoPlatform.gd` | Physical contact → cracking → falling; pose and collapse state restore on rewind. |
| `scripts/mechanics/ChronoMonolith.gd` | Lever-triggered tipping, physical bridge collision, and reversible angle/velocity. |
| `scripts/mechanics/ChronoLift.gd` | Periodic moving floor with reversible phase and AnimatableBody3D collision that carries riders. |
| `scripts/mechanics/TemporalEcho.gd` | Non-blocking kinematic replay, player-layer trigger participation, final hold and dissolve. |
| `scripts/mechanics/sun_gate.gd` | Occupant-aware dual plates, persistent solution, raised gate visual and released collision. |
| `scripts/mechanics/rising_void.gd` | Player detection, rewind-paused upward movement, and death signal. Ignores echoes. |
| `scripts/mechanics/chrono_post_process.gd` / `shaders/chrono_warp.gdshader` | Read-only rewind presentation below the HUD. |
| `scripts/ui/ChronoHUD.gd` | Watch/energy display, form, sector, contextual guidance and operable pause/retry menu. |

The older `escape_controller.gd` remains a compatibility helper for its isolated component test; it is not the playable route's controller. The older shared Player and legacy 0D/2.5D mechanics also remain available, while this route uses ChronoPlayer. Global enum values differ from local mode numbers: local mode 3 explicitly maps to `Global.Dimension.DIM_3D` (enum value 4).

RewindController runs at physics priority −100, before world entities and player movement. It establishes the shared rewind state for that tick. World entities then restore their historical transform and custom state while player normal movement is suspended. Area masks are 2 for player/echo detection; physical world bodies are layer 1. The echo is layer 2/mask 0 so it can activate Areas without colliding with John.

## Verification and build

- `verify_time_route.gd`: 125 checks, including a real contact-triggered crumble, held-input player/world rewind, a generated echo solving the seals through actual overlaps, bridge crossing, carried lift ride, final jumps, 1D slit and escape completion.
- `verify_time_safety.gd`: 17 checks covering bounded history, exhaustion/release, energy duration at different deltas, restored depth/form, multiple plate occupants, real void death/retry, lift phase, and pause during rewind.
- `verify_time_progression.gd`: 9 checks covering dimension-correct boss damage, time unlock, actual boss-to-escape fade and escape-to-ending handoff.
- The original route/UI/jump/boss/transition/ending suites and existing chrono component tests remain regression checks.

Run suites with Godot 4.7.2: `godot --headless --path . --fixed-fps 60 --script tools/verify_time_route.gd`. SceneTree test scripts load gameplay classes after initialization and access autoloads through root; preloading them before singleton registration can cause compilation failures.

`tools/capture_time_chamber.gd` renders inspection views into `docs/screenshots/time_chamber/`. Its scene repositioning is exclusively for visual review, independent of the unteleported route test. Launchable Windows preview artifacts are placed outside source control in `../build/TimeRewindPreview`; its launchers select the new PCK and can enter either the time chamber or the full game. Source can also be played directly by opening DaylightEscape.tscn in Godot and pressing F6.

This is a playable mechanics foundation. Human playtesting should now tune timing, camera feel, puzzle guidance and pacing. Later sectors can use the same rewindable node classes and snapshot contract; the first chamber and miniboss redesign need not duplicate the clock or echo systems.
