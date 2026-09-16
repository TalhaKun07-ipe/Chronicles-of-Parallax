extends SceneTree

var out_dir: String = "C:/Users/USER/.gemini/antigravity-ide/brain/6b82e086-38f1-481a-abb8-cd64ea27d565/"

func _initialize() -> void:
	call_deferred("run")

func set_mode_force(demo: Node3D, target_mode: int, z: float) -> void:
	var p = demo.player
	p.mode = target_mode
	p.active_rail = {}
	p.plane_z = z
	p.position.z = z
	p.velocity = Vector3.ZERO
	if target_mode == 1:
		p.active_rail = demo.chamber.rail_near(p.position)
		p.shape_node.shape = p.rod
		p.shape_node.position.y = 0
		p.sprite.position.y = 0
	else:
		p.shape_node.shape = p.humanoid
		p.shape_node.position.y = 0.575
		p.sprite.position.y = 0.576
	p._update_sprite()
	demo._update_controls_label(target_mode)
	demo.chamber.set_spatial_mode(target_mode)
	demo.chamber.update_occlusion(z)

func set_subtitle(demo: Node3D, text: String) -> void:
	demo.subtitle_queue.clear()
	demo.subtitle_label.text = text
	demo.subtitle_label.modulate.a = 1.0
	demo.current_subtitle_time = 10.0

func run() -> void:
	var demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	
	for i in 15:
		await physics_frame
		
	if demo.dialogue_box and is_instance_valid(demo.dialogue_box):
		demo.dialogue_box.queue_free()
		demo.dialogue_box = null
	demo.player.input_override = false
	
	# 1. Section A: Arrival (3D)
	demo.player.position = Vector3(-14.0, 0.08, 0.0)
	set_mode_force(demo, 3, 0.0)
	set_subtitle(demo, "Three dimensions. Three ways forward.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_a_arrival_3d.png")
	
	# 2. Section B: The Broken Stair (2D)
	demo.player.position = Vector3(-1.7, 1.68, 0.0)
	set_mode_force(demo, 2, 0.0)
	set_subtitle(demo, "Switch to 2D [2]. Press SPACE to jump.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_b_broken_stair_2d.png")
	
	# 3. Section C: The Offset Passage (3D)
	demo.player.position = Vector3(14.0, 2.48, -4.0)
	set_mode_force(demo, 3, -4.0)
	set_subtitle(demo, "The path continues at another depth. Return to 3D [3].")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_c_offset_passage_3d.png")
	
	# 4. Section D: The Narrow Conduit (1D)
	demo.player.position = Vector3(21.0, 2.58, -4.0)
	set_mode_force(demo, 1, -4.0)
	set_subtitle(demo, "Too narrow? Become a line [1].")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_d_narrow_conduit_1d.png")
	
	# 5. Section E: The Fractured Gallery (2D)
	demo.player.position = Vector3(36.0, 3.28, -4.0)
	set_mode_force(demo, 2, -4.0)
	set_subtitle(demo, "Time your jumps across the moving terrace.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_e_fractured_gallery_2d.png")
	
	# 6. Section F: The Relay Court (3D)
	demo.player.position = Vector3(56.0, 3.08, 0.0)
	set_mode_force(demo, 3, 0.0)
	set_subtitle(demo, "The circuit answers. A new path opens.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_f_relay_court_3d.png")
	
	# 7. Section G: The Interwoven Ascent (3D Transversal Walkway)
	demo.player.position = Vector3(71.0, 4.28, 0.0)
	set_mode_force(demo, 3, 0.0)
	set_subtitle(demo, "Combine all three dimensions to ascend.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_g_interwoven_ascent_3d.png")
	
	# 8. Section H: Guardian Hall & Exit Portal Archway (3D)
	demo.player.position = Vector3(95.0, 5.88, 0.0)
	set_mode_force(demo, 3, 0.0)
	set_subtitle(demo, "Flat Guardian ahead. In 2D, you can slip right through it.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_section_h_guardian_exit_3d.png")
	
	print("ALL 8 SECTION SHOWCASE SCREENSHOTS CAPTURED WITH EXACT CONTEXT!")
	quit(0)

func _save_screen(filename: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img:
		var path = out_dir + filename
		img.save_png(path)
		print("Saved: ", path)
