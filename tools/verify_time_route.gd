extends SceneTree

var room
var player
var clock
var checks: int = 0
var global: Node

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: " + description + " at " + str(player.position if player else Vector3.ZERO))
		quit(1)
		assert(ok, description)
	checks += 1
	print("PASS: ", description)

func frames(n: int) -> void:
	for i in n: await physics_frame

func walk(x: float, z: float = 0.0, limit: int = 500) -> bool:
	for i in limit:
		var offset := Vector2(x - player.position.x, z - player.position.z)
		if player.mode != 3: offset.y = 0
		if offset.length() < 0.09:
			player.move_input = Vector2.ZERO
			return true
		player.move_input = offset.normalized()
		await physics_frame
	player.move_input = Vector2.ZERO
	return false

func jump_to(x: float, top: float = -100.0) -> void:
	var launch: Vector3 = player.position
	check(player.is_on_floor(), "Jump launches from solid floor at X=%.1f" % launch.x)
	player.override_jump = true
	await frames(1)
	check(await walk(x, player.plane_z, 85), "Jump reaches X=%.1f" % x)
	for i in 70:
		if player.is_on_floor() and player.position.y > launch.y - 0.2: break
		await physics_frame
	check(player.is_on_floor(), "Jump lands on physical collision at X=%.1f" % x)
	if top > -90:
		check(absf(player.position.y - top) < 0.2, "Landing height %.1f is reachable" % top)

func stair_route() -> void:
	check(await walk(5.65), "Walks across arrival floor")
	await jump_to(7.5, 0.6)
	check(await walk(9.1), "Reaches first step edge")
	await jump_to(11.1, 1.2)
	check(await walk(12.7), "Reaches second step edge")
	await jump_to(14.8, 1.8)
	check(await walk(16.5), "Crosses first crumbling floor before it falls")
	await jump_to(18.7, 2.4)
	check(await walk(20.35), "Crosses second crumbling floor")
	await jump_to(22, 2.4)
	check(await walk(25), "Reaches first time anchor")
	await frames(2)
	check(room.checkpoint_index == 1, "First anchor records progress")

