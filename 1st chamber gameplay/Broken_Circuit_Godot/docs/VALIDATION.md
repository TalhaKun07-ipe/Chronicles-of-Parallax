# Validation record

## Engine

- Godot **4.3.stable.official.77dcf97d8**, Linux.
- Successful headless editor import and script registration.
- Complete route exercised under the **OpenGL Compatibility** renderer with Mesa llvmpipe software rendering.
- Actual 320×180 captures inspected for the overview, gate approach, and flat staircase view.

## Route result

`tools/verify_route.gd` passed **32 checks** using the real CharacterBody3D controller and world collisions. It walks from spawn through the conduit and courtyard, then jumps up every step. It does not teleport to solve the route.

Coverage includes: rejecting off-rail 1D entry; crossing the pit and low gate; rejecting expansion over the abyss; picking up and carrying charge; the monolith blocking 2D movement; walking around it in 3D; powering the receiver; 3D steps remaining non-solid; retaining rear depth in 2D; activating stair collisions; landing at 0.85m, 1.70m, 2.55m, 3.40m, and 4.25m; reaching the exit; and preserving solved progress during checkpoint recovery.

The final palette and opening camera framing were subsequently adjusted and captured with the same renderer. Geometry, movement, and puzzle rules were unchanged.

## Commands

```sh
godot --headless --path . --editor --import --quit
godot --path . --audio-driver Dummy --script res://tools/verify_route.gd
```

On a Linux machine without a display, run the second command under a working Xvfb display. The headless dummy renderer completed all route checks but emitted mesh-storage messages during teardown; the real OpenGL run completed without those errors. The test environment reported an unsupported V-Sync setting warning.

## Remaining validation

The existing Degrees of Escape source project was not supplied, so compatibility with its exact current autoload APIs, player scene, or progression manager is not verified. Hardware performance, gamepad support, final-game audio mix, and first-time player comprehension still need testing in the actual project. The demo provides keyboard controls and a local chamber completion signal.
