extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run() -> void:
	# 1. Load Intro Cutscene
	var intro = load("res://scenes/ui/IntroCutscene.tscn").instantiate()
	root.add_child(intro)
	await frames(10)
	assert(intro != null, "Intro cutscene loaded")
	
	# 2. Trigger skip to game
	intro.skip_to_game()
	await frames(30)
	
	# 3. Verify current scene is Broken Circuit demo
	var current = root.get_child(root.get_child_count() - 1)
	assert(current.name == "BrokenCircuitDemo" or current.has_node("Chamber"), "Transitioned to Broken Circuit Chamber")
	
	# 4. Verify dialogue box exists in the chamber
	var dbox = current.get_node_or_null("UndertaleDialogueBox")
	assert(dbox != null, "Dialogue box is present in Chamber")
	
	print("FULL FLOW VALIDATED: IntroCutscene -> Chamber 1 with Undertale Dialogue!")
	quit(0)
