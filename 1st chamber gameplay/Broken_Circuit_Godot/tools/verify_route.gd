extends SceneTree
## Runs the real CharacterBody3D through the intended solution, without teleporting.
var demo: Node3D
var player: CharacterBody3D
var chamber: Node3D
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if not condition:
		push_error("FAIL: " + description)
		quit(1)
		assert(condition, description)
	checks += 1
	print("PASS: " + description)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func walk_to(goal: Vector2, limit: int = 240) -> bool:
	for i in limit:
		var diff := Vector3(goal.x-player.position.x, 0, goal.y-player.position.z)
		if diff.length() < 0.075:
			player.move_input = Vector2.ZERO
			await frames(3)
			return true
		var direction: Vector3 = diff.normalized()
		if player.mode == 3:
			direction = direction.rotated(Vector3.UP, deg_to_rad(32.0))
		player.move_input = Vector2(direction.x, direction.z)
		await physics_frame
	player.move_input = Vector2.ZERO
	return false

func jump_to(x: float, expected_height: float) -> void:
	player.override_jump = true
	await frames(1)
	check(await walk_to(Vector2(x,-2.5),100), "Jump reaches X %.1f" % x)
	await frames(55)
	check(player.is_on_floor() and absf(player.position.y-expected_height) < 0.09, "Lands on surface at Y %.2f" % expected_height)

func run() -> void:
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player = demo.get_node("Player")
	chamber = demo.get_node("Chamber")
	player.input_override = true
	await frames(10)
	check(not player.request_mode(1), "Rejects 1D away from rail")
	check(await walk_to(Vector2(-9.7,0)), "Walks from spawn to conduit dock")
	check(player.request_mode(1), "Enters conduit in 1D")
	check(await walk_to(Vector2(-6.0,0)), "Crosses pit beneath slotted gate")
	check(not player.request_mode(3) and player.mode == 1, "Rejects expansion over abyss / inside gate")
	check(await walk_to(Vector2(-2.4,0)), "Reaches far dock")
	check(chamber.carrying_charge, "Collects spark on the way")
	check(player.request_mode(2), "Expands safely onto courtyard floor")
	player.move_input = Vector2.RIGHT
	await frames(80)
	player.move_input = Vector2.ZERO
	check(player.position.x < -1.0, "Monolith blocks the flat route")
	check(player.request_mode(3), "3D remains available with charge")
	check(await walk_to(Vector2(-1.7,-2.5)), "Walks around left side of monolith")
	check(await walk_to(Vector2(-0.3,-2.5)), "Discovers rear receiver")
	chamber.try_interact(player.position)
	await frames(3)
	check(chamber.powered and not chamber.carrying_charge, "Receiver consumes charge and latches circuit")
	check(chamber.get_node("Mechanisms/RunicStep1/Collision").disabled, "Powered steps remain non-solid in 3D")
	check(await walk_to(Vector2(-0.3,-3.3)), "Passes behind receiver")
	check(await walk_to(Vector2(2.4,-3.3)), "Reaches climb approach")
	check(await walk_to(Vector2(2.4,-2.5)), "Aligns with rear staircase")
	check(player.request_mode(2), "Selects 2D at current depth")
	check(absf(player.plane_z + 2.5) < 0.08, "2D preserves depth without Z=0 teleport")
	await frames(3)
	check(not chamber.get_node("Mechanisms/RunicStep1/Collision").disabled, "2D activates staircase collisions")
	await jump_to(3.4,0.85)
	await jump_to(5.3,1.7)
	await jump_to(7.2,2.55)
	await jump_to(9.1,3.4)
	await jump_to(11.6,4.25)
	check(chamber.completed, "Upper exit completes the chamber")
	player.respawn()
	await frames(10)
	check(chamber.powered and player.position.x > 2, "Recovery preserves solved circuit and courtyard checkpoint")
	print("ROUTE VALIDATED: %d checks" % checks)
	quit(0)
