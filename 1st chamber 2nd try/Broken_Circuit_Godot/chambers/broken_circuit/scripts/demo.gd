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
var focus: Vector3 = Vector3(-11.5, .85, 0)
@onready var player: CharacterBody3D = $Player
@onready var chamber: Node3D = $Chamber
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("403726")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("ebd8b0")
	env.ambient_light_energy = 0.40
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -25, 0)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 0.60
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 50
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 155, 0)
	fill.light_color = Color("c29f5c")
	fill.light_energy = 0.24
	add_child(fill)
	for pos in [Vector3(-9,2.5,0),Vector3(7.5,2.5,-4),Vector3(37,4.5,2),Vector3(48,4.5,0)]:
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
	chamber.plate_activated.connect(_plate_activated)
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
	controls.text = "WASD move  SPACE jump  Q/E form  F use  M view"

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
		hint.text = "COURSE COMPLETE — The ascent continues."
	elif message_time > 0:
		hint.text = message
	elif chamber.upper_rail_live:
		hint.text = "1D / Shutter OPEN. Slide through." if chamber.shutter_open else "1D / Shutter closed. Wait for the light."
	elif player.gallery_reached:
		hint.text = "3D / Walk around the divider to the gold plate."
	elif chamber.powered:
		hint.text = "2D / Climb the broad terraces on the rear path."
	elif chamber.carrying_charge:
		hint.text = "3D / Follow the gold trace behind the masonry."
	elif chamber.first_rail_live:
		hint.text = "1D / Reach the rail, flatten and slide through."
	else:
		hint.text = "Stand on the gold plate ahead."

func _plate_activated(upper: bool) -> void:
	show_message("Upper rail awake. Watch the shutter, then slide." if upper else "A path appears beneath the gate. Press 1 at its socket.")
	_tone(550, .25)

func _update_camera(delta: float) -> void:
	var blend: float = minf(1, delta * 7.0)
	var target_yaw: float = -45.0 if player.mode == 3 or overview else 0.0
	var target_pitch: float = -30.0 if player.mode == 3 or overview else 0.0
	yaw = lerpf(yaw,target_yaw,blend)
	pitch = lerpf(pitch,target_pitch,blend)
	var target := player.position + Vector3(0.65,.85,0)
	focus = focus.lerp(target,blend)
	camera.size = lerpf(camera.size,14.0 if overview else 5.2,blend)
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
