extends Node3D
## Lighting, camera and minimal HUD for the standalone reference scene.
var overview: bool = false
var establishing_time: float = 2.4
var yaw: float = -32.0
var pitch: float = -28.0
var message_time: float = 0.0
var message: String = "The watch stirs. All three spatial forms are yours."
var hint: Label
var status: Label
var title: Label
var controls: Label
var focus: Vector3 = Vector3(-8, 2, 0)
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
	_build_hud()
	player.notice.connect(show_message)
	player.mode_changed.connect(func(_mode: int): _tone(330,0.09))
	chamber.charge_collected.connect(func(): show_message("A spark follows you. Find its missing socket."); _tone(660,0.18))
	chamber.circuit_completed.connect(func(): _tone(880,0.32))
	chamber.chamber_completed.connect(func(): show_message("CHAMBER COMPLETE — The way upward is open."); _tone(1100,0.5))
	show_message(message)
	_update_camera(1.0)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.078,0.047,0.016,0.88)
	panel.position = Vector2.ZERO
	panel.size = Vector2(320,21)
	layer.add_child(panel)
	title = _label(layer, Vector2(8,3), 10, Color("ebd8b0"))
	title.text = "01 / THE BROKEN CIRCUIT"
	status = _label(layer, Vector2(233,5), 8, Color("d4af67"))
	var lower := ColorRect.new()
	lower.position = Vector2(0,152)
	lower.size = Vector2(320,28)
	lower.color = Color(0.078,0.047,0.016,0.91)
	layer.add_child(lower)
	hint = _label(layer, Vector2(8,154), 8, Color("ebd8b0"))
	controls = _label(layer, Vector2(8,167), 7, Color("c29f5c"))
	controls.text = "WASD move   SPACE jump   1/2/3 form   F use   M map"

func _label(parent: Node, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",tint)
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
	status.text = "%dD  %s" % [player.mode, "AWAKE" if chamber.powered else ("SPARK" if chamber.carrying_charge else "DORMANT")]
	if chamber.completed:
		hint.text = "CHAMBER COMPLETE. Continue upward in your game."
	elif message_time > 0:
		hint.text = message
	elif chamber.powered:
		hint.text = "Rear gold line / 2D makes the steps solid."
	elif chamber.carrying_charge:
		hint.text = "3D / Follow the gold line behind the pillar. F to use."
	elif player.position.x < -7.7:
		hint.text = "The low slot / Stand on the pale rail and press 1."
	else:
		hint.text = "Find the spark at the far end of the conduit."

func _update_camera(delta: float) -> void:
	var blend: float = minf(1, delta * 7.0)
	var wide_view: bool = overview or establishing_time > 0
	var target_yaw: float = -32.0 if player.mode == 3 or wide_view else 0.0
	var target_pitch: float = -28.0 if player.mode == 3 or wide_view else 0.0
	yaw = lerpf(yaw, target_yaw, blend)
	pitch = lerpf(pitch, target_pitch, blend)
	var target := Vector3(clampf(player.position.x, -8, 8.0), maxf(2.1,player.position.y + 0.5), 0)
	if wide_view:
		target = Vector3(0, 2.0, 0)
	focus = focus.lerp(target, blend)
	camera.size = lerpf(camera.size, 18.8 if wide_view else 8.0, blend)
	var offset := Vector3(0,0,28).rotated(Vector3.RIGHT,deg_to_rad(pitch)).rotated(Vector3.UP,deg_to_rad(yaw))
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
