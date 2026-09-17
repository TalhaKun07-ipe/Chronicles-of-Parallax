extends Node3D
## Chamber 1 (The Broken Circuit) - Redesigned 8-Section Master Controller
## Features: Clean floating HUD, readable gameplay subtitles, contextual controls,
## continuous camera lookahead tracking, checkpoint recovery, and seamless transition to Chamber 2.

var yaw: float = -45.0
var pitch: float = -30.0
var focus: Vector3 = Vector3(-15.0, 1.0, 0)
var dialogue_box: CanvasLayer

# Subtitle presentation system
var subtitle_label: Label
var subtitle_queue: Array[Dictionary] = [] # Array of {"text": String, "duration": float}
var current_subtitle_time: float = 0.0
var current_subtitle_duration: float = 3.5
var shown_milestones: Dictionary = {}

# Floating HUD elements
var controls_label: Label
var heart_icons: Array[TextureRect] = []
var heart_full_tex: Texture2D = preload("res://assets/ui/heart_full.png")
var heart_empty_tex: Texture2D = preload("res://assets/ui/heart_empty.png")

# Checkpoint system
var latest_checkpoint: Vector3 = Vector3(-15.0, 0.08, 0.0)
var latest_checkpoint_mode: int = 3

@onready var player: CharacterBody3D = $Player
@onready var chamber: Node3D = $Chamber
@onready var camera: Camera3D = $Camera3D
var guardian: Node3D = null
var pp_rect: ColorRect = null

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0e0b08")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dfcaa0")
	env.ambient_light_energy = 0.35
	
	# SSAO for deep crevices and contact shadows
	env.ssao_enabled = true
	env.ssao_radius = 1.4
	env.ssao_intensity = 2.8
	env.ssao_power = 1.4
	env.ssao_detail = 0.5
	
	# Volumetric Fog & Atmospheric God Rays
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.014
	env.volumetric_fog_albedo = Color("eedbb2")
	env.volumetric_fog_emission = Color("1a120b")
	env.volumetric_fog_emission_energy = 0.15
	env.volumetric_fog_anisotropy = 0.3
	
	# High-Dynamic-Range Glow
	env.glow_enabled = true
	env.glow_intensity = 0.65
	env.glow_bloom = 0.18
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.glow_hdr_threshold = 1.0
	
	# Filmic Tonemapping & Color Grading
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.12
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.12

	world.environment = env

	# Far Depth of Field - softens distant architecture for atmospheric depth
	# (Ori-style foreground/background separation). Kept subtle and far-only so
	# nearby platforms, hazards and rails stay perfectly readable. DOF moved off
	# Environment and onto CameraAttributes as of Godot 4.3.
	# Camera sits a fixed 28 units from its focus point (see _update_camera's `dist`),
	# so the blur threshold must start noticeably past that or the whole frame blurs.
	var cam_attrs := CameraAttributesPractical.new()
	cam_attrs.dof_blur_far_enabled = true
	cam_attrs.dof_blur_far_distance = 34.0
	cam_attrs.dof_blur_far_transition = 14.0
	cam_attrs.dof_blur_amount = 0.05
	world.camera_attributes = cam_attrs

	add_child(world)
	
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 1.2
	sun.light_volumetric_fog_energy = 1.8
	sun.shadow_enabled = true
	sun.shadow_blur = 1.2
	sun.directional_shadow_max_distance = 80
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.015
	sun.shadow_normal_bias = 1.0
	add_child(sun)
	
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(45, 150, 0)
	fill.light_color = Color("8c7b64")
	fill.light_energy = 0.35
	add_child(fill)
	
	# Atmospheric architectural lamps spaced along the 8 sections
	var lamp_positions: Array[Vector3] = [
		Vector3(-14, 2.4, 0),
		Vector3(-2.0, 3.2, 0),
		Vector3(12.0, 4.5, -3.5),
		Vector3(22.0, 4.5, -4.0),
		Vector3(36.0, 5.0, -4.0),
		Vector3(55.0, 5.0, 0.0),
		Vector3(64.0, 5.2, -3.5),
		Vector3(76.0, 6.5, 2.5),
		Vector3(95.0, 7.5, 0.0),
		Vector3(102.5, 8.0, 0.0)
	]
	var flicker_rng := RandomNumberGenerator.new()
	flicker_rng.randomize()
	for pos in lamp_positions:
		var lamp := OmniLight3D.new()
		lamp.position = pos
		lamp.light_color = Color("ffa142") # Warm ancient lantern amber
		lamp.light_energy = 1.45
		lamp.light_volumetric_fog_energy = 1.35
		lamp.omni_range = 8.5
		lamp.omni_attenuation = 1.4
		add_child(lamp)
		# Living flame flicker instead of a static glow, randomized per-lamp so they don't
		# pulse in obvious unison.
		var lamp_tween := lamp.create_tween()
		lamp_tween.set_loops()
		for i in 8:
			lamp_tween.tween_property(lamp, "light_energy", 1.45 * flicker_rng.randf_range(0.72, 1.25), flicker_rng.randf_range(0.06, 0.16))

	# Stylized Volumetric God Rays streaming through ancient ceiling fissures
	var ray_shader = load("res://shaders/god_ray.gdshader")
	if ray_shader:
		var ray_mat := ShaderMaterial.new()
		ray_mat.shader = ray_shader
		var ray_positions: Array[Vector3] = [
			Vector3(-12.0, 5.5, 0.0),
			Vector3(0.0, 6.2, 0.0),
			Vector3(18.0, 7.0, -3.5),
			Vector3(34.0, 7.5, -4.0),
			Vector3(56.0, 7.8, 0.0),
			Vector3(74.0, 8.5, 1.5),
			Vector3(96.0, 9.5, 0.0)
		]
		for rpos in ray_positions:
			var ray_mesh := MeshInstance3D.new()
			var quad := QuadMesh.new()
			quad.size = Vector2(4.2, 10.5)
			ray_mesh.mesh = quad
			ray_mesh.material_override = ray_mat
			ray_mesh.position = rpos
			ray_mesh.rotation_degrees = Vector3(12.0, 18.0, -32.0)
			add_child(ray_mesh)
			
	# Floating Light Dust & Amber Ember Motes (GPUParticles3D)
	var particles := GPUParticles3D.new()
	particles.amount = 80
	particles.lifetime = 6.0
	particles.preprocess = 3.0
	var p_mat := ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p_mat.emission_box_extents = Vector3(60.0, 4.5, 8.0)
	p_mat.direction = Vector3(0.2, 1.0, 0.1)
	p_mat.spread = 25.0
	p_mat.initial_velocity_min = 0.25
	p_mat.initial_velocity_max = 0.65
	p_mat.gravity = Vector3(0.0, 0.05, 0.0)
	p_mat.scale_min = 0.03
	p_mat.scale_max = 0.08
	p_mat.color = Color("ffebba")
	particles.process_material = p_mat
	
	var quad_mesh := QuadMesh.new()
	quad_mesh.size = Vector2(0.08, 0.08)
	var quad_mat := StandardMaterial3D.new()
	quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mat.albedo_color = Color("ffe099")
	quad_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad_mesh.material = quad_mat
	particles.draw_pass_1 = quad_mesh
	
	particles.position = Vector3(45.0, 3.5, -1.0)
	add_child(particles)
		
	# Screen-space post-processing overlay (vignette, chromatic aberration, film grain)
	var pp_canvas := CanvasLayer.new()
	pp_canvas.layer = 50
	pp_rect = ColorRect.new()
	pp_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pp_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pp_mat := ShaderMaterial.new()
	var pp_shader = load("res://shaders/post_process.gdshader")
	if pp_shader:
		pp_mat.shader = pp_shader
		pp_rect.material = pp_mat
	pp_canvas.add_child(pp_rect)
	add_child(pp_canvas)
		
	# Global & SceneTransition integration
	var global = get_node_or_null("/root/Global")
	if global:
		if "current_chamber_id" in global:
			global.current_chamber_id = "broken_circuit"
		if global.has_method("unlock_dimension") and "Dimension" in global:
			global.unlock_dimension(global.Dimension.DIM_1D)
			global.unlock_dimension(global.Dimension.DIM_2D)
			global.unlock_dimension(global.Dimension.DIM_3D)
			global.active_dimension = global.Dimension.DIM_3D
			
	var transition = get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("fade_in_from_black"):
		transition.fade_in_from_black(0.4)

	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_bgm"):
		sm.play_bgm("gameplay", -8.0, true, 0.0, 1.0)
		
	_build_clean_hud()
	
	player.notice.connect(queue_subtitle)
	player.mode_changed.connect(func(mode: int):
		_tone(330, 0.08)
		_update_controls_label(mode)
		_trigger_dimensional_shockwave()
		if chamber:
			chamber.set_spatial_mode(mode)
	)
	
	chamber.charge_collected.connect(func():
		queue_subtitle("A spark follows you. Guide it through 3D to the receiver.")
		_tone(660, 0.18)
		var g = get_node_or_null("/root/Global")
		if g and "carried_charge" in g:
			g.carried_charge = true
			if g.has_signal("charge_state_changed"):
				g.emit_signal("charge_state_changed", true)
	)
	
	chamber.relay_activated.connect(func():
		queue_subtitle("Ancient relay awakened! The 1D conduit rail is energized.", 3.5)
		add_trauma(0.3)
		_tone(550, 0.2)
	)
	
	chamber.circuit_completed.connect(func():
		queue_subtitle("Ancient mechanisms awaken! The Runic Bridge reconstructs across the chasm!", 4.5)
		add_trauma(0.85)
		_tone(880, 0.32)
		var g = get_node_or_null("/root/Global")
		if g and "carried_charge" in g:
			g.carried_charge = false
			if "receiver_powered" in g:
				g.receiver_powered = true
			if g.has_signal("charge_state_changed"):
				g.emit_signal("charge_state_changed", false)
	)
	
	chamber.chamber_completed.connect(func():
		queue_subtitle("★ CHAMBER 1 COMPLETE ★ — The Ascent Portal is Open!")
		_tone(1100, 0.5)
		var g = get_node_or_null("/root/Global")
		if g and "exit_open" in g:
			g.exit_open = true
		if get_tree().current_scene == self:
			get_tree().create_timer(1.8).timeout.connect(_enter_axiom_sanctum)
	)
	
	# Spawn Flat Guardian Sentinel in Section H (Upper Guardian Hall)
	var guardian_script = load("res://chambers/broken_circuit/scripts/flat_guardian.gd")
	if guardian_script:
		guardian = guardian_script.new()
		guardian.name = "FlatGuardian"
		if chamber.has_node("Markers/GuardianSpawn"):
			guardian.position = chamber.get_node("Markers/GuardianSpawn").position
		else:
			guardian.position = Vector3(96.0, 6.38, 0.0)
		add_child(guardian)
	
	# Global health signal connection
	var g_node = get_node_or_null("/root/Global")
	if g_node and g_node.has_signal("health_changed"):
		g_node.health_changed.connect(_on_health_changed)
		_on_health_changed(g_node.current_health if "current_health" in g_node else 3)
	
	_setup_dialogue()
	_update_camera(1.0)
	_update_controls_label(player.mode)
	
	# Initial Arrival subtitle
	trigger_milestone("arrival", "Three dimensions. Three ways forward.", 4.0)

