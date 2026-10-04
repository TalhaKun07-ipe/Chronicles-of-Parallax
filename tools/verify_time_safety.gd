extends SceneTree

var room
var player
var clock
var global: Node
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		push_error("FAIL: " + description)
		quit(1)
		assert(ok, description)
	print("PASS: ", description)

func frames(n: int) -> void:
	for i in n: await physics_frame

func run() -> void:
	change_scene_to_file("res://scenes/levels/DaylightEscape.tscn")
	await frames(300)
	room = current_scene
	room.transition_on_win = false
	player = room.player
	clock = player.rewind_controller
	global = root.get_node("Global")
	player.input_override = true
	clock.input_override = true
	check(clock.history.size() == clock.MAX_HISTORY, "History stays bounded after waiting longer than four seconds")
	clock.rewind_requested = true
	await frames(310)
	check(not global.is_rewinding and not clock.is_rewinding and clock.must_release, "Exhaustion stops player and world together until R is released")
	await frames(200)
	check(not global.is_rewinding, "Holding R after exhaustion cannot automatically restart rewind")
	clock.rewind_requested = false
	await frames(3)
	check(not clock.must_release, "Releasing R rearms the ability")
	room.retry()
	await frames(3)
	check(not is_instance_valid(clock.active_echo) and clock.energy_seconds == clock.max_energy_seconds, "Retry cleans echoes and fully refills energy")
	# Different simulated deltas consume the same duration of energy.
	clock.set_physics_process(false)
	for delta in [1.0 / 30.0, 1.0 / 120.0]:
		clock.reset_timeline()
		clock.rewind_requested = false
		for i in 240: clock.record_state()
		clock.energy_seconds = 4.0
		clock.must_release = false
		clock.rewind_requested = true
		var ticks: int = roundi(1.0 / delta)
		for i in ticks: clock._physics_process(delta)
		check(absf(clock.energy_seconds - 3.0) < 0.001, "One second of rewind costs one second of energy at %.0f Hz" % (1.0 / delta))
		clock.stop_rewind(false)
	clock.rewind_requested = false
	clock.reset_timeline()
	clock.set_physics_process(true)
	# Snapshot dimensions and depth must return with the position.
	player.reset_at(Vector3(30, 2.45, -1.4))
	await frames(3)
	player.request_mode(3)
	var snapshot: Dictionary = player.capture_time_state()
	player.position.z = 1.4
	player.request_mode(2)
	player.restore_time_state(snapshot)
	check(player.mode == 3 and absf(player.position.z + 1.4) < 0.01, "Restoring a snapshot restores volume mode and depth")
	check(global.active_dimension == 4, "Local volume mode maps to the correct global enum")
	# Multiple occupants cannot release a seal while another body remains.
	var first := CharacterBody3D.new()
	var second := CharacterBody3D.new()
	root.add_child(first)
	root.add_child(second)
	first.add_to_group("player")
	second.add_to_group("player")
	room.sun_gate._on_plate_a_entered(first)
	room.sun_gate._on_plate_a_entered(second)
	room.sun_gate._on_plate_a_exited(first)
	check(room.sun_gate.a_pressed, "A seal remains occupied after only one of two bodies leaves")
	room.sun_gate._on_plate_a_exited(second)
	first.queue_free()
	second.queue_free()
	# Real physical void contact invokes death and respawns at an established anchor.
	room.set_checkpoint(3)
	room.monolith.trigger_topple()
	room.crumble_platforms[0].trigger_collapse()
	await frames(50)
	player.reset_at(Vector3(76, 5.45, 0))
	room.timer_started = true
	room.rising_void.is_active = true
	room.rising_void.position = Vector3(76, 5.7, 0)
	await frames(6)
	check(player.position.distance_to(room.ANCHORS[3]) < 0.25 and not room.rising_void.is_active, "Actual void collision respawns at the last time anchor")
	check(room.crumble_platforms[0].state == 0 and room.monolith.current_angle_deg == 0, "Death restores all mechanisms to a safe initial state")
	check(not global.is_rewinding and not player.locked, "Respawn leaves controls and world clock usable")
	await frames(60)
	var before: float = room.lift.elapsed
	clock.rewind_requested = true
	await frames(25)
	check(room.lift.elapsed < before, "Moving lift restores its phase under the same held-rewind input")
	var rewind_position: Vector3 = player.position
	var energy: float = clock.energy_seconds
	room.toggle_pause()
	await frames(20)
	check(player.position == rewind_position and clock.energy_seconds == energy, "Pausing freezes rewind and movement without consuming energy")
	room.toggle_pause()
	clock.rewind_requested = false
	await frames(3)
	check(not clock.is_rewinding and not global.is_rewinding, "Rewind can safely finish after resuming")
	room.retry()
	await frames(3)
	check(clock.history.size() < 7 and room.checkpoint_index == 3, "Retry preserves the anchor while removing future history")
	print("TIME SAFETY: %d checks passed." % checks)
	quit(0)
