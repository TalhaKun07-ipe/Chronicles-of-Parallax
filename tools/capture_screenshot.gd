extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	
	for i in 15:
		await physics_frame
		
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.close_dialogue()
		
	for i in 5:
		await physics_frame
		
	# Toggle full map overview
	demo.overview = true
	
	# Let camera smoothly lerp to overview framing
	for i in 60:
		await physics_frame
		
	var img = root.get_viewport().get_texture().get_image()
	if img:
		print("Captured overview image size: ", img.get_size())
		img.save_png("res://test_overview_render.png")
		print("Saved test_overview_render.png successfully!")
	quit(0)