func _setup_dialogue() -> void:
	var d_scene = load("res://scenes/ui/UndertaleDialogueBox.tscn")
	if d_scene:
		dialogue_box = d_scene.instantiate()
		add_child(dialogue_box)
		if not player.input_override:
			player.input_override = true
			var timer = get_tree().create_timer(0.35)
			timer.timeout.connect(func():
				if dialogue_box and is_instance_valid(dialogue_box) and not dialogue_box.is_active:
					dialogue_box.start_dialogue()
			)
			dialogue_box.dialogue_finished.connect(func():
				player.input_override = false
			)

func _build_clean_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "CleanHUD"
	layer.layer = 100 # Above the post-process overlay (layer 50) so vignette/grain/CA never dims or distorts UI
	add_child(layer)
	
	# 1. Floating Health Hearts (Top-Left, no brown panel)
	var hp_container := HBoxContainer.new()
	hp_container.name = "HealthHearts"
	hp_container.position = Vector2(32, 24)
	hp_container.add_theme_constant_override("separation", 10)
	layer.add_child(hp_container)
	
	heart_icons.clear()
	for i in 3:
		var heart := TextureRect.new()
		heart.texture = heart_full_tex
		heart.custom_minimum_size = Vector2(28, 28)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hp_container.add_child(heart)
		heart_icons.append(heart)

	# 2. Large, Readable Gameplay Subtitles (Lower-middle safe area, above controls)
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.custom_minimum_size = Vector2(960, 70)
	subtitle_label.size = Vector2(960, 70)
	subtitle_label.position = Vector2(160, 565)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 30)
	subtitle_label.add_theme_color_override("font_color", Color.WHITE)
	subtitle_label.add_theme_constant_override("outline_size", 6)
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.04, 0.04, 0.04, 0.95))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	subtitle_label.modulate.a = 0.0
	layer.add_child(subtitle_label)

	# 3. Contextual Bottom Controls (No brown bar, large legible typography)
	controls_label = Label.new()
	controls_label.name = "ControlsLabel"
	controls_label.custom_minimum_size = Vector2(1200, 36)
	controls_label.size = Vector2(1200, 36)
	controls_label.position = Vector2(40, 668)
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	controls_label.add_theme_font_size_override("font_size", 23)
	controls_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 1.0))
	controls_label.add_theme_constant_override("outline_size", 5)
	controls_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
	controls_label.add_theme_constant_override("shadow_offset_x", 2)
	controls_label.add_theme_constant_override("shadow_offset_y", 2)
	controls_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	layer.add_child(controls_label)

