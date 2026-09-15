extends Node3D
## Lighting, camera and minimal HUD for the standalone reference scene.
var overview: bool = false
var establishing_time: float = 0.0
var yaw: float = -45.0
var pitch: float = -30.0
var message_time: float = 0.0
var message: String = "Stand on the gold plate to wake the first conduit."
var hint: Label
var status: Label
var title: Label
var controls: Label
var map_button: Button
var focus: Vector3 = Vector3(-11.5, .85, 0)
var dialogue_box: CanvasLayer
var heart_icons: Array[TextureRect] = []
var heart_full_tex: Texture2D = preload("res://assets/ui/heart_full.png")
var heart_empty_tex: Texture2D = preload("res://assets/ui/heart_empty.png")

@onready var player: CharacterBody3D = $Player
@onready var chamber: Node3D = $Chamber
@onready var camera: Camera3D = $Camera3D

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
	sun.directional_shadow_max_distance = 65
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_bias = 0.02
	sun.shadow_normal_bias = 1.5
	add_child(sun)
	
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("bca068")
	fill.light_energy = 0.28
	add_child(fill)
	
	# Atmospheric architectural lamps
	for pos in [Vector3(-9, 2.2, 0), Vector3(3.0, 2.4, 0), Vector3(7.5, 2.2, -4), Vector3(20, 3.2, -4), Vector3(35.5, 4.0, -4.5)]:
		var lamp := OmniLight3D.new()
		lamp.position = pos
		lamp.light_color = Color("ffc97a")
		lamp.light_energy = 0.85
		lamp.omni_range = 5.0
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
		
	_build_hud()
	player.notice.connect(show_message)
	player.mode_changed.connect(func(_mode: int): _tone(330, 0.09))
	chamber.charge_collected.connect(func():
		show_message("A spark follows you. Find its missing socket.")
		_tone(660, 0.18)
		var g = get_node_or_null("/root/Global")
		if g and "carried_charge" in g:
			g.carried_charge = true
			if g.has_signal("charge_state_changed"):
				g.emit_signal("charge_state_changed", true)
	)
	chamber.circuit_completed.connect(func():
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
		show_message("★ CHAMBER 1 COMPLETE ★ — The Ascent Portal is Open!")
		_tone(1100, 0.5)
		var g = get_node_or_null("/root/Global")
		if g and "exit_open" in g:
			g.exit_open = true
	)
	chamber.plate_activated.connect(_plate_activated)
	
	# Spawn Flat Guardian Sentinel in the upper arena
	var guardian_script = load("res://chambers/broken_circuit/scripts/flat_guardian.gd")
	var guardian = guardian_script.new()
	guardian.name = "FlatGuardian"
	if chamber.has_node("Markers/GuardianSpawn"):
		guardian.position = chamber.get_node("Markers/GuardianSpawn").position
	else:
		guardian.position = Vector3(31.5, 0.88, 0.0)
	add_child(guardian)
	
	# Global health signal connection
	var g_node = get_node_or_null("/root/Global")
	if g_node and g_node.has_signal("health_changed"):
		g_node.health_changed.connect(_on_health_changed)
		_on_health_changed(g_node.current_health if "current_health" in g_node else 3)
	
	_setup_dialogue()
	show_message(message)
	_update_camera(1.0)

