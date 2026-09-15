extends SceneTree

var demo: Node3D
var player: CharacterBody3D
var chamber: Node3D
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: " + description)
		quit(1)
		assert(ok, description)
	checks += 1
	print("PASS: " + description)

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run() -> void:
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player = demo.get_node("Player")
	chamber = demo.get_node("Chamber")
	
	await frames(10)
	
	# Check 1: Dialogue box is present
	var dialogue_box = demo.get_node_or_null("UndertaleDialogueBox")
	check(dialogue_box != null, "UndertaleDialogueBox exists in scene")
	
	# Check 2: Start dialogue and verify player is locked
	dialogue_box.start_dialogue()
	await frames(5)
	check(dialogue_box.is_active, "Dialogue is active")
	check(dialogue_box.current_line_idx == 0, "Line 0 (Waking) starts")
	check(dialogue_box.portrait_rect.texture != null, "Dazed portrait loaded")
	
	# Check 3: Fast-forward line 0
	dialogue_box._advance()
	await frames(2)
	check(not dialogue_box.is_typing, "Line 0 fast-forwarded to completion")
	check(dialogue_box.arrow_indicator.visible, "Advance prompt indicator visible")
	
	# Advance to Line 1 (Watch)
	dialogue_box._advance()
	await frames(2)
	check(dialogue_box.current_line_idx == 1, "Line 1 (Watch) active")
	check(dialogue_box.full_text.contains("still glowing"), "Watch dialogue text confirmed")
	
	# Fast-forward Line 1
	dialogue_box._advance()
	await frames(2)
	check(not dialogue_box.is_typing, "Line 1 fast-forwarded")
	
	# Advance to Line 2 (Revelation)
	dialogue_box._advance()
	await frames(2)
	check(dialogue_box.current_line_idx == 2, "Line 2 (Revelation - line/plane/body) active")
	check(dialogue_box.full_text.contains("A line"), "Revelation text confirmed")
	
	# Fast-forward Line 2
	dialogue_box._advance()
	await frames(2)
	
	# Advance to Line 3 (Determined)
	dialogue_box._advance()
	await frames(2)
	check(dialogue_box.current_line_idx == 3, "Line 3 (Determined - long way up) active")
	check(dialogue_box.full_text.contains("long way up"), "Determined text confirmed")
	
	# Fast-forward Line 3
	dialogue_box._advance()
	await frames(2)
	
	# Finish and close dialogue
	dialogue_box._advance()
	await frames(25)
	check(not dialogue_box.is_active, "Dialogue closed successfully")
	check(not player.input_override, "Player input unlocked after conversation")
	
	# Check 7: Test Map button / Overview mode
	check(not demo.overview, "Initially not in overview")
	demo._toggle_overview()
	await frames(5)
	check(demo.overview, "Map toggle activates overview")
	check(demo.camera.size > 10.0, "Camera size zoomed out for full map")
	
	# Check 8: Player movement triggers AUTO-RESET of overview to default view
	player.input_override = true
	player.move_input = Vector2.RIGHT
	await frames(2)
	demo._process(0.016)
	check(not demo.overview, "Player movement auto-resets full map to close view")
	
	player.move_input = Vector2.ZERO
	player.input_override = false
	await frames(30)
	check(demo.camera.size < 6.0, "Camera smoothly returns to tight 5.2 gameplay view")
	
	print("\nALL NEW FEATURES VERIFIED SUCCESSFULLY (%d checks)!" % checks)
	quit(0)
