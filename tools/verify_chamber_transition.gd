extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func run() -> void:
	print("--- TESTING CHAMBER 1 -> CHAMBER 2 (AXIOM WARDEN) TRANSITION ---")
	
	# Load Broken Circuit Demo
	var demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	await frames(10)
	assert(demo != null, "BrokenCircuitDemo instantiated")
	
	var chamber = demo.get_node("Chamber")
	assert(chamber != null, "Chamber node exists")
	
	# Power chamber and trigger exit
	chamber.powered = true
	var exit_pos: Vector3 = chamber.get_node("Markers/Exit").position
	print("Triggering exit at marker: ", exit_pos)
	var exited: bool = chamber.try_exit(exit_pos)
	assert(exited, "Exit triggered successfully")
	
	# Wait for transition (1.2s delay + 0.35s fade + frame waits)
	print("Waiting for SceneTransition to load Axiom Warden...")
	for i in 180:
		await physics_frame
		var current = root.get_child(root.get_child_count() - 1)
		if current.name == "AxiomWardenChamber" or current.get_script().resource_path.ends_with("encounter.gd"):
			print("SUCCESS: Transitioned to Axiom Warden Chamber!")
			break
			
	var active_scene = root.get_child(root.get_child_count() - 1)
	assert(active_scene.name == "AxiomWardenChamber" or active_scene.get_script().resource_path.ends_with("encounter.gd"), "Active scene is Axiom Warden")
	
	var st = root.get_node_or_null("SceneTransition")
	if st and st.color_rect:
		await frames(40) # allow fade in to finish
		assert(st.color_rect.modulate.a <= 0.1, "Screen is visible (not black screen)")
		print("CONFIRMED: Fade in finished, screen opacity is transparent (a=%.2f)" % st.color_rect.modulate.a)
		
	print("CHAMBER 1 -> AXIOM WARDEN TRANSITION 100% VALIDATED!")
	quit(0)