func _setup_dialogue() -> void:
	# Instantiate Undertale-style conversation box
	var d_scene = load("res://scenes/ui/UndertaleDialogueBox.tscn")
	if d_scene:
		dialogue_box = d_scene.instantiate()
		add_child(dialogue_box)
		
		# If this is active gameplay and not an automated headless test
		if not player.input_override:
			player.input_override = true
			var timer = get_tree().create_timer(0.35)
			timer.timeout.connect(func():
				if dialogue_box and is_instance_valid(dialogue_box) and not dialogue_box.is_active:
					dialogue_box.start_dialogue()
			)
			dialogue_box.dialogue_finished.connect(func():
				player.input_override = false
				show_message("Stand on the gold plate to wake the first conduit.")
			)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	
	# Top bar - 1280x44 sleek glassmorphic banner
	var top_panel := PanelContainer.new()
	top_panel.custom_minimum_size = Vector2(1280, 44)
	top_panel.size = Vector2(1280, 44)
	top_panel.position = Vector2.ZERO
	var top_style := StyleBoxFlat.new()
	top_style.bg_color = Color(0.06, 0.04, 0.02, 0.92)
	top_style.border_width_bottom = 2
	top_style.border_color = Color(0.66, 0.47, 0.16, 0.7)
	top_panel.add_theme_stylebox_override("panel", top_style)
	layer.add_child(top_panel)
	
	var top_margin := MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left", 24)
	top_margin.add_theme_constant_override("margin_right", 24)
	top_margin.add_theme_constant_override("margin_top", 6)
	top_margin.add_theme_constant_override("margin_bottom", 6)
	top_panel.add_child(top_margin)
	
	var top_hbox := HBoxContainer.new()
	top_margin.add_child(top_hbox)
	
	# Top-Left Health Points: Crisp Retro Red Pixel Hearts
	var hp_container := HBoxContainer.new()
	hp_container.add_theme_constant_override("separation", 8)
	top_hbox.add_child(hp_container)
	
	heart_icons.clear()
	for i in 3:
		var heart := TextureRect.new()
		heart.texture = heart_full_tex
		heart.custom_minimum_size = Vector2(24, 24)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hp_container.add_child(heart)
		heart_icons.append(heart)
		
	var hp_divider := Label.new()
	hp_divider.text = "   |   "
	hp_divider.add_theme_font_size_override("font_size", 15)
	hp_divider.add_theme_color_override("font_color", Color(0.66, 0.47, 0.16, 0.7))
	top_hbox.add_child(hp_divider)
	
	title = Label.new()
	title.text = "01 / THE BROKEN CIRCUIT"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("ebd8b0"))
	top_hbox.add_child(title)
	
	var spacer1 := Control.new()
	spacer1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer1)
	
	# Interactive Full Map button
	map_button = Button.new()
	map_button.text = "FULL MAP [M]"
	map_button.custom_minimum_size = Vector2(140, 30)
	map_button.add_theme_font_size_override("font_size", 13)
	map_button.add_theme_color_override("font_color", Color("ebd8b0"))
	map_button.add_theme_color_override("font_hover_color", Color("fff3dd"))
	map_button.focus_mode = Control.FOCUS_NONE
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.14, 0.09, 0.04, 0.95)
	style_normal.border_width_left = 1
	style_normal.border_width_top = 1
	style_normal.border_width_right = 1
	style_normal.border_width_bottom = 1
	style_normal.border_color = Color("c29f5c")
	style_normal.corner_radius_top_left = 3
	style_normal.corner_radius_top_right = 3
	style_normal.corner_radius_bottom_right = 3
	style_normal.corner_radius_bottom_left = 3
	map_button.add_theme_stylebox_override("normal", style_normal)
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = Color(0.28, 0.19, 0.09, 0.95)
	style_hover.border_color = Color("ffd778")
	map_button.add_theme_stylebox_override("hover", style_hover)
	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = Color(0.40, 0.28, 0.12, 1.0)
	style_pressed.border_color = Color("ffffff")
	map_button.add_theme_stylebox_override("pressed", style_pressed)
	map_button.pressed.connect(_toggle_overview)
	top_hbox.add_child(map_button)
	
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(spacer2)
	
	status = Label.new()
	status.add_theme_font_size_override("font_size", 15)
	status.add_theme_color_override("font_color", Color("d4af67"))
	top_hbox.add_child(status)
	
	# Lower bar - 1280x62 docked footer
	var bot_panel := PanelContainer.new()
	bot_panel.custom_minimum_size = Vector2(1280, 62)
	bot_panel.size = Vector2(1280, 62)
	bot_panel.position = Vector2(0, 658)
	var bot_style := StyleBoxFlat.new()
	bot_style.bg_color = Color(0.06, 0.04, 0.02, 0.93)
	bot_style.border_width_top = 2
	bot_style.border_color = Color(0.66, 0.47, 0.16, 0.7)
	bot_panel.add_theme_stylebox_override("panel", bot_style)
	layer.add_child(bot_panel)
	
	var bot_margin := MarginContainer.new()
	bot_margin.add_theme_constant_override("margin_left", 24)
	bot_margin.add_theme_constant_override("margin_right", 24)
	bot_margin.add_theme_constant_override("margin_top", 8)
	bot_margin.add_theme_constant_override("margin_bottom", 8)
	bot_panel.add_child(bot_margin)
	
	var bot_vbox := VBoxContainer.new()
	bot_vbox.add_theme_constant_override("separation", 4)
	bot_margin.add_child(bot_vbox)
	
	hint = Label.new()
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color("ebd8b0"))
	bot_vbox.add_child(hint)
	
	controls = Label.new()
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color("c29f5c"))
	controls.text = "WASD Move   •   SPACE Jump   •   Q/E Change Dimension   •   F Interact   •   M Full Map"
	bot_vbox.add_child(controls)

