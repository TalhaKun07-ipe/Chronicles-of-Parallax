
## Axiom Sanctum architecture — source prototype, 2026-09-16

`chambers/axiom_warden/AxiomWarden.tscn` attaches `encounter.gd` to a Node3D. `_ready()` builds the world, player, procedural boss, hazard container, Camera3D and CanvasLayer HUD. This implementation is self-contained; it does not replace the shared player controller used by Chamber 1.

- `geometry.gd`: reusable box mesh/collision and torus constructors, stone and emissive materials. Collision exists on floor/platform bodies; visual trim does not change collision.
- `player.gd`: CharacterBody3D, faceless Sprite3D, upright capsule or 1D rod collider, direct key input, coyote time, jump buffer, preserved midair momentum, clearance-tested expansion, ground-rail entry, 0.45-second melee cooldown. Dimension numbers are local 1/2/3; Global maps 3D to enum index 4. It exposes signals `struck`, `fell`, `mode_changed`, and `notice`.
- `warden.gd`: genuine 3D mesh hierarchy with animated torso, axe arm, emitter arm, halo, chest doors and floating core. Poses include idle, sweep, beam, bolts, lane, hit, fallen, revive and dead. Animation does not drive collision.
- `hazard.gd`: beam, lane, sweep, bolt and body intersection rules. Amber warnings are harmless. Bolts use previous/current segment intersection and sweeps cover the previous/current radial interval. Dimension does not grant generic hazard immunity. Each hazard reports at most one hit.
- `hud.gd`: always-processing CanvasLayer child with typewriter dialogue, faceless geometric portraits, bottom segmented boss health, top player health, objective, pause, retry and completion overlays. Dialogue uses Z/Space/Enter/click; Esc skips it. The HUD continues receiving pause input while gameplay is paused.
- `encounter.gd`: explicit states `approach`, `dialogue`, `draw_weapon`, `combat`, `opening`, `stagger`, `false_defeat`, `revival_dialogue`, `surge`, `collapse`, `victory`, `defeated`. `events_for_phase()` holds telegraphed deterministic schedules. `try_strike()` checks phase, range, dimension and exposed core before incrementing hits. Hits 1–4 advance, 5 revives once, 6 completes. `clear_hazards()` disables and removes hazards before deferred freeing, preventing a stale hit during transitions.
- `sound.gd`: standalone-only six-voice tone synthesizer implementing `play_sfx`. Integrated projects keep their current SoundManager.

`boss_hit(total)` exposes accepted strikes; `chamber_completed` fires once after final collapse. No rewind reward fires. Arena retry resets all boss phases and player health at the checkpoint, skipping completed approach/dialogue. Health is assigned and `Global.health_changed` emitted directly, avoiding the shared autoload's scene-reload defeat behavior.

Integration modifies only Demo's chamber-complete handler and adds `_enter_axiom_sanctum()`. A current_scene guard keeps existing headless fixtures from advancing scenes unexpectedly. Production scene transition is deferred after a 1.6-second timer.

`tools/verify_axiom_warden.gd` exercises physics jump feasibility, rail constraints, mode switching, geometric hazard cases, hit gating, six-hit state flow, actual final-surge spawns, retry and pause. It parses successfully but has not been run in Godot. Run it plus `verify_route.gd`, `verify_new_features.gd`, and `verify_full_flow.gd` before merging. Human playtesting and visual camera inspection are also pending.
