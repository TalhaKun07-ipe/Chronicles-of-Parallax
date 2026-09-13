# Degrees of Escape — Revised Game Plan

**Direction:** Learn to combine space; earn control over time.

**Status:** Design plan, not a report of implemented features. The core direction below reflects our agreed revision. Room layouts, timings, and controls are proposed starting points for playtesting.

## 1. The new core concept

John Rod can deliberately switch between **1D, 2D, and 3D from the start of playable exploration**. He climbs out of the cavern by combining their strengths within the same rooms. Progress comes from understanding the dimensions, rather than unlocking them one stage at a time.

Defeating the Guardian unlocks **4D rewind**. A short playable escape lets the player use that reward before the ending.

Keep the game compact: one introductory room, three puzzle chambers, one boss arena, and one escape sequence. Aim initially for roughly **12–18 minutes**, then adjust from playtests.

## 2. Story and introduction

Keep the existing six-panel intro: ancient relic, exploration, discovery, contact, dimensional fall, and the point at the bottom.

Immediately afterward, the Chrono-Lens flickers back to life. John briefly expands through line, silhouette, and full spatial form. The three spatial symbols illuminate on the watch; the time symbol stays dark.

This preserves the fall and existing intro artwork while replacing the old gradual spatial-unlock progression. The 0D point is a brief narrative state, not a separate puzzle stage.

## 3. Dimension rules

| Form | Main use | Constraint |
| --- | --- | --- |
| **1D — Line** | Slide along conduits, through narrow openings, and beneath barriers | Movement stays on a visible rail; no jumping or independent depth movement |
| **2D — Plane** | Run and jump along a vertical slice; use thin runic platforms | Depth is fixed while this form is active |
| **3D — Volume** | Move around pillars, explore depth, approach mechanisms from another side | Full body needs clearance and cannot enter narrow conduits |
| **4D — Time** | Rewind selected recent events during the final escape | Locked until the boss is defeated; short rewind window |

**Switching rules:**

- Preserve John's world position when changing form. A camera change must not teleport him across depth or through a wall.
- Allow deliberate switching whenever the destination form is valid, without an energy meter or a long cooldown.
- Enter 1D only when touching or closely aligned with a visible conduit. Author rail endpoints with enough clearance to expand safely.
- Entering 2D freezes the current depth coordinate. Returning to 3D restores depth movement at that same position.
- If a larger form would overlap solid geometry, reject the switch with a brief watch flicker and keep the current form.
- Mark dimension-dependent geometry consistently. For example, thin runic ledges become solid in 2D and remain visible as faint outlines in 3D.
- If the existing 3D controller supports jumping, retain it initially. Make 2D routes useful through their special platforms, rather than relying on an unexplained jump restriction.

Treat 2.5D as a camera/presentation transition for this version, not a fourth spatial control the player must learn.

## 4. Map and progression

The sanctuary is a stack of connected chambers. Each solved room opens a higher doorway or route. Individual rooms offer depth, conduits, and vertical platforms; the overall route remains easy to follow.

| Area, bottom to top | Purpose | Route to the next area |
| --- | --- | --- |
| **Arrival: The Broken Circuit** | Introduce the three forms | Upper doorway |
| **Chamber 1: The Hidden Connection** | Explore and return from a new direction | Powered stair platforms |
| **Chamber 2: The Moving Wall** | Combine timing with dimension changes | Raised bridge |
| **Chamber 3: The Ascent Engine** | Recombine all learned mechanics | Guardian antechamber |
| **Guardian arena** | Solve a spatial puzzle under pressure | Boss defeat releases the time seal |
| **Final escape** | Experience 4D rewind | Daylight and ending |

## 5. Puzzle rooms

### Arrival — The Broken Circuit

**Layout:** A sealed door has a narrow conduit beneath it. Beyond the door, a pillar hides a receiver. Runic ledges rise toward the exit.

**Intended solution:**

1. Become 1D and slide through the conduit, collecting a charge on the way.
2. Expand to 3D in the clear space beyond the door and walk around the pillar.
3. Touch the receiver to deliver the charge and activate the runic ledges.
4. Become 2D and jump up the ledges to the upper doorway.

All forms are already available. The room teaches their uses through one obstacle at a time. No lethal hazards here.

### Chamber 1 — The Hidden Connection

**Layout:** The exit receiver is visible near the entrance, but its charge is behind a large central structure. A conduit threads beneath the structure; its far endpoint connects to a recessed chamber.

**Intended solution:** Use 3D to find the conduit entrance, use 1D to reach the recessed chamber and collect the charge, then return to the earlier receiver. Powering it activates a 2D stair route above the entrance.

**The discovery:** Moving backward completes the circuit and creates the upward route.

**Clue:** On collection, a light travels along a background cable toward the receiver. Carrying a charge survives dimension changes and requires no inventory controls.

### Chamber 2 — The Moving Wall

**Layout:** A mechanical shutter periodically blocks a conduit. The far end opens into a safe recess. A lever sits behind the shutter housing, reachable by moving around it in depth. Above it is a broken bridge with 2D runic footholds.

