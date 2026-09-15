extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	
	for i in 15:
		await physics_frame
		
	# Dismiss dialogue box
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.close_dialogue()
		
	for i in 10:
		await physics_frame
		
	# 1. Capture Spawn view with 3 Red Pixel Hearts in top-left corner
	var img1 = root.get_viewport().get_texture().get_image()
	if img1:
		img1.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/706e0fab-7b17-44ef-bb64-c76d56428859/showcase_hearts_topleft.png")
		print("Saved showcase_hearts_topleft.png")
		
	# 2. Move player to Terrace 1 area to show permanent 3D terrace visibility
	demo.player.position = Vector3(14.0, 0.08, -3.5)
	for i in 25:
		await physics_frame
	var img2 = root.get_viewport().get_texture().get_image()
	if img2:
		img2.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/706e0fab-7b17-44ef-bb64-c76d56428859/showcase_terrace_visible_3d.png")
		print("Saved showcase_terrace_visible_3d.png")
		
	# 3. Move player to Guardian Arena in 3D to show Flat Guardian chasing
	demo.player.position = Vector3(28.5, 0.88, 0.0)
	for i in 35:
		await physics_frame
	var img3 = root.get_viewport().get_texture().get_image()
	if img3:
		img3.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/706e0fab-7b17-44ef-bb64-c76d56428859/showcase_guardian_chasing.png")
		print("Saved showcase_guardian_chasing.png")
		
	# 4. Switch to 2D in Guardian Arena to show Flat Guardian ethereal slip-through
	demo.player.request_mode(2)
	for i in 25:
		await physics_frame
	var img4 = root.get_viewport().get_texture().get_image()
	if img4:
		img4.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/706e0fab-7b17-44ef-bb64-c76d56428859/showcase_guardian_2d_phase.png")
		print("Saved showcase_guardian_2d_phase.png")
		
	# 5. Full Map view of the complete course
	demo.overview = true
	for i in 60:
		await physics_frame
	var img5 = root.get_viewport().get_texture().get_image()
	if img5:
		img5.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/706e0fab-7b17-44ef-bb64-c76d56428859/showcase_full_course.png")
		print("Saved showcase_full_course.png")
		
	quit(0)
