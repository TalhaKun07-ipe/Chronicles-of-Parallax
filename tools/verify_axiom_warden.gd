extends SceneTree
## Run: godot --headless --path . --script tools/verify_axiom_warden.gd
var Encounter
var Hazard
var failures: int = 0
var checks: int = 0
var encounter: Node3D

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if condition: print("PASS: ", message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func frames(count: int) -> void:
	for i: int in count: await physics_frame

func run() -> void:
	Encounter = load("res://chambers/axiom_warden/scripts/encounter.gd")
	Hazard = load("res://chambers/axiom_warden/scripts/hazard.gd")
	encounter = Encounter.new()
	root.add_child(encounter)
	await frames(10)
	var p = encounter.player
	p.input_override = true
	check(p.is_on_floor(), "John starts on a collidable platform")
	check(not p.armed, "Weapon stays hidden during the approach")
	check(p.request_mode(2), "Side view is available on the approach")
	check(not p.request_mode(1), "No rail teleport during the approach")
	# Actual physics crossing of the first gap, with a rising destination.
	p.position = Vector3(-29.6, -2.35, 0)
	p.velocity = Vector3.ZERO
	await frames(8)
	p.move_input = Vector2.RIGHT
	p.override_jump = true
	await frames(38)
	p.move_input = Vector2.ZERO
	await frames(15)
	check(p.position.x > -28.0 and p.is_on_floor(), "A normal jump reaches the next terrace")
	encounter.begin_intro()
	check(encounter.state == "dialogue" and p.locked, "Arena entry locks movement for dialogue")
	check(encounter.dialogue_pages.size() == 6, "Six opening dialogue pages")
	encounter.skip_dialogue()
	check(encounter.state == "draw_weapon" and p.armed, "Dialogue leads into drawing the rod")
	await frames(90)
	check(encounter.state == "combat" and not p.locked, "Combat begins after drawing the rod")
	p.invulnerable = 999.0
	p.position = Vector3(-6, 0.06, 1.5)
	await frames(8)
	check(not p.request_mode(1), "1D requires alignment with a visible rail")
	p.position.z = 0
	await frames(8)
	check(p.request_mode(1), "Grounded rail alignment enters 1D")
	p.override_jump = true
	await frames(3)
	check(is_equal_approx(p.position.y, 0.2), "1D stays on its rail and cannot jump")
	p.override_jump = false
	check(p.request_mode(2), "1D can expand into 2D")
	await frames(8)
	p.override_jump = true
	await frames(5)
	var old_y: float = p.velocity.y
	var old_z: float = p.position.z
	check(p.request_mode(3), "Can change dimension during a jump")
	check(is_equal_approx(p.velocity.y, old_y), "Midair dimension change preserves vertical momentum")
	check(p.request_mode(2) and is_equal_approx(p.plane_z, old_z), "2D freezes the current depth")
	encounter.clear_hazards()
	# Test warning and active collision geometry independently of camera projection.
	var h = Hazard.new()
	h.kind = "beam"
	h.position = Vector3(0, 0.2, 0)
	root.add_child(h)
	h.set_physics_process(false)
	check(not h.intersects(Vector3(0, 0.2, 0), 1.14, 0.19, 1), "Amber warning is harmless")
	h.age = h.warning + 0.1
	check(h.intersects(Vector3(0, 0.2, 0), 1.14, 0.19, 1), "Low laser hits 1D")
	check(not h.intersects(Vector3(0, 1, 0), 1.14, 0.19, 2), "Jump clears the low laser")
	check(not h.intersects(Vector3(0, 0, 2), 1.14, 0.19, 3), "Depth movement dodges the laser")
	h.kind = "sweep"
	h.position.y = 0.85
	h.previous_radius = 1
	h.radius = 2
	check(not h.intersects(Vector3(1.5, 0.2, 0), 1.14, 0.19, 1), "1D slips under the high swing")
	check(h.intersects(Vector3(1.5, 0, 0), 1.14, 0.19, 2), "Standing 2D is vulnerable to the swing")
	check(not h.intersects(Vector3(1.5, 1.05, 0), 1.14, 0.19, 2), "A sufficiently high jump clears the swing")
	h.kind = "lane"
	check(h.intersects(Vector3(0, 0.2, 0), 1.14, 0.19, 1), "Depth lock hits an occupied rail")
	h.kind = "bolt"
	h.previous_position = Vector3(-3, 0.95, 0)
	h.position = Vector3(3, 0.95, 0)
	check(h.intersects(Vector3.ZERO, 1.14, 0.19, 3), "Fast projectile segment cannot tunnel through John")
	h.queue_free()
	encounter.clear_hazards()
	p.position = Vector3(7, 0.06, 0)
	p.move_input = Vector2.ZERO
	await frames(8)
	p.request_mode(3)
	encounter.core_open = true
	check(not encounter.try_strike(), "3D armor deflects an otherwise valid strike")
	p.request_mode(2)
	encounter.core_open = false
	check(not encounter.try_strike(), "Cannot skip a pattern by striking a sealed core")
	encounter.core_open = true
	p.position.x = -7
	check(not encounter.try_strike(), "A distant F strike cannot damage the boss")
	p.position.x = 7
	for hit_index: int in 5:
		encounter.clear_hazards()
		encounter.core_open = true
		encounter.state = "opening"
		check(encounter.try_strike(), "Successful core strike %d" % (hit_index + 1))
		check(not encounter.try_strike(), "One opening accepts only one hit")
		if hit_index < 4:
			await frames(80)
			check(encounter.hits == hit_index + 1 and encounter.state == "combat", "Hit advances to the next attack phase")
	check(encounter.hits == 5 and encounter.state == "false_defeat", "Fifth hit is a false defeat")
	await frames(160)
	check(encounter.state == "revival_dialogue", "False defeat leads to the final dialogue")
	encounter.skip_dialogue()
	check(encounter.state == "surge", "Revival starts the last surge")
	check(not encounter.try_strike(), "Final strike is locked until the surge has passed")
	var seen: Dictionary = {}
	for i: int in 1100:
		await physics_frame
		for hazard: Node in encounter.hazards.get_children(): seen[hazard.kind] = true
		if encounter.state == "opening": break
	check(seen.has("sweep") and seen.has("beam") and seen.has("bolt") and seen.has("lane"), "Final surge actually spawns all four attack types")
	check(encounter.state == "opening" and encounter.core_open, "Surviving the surge exposes the final core")
	p.position = Vector3(7, 0.06, 0)
	check(encounter.try_strike() and encounter.hits == 6, "Sixth hit collapses the Warden")
	await frames(130)
	check(encounter.state == "victory" and not encounter.exit_seal.visible, "Collapse completes the chamber")
	var g: Node = root.get_node_or_null("Global")
	if g: check(not bool(g.get("rewind_unlocked")), "Rewind remains locked")
	# Retry restores this arena rather than replaying the parkour or dialogue.
	encounter.state = "combat"
	encounter.health = 1
	p.invulnerable = 0
	encounter.hurt_player()
	check(encounter.state == "defeated", "Lethal damage opens the retry screen")
	encounter.retry()
	check(encounter.hits == 0 and encounter.health == 3 and encounter.state == "combat", "Retry restores all boss phases and John health")
	check(p.position.is_equal_approx(encounter.CHECKPOINT), "Retry starts at the arena checkpoint")
	encounter.toggle_pause()
	check(paused, "Escape pauses the encounter")
	encounter.toggle_pause()
	check(not paused, "Escape resumes the encounter")
	print("AXIOM WARDEN: %d/%d checks passed" % [checks - failures, checks])
	encounter.queue_free()
	await process_frame
	quit(1 if failures else 0)