var trauma: float = 0.0

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _update_controls_label(mode: int) -> void:
	if not controls_label:
		return
	match mode:
		2:
			controls_label.text = "WASD Move   •   SPACE Jump   •   1/2/3 Dimension   •   F Interact"
		3:
			controls_label.text = "WASD Move Across Depth   •   1/2/3 Dimension   •   F Interact"
		1:
			controls_label.text = "A/D Slide Along Conduit   •   1/2/3 Dimension   •   F Interact"

func queue_subtitle(text: String, duration: float = 3.5) -> void:
	subtitle_queue.append({"text": text, "duration": duration})

func trigger_milestone(id: String, text: String, duration: float = 3.5) -> void:
	if shown_milestones.has(id):
		return
	shown_milestones[id] = true
	queue_subtitle(text, duration)
	_ignite_wall_glyph(id)

func _ignite_wall_glyph(id: String) -> void:
	# Ancient hieroglyph burst that ignites gold as each course milestone is crossed, then fades away.
	if not player or not player.is_inside_tree():
		return
	var glyph_shader = load("res://shaders/wall_glyphs.gdshader")
	if not glyph_shader:
		return
	var glyph := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 1.4)
	glyph.mesh = quad
	var mat := ShaderMaterial.new()
	mat.shader = glyph_shader
	mat.set_shader_parameter("lit", 0.0)
	glyph.material_override = mat
	glyph.name = "WallGlyph_" + id
	glyph.position = player.global_position + Vector3(0, 2.2, 0)
	glyph.rotation_degrees.y = 45.0
	add_child(glyph)
	var t := create_tween()
	t.tween_method(func(v: float): mat.set_shader_parameter("lit", v), 0.0, 1.0, 0.8).set_trans(Tween.TRANS_QUAD)
	t.tween_interval(2.0)
	t.tween_method(func(v: float): mat.set_shader_parameter("lit", v), 1.0, 0.0, 1.0)
	t.tween_callback(glyph.queue_free)


