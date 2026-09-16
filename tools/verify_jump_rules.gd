extends SceneTree

var demo: Node3D
var player: CharacterBody3D
var chamber: Node3D
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, desc: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", desc)
	else:
		failures += 1
		push_error("FAIL: " + desc)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run() -> void:
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player = demo.get_node("Player")
	chamber = demo.get_node("Chamber")
	
	# Dismiss dialogue for automated physics tests
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.queue_free()
		demo.dialogue_box = null
		
	await frames(10)
	player.input_override = true
	
	print("--- TESTING JUMP RULES & KINEMATICS ---")
	
	# 1. Test 3D Jump Rejection: Space never produces a jump impulse in 3D
	check(player.mode == 3, "Player starts in 3D mode")
	check(player.is_on_floor(), "Player is grounded in 3D")
	player.override_jump = true # Attempt to trigger jump
	await frames(2)
	check(player.velocity.y <= 0.0, "Jump input in 3D produces NO upward impulse (vy <= 0)")
	check(player.jump_buffer == 0.0, "Jump buffer is not set in 3D")
	
	# 2. Test 3D Jump Buffer Rejection on Mode Switch:
	# Pressing space while in 3D and then switching to 2D must NOT automatically jump!
	var ev = InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	player._unhandled_key_input(ev)
	check(player.jump_buffer == 0.0, "Raw Space key in 3D does not buffer a jump")
	player.request_mode(2)
	check(player.mode == 2, "Switched to 2D mode")
	check(player.jump_buffer == 0.0, "Jump buffer is strictly zero after switching to 2D")
	await frames(5)
	check(player.velocity.y <= 0.0, "No phantom jump occurred upon switching to 2D")
	
	# 3. Test 2D Jump Execution: Space jumps in 2D
	check(player.is_on_floor(), "Player is grounded in 2D")
	player.override_jump = true
	await frames(2)
	check(player.velocity.y > 5.0, "Jump in 2D successfully initiates upward impulse (vy > 5.0)")
	check(not player.is_on_floor(), "Player becomes airborne in 2D")
	
	# 4. Test Midair 2D -> 3D Momentum Preservation:
	# Switching dimensions in midair preserves vertical motion and gravity without extra height
	await frames(5) # Mid-flight
	var vy_before = player.velocity.y
	var y_before = player.position.y
	player.request_mode(3)
	check(player.mode == 3, "Switched to 3D midair")
	check(absf(player.velocity.y - vy_before) < 0.2, "Midair switch preserves vertical velocity (vy=%.2f -> %.2f)" % [vy_before, player.velocity.y])
	check(absf(player.position.y - y_before) < 0.1, "Midair switch preserves height without double jump impulse")
	
	# 5. Test 3D Airborne Depth Steering Lock:
	# While airborne in 3D, depth (Z) steering must be locked to prevent midair lane hopping
	check(not player.is_on_floor(), "Player is airborne in 3D")
	player.move_input = Vector2(0.0, 1.0) # Full forward (Z) input
	await frames(3)
	check(player.velocity.z == 0.0, "3D airborne depth steering is locked (vz == 0)")
	
	# Wait for player to land
	player.move_input = Vector2.ZERO
	for i in 60:
		if player.is_on_floor(): break
		await physics_frame
	check(player.is_on_floor(), "Player lands back on ground in 3D")
	
	# Once grounded in 3D, depth steering works normally
	player.move_input = Vector2(0.0, 1.0)
	await frames(5)
	check(absf(player.velocity.z) > 1.0, "3D grounded depth steering works normally when grounded")
	player.move_input = Vector2.ZERO
	
	# 6. Test 1D Rail Jump Rejection
	# Move to Section D Conduit rail entry
	player.position = chamber.get_node("Markers/Rail1Start").position
	await frames(5)
	check(player.request_mode(1), "Entered 1D conduit rail")
	check(player.mode == 1, "Player is in 1D mode")
	player.override_jump = true
	await frames(3)
	check(player.velocity.y == 0.0, "1D rail cannot jump (vy == 0.0)")
	
	print("\n=======================================================")
	print("JUMP RULES & KINEMATICS VERIFIED: %d/%d CHECKS PASSED!" % [checks - failures, checks])
	print("=======================================================\n")
	
	quit(1 if failures > 0 else 0)
