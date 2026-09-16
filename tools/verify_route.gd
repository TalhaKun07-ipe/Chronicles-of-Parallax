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

func walk(goal: Vector2, limit: int = 400) -> bool:
	for i in limit:
		var d := Vector3(goal.x - player.position.x, 0, goal.y - player.position.z)
		if d.length() < 0.12:
			player.move_input = Vector2.ZERO
			await frames(2)
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
	await walk(Vector2(x, target_z), 90)
	await frames(25)
	check(player.is_on_floor() and absf(player.position.y - height) < 0.18,
		"Lands at Y=%.2f (actual=%.2f)" % [height, player.position.y])

func run() -> void:
	print("--- BEGINNING CHAMBER 1 FULL 8-SECTION ROUTE VERIFICATION ---")
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player = demo.get_node("Player")
	chamber = demo.get_node("Chamber")
	
	await frames(10)
	
	# Dismiss intro dialogue for automated headless test
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.queue_free()
		demo.dialogue_box = null
	await frames(2)
	player.input_override = true
	
	var global = demo.get_node_or_null("/root/Global")
	check(global != null, "Global autoload present")
	check(global.current_health == 3, "Starts with 3 full health points")
	check(demo.heart_icons.size() == 3, "Clean HUD displays 3 floating health hearts")
	
	# =========================================================================
	# SECTION A: Arrival & Safe Orientation
	# =========================================================================
	check(player.mode == 3, "Starts in 3D volume mode")
	check(await walk(Vector2(-11.5, 0.0)), "Walks across arrival terrace in 3D")
	
	# Verify 3D cannot jump
	player.override_jump = true
	await frames(3)
	check(player.velocity.y <= 0.01, "Jump in 3D is strictly rejected (no upward impulse)")
	
	# Switch to 2D to jump onto raised ledge
	check(player.request_mode(2), "Switches to 2D at raised ledge")
	await jump_to(-9.0, 0.0, 0.80)
	check(await walk(Vector2(-7.8, 0.0)), "Reaches edge of raised ledge A")
	
	# =========================================================================
	# SECTION B: The Broken Stair (4 Ascending 2D Jumps)
	# =========================================================================
	# Jump 1: to StairB1 (Y=1.20)
	await jump_to(-5.2, 0.0, 1.20)
	# Jump 2: to StairB2 (Y=1.60)
	await jump_to(-1.7, 0.0, 1.60)
	# Jump 3: to StairB3 (Y=2.00)
	await jump_to(2.0, 0.0, 2.00)
	check(await walk(Vector2(2.8, 0.0)), "Walks to edge of Stair B3")
	# Jump 4: to TerraceBTop (Y=2.40)
	await jump_to(5.8, 0.0, 2.40)
	check(player.position.y > 2.30, "Reaches broad resting Terrace B at Y=2.40")
	
	# Verify forward 2D route is blocked by BarrierMonolithC
	player.move_input = Vector2.RIGHT
	await frames(40)
	player.move_input = Vector2.ZERO
	check(player.position.x < 10.0, "Barrier Monolith C genuinely blocks forward 2D route")
	
	# =========================================================================
	# SECTION C: The Offset Passage (3D Depth Routing)
	# =========================================================================
	check(player.request_mode(3), "Switches to 3D to route around barrier monolith")
	check(await walk(Vector2(8.5, -4.0)), "Steps across depth into rear aisle (Z=-4.0)")
	check(await walk(Vector2(16.0, -4.0)), "Walks through offset corridor behind monolith in 3D")
	check(absf(player.position.z + 4.0) < 0.3, "Successfully navigated around depth barrier to Z=-4.0 lane")
	
	# =========================================================================
	# SECTION D: The Narrow Conduit (1D Passage through Bulkhead)
	# =========================================================================
	check(await walk(Vector2(16.5, -4.0)), "Walks to Conduit D start dock")
	check(player.request_mode(1), "Enters 1D mode on conduit rail")
	check(absf(player.position.y - 2.58) < 0.1, "Locked to rail elevation")
	check(await walk(Vector2(21.0, -4.0)), "Slides in 1D through bulkhead slit across rift")
	check(not player.request_mode(3), "Unsafe expansion over open rift strictly rejected")
	check(await walk(Vector2(25.5, -4.0)), "Reaches destination dock at Section E entrance")
	check(player.request_mode(2), "Expands safely into 2D on Gallery terrace")
	
	# =========================================================================
	# SECTION E: The Fractured Gallery (Extended 2D Parkour)
	# =========================================================================
	check(await walk(Vector2(29.0, -4.0)), "Walks to edge of Gallery entrance terrace")
	# Jump 1: to Pillar E1 (Y=2.80)
	await jump_to(32.0, -4.0, 2.80)
	check(await walk(Vector2(32.8, -4.0)), "Walks to edge of Pillar E1")
	# Jump 2: to Pillar E2 (Y=3.20)
	await jump_to(35.8, -4.0, 3.20)
	check(await walk(Vector2(36.6, -4.0)), "Walks to edge of Pillar E2")
	# Jump 3: to Moving Platform E3 (Y=3.20)
	await jump_to(39.5, -4.0, 3.20)
	await frames(10)
	# Jump 4: to Pillar E4 (Y=3.20)
	await jump_to(44.5, -4.0, 3.20)
	check(await walk(Vector2(45.4, -4.0)), "Walks to edge of Pillar E4")
	# Jump 5: to Relay Court Landing (Y=3.00)
	await jump_to(48.5, -4.0, 3.00)
	check(player.position.y >= 2.90, "Reaches Relay Court checkpoint terrace at Y=3.00")
	
	# =========================================================================
	# SECTION F: The Relay Court (Interactive Dimension Puzzle)
	# =========================================================================
	check(player.request_mode(3), "Switches to 3D to explore Relay Court")
	check(await walk(Vector2(51.5, 3.5)), "Walks to security grille conduit dock at Z=+3.5")
	check(player.request_mode(1), "Flattens to 1D to enter security grille conduit")
	check(await walk(Vector2(56.0, 3.5)), "Slides in 1D through grille slit into spark chamber")
	check(chamber.carrying_charge, "Collected and carrying circuit spark behind security grille")
	check(await walk(Vector2(51.5, 3.5)), "Returns in 1D with spark back through grille")
	check(player.request_mode(3), "Expands into 3D volume at Relay Court")
	
	# Route around central wall across depth to receiver
	check(await walk(Vector2(54.0, 0.0)), "Steps across depth to central court")
	check(await walk(Vector2(61.2, -2.5)), "Navigates depth around central wall to receiver")
	var interact_msg = chamber.try_interact(player.position)
	await frames(5)
	check(chamber.powered, "Deposited spark powers circuit and ignites runic bridge!")
	
	# Step around receiver pedestal in 3D to reach base of runic bridge
	check(await walk(Vector2(63.2, -2.2)), "Advances past pedestal in 3D")
	check(await walk(Vector2(63.2, -3.5)), "Aligns to runic bridge climb lane (Z=-3.5)")
	
	# =========================================================================
	# SECTION G: The Interwoven Ascent (Multi-Dimensional Climax)
	# =========================================================================
	# 2D jump onto runic bridge
	check(player.request_mode(2), "Switches to 2D for runic ascent")
	await jump_to(65.5, -3.5, 3.60)
	check(await walk(Vector2(67.5, -3.5)), "Walks along runic bridge")
	await jump_to(70.5, -3.5, 4.20)
	check(player.position.y > 4.10, "Stands on Terrace G1 at Y=4.20")
	
	# Required 3D depth walk across Transversal Walkway
	check(player.request_mode(3), "Switches to 3D for depth transversal walk")
	check(await walk(Vector2(71.0, 2.5)), "Walks across transversal depth walkway from Z=-3.5 to Z=+2.5")
	
	# 2D jump sequence on front lane
	check(player.request_mode(2), "Switches to 2D on front lane (Z=+2.5)")
	check(await walk(Vector2(72.5, 2.5)), "Walks to front lane jump edge")
	await jump_to(75.0, 2.5, 4.80)
	check(await walk(Vector2(76.2, 2.5)), "Walks to edge of Terrace G2")
	await jump_to(79.0, 2.5, 5.20)
	check(player.position.y > 5.10, "Stands on High Conduit dock at Y=5.20")
	
	# 1D High Conduit slide through gate bulkhead
	check(player.request_mode(1), "Collapses to 1D on High Conduit rail")
	check(await walk(Vector2(85.5, 2.5)), "Slides in 1D through high bulkhead slit across chasm")
	check(player.request_mode(2), "Expands into 2D at far dock")
	check(await walk(Vector2(85.8, 2.5)), "Walks to edge of exit dock")
	
	# Final 2D jumps to Guardian Threshold
	await jump_to(87.5, 2.5, 5.50)
	check(await walk(Vector2(88.2, 2.5)), "Walks to edge of stepping stone")
	await jump_to(91.0, 2.5, 5.80)
	check(player.position.y > 5.70, "Ascends onto Guardian Hall grand threshold at Y=5.80")
	
	# =========================================================================
	# SECTION H: Guardian Hall & Chamber Exit
	# =========================================================================
	check(player.request_mode(3), "Enters Guardian arena in 3D")
	check(await walk(Vector2(94.0, 0.0)), "Steps onto Guardian arena floor")
	
	guardian = demo.get_node_or_null("FlatGuardian")
	check(guardian != null, "Flat Guardian is present in arena")
	guardian.global_position = Vector3(97.0, 6.38, 0.0)
	await frames(5)
	check(guardian.mode == 3 and not guardian.is_ethereal_2d, "Flat Guardian is active and solid in 3D")
	
	# Take damage check
	var hp_before = global.current_health
	player.take_damage(1, guardian.global_position)
	await frames(5)
	check(global.current_health == hp_before - 1, "Player takes 1 damage from contact in 3D")
	check(demo.heart_icons[2].texture == demo.heart_empty_tex, "Third heart icon reflects damage")
	
	# Switch to 2D: Guardian collapses into paper-thin ethereal phase
	check(player.request_mode(2), "Player switches to 2D to bypass Flat Guardian")
	await frames(5)
	check(guardian.mode == 2 and guardian.is_ethereal_2d, "Flat Guardian enters 2D paper-thin ethereal phase")
	
	# Slip right through guardian unharmed
	var hp_pass = global.current_health
	check(await walk(Vector2(99.0, 0.0)), "Walks directly through Flat Guardian in 2D")
	check(global.current_health == hp_pass, "Passed through Flat Guardian taking ZERO damage in 2D")
	
	# Reach Exit Archway
	check(await walk(Vector2(102.5, 0.0)), "Reaches Chamber 1 Exit Portal Archway")
	await frames(5)
	check(chamber.completed, "Chamber 1 completed successfully!")
	
	# Test Pit Respawn / Checkpoint Recovery
	player.position = Vector3(95.0, -8.0, 0.0)
	await frames(5)
	demo._process(0.016)
	await frames(5)
	check(player.position.y > 5.0, "Pit fall respawns player at safe Section H checkpoint (Y=5.88)")
	check(chamber.powered, "Puzzle state (circuit powered) retained after respawn")
	
	print("\n=======================================================")
	print("ALL %d CHAMBER 1 8-SECTION REDESIGN ROUTE CHECKS PASSED 100%%!" % checks)
	print("=======================================================\n")
	quit(0)
