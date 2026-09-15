# Revision 2 validation

- Godot **4.3.stable.official.77dcf97d8**.
- Successful headless editor import and script registration.
- Complete route passed **45 checks** using actual CharacterBody3D physics under the OpenGL Compatibility renderer (Mesa llvmpipe).
- Covered both pressure plates; lower rail and spark; blocked 2D court; 3D receiver approach; persistent receiver state; current-depth 2D locking; every broad terrace jump and landing; upper divider bypass; elevated rail at Y=2.75/Z=2; timed shutter crossing; exit; upper checkpoint; and close camera size.
- Game captures use the actual 320×180 viewport. Final framing and masonry colors were reviewed in angled and side-on views.
- The final visual pass lowered the western boundary to prevent camera occlusion and added a cavern backdrop. The near perimeter is visually cut away in flat modes to keep John visible. The main solution route and jump dimensions were unchanged.

Run from this folder:

```sh
godot --headless --path . --editor --import --quit
godot --path . --audio-driver Dummy --script res://tools/verify_route.gd
```

A Linux machine without a display needs a working Xvfb display for the second command. The headless dummy renderer also completed the route but emitted mesh-storage messages during teardown; the OpenGL run did not. The software graphics driver reported an unsupported V-Sync setting warning.

The optional autoload bridge is defensive and was imported with the final package. Actual integration into the user's modified project, save format, next-chamber scene, hardware performance and first-time player comprehension require checks in that project. Its source was not attached. The reference video was inspected, not embedded in the package.
