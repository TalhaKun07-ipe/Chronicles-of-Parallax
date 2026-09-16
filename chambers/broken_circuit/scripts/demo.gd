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

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1a1510")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e0cb9e")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.15
	world.environment = env
	add_child(world)
	
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 1.5
	add_child(sun)
	
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("bca068")
	fill.light_energy = 0.28
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
	for pos in lamp_positions:
		var lamp := OmniLight3D.new()
		lamp.position = pos
		lamp.light_color = Color("ffc97a")
		lamp.light_energy = 0.85
		lamp.omni_range = 7.0
		add_child(lamp)
		
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
		
	_build_clean_hud()
	
	player.notice.connect(queue_subtitle)
	player.mode_changed.connect(func(mode: int):
		_tone(330, 0.08)
		_update_controls_label(mode)
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
	
	chamber.circuit_completed.connect(func():
		queue_subtitle("The circuit answers. A new path opens.")
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
		trigger_milestone("relay_f", "Enter the conduit to fetch the spark, then route it through 3D.")
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
	var transition = get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("change_chamber"):
		transition.change_chamber("res://chambers/axiom_warden/AxiomWarden.tscn")
	else:
		get_tree().change_scene_to_file("res://chambers/axiom_warden/AxiomWarden.tscn")
