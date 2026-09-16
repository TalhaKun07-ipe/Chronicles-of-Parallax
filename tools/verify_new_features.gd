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
	
	# 1. Dialogue box is present and operational
	var dialogue_box = demo.get_node_or_null("UndertaleDialogueBox")
	check(dialogue_box != null, "UndertaleDialogueBox exists in scene")
	dialogue_box.start_dialogue()
	await frames(5)
	check(dialogue_box.is_active, "Dialogue is active")
	check(dialogue_box.portrait_rect.texture != null, "Dazed portrait loaded")
	
	# Fast-forward all dialogue lines
	for i in 4:
		dialogue_box._advance()
		await frames(3)
		dialogue_box._advance()
		await frames(3)
	await frames(30)
	check(not dialogue_box.is_active, "Dialogue closed successfully")
	check(not player.input_override, "Player input unlocked after conversation")
	
	# 2. Verify Simplified Clean HUD (No top brown bar, no status/title, no map button)
	var hud = demo.get_node_or_null("CleanHUD")
	check(hud != null, "CleanHUD CanvasLayer exists")
	check(demo.get_node_or_null("CleanHUD/TopPanel") == null, "Top brown bar removed")
	check(demo.get_node_or_null("CleanHUD/Title") == null, "Chamber title removed from HUD")
	check(demo.get_node_or_null("CleanHUD/MapButton") == null, "Full Map button removed")
	check(demo.get_node_or_null("CleanHUD/BotPanel") == null, "Bottom brown strip removed")
	
	# 3. Floating Health Hearts
	check(demo.heart_icons.size() == 3, "Floating HUD has 3 heart icons in top-left")
	check(demo.heart_icons[0].texture == demo.heart_full_tex, "First heart full")
	
	# 4. Large Gameplay Subtitles
	var subtitle = demo.get_node_or_null("CleanHUD/SubtitleLabel")
	check(subtitle != null, "Large Gameplay SubtitleLabel exists")
	check(subtitle.get_theme_font_size("font_size") >= 28, "Subtitle font size is large (>= 28px)")
	check(subtitle.get_theme_constant("outline_size") >= 5, "Subtitle has strong outline")
	
	check(subtitle.text.length() > 0, "Subtitle text displayed from queue")
	check(subtitle.modulate.a > 0.0, "Subtitle fades in")
	
	# 5. Contextual Controls Label (No brown bar, accurate per dimension)
	var controls = demo.get_node_or_null("CleanHUD/ControlsLabel")
	check(controls != null, "Contextual ControlsLabel exists")
	check(controls.get_theme_font_size("font_size") >= 22, "Controls font size is legible (>= 22px)")
	
	# In 3D: must NOT show SPACE Jump
	player.request_mode(3)
	await frames(3)
	check(not controls.text.contains("SPACE Jump"), "3D controls do NOT advertise SPACE Jump")
	check(controls.text.contains("Depth"), "3D controls describe depth movement")
	
	# In 2D: must show SPACE Jump
	player.request_mode(2)
	await frames(3)
	check(controls.text.contains("SPACE Jump"), "2D controls accurately display SPACE Jump")
	
	# In 1D: must NOT show SPACE Jump
	player.position = chamber.get_node("Markers/Rail1Start").position
	check(player.request_mode(1), "Switches to 1D on rail")
	await frames(2)
	check(not controls.text.contains("SPACE Jump"), "1D controls do NOT advertise SPACE Jump")
	check(controls.text.contains("Slide Along Conduit"), "1D controls describe rail sliding")
	
	# 6. Camera Tracking (Close scale, forward look-ahead)
	player.request_mode(2)
	await frames(5)
	demo._update_camera(1.0)
	check(demo.camera.size <= 5.8, "Camera scale is close and readable (<= 5.8)")
	check(demo.focus.x > player.position.x, "Camera focus has forward look-ahead along X axis")
	
	print("\nALL NEW FEATURES VERIFIED SUCCESSFULLY (%d checks)!" % checks)
	quit(0)