func _toggle_overview() -> void:
	overview = not overview
	if overview:
		show_message("[ FULL MAP ] Move to return to close view.")
		_tone(440, 0.08)
	else:
		_tone(330, 0.08)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			_toggle_overview()
		elif event.physical_keycode == KEY_F5:
			get_tree().reload_current_scene()

func show_message(text: String) -> void:
	message = text
	message_time = 5.0

func _process(delta: float) -> void:
	establishing_time = maxf(0, establishing_time - delta)
	
	# Auto-reset full map view if player moves
	if overview:
		var is_moving: bool = player.move_input.length() > 0.08 \
			or Input.is_action_pressed("move_left") \
			or Input.is_action_pressed("move_right") \
			or Input.is_action_pressed("move_up") \
			or Input.is_action_pressed("move_down") \
			or Input.is_action_pressed("jump") \
			or Input.is_physical_key_pressed(KEY_W) \
			or Input.is_physical_key_pressed(KEY_A) \
			or Input.is_physical_key_pressed(KEY_S) \
			or Input.is_physical_key_pressed(KEY_D) \
			or Input.is_physical_key_pressed(KEY_SPACE) \
			or Input.is_physical_key_pressed(KEY_UP) \
			or Input.is_physical_key_pressed(KEY_LEFT) \
			or Input.is_physical_key_pressed(KEY_DOWN) \
			or Input.is_physical_key_pressed(KEY_RIGHT)
		if is_moving:
			overview = false
			
	_update_camera(delta)
	message_time = maxf(0, message_time - delta)
	status.text = "%dD  %s" % [player.mode, "AWAKE" if chamber.powered else ("SPARK" if chamber.carrying_charge else "DORMANT")]
	if chamber.completed:
		hint.text = "CHAMBER 1 COMPLETE — The path to the next trial awaits."
	elif overview:
		hint.text = "[ FULL MAP VIEW ] — Move in any direction to return to close view."
	elif message_time > 0:
		hint.text = message
	elif player.position.x > 26.5:
		if player.mode == 3:
			hint.text = "FLAT GUARDIAN ATTACKING! Switch to 2D [2] to slip right through it!"
		else:
			hint.text = "2D / Slip through the Flat Guardian to reach the Exit Portal!"
	elif player.mode == 1 and player.position.x > 18.0:
		hint.text = "1D / Slide across the high conduit to the Guardian Hall."
	elif player.position.x > 17.0 and player.position.y > 0.6:
		if player.mode == 2:
			hint.text = "3D / Switch to 3D [3] and walk forward to the front rail dock."
		else:
			hint.text = "1D / Step to the high conduit dock and press 1 to slide across."
	elif chamber.powered:
		hint.text = "2D / Jump up onto the glowing terrace in 2D."
	elif chamber.carrying_charge:
		hint.text = "3D / Follow the gold trace behind the monolith to the receiver."
	elif chamber.first_rail_live:
		hint.text = "1D / Reach the conduit dock, flatten into 1D, and slide through."
	else:
		hint.text = "Stand on the gold plate ahead."

func _on_health_changed(hp: int) -> void:
	for i in heart_icons.size():
		heart_icons[i].texture = heart_full_tex if i < hp else heart_empty_tex
		heart_icons[i].modulate = Color.WHITE if i < hp else Color(0.5, 0.5, 0.5, 0.5)

func _plate_activated(_upper: bool = false) -> void:
	show_message("A path appears beneath the gate. Press 1 at its socket.")
	_tone(550, .25)

func _update_camera(delta: float) -> void:
	var blend: float = minf(1.0, delta * 7.0)
	var target_yaw: float = -45.0 if player.mode == 3 or overview else 0.0
	var target_pitch: float = -30.0 if player.mode == 3 or overview else 0.0
	yaw = lerpf(yaw, target_yaw, blend)
	pitch = lerpf(pitch, target_pitch, blend)
	
	var target: Vector3
	if overview:
		# Centered to frame the 52-meter Chamber 1 course from X=-14 to X=38
		target = Vector3(12.0, 1.2, 0.0)
	else:
		target = player.position + Vector3(0.65, 0.85, 0)
		
	focus = focus.lerp(target, blend)
	
	var target_size: float = 16.5 if overview else 5.2
	camera.size = lerpf(camera.size, target_size, blend)
	
	var dist: float = 34.0 if overview else 28.0
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
		var envelope: float = pow(1.0-float(i)/samples,2.0)
		data.encode_s16(i*2, int(sin(TAU*frequency*i/22050.0)*envelope*2800))
	stream.data = data
	audio.stream = stream
	add_child(audio)
	audio.finished.connect(audio.queue_free)
	audio.play()