**Intended solution:** Observe the shutter, cross in 1D during an opening, expand in the safe recess, and use 3D to reach the rear lever. The lever permanently holds the shutter open and energizes the 2D route across the bridge.

**The discovery:** Solve the timing challenge once, then change the machinery so it becomes safe.

**Fairness:** Give the shutter a clear warning flash and sound. A failed crossing returns John to the nearby rail entrance; it never restarts the whole room. Holding it open is a mechanical action, not early access to 4D.

### Chamber 3 — The Ascent Engine

**Layout:** A dormant lift occupies the center. Its power source is inside a narrow maintenance conduit; its receiver is at the rear of the lift. A control lever sits above the receiver on runic ledges.

**Intended solution:** Reach the source in 1D, carry its charge around the lift in 3D, and power the receiver. Climb the newly active ledges in 2D to pull the lever. The lift rises and carries John to the boss entrance.

**The discovery:** Different forms solve different parts of one visible machine.

Use familiar objects here. Increase the planning required without adding another currency, switch type, or movement ability.

## 6. Guardian encounter

The Guardian tests the spatial skills already learned. **Rewind is unavailable throughout this fight.**

Proposed attack-and-puzzle cycle:

1. A clearly signaled slam exposes a low maintenance conduit while blocking the direct route.
2. John becomes 1D to pass through it into a protected recess.
3. In 3D, he circles behind the Guardian and activates an exposed mechanism.
4. The mechanism reveals 2D runic footholds leading to the vulnerable core.
5. John switches to 2D, climbs, and strikes the core with a simple interaction.

Use two successful cycles initially. The second changes the approach or attack timing while keeping the rules recognizable. Allow enough recovery time to understand the route; avoid a long repeated damage routine.

On defeat, the Guardian releases the watch's time seal. The escape staircase then collapses in view of the player.

## 7. 4D reward and playable ending

Give the player approximately **1–2 minutes of practical use** after the unlock.

1. Demonstrate rewind on the freshly collapsed staircase: holding the rewind input restores the steps.
2. Let the player reverse a falling debris obstacle to reopen the next passage.
3. Finish with one short climb that combines familiar spatial switching with rewind.
4. John reaches daylight; the watch settles into a quiet glow.

Start with the documented four-second rewind window. Record eligible objects before the unlock so the first demonstration has history to restore. Mark rewindable objects with the same gold watch motif. Keep progression flags, the boss's defeat, and the time unlock permanent.

The first rewind obstacle should be safe to experiment with and repeatable if the player waits too long. Reconstructed stairs remain usable after releasing rewind, rather than immediately collapsing again.

## 8. Visual and interaction language

- **John:** Clean neutral-silver wire silhouette, consistent with the revised sprites.
- **Cavern:** Dark stone, broken sanctuary machinery, distant inaccessible architecture, and increasing light toward the surface.
- **1D routes:** Thin cyan conduits with clearly visible entrances and exits.
- **2D routes:** Runic edges and faint platform outlines that become solid in the plane view.
- **Charges and receivers:** Matching shapes, with a visible connection lighting up when powered.
- **Time:** Antique-gold watch motifs, introduced fully after the boss.
- Keep the active route readable against the scenery. Pair colors with shapes, movement, and sound.

Proposed controls: `1 / 2 / 3` select spatial forms; `A/D` or arrows move sideways; `W/S` adds depth movement in 3D; `Space` jumps where supported; one interaction key operates levers and strikes the exposed core. Touch collects and deposits charges. `R` becomes rewind after the boss.

Place checkpoints at chamber entrances and before the Guardian. Retain completed receiver activations within a room so a mistake does not require repeating its entire solution.

## 9. Build order and scope

1. Update the design state: all three spatial forms available at arrival; time remains locked.
2. Prototype position-preserving switches, rail entry/exit, 2D depth locking, and clearance rejection in one plain test room.
3. Build the arrival puzzle and test whether a new player understands it without explanation.
4. Add reusable charge, receiver, gate, shutter, and runic-platform components.
5. Assemble the three chambers from those components.
6. Build the Guardian with the same route and mechanism rules.
7. Add the rewind unlock and short escape; then finish lighting, audio, camera transitions, and art.

Keep the first version to one environment family, one charge type, one boss, and a small set of reusable obstacles. Avoid skill trees, crafting, multiple enemy types, or lengthy dialogue.

## 10. Playtest checks

- Can a new player explain each form's use after the arrival room?
- Does switching preserve position and avoid wall clipping, surprise falls, or unintended depth shortcuts?
- Does every chamber use multiple dimensions for an understandable reason?
- Are alternate solutions acceptable, and are any accidental shortcuts bypassing the central puzzle?
- Can the player identify safe waiting spaces and predict shutter/boss attacks?
- Do checkpoints and retained activations prevent tedious repetition or softlocks?
- Does the final rewind reward offer a useful new interaction before the credits?

## Changes from the earlier plan

This revision replaces the separate 1D-only, 2D-only, and 3D-only progression. It also replaces the earlier concept of rewinding during the Guardian fight. Preserve the protagonist, cavern setting, watch, intro fall, pixel-art direction, and reusable spatial/rewind systems, but review their implementation against these new rules before reusing them.
