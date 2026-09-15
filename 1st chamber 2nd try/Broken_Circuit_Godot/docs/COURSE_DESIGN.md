# Chamber 01 — Expanded course

## Why the earlier layout felt too small

The earlier room put a short strip of terrain and narrow floating steps inside a mostly empty overview. The new reference asks for a traversable environment: a camera close to John, substantial platform faces, repeated architectural masses, and space between interactions.

This revision uses a 64 × 16m playable footprint. The terrain and background continue beyond the camera frame. The player sees the current obstacle and approaching landing; the full course is not the normal gameplay composition. The old 1.35m ledges have become 4.5–5.5m terraces.

Session 9's camera/control changes are retained: size 5.2; 3D −45°/−30°; 2D flat; tracking in X/Y/Z; bounded Q/E and Z/X dimension stepping. All three spatial forms are available at the start. No 4D unlock occurs here.

## Five connected sections

| Section | Footprint / height | Interaction and spatial lesson |
| --- | --- | --- |
| Arrival court | X −14 to −3, floor Y=0 | Step on the brass plate at (−9,0,0). It makes the first rail appear. The large court gives room to understand movement. |
| Low gate and receiver court | First rift X −3 to 1; court X 1 to 15 | Enter 1D at X −5.5, cross under the low bulkhead, collect the spark and expand at X=3. A 3.7m-high block stops the original 2D route; explore the rear aisle in 3D. |
| Broad terrace climb | X 15 to 32, Z −5.6 to −2.4 | Power the receiver at (7.5,0.6,−4). Walk to the rear approach and select 2D. Three substantial blocks become solid. Jump from near each edge, then walk across its generous top surface. |
| Upper gallery | X 32 to 40, Z −6 to 5.5, Y=2.55 | A tall divider stops 2D movement at the rear depth. Expand into 3D, walk around the divider toward Z=2 and step on the upper plate at X=37. |
| Upper crossing and exit | Rift X 40 to 44; exit X 44 to 50, Y=2.55 | The upper plate powers a second conduit. Flatten at the dock near X=38 and cross when the shutter is open. Expand at the far dock and walk into the doorway near (48,2.63,1). |

The two 4m rifts are wider than a normal jump. Their bulkheads also block jumping across the upper route. Rail entry only works near a powered line. The second rail has its own height and depth; it is not snapped to the first rail.

## Terraces

| Terrace | X extent | Width | Z extent | Top height |
| --- | --- | --- | --- | --- |
| First | 15 to 19.5 | 4.5m | −5.6 to −2.4 | 0.85m |
| Second | 20.5 to 25.5 | 5.0m | −5.6 to −2.4 | 1.70m |
| Third | 26.5 to 32 | 5.5m | −5.6 to −2.4 | 2.55m |

Gaps are 1m; rises are 0.85m. John retains 4m/s movement, 6.5m/s jump impulse and 18m/s² gravity. The jump apex is approximately 1.17m. The route test walks to each takeoff edge and lands on the next block before walking across it; it does not attempt center-to-center jumps.

Runic terrain is solid in 2D once powered and translucent/non-colliding in 3D or 1D. The upper gallery and exit terrace are permanent safe structures. This creates an explicit place to expand after the climb.

## Shutter timing

The upper shutter repeats a 4.8-second cycle: **3.0 seconds open, 1.8 seconds closed**. Its light flashes during the last 0.6 seconds of the opening. The HUD reports whether it is open. The upper rail crosses the four-meter rift in about 1.14 seconds, leaving a generous window when the player commits at the right moment.

If a closing shutter overlaps John, he is pushed back to the upper dock in 1D. Solved circuits remain powered. This introduces timing after the earlier untimed spatial lessons.

## Exploration and recovery

An optional watch echo sits in the front courtyard at (4,0.65,4.8). It does not gate progress. The receiver has rear approach space, and the upper divider requires a real walk around its end.

Checkpoints advance from arrival to the receiver court, then the climb approach, then the permanent upper gallery. Ordinary missed terrace jumps land on the court floor. Falling from the upper route returns John to its gallery checkpoint. Charge, plate and receiver states survive recovery.

## Art and framing

The scene uses deep stone foundations, broad top surfaces, brick courses, chipped edges, perimeter walls, broken pillars and a distant cavern face. Geometry stays editable in Godot. The masonry shader quantizes world coordinates to produce crisp stone detail in both perspectives.

The palette stays within warm sepia, brass and parchment, with teal used for conduit readability. John uses the approved neutral chrome sprites. No green reference-game palette, reference textures or reference code are redistributed.

The close view is the default immediately on load. M changes size from 5.2 to 14 for a local overview. The whole 64m course is represented by the separate plan drawing, not squeezed into the gameplay viewport.

The near perimeter walls are cut away visually in 1D/2D so they cannot obscure John or the platform edges; their collisions remain. In 3D the walls are visible again.

The low western boundary was adjusted after a render review to avoid hiding John at spawn. Background architecture fills the 2D frame without changing the current depth plane.

## Tuning targets

Aim for approximately 4–7 minutes for a new player, subject to playtesting. The intention is a short sequence of spatial discoveries with walking and landing space, not a long series of precision jumps. There is no health attrition in this chamber.

The reference video was sampled across its full minute: broad enclosed courts, repeated block walls, pressure-button interactions, dimensional reveals, and transitions between angled and side-on views informed this original course.