func _process(delta: float) -> void:
	_handle_subtitles(delta)
	_update_checkpoints_and_milestones()
	_handle_pit_respawn()
	_update_camera(delta)

func _handle_subtitles(delta: float) -> void:
	if current_subtitle_time > 0:
		current_subtitle_time -= delta
		# Smooth fade in / fade out
		var t_in = minf(1.0, (current_subtitle_duration - current_subtitle_time) / 0.25)
		var t_out = minf(1.0, current_subtitle_time / 0.35)
		subtitle_label.modulate.a = minf(t_in, t_out)
	else:
		if not subtitle_queue.is_empty():
			var item = subtitle_queue.pop_front()
			subtitle_label.text = item["text"]
			current_subtitle_duration = item["duration"]
			current_subtitle_time = item["duration"]
			subtitle_label.modulate.a = 0.0
		else:
			subtitle_label.modulate.a = 0.0

func _update_checkpoints_and_milestones() -> void:
	var px: float = player.position.x
	
	# Milestone tutorials
	if px > -12.5 and px < -8.5:
		trigger_milestone("first_ledge", "Switch to 2D [2]. Press SPACE to jump.")
	elif px >= 8.0 and px <= 14.0:
		trigger_milestone("offset_passage", "The path continues at another depth. Return to 3D [3].")
	elif px >= 15.5 and px <= 19.5:
		trigger_milestone("conduit_d", "Too narrow? Become a line [1].")
	elif px >= 26.5 and px <= 32.0:
		trigger_milestone("gallery_e", "Time your jumps across the moving terrace.")
	elif px >= 48.0 and px <= 53.0:
		trigger_milestone("relay_f", "Awaken the ancient relay to power the conduit [0 / F], then slide in 1D to fetch the charge.")
	elif px >= 68.0 and px <= 73.0:
		trigger_milestone("ascent_g", "Combine all three dimensions to ascend.")
	elif px >= 90.0 and px <= 96.0:
		trigger_milestone("guardian_h", "Flat Guardian ahead. In 2D, you can slip right through it.")

	# Safe Checkpoints
	if px >= 90.0:
		latest_checkpoint = Vector3(91.0, 5.88, 0.0)
		latest_checkpoint_mode = 3
	elif px >= 69.0:
		latest_checkpoint = Vector3(69.5, 4.28, -3.5)
		latest_checkpoint_mode = 2
	elif px >= 49.0:
		latest_checkpoint = Vector3(49.5, 3.08, 0.0)
		latest_checkpoint_mode = 3
	elif px >= 26.0:
		latest_checkpoint = Vector3(26.5, 2.48, -4.0)
		latest_checkpoint_mode = 2
	elif px >= 15.0:
		latest_checkpoint = Vector3(15.5, 2.48, -4.0)
		latest_checkpoint_mode = 3
	elif px >= 6.0:
		latest_checkpoint = Vector3(6.5, 2.48, 0.0)
		latest_checkpoint_mode = 3

