extends SceneTree

var checks: int = 0
var failures: int = 0
var global_node: Node

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
	print("   VERIFYING CHAMBER 3 (DAYLIGHT ESCAPE) MECHANICS")
	print("==================================================")

	var EscapeControllerClass = load("res://scripts/mechanics/escape_controller.gd")
	var RisingVoidClass = load("res://scripts/mechanics/rising_void.gd")
	var SunGateClass = load("res://scripts/mechanics/sun_gate.gd")
	var ChronoPostProcessClass = load("res://scripts/mechanics/chrono_post_process.gd")
	var TemporalEchoClass = load("res://scripts/mechanics/TemporalEcho.gd")

	global_node = root.get_node_or_null("/root/Global")
	if not global_node:
		var GScript = load("res://scripts/autoload/Global.gd")
		global_node = GScript.new()
		global_node.name = "Global"
		root.add_child(global_node)

	# --- 1. Rising Void Pauses on Rewind ---
	var void_hazard = RisingVoidClass.new()
	void_hazard.rise_speed = 10.0 # Fast for testing
	root.add_child(void_hazard)
	void_hazard.global_position = Vector3(0, 0, 0)

	await frames(10)
	var y1 = void_hazard.global_position.y
	check(y1 > 0.0, "RisingVoid moves upward during normal time (y: " + str(y1) + ")")

	global_node.set("is_rewinding", true)
	await frames(10)
	var y2 = void_hazard.global_position.y
	check(abs(y2 - y1) < 0.01, "RisingVoid pauses while rewinding (y1: " + str(y1) + ", y2: " + str(y2) + ")")

	global_node.set("is_rewinding", false)
	void_hazard.queue_free()

	# --- 2. Sun Gate Dual Pressure Puzzle ---
	var sun_gate = SunGateClass.new()
	var plate_a = Area3D.new()
	var plate_b = Area3D.new()
	sun_gate.plate_a = plate_a
	sun_gate.plate_b = plate_b
	root.add_child(sun_gate)

	check(sun_gate.is_open == false, "SunGate starts closed")

	var player_mock = Node3D.new()
	player_mock.add_to_group("player")
	var echo_mock = Node3D.new()
	echo_mock.add_to_group("player")

	sun_gate._on_plate_a_entered(echo_mock)
	check(sun_gate.a_pressed == true, "SunGate detects TemporalEcho on Plate A")

	sun_gate._on_plate_b_entered(player_mock)
	check(sun_gate.b_pressed == true, "SunGate detects Player on Plate B")

	await frames(2) # Allow _process to open gate
	check(sun_gate.is_open == true, "SunGate opens when both plates are pressed")

	sun_gate.queue_free()
	player_mock.queue_free()
	echo_mock.queue_free()

	# --- 3. Escape Controller Win Condition ---
	var controller = EscapeControllerClass.new()
	var player = Node3D.new()
	var cam = Camera3D.new()
	controller.player = player
	controller.camera = cam
	controller.win_y_threshold = 50.0

	root.add_child(player)
	root.add_child(cam)
	root.add_child(controller)

	player.global_position.y = 10.0
	await frames(5)
	check(controller.chamber_won == false, "EscapeController chamber not won at y=10")

	player.global_position.y = 51.0
	await frames(2)
	check(controller.chamber_won == true, "EscapeController detects win when player passes threshold")

	controller.queue_free()
	player.queue_free()
	cam.queue_free()

	print("==================================================")
	print("CHAMBER 3 MECHANICS RESULTS: ", checks, " checks, ", failures, " failures.")
	print("==================================================")

	if failures > 0:
		quit(1)
	else:
		quit(0)
