extends Node3D
## Lighting, camera and minimal HUD for the standalone reference scene.
var overview: bool = false
var establishing_time: float = 0.0
var yaw: float = -45.0
var pitch: float = -30.0
var message_time: float = 0.0
var message: String = "The watch stirs. All three spatial forms are yours."
var hint: Label
var status: Label
var title: Label
var controls: Label
var focus: Vector3 = Vector3(-11.3, 1.0, 0)
@onready var player: CharacterBody3D = $Player
@onready var chamber: Node3D = $Chamber
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("140c04")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ebd8b0")
	env.ambient_light_energy = 0.40
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("ffe0a1")
	sun.light_energy = 0.68
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("c29f5c")
	fill.light_energy = 0.24
	add_child(fill)
	for pos in [Vector3(-11,2.3,-3.5),Vector3(2.8,2.2,-3.7),Vector3(11.5,5.5,-3.1)]:
		var lamp := OmniLight3D.new()
		lamp.position = pos
		lamp.light_color = Color("ffc376")
		lamp.light_energy = 0.8
		lamp.omni_range = 4.0
		add_child(lamp)
	if Global:
		Global.current_chamber_id = "broken_circuit"
		Global.unlocked_dimensions[Global.Dimension.DIM_1D] = true
		Global.unlocked_dimensions[Global.Dimension.DIM_2D] = true
		Global.unlocked_dimensions[Global.Dimension.DIM_3D] = true
		Global.active_dimension = Global.Dimension.DIM_3D

	if SceneTransition:
		SceneTransition.fade_in_from_black(0.4)

	_build_hud()
	player.notice.connect(show_message)
	player.mode_changed.connect(func(_mode: int): _tone(330,0.09))
	chamber.charge_collected.connect(func():
		show_message("A spark follows you. Find its missing socket.")
		_tone(660,0.18)
		if Global:
			Global.carried_charge = true
			Global.charge_state_changed.emit(true)
	)
	chamber.circuit_completed.connect(func():
		_tone(880,0.32)
		if Global:
			Global.carried_charge = false
			Global.charge_state_changed.emit(false)
			if Global.chamber_states.has("chamber_1"):
				Global.chamber_states["chamber_1"]["receiver_powered"] = true
	)
	chamber.chamber_completed.connect(func():
		show_message("CHAMBER COMPLETE — The way upward is open.")
		_tone(1100,0.5)
		if Global and Global.chamber_states.has("chamber_1"):
			Global.chamber_states["chamber_1"]["exit_open"] = true
		if not player.input_override:
			var timer = get_tree().create_timer(1.6)
			timer.timeout.connect(_transition_to_next_chamber)
	)
	show_message(message)
	_update_camera(1.0)

func _transition_to_next_chamber() -> void:
	if SceneTransition:
		SceneTransition.change_chamber("res://scenes/levels/Chamber1_DimensionalTrial.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/levels/Chamber1_DimensionalTrial.tscn")

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.06, 0.04, 0.015, 0.88)
	panel.position = Vector2.ZERO
	panel.size = Vector2(320, 22)
	layer.add_child(panel)
	title = _label(layer, Vector2(8, 3), 9, Color("ebd8b0"))
	title.text = "01 / THE BROKEN CIRCUIT"
	status = _label(layer, Vector2(140, 2), 8, Color("d4af67"))
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.custom_minimum_size = Vector2(172, 18)
	var lower := ColorRect.new()
	lower.position = Vector2(0, 154)
	lower.size = Vector2(320, 26)
	lower.color = Color(0.06, 0.04, 0.015, 0.91)
	layer.add_child(lower)
	hint = _label(layer, Vector2(8, 155), 8, Color("ebd8b0"))
	controls = _label(layer, Vector2(8, 168), 7, Color("c29f5c"))
	controls.text = "A/D Move   SPACE Jump   Q/E Dimension (1/2/3)   F Use   M Map"

func _label(parent: Node, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	parent.add_child(label)
	return label

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_M:
			overview = not overview
		elif event.physical_keycode == KEY_F5:
			get_tree().reload_current_scene()

func show_message(text: String) -> void:
	message = text
	message_time = 5.0

func _process(delta: float) -> void:
	establishing_time = maxf(0, establishing_time - delta)
	_update_camera(delta)
	message_time = maxf(0, message_time - delta)
	
	var mode_name := "3D VOLUME"
	var mode_hint := "[Q] 2D"
	if player.mode == 2:
		mode_name = "2D PLANE"
		mode_hint = "[Q] 1D  [E] 3D"
	elif player.mode == 1:
		mode_name = "1D LINE"
		mode_hint = "[E] 2D"
		
	var state_str := "DORMANT"
	if chamber.powered:
		state_str = "AWAKE"
	elif chamber.carrying_charge:
		state_str = "SPARK"
		
	status.text = "%s [%s]  %s" % [mode_name, state_str, mode_hint]
	
	if chamber.completed:
		hint.text = "CHAMBER COMPLETE. Ascending upward..."
	elif message_time > 0:
		hint.text = message
	elif chamber.powered:
		hint.text = "Stairs ready! Press 2 (or Q) from rear line to solidify steps."
	elif chamber.carrying_charge:
		hint.text = "3D (or E) -> Walk behind monolith to receiver. Press F."
	elif player.position.x < -7.7:
		hint.text = "Low slot -> Stand on pale rail socket, press 1 (or Q)."
	else:
		hint.text = "Follow the conduit to retrieve the spark."

func _update_camera(delta: float) -> void:
	var blend: float = minf(1.0, delta * 8.0)
	var wide_view: bool = overview or establishing_time > 0
	var target_yaw: float = -45.0 if player.mode == 3 and not wide_view else 0.0
	var target_pitch: float = -30.0 if player.mode == 3 and not wide_view else 0.0
	if wide_view:
		target_yaw = -45.0
		target_pitch = -30.0
	yaw = lerpf(yaw, target_yaw, blend)
	pitch = lerpf(pitch, target_pitch, blend)
	
	# Tight, screen-filling platforming framing following John
	var target_z: float = player.position.z if player.mode == 3 else player.plane_z
	var target := Vector3(player.position.x, player.position.y + 0.85, target_z)
	if wide_view:
		target = Vector3(0, 2.0, 0)
	focus = focus.lerp(target, blend)
	
	var target_size: float = 14.0 if wide_view else 5.2
	camera.size = lerpf(camera.size, target_size, blend)
	
	var offset := Vector3(0, 0, 24.0).rotated(Vector3.RIGHT, deg_to_rad(pitch)).rotated(Vector3.UP, deg_to_rad(yaw))
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