func _handle_pit_respawn() -> void:
	if player.position.y < -5.5:
		# Player fell into the abyss; respawn safely at latest milestone
		player.velocity = Vector3.ZERO
		player.position = latest_checkpoint
		player.request_mode(latest_checkpoint_mode)
		_tone(220, 0.25)
		queue_subtitle("Careful! Returned to the latest resting terrace.", 2.5)

func _on_health_changed(hp: int) -> void:
	for i in heart_icons.size():
		heart_icons[i].texture = heart_full_tex if i < hp else heart_empty_tex
		heart_icons[i].modulate = Color.WHITE if i < hp else Color(0.45, 0.45, 0.45, 0.4)

func _update_camera(delta: float) -> void:
	var blend: float = minf(1.0, delta * 7.0)
	var target_yaw: float = -45.0 if player.mode == 3 else 0.0
	var target_pitch: float = -30.0 if player.mode == 3 else 0.0
	yaw = lerpf(yaw, target_yaw, blend)
	pitch = lerpf(pitch, target_pitch, blend)
	
	# Smooth forward look-ahead along X axis so upcoming jumps and platforms are clearly framed
	var lookahead_x: float = 1.2 if player.mode == 2 else 0.8
	var target: Vector3 = player.position + Vector3(lookahead_x, 0.9, 0)
	focus = focus.lerp(target, blend)
	
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 0.7)
		var shake = trauma * trauma * 0.45
		focus += Vector3(randf_range(-shake, shake), randf_range(-shake, shake), randf_range(-shake, shake))
	
	# Maintain close, large scale view on screen (size ~ 5.2)
	var target_size: float = 5.4 if player.mode == 3 else 4.8
	camera.size = lerpf(camera.size, target_size, blend)
	
	var dist: float = 28.0
	var offset := Vector3(0, 0, dist).rotated(Vector3.RIGHT, deg_to_rad(pitch)).rotated(Vector3.UP, deg_to_rad(yaw))
	camera.position = focus + offset
	camera.look_at(focus)

func _tone(frequency: float, duration: float) -> void:
	var audio := AudioStreamPlayer.new()
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var samples: int = int(duration * 22050)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i in samples:
		var envelope: float = pow(1.0 - float(i) / samples, 2.0)
		data.encode_s16(i * 2, int(sin(TAU * frequency * i / 22050.0) * envelope * 2800))
	stream.data = data
	audio.stream = stream
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()

func _enter_axiom_sanctum() -> void:
	if not is_inside_tree() or get_tree().current_scene != self:
		return
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("stop_bgm"):
		sm.stop_bgm(0.8)
	var transition = get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("change_chamber"):
		transition.change_chamber("res://chambers/axiom_warden/AxiomWarden.tscn")
	else:
		get_tree().change_scene_to_file("res://chambers/axiom_warden/AxiomWarden.tscn")

func _trigger_dimensional_shockwave() -> void:
	if pp_rect and is_instance_valid(pp_rect) and pp_rect.material is ShaderMaterial:
		var sm: ShaderMaterial = pp_rect.material
		var t := create_tween()
		t.tween_method(func(val: float):
			if is_instance_valid(pp_rect) and sm:
				sm.set_shader_parameter("shockwave_progress", val),
			0.0, 1.0, 0.28
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
