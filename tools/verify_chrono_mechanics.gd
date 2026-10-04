extends SceneTree

var checks: int = 0
var failures: int = 0
var global_node: Node
var sound_node: Node

var ChronoEntityClass
var ChronoPlatformClass
var ChronoMonolithClass
var TemporalEchoClass

func _initialize() -> void:
	call_deferred("run_tests")

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

func run_tests() -> void:
	print("==================================================")
	print("   VERIFYING 4D TIME REWIND CHRONO MECHANICS      ")
	print("==================================================")

	ChronoEntityClass = load("res://scripts/mechanics/ChronoEntity3D.gd")
	ChronoPlatformClass = load("res://scripts/mechanics/ChronoPlatform.gd")
	ChronoMonolithClass = load("res://scripts/mechanics/ChronoMonolith.gd")
	TemporalEchoClass = load("res://scripts/mechanics/TemporalEcho.gd")

	# Ensure Global and SoundManager autoload singletons exist in tree
	global_node = root.get_node_or_null("/root/Global")
	if not global_node:
		var GScript = load("res://scripts/autoload/Global.gd")
		global_node = GScript.new()
		global_node.name = "Global"
		root.add_child(global_node)

	sound_node = root.get_node_or_null("/root/SoundManager")
	if not sound_node:
		var SMScript = load("res://scripts/autoload/SoundManager.gd")
		sound_node = SMScript.new()
		sound_node.name = "SoundManager"
		root.add_child(sound_node)

	# --- 1. SoundManager Rewind SFX Synthesis ---
	check(sound_node != null, "SoundManager autoload is present")
	if sound_node:
		var loop_wav = sound_node.generate_sound("rewind_loop")
		check(loop_wav != null, "generate_sound('rewind_loop') produces valid AudioStreamWAV")
		if loop_wav:
			check(loop_wav.data.size() > 0, "rewind_loop has audio sample data (" + str(loop_wav.data.size()) + " bytes)")

		var echo_wav = sound_node.generate_sound("rewind_echo")
		check(echo_wav != null, "generate_sound('rewind_echo') produces valid AudioStreamWAV")
		if echo_wav:
			check(echo_wav.data.size() > 0, "rewind_echo has audio sample data (" + str(echo_wav.data.size()) + " bytes)")

	# --- 2. ChronoEntity3D Ring Buffer ---
	var entity = ChronoEntityClass.new()
	root.add_child(entity)
	entity.global_position = Vector3(0, 5, 0)
	await frames(5)

	# Move in forward time
	for i in 10:
		entity.global_position.x += 1.0
		await physics_frame

	var final_x = entity.global_position.x
	check(entity.history.size() >= 10, "ChronoEntity3D recorded at least 10 history frames (size: " + str(entity.history.size()) + ")")

	# Start rewind
	global_node.set("is_rewinding", true)
	await frames(5)
	check(entity.global_position.x < final_x, "ChronoEntity3D rewound position backward in time (x: " + str(entity.global_position.x) + " < " + str(final_x) + ")")

	global_node.set("is_rewinding", false)
	entity.queue_free()

	# --- 3. ChronoPlatform Falling & Rewind ---
	var platform = ChronoPlatformClass.new()
	platform.collapse_delay = 0.05
	root.add_child(platform)
	platform.global_position = Vector3(10, 15, 0)
	await frames(2)

	var start_y = platform.global_position.y
	# Trigger cracking
	platform.trigger_collapse()
	check(platform.state == platform.State.CRACKING, "ChronoPlatform entered CRACKING state on contact")

	# Wait for collapse and fall
	await frames(15)
	check(platform.state == platform.State.FALLING, "ChronoPlatform transitioned to FALLING state")
	check(platform.global_position.y < start_y, "ChronoPlatform fell below start height (y: " + str(platform.global_position.y) + " < " + str(start_y) + ")")

	# Rewind platform
	global_node.set("is_rewinding", true)
	var fell_y = platform.global_position.y
	await frames(10)
	check(platform.global_position.y > fell_y, "ChronoPlatform rose back upward during rewind (y: " + str(platform.global_position.y) + " > " + str(fell_y) + ")")

	global_node.set("is_rewinding", false)
	platform.queue_free()

	# --- 4. ChronoMonolith Toppling & Rewind ---
	var monolith = ChronoMonolithClass.new()
	root.add_child(monolith)
	await frames(2)

	check(monolith.current_angle_deg == 0.0, "ChronoMonolith starts completely upright (0 deg)")
	monolith.trigger_topple()
	check(monolith.is_toppling, "ChronoMonolith begins toppling upon trigger")

	await frames(15)
	var toppled_angle = monolith.current_angle_deg
	check(toppled_angle > 5.0, "ChronoMonolith rotated forward while falling (angle: " + str(toppled_angle) + " deg)")

	# Rewind monolith
	global_node.set("is_rewinding", true)
	await frames(10)
	check(monolith.current_angle_deg < toppled_angle, "ChronoMonolith un-toppled backward toward upright during rewind (angle: " + str(monolith.current_angle_deg) + " deg)")

	global_node.set("is_rewinding", false)
	monolith.queue_free()

	# --- 5. TemporalEcho Replay ---
	var echo = TemporalEchoClass.new()
	root.add_child(echo)
	var test_trajectory: Array[Dictionary] = [
		{"position": Vector3(0, 0, 0), "sprite_flip_h": false},
		{"position": Vector3(1, 0, 0), "sprite_flip_h": false},
		{"position": Vector3(2, 0, 0), "sprite_flip_h": true}
	]
	echo.set_trajectory(test_trajectory)
	check(echo.is_in_group("player"), "TemporalEcho is marked in group 'player' to trigger floor runes")
	await frames(2)
	check(echo.global_position.x >= 1.0, "TemporalEcho moved along recorded trajectory (x: " + str(echo.global_position.x) + ")")
	echo.queue_free()

	# --- Test Summary ---
	print("==================================================")
	print("CHRONO MECHANICS RESULTS: ", checks, " checks, ", failures, " failures.")
	print("==================================================")

	if failures > 0:
		quit(1)
	else:
		quit(0)
