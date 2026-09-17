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
	if target_mode == 0:
		p.shape_node.shape = p.humanoid
		p.shape_node.position.y = 0.2
		p.sprite.position.y = 0.2
		p.sprite.scale = Vector3(0.35, 0.35, 0.35)
	elif target_mode == 1:
		p.active_rail = demo.chamber.rail_near(p.position)
		p.shape_node.shape = p.rod
		p.shape_node.position.y = 0
		p.sprite.position.y = 0
		p.sprite.scale = Vector3.ONE
	else:
		p.shape_node.shape = p.humanoid
		p.shape_node.position.y = 0.575
		p.sprite.position.y = 0.576
		p.sprite.scale = Vector3.ONE
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
	
	# 1. Sealed 1D Containment Alcove & Ancient Relay Terminal (Section F)
	demo.player.position = Vector3(51.5, 3.08, 1.8)
	set_mode_force(demo, 3, 1.8)
	set_subtitle(demo, "The ancient relay is dormant. Awaken it [0 / F] to energize the conduit.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_sealed_energy_alcove_1d.png")
	
	# 2. Deep Chasm & Submerged Bridge before activation
	demo.player.position = Vector3(59.0, 3.08, -3.5)
	set_mode_force(demo, 3, -3.5)
	set_subtitle(demo, "A 6-meter chasm blocks the way. Deposit the Energy Charge to reconstruct the bridge.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_submerged_bridge_chasm.png")
	
	# 3. Reconstruct bridge and capture activated bridge
	demo.chamber.carrying_charge = true
	demo.chamber.try_interact(demo.player.position)
	for i in 100: await physics_frame
	demo.player.position = Vector3(65.0, 3.68, -3.5)
	set_mode_force(demo, 2, -3.5)
	set_subtitle(demo, "Ancient mechanisms align. The Runic Bridge has reconstructed!")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_bridge_reconstructed.png")
	
	# 4. Enclosed Exit Vestibule (No void gap behind portal)
	demo.player.position = Vector3(104.5, 5.88, 0.0)
	set_mode_force(demo, 3, 0.0)
	set_subtitle(demo, "Stepping through the portal into the sealed transition vestibule.")
	demo._update_camera(1.0)
	for i in 20: await physics_frame
	_save_screen("chamber1_sealed_exit_vestibule.png")
	
	print("ALL BRIDGE PUZZLE & EXIT VESTIBULE SHOWCASE SCREENSHOTS CAPTURED!")
	quit(0)

func _save_screen(filename: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img:
		var path = out_dir + filename
		img.save_png(path)
		print("Saved: ", path)
