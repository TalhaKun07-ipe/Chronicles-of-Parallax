extends SceneTree

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
	change_scene_to_file("res://chambers/axiom_warden/AxiomWarden.tscn")
	await frames(30)
	var encounter = current_scene
	var p = encounter.player
	p.input_override = true
	encounter.begin_intro()
	encounter.skip_dialogue()
	await frames(95)
	p.armed = true
	p.locked = false
	p.arena_active = true
	p.position = Vector3(7, 0.06, 0)
	await frames(3)
	encounter.state = "opening"
	encounter.core_open = true
	p.request_mode(1)
	check(p.mode == 1 and not encounter.try_strike() and encounter.hits == 0, "An exposed core rejects 1D attacks")
	p.request_mode(3)
	check(p.mode == 3 and not encounter.try_strike() and encounter.hits == 0, "An exposed core rejects 3D attacks")
	p.request_mode(2)
	encounter.hits = 5
	check(encounter.try_strike(), "2D final strike defeats the boss")
	check(root.get_node("Global").rewind_unlocked, "Defeat grants the fourth degree of freedom")
	await frames(240)
	check(current_scene.name == "DaylightEscape", "Actual boss collapse transitions into the playable time chamber")
	var room = current_scene
	check(room.player.rewind_controller != null and room.sun_gate != null, "Escape transition initializes the complete route and time controller")
	check(root.get_node("SceneTransition").color_rect.modulate.a < 0.1, "Escape fades in without a stuck black screen")
	room.complete_escape()
	await frames(170)
	check(current_scene.name == "EndingCutscene", "Completing the escape transitions into the existing illustrated ending")
	check(not root.get_node("Global").is_rewinding, "Ending has no residual rewind state")
	print("TIME PROGRESSION: %d checks passed." % checks)
	quit(0)
