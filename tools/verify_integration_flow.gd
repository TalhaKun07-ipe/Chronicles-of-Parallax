extends SceneTree
## Verifies the integration transition from IntroCutscene into Chamber 01 Demo

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	print("--- Starting Integration Flow Test ---")
	
	# 1. Load and instantiate IntroCutscene
	var intro_scene_resource = load("res://scenes/ui/IntroCutscene.tscn")
	assert(intro_scene_resource != null, "IntroCutscene.tscn must exist")
	var intro = intro_scene_resource.instantiate()
	root.add_child(intro)
	print("PASS: IntroCutscene instantiated successfully")
	
	# Wait 5 frames
	for i in 5:
		await process_frame
		
	# 2. Trigger skip_to_game
	print("Triggering skip_to_game()...")
	intro.skip_to_game()
	
	# Wait 0.5s for tween and scene change
	var timer := create_timer(0.5)
	await timer.timeout
	
	for i in 10:
		await process_frame
		
	var active_scene = current_scene
	if active_scene == null and root.get_child_count() > 0:
		active_scene = root.get_child(root.get_child_count() - 1)
		
	print("Current root child: ", active_scene.name)
	assert(active_scene.name == "BrokenCircuitDemo" or active_scene.scene_file_path.ends_with("Demo.tscn"), "Must have transitioned to BrokenCircuitDemo")
	print("PASS: Successfully transitioned to Chamber 01 (Demo.tscn)")
	
	var player = active_scene.get_node_or_null("Player")
	var chamber = active_scene.get_node_or_null("Chamber")
	var camera = active_scene.get_node_or_null("Camera3D")
	var hud = active_scene.get_node_or_null("HUD")
	
	assert(player != null, "Player node must exist in Demo")
	assert(chamber != null, "Chamber node must exist in Demo")
	assert(camera != null, "Camera3D must exist in Demo")
	assert(hud != null, "HUD CanvasLayer must exist in Demo")
	
	print("PASS: All essential nodes (Player, Chamber, Camera3D, HUD) verified in Chamber 01")
	print("--- Integration Flow Test PASSED ---")
	quit(0)
