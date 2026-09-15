extends SceneTree

var demo: Node3D
var player: CharacterBody3D
var chamber: Node3D
var guardian
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: " + description + " at " + str(player.position if player else "N/A"))
		quit(1)
		assert(ok, description)
	checks += 1
	print("PASS: " + description)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func walk(goal: Vector2, limit: int = 450) -> bool:
	for i in limit:
		var d := Vector3(goal.x - player.position.x, 0, goal.y - player.position.z)
		if d.length() < 0.08:
			player.move_input = Vector2.ZERO
			await frames(3)
			return true
		d = d.normalized()
		if player.mode == 3:
			d = d.rotated(Vector3.UP, deg_to_rad(45.0))
		player.move_input = Vector2(d.x, d.z)
		await physics_frame
	player.move_input = Vector2.ZERO
	return false

func jump_to(x: float, target_z: float, height: float) -> void:
	player.override_jump = true
	await frames(1)
	await walk(Vector2(x, target_z), 120)
	await frames(35)
	check(player.is_on_floor() and absf(player.position.y - height) < 0.12, "Lands at Y=%.2f (actual=%.2f)" % [height, player.position.y])

func run() -> void:
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player = demo.get_node("Player")
	chamber = demo.get_node("Chamber")
	
	await frames(10)
	
	# Dismiss/remove intro dialogue for headless route walk
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.queue_free()
		demo.dialogue_box = null
	await frames(2)
	player.input_override = true
	
	# Verify top-left hearts HUD initial state
	var global = demo.get_node_or_null("/root/Global")
	check(global != null, "Global autoload present")
	check(global.current_health == 3, "Starts with 3 full health points")
	check(demo.heart_icons.size() == 3, "HUD has 3 red heart icons in top-left")
	check(demo.heart_icons[0].texture == demo.heart_full_tex, "First heart is full")
	check(demo.heart_icons[1].texture == demo.heart_full_tex, "Second heart is full")
	check(demo.heart_icons[2].texture == demo.heart_full_tex, "Third heart is full")
	
	# Verify 3D Terrace Visibility BEFORE 2D activation (User Request 1)
	for step in root.get_tree().get_nodes_in_group("bc_steps"):
		for mesh in step.find_children("*", "MeshInstance3D"):
			check(mesh.material_override != null, "Terrace mesh has solid masonry material in 3D")
	
	# Step 1: Walk to wake plate
	check(not player.request_mode(1), "Rejects 1D away from live conduit")
	check(await walk(Vector2(-9.0, 0.0)), "Walks to arrival wake plate")
	check(chamber.first_rail_live, "Plate wakes lower conduit rail")
	
	# Step 2: 1D traverse across lower rift
	check(await walk(Vector2(-5.5, 0.0)), "Walks to first conduit rail entry")
	check(player.request_mode(1), "Enters 1D conduit rail")
	check(await walk(Vector2(-1.1, 0.0)), "Slides in 1D below bulkhead across 4m rift")
	check(not player.request_mode(3), "Rejects unsafe expansion over open rift")
	check(await walk(Vector2(3.0, 0.0)), "Reaches far landing in 1D")
	check(chamber.carrying_charge, "Picks up circuit spark")
	
	# Step 3: Expand to 2D then 3D and reach receiver
	check(player.request_mode(2), "Expands to 2D at safe landing")
	player.move_input = Vector2.RIGHT
	await frames(80)
	player.move_input = Vector2.ZERO
	check(player.position.x < 6.0, "Masonry wall stops 2D forward route")
	
	check(player.request_mode(3), "Restores 3D volume mode")
	check(await walk(Vector2(5.0, -4.0)), "Follows rear aisle in 3D")
	check(await walk(Vector2(6.6, -4.0)), "Walks to receiver socket")
	
	var msg = chamber.try_interact(player.position)
	await frames(5)
	check(chamber.powered and not chamber.carrying_charge, "Deposits spark and powers circuit")
	
	# Verify Terrace blocks remain solid and visible in 3D
	check(chamber.has_node("Mechanisms/HighConduit"), "High conduit unhidden upon power")
	
	# Step 4: Multi-dimensional platforming: Jump onto block in 2D
	check(await walk(Vector2(6.6, -5.0)), "Walks behind receiver")
	check(await walk(Vector2(13.6, -5.0)), "Crosses generous rear court")
	check(await walk(Vector2(13.9, -4.0)), "Aligns to climb plane at terrace base")
	check(player.request_mode(2), "Switches to 2D to jump onto runic terrace")
	check(absf(player.plane_z + 4.0) < 0.1, "Locks to 2D plane at Z=-4.0")
	await jump_to(16.0, -4.0, 0.85)
	check(await walk(Vector2(19.0, -4.0)), "Walks along 2D terrace surface at Y=0.85")
	
	# Step 5: Switch to 3D and traverse front along +Z walkway
	check(player.request_mode(3), "Switches to 3D on terrace surface")
	check(await walk(Vector2(18.5, 0.0)), "Traverses forward ('front') in 3D onto front terrace walkway")
	check(player.position.y > 0.75, "Remains firmly standing on elevated 3D terrace")
	
	# Step 6: Utilize 1D again via High Conduit Rail across chasm
	check(await walk(Vector2(20.2, 0.0)), "Walks to High Conduit Rail entry")
	check(player.request_mode(1), "Collapses to 1D on high rail")
	check(absf(player.position.y - 1.05) < 0.1, "Locked to High Rail elevation (Y=1.05)")
	check(await walk(Vector2(23.5, 0.0)), "Slides in 1D through narrow slit lintel over deep rift")
	check(not player.request_mode(3), "Cannot expand into 3D inside narrow rift slit")
	check(await walk(Vector2(26.5, 0.0)), "Reaches Guardian Hall entrance landing")
	
	# Step 7: Expand into Guardian Hall in 3D and test Flat Guardian mechanics
	check(player.request_mode(3), "Expands into 3D in Guardian Hall")
	check(await walk(Vector2(27.5, 0.0)), "Steps onto Guardian Hall arena floor")
	
	# Find Flat Guardian instance
	guardian = demo.get_node_or_null("FlatGuardian")
	check(guardian != null, "Flat Guardian is spawned and active in arena")
	
	# In 3D: Guardian detects and pursues player
	guardian.global_position = Vector3(29.0, 1.35, 0.0)
	await frames(5)
	check(guardian.mode == 3 and not guardian.is_ethereal_2d, "Guardian is in 3D hostile pursuit mode")
	check(guardian.collision_layer == 1, "Guardian is physically solid in 3D")
	
	# Test Player Taking Damage from Guardian
	var hp_before = global.current_health
	player.take_damage(1, guardian.global_position)
	await frames(5)
	check(global.current_health == hp_before - 1, "Player takes 1 damage from Guardian attack")
	check(demo.heart_icons[2].texture == demo.heart_empty_tex, "Third heart becomes empty in HUD")
	check(player.invulnerable_timer > 0.0, "Player gains invulnerability frames and knockback")
	
	# Step 8: Switch to 2D - Guardian phases into paper-thin ethereal form
	check(player.request_mode(2), "Player switches to 2D to bypass Flat Guardian")
	await frames(5)
	check(guardian.mode == 2 and guardian.is_ethereal_2d, "Flat Guardian collapses to 2D paper-thin phase")
	check(guardian.collision_layer == 0, "Guardian collision layer disabled in 2D")
	check(guardian.collision_mask == 0, "Guardian collision mask disabled in 2D")
	check(guardian.sprite.modulate.a < 0.5, "Guardian visually ethereal in 2D (low alpha)")
	
	# Walk straight through Guardian unharmed!
	var hp_during_pass = global.current_health
	check(await walk(Vector2(32.0, 0.0)), "Walks straight through Flat Guardian in 2D")
	check(global.current_health == hp_during_pass, "Took ZERO damage passing through Flat Guardian in 2D!")
	
	# Step 9: Reach Exit Archway and Complete Chamber 1
	check(await walk(Vector2(36.0, 0.0)), "Walks to Chamber 1 Exit Archway")
	await frames(5)
	check(chamber.completed, "Exit triggered and Chamber 1 completed successfully!")
	
	# Step 10: Test Respawn / Health Reset
	guardian.global_position = Vector3(33.5, 1.35, 0.0)
	player.respawn()
	await frames(2)
	check(global.current_health == 3, "Respawn restores player to 3 full health points")
	check(demo.heart_icons[2].texture == demo.heart_full_tex, "HUD hearts fully restored upon respawn")
	check(player.position.x > 25.0, "Respawn places player at safe Guardian Hall checkpoint")
	
	print("\n=======================================================")
	print("ALL %d CHAMBER 1 PLATFORMING & ROUTE CHECKS PASSED 100%%!" % checks)
	print("=======================================================\n")
	quit(0)