func run() -> void:
	change_scene_to_file("res://scenes/levels/DaylightEscape.tscn")
	await frames(75)
	room = current_scene
	global = root.get_node("Global")
	room.transition_on_win = false
	player = room.player
	clock = player.rewind_controller
	player.input_override = true
	clock.input_override = true
	check(global.rewind_unlocked and player.mode == 2, "Escape starts with time unlocked and 2D jumping")
	check(room.crumble_platforms.size() == 3, "Three reversible floors are built")
	check(room.sun_gate.plate_a.collision_mask == 2 and room.sun_gate.gate_body.collision_layer == 1, "Plate detects player layer and sealed gate has blocking collision")
	# A real floor contact and actual held-rewind input, not direct component handlers.
	check(await walk(5.65), "Rewind practice reaches first ledge")
	await jump_to(7.5, 0.6)
	await walk(9.1)
	await jump_to(11.1, 1.2)
	await walk(12.7)
	await jump_to(14.8, 1.8)
	await frames(4)
	check(room.crumble_platforms[0].state != 0, "Physical player contact cracks a floor")
	var before: Vector3 = player.position
	clock.rewind_requested = true
	await frames(65)
	check(global.is_rewinding and player.position.x < before.x, "Holding rewind restores actual player position")
	check(room.crumble_platforms[0].state == 0, "The same rewind restores the contacted floor")
	clock.rewind_requested = false
	await frames(2)
	check(is_instance_valid(clock.active_echo), "Releasing rewind creates an echo")
	var trajectory = clock.active_echo.trajectory
	check(trajectory[0].position.x < trajectory[-1].position.x, "Echo trajectory runs from rewound origin toward discarded future")
	check(clock.energy_seconds < clock.max_energy_seconds, "Rewind consumes physics-time energy")
	room.retry()
	await frames(3)
	check(clock.history.size() < 6 and not is_instance_valid(clock.active_echo), "Retry clears old history and echoes")
	await stair_route()
	# Solve the seals using the actual generated echo and actual Area3D overlaps.
	check(player.request_mode(3), "3D enables movement between depth seals")
	check(await walk(29, -1.45), "Physically stands on seal A")
	await frames(3)
	check(room.sun_gate.a_pressed and not room.sun_gate.b_pressed, "Physical collision activates only occupied seal A")
	check(await walk(33.6, 1.45), "Physically moves from A to seal B")
	await frames(90)
	check(room.sun_gate.b_pressed and not room.sun_gate.is_open, "A single John on B cannot open both seals")
	clock.rewind_requested = true
	await frames(160)
	clock.rewind_requested = false
	await frames(2)
	check(await walk(29, -1.45), "John returns to A while the echo walks toward B")
	for i in 180:
		if room.sun_gate.is_open: break
		await physics_frame
	check(room.sun_gate.is_open, "Real John plus replayed echo opens the Sun Gate")
	await frames(3)
	check(room.sun_gate.gate_body.collision_layer == 0, "Solved gate releases actual blocking collision")
	check(await walk(42, 0), "Walks through solved gate to the next anchor")
	check(room.checkpoint_index == 2, "Echo puzzle permanently commits the second anchor")
	check(player.request_mode(2), "Returns to 2D for the Clockwork Span")
	check(await walk(45.7), "Reaches physical monolith lever")
	player.interacted.emit()
	await frames(90)
	check(room.monolith.has_fallen and absf(room.monolith.current_angle_deg - 90) < 0.1, "F turns the monolith into a horizontal bridge")
	await jump_to(48, 3.0)
	check(await walk(55.6), "Crosses monolith collision and reaches opposite dock")
	await jump_to(57.5, 3.6)
	await walk(59.25)
	await jump_to(61, 3.6)
	check(player.request_mode(3), "Uses 3D depth to line up with rear lift")
	check(await walk(63.6, -2), "Aligns with lift from the depth court")
	check(player.request_mode(2), "Locks the correct depth lane for lift jump")
	for i in 400:
		if fmod(room.lift.elapsed, room.lift.cycle_seconds) > 4.1: break
		await physics_frame
	await jump_to(66.3)
	check(player.position.y > 3.4, "Boards the real moving lift")
	for i in 400:
		if room.lift.position.y + 0.25 >= 5.15: break
		await physics_frame
	check(player.position.y > 4.8, "Lift collision carries John to its high position")
	await walk(68.15, -2)
	await jump_to(70, 5.4)
	await walk(72.6, -2)
	await jump_to(74.5, 5.4)
	player.request_mode(3)
	check(await walk(76, 0), "Reaches final anchor and central depth lane")
	await frames(2)
	check(room.checkpoint_index == 3, "Final ascent checkpoint is safe and reachable")
	player.request_mode(2)
	await walk(78.6)
	await jump_to(80.2, 6.0)
	await walk(82.1)
	await jump_to(84.2, 6.6)
	await walk(86.1)
	await jump_to(88.2, 7.2)
	await walk(90.1)
	await jump_to(92.2, 7.8)
	await walk(94.1)
	await jump_to(96.2, 8.4)
	await walk(98.1)
	await jump_to(100, 8.4)
	check(room.timer_started and room.rising_void.is_active, "Final run activates the rising void")
	check(player.request_mode(1), "Final conduit accepts 1D only on its real rail")
	check(await walk(104.9), "1D body passes through the narrow stone seal")
	check(player.request_mode(2), "Expands safely beyond the seal")
	check(await walk(106.1), "Walks into daylight")
	await frames(3)
	check(room.won and global.chamber_states.chamber_3.escaped, "Full unteleported route completes the escape")
	check(not room.rising_void.is_active and not global.is_rewinding, "Completion stops hazards and rewind")
	print("TIME ROUTE: %d checks passed; four sectors completed using real physics, rewind and echo collisions." % checks)
	quit(0)
