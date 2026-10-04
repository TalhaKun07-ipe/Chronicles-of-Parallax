extends Node3D
class_name DaylightEscape

## A complete time-mechanics route. Sector geometry is separate from its rules.
signal checkpoint_changed(index: int)
signal escaped()
const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
const PlayerClass = preload("res://scripts/player/ChronoPlayer.gd")
const HudClass = preload("res://scripts/ui/ChronoHUD.gd")
const PostClass = preload("res://scripts/mechanics/chrono_post_process.gd")
const START := Vector3(0, 0.05, 0)
const ANCHORS: Array[Vector3] = [START, Vector3(25, 2.45, 0), Vector3(42, 2.45, 0), Vector3(76, 5.45, 0)]
const SECTOR_TITLES = ["I  /  THE FRACTURED STAIR", "II  /  THE ECHO COURT", "III  /  THE CLOCKWORK SPAN", "IV  /  THE DAYLIGHT RUN"]
@export var transition_on_win: bool = true
var player: ChronoPlayer
var camera: Camera3D
var hud: CanvasLayer
var sun_gate: SunGate
var monolith: ChronoMonolith
var lift: ChronoLift
var rising_void: RisingVoid
var crumble_platforms: Array[ChronoPlatform] = []
var checkpoint_index: int = 0
var checkpoint_pos := START
var sector: int = 0
var won: bool = false
var respawning: bool = false
var timer_started: bool = false
var focus := START + Vector3(2, 1, 0)
var camera_yaw: float = 0.0
var camera_pitch: float = 0.0
var shown: Dictionary = {}
var plates_material: Array[StandardMaterial3D] = []
var floor_material: Material
var coping_material: Material
var trim_material: Material
var exit_light: OmniLight3D
var foreground_walls: Array[MeshInstance3D] = []

func _ready() -> void:
	Global.is_rewinding = false
	Global.rewind_unlocked = true
	Global.current_chamber_id = "daylight_escape"
	Global.current_checkpoint_pos = START
	Global.chamber_states["daylight_escape"] = {"anchor": 0, "sun_gate_open": false, "escaped": false}
	Global.chamber_states.chamber_3.escaped = false
	Global.reset_health()
	floor_material = Geo.stone_material(Color("77624b"))
	coping_material = Geo.material(Color("777363"))
	coping_material.albedo_texture = load("res://assets/textures/floor_pavers.png")
	coping_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	coping_material.uv1_triplanar = true
	coping_material.uv1_scale = Vector3(0.65, 0.65, 0.65)
	trim_material = Geo.material(Color("8a754d"))
	_build_environment()
	_build_fractured_stair()
	_build_echo_court()
	_build_clockwork_span()
	_build_daylight_run()
	player = PlayerClass.new()
	player.name = "Player"
	player.position = START
	add_child(player)
	player.died.connect(func(): call_deferred("respawn"))
	player.interacted.connect(interact)
	player.notice.connect(func(text): hud.show_hint(text))
	var post := PostClass.new()
	post.name = "ChronoPostProcess"
	post.controller = player.rewind_controller
	add_child(post)
	camera = Camera3D.new()
	camera.name = "ChamberCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.8
	camera.current = true
	add_child(camera)
	hud = HudClass.new()
	hud.name = "ChronoHUD"
	hud.player = player
	hud.room = self
	add_child(hud)
	hud.pause_requested.connect(toggle_pause)
	hud.retry_requested.connect(retry)
	_update_camera(1.0)
	SoundManager.play_bgm("gameplay", -10.0)
	SceneTransition.fade_in_from_black(0.65)
	hud.show_hint("The Chrono-Lens is whole. Hold R to rewind John and the room. Release R to leave an echo.", 11)

func floor_block(id: String, x: float, top: float, width: float, depth: float = 5.0, z: float = 0.0) -> Node3D:
	var floor_mesh := Geo.box(self, Vector3(x, top - 0.75, z), Vector3(width, 1.5, depth), floor_material, true)
	floor_mesh.name = id
	Geo.box(self, Vector3(x, top - 0.015, z), Vector3(width + 0.02, 0.05, depth + 0.02), coping_material)
	Geo.box(self, Vector3(x, top - 0.25, z + depth * 0.5 + 0.025), Vector3(width, 0.045, 0.035), trim_material)
	return floor_mesh

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("101b29")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b7c7d2")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -25, 0)
	sun.light_color = Color("ffe3b3")
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var wall_mat := Geo.stone_material(Color("1d303b"))
	for i in 12:
		var x := float(i) * 10.0 - 2.0
		var y := maxf(0, x * 0.085)
		Geo.box(self, Vector3(x, y + 3, -5.0), Vector3(9.8, 14, 0.55), wall_mat)
		Geo.column(self, Vector3(x - 4.0, y - 1.0, -4.55), 0.38, 8.0, floor_material, wall_mat, trim_material)
		Geo.torch(self, Vector3(x, y + 2.8, -4.65), Color("ffcf95"), 0.8, 7)
	# A distant void plane gives falling a clear visual destination.
	Geo.box(self, Vector3(53, -8, 0), Vector3(120, 0.3, 24), Geo.material(Color("101d2b")))

func _build_fractured_stair() -> void:
	floor_block("ArrivalFloor", 1, 0, 10, 6)
	floor_block("FirstStep", 8, 0.6, 2.8)
	floor_block("SecondStep", 11.8, 1.2, 2.6)
	crumble("CrumbleA", Vector3(15.4, 1.55, 0), 0.9)
	crumble("CrumbleB", Vector3(19.3, 2.15, 0), 0.9)
	floor_block("StairAnchor", 24, 2.4, 6)
	anchor_visual(ANCHORS[1])
	world_label("THE FRACTURED STAIR", Vector3(0, 3.0, -4.6), Color("bac9cb"))
	world_label("R  /  RESTORE THE FALL", Vector3(16.5, 5, -4.6), Color("78d5dd"), 20)

func crumble(id: String, at: Vector3, delay: float) -> ChronoPlatform:
	var platform := ChronoPlatform.new()
	platform.name = id
	platform.position = at
	platform.platform_size = Vector3(2.8, 0.5, 4.8)
	platform.collapse_delay = delay
	add_child(platform)
	platform.platform_material.albedo_color = Color("667f87")
	for z in [-2.1, 2.1]:
		Geo.box(platform, Vector3(0, 0.27, z), Vector3(2.6, 0.04, 0.07), Geo.conduit_material())
	# Fracture seams distinguish these from permanent landings before contact.
	for x in [-0.55, 0.55]:
		var seam := Geo.box(platform, Vector3(x, 0.255, 0), Vector3(0.035, 0.012, 3.8), Geo.material(Color("233440")))
		seam.rotation.y = 0.22 if x < 0 else -0.3
	crumble_platforms.append(platform)
	return platform

func _build_echo_court() -> void:
	floor_block("EchoCourtFloor", 34, 2.4, 20, 7)
	sun_gate = SunGate.new()
	sun_gate.name = "SunGate"
	sun_gate.plate_a = make_plate(Vector3(29, 2.43, -1.45), "A")
	sun_gate.plate_b = make_plate(Vector3(33.6, 2.43, 1.45), "B")
	sun_gate.gate_mesh = Node3D.new()
	sun_gate.gate_mesh.name = "GateVisual"
	sun_gate.gate_mesh.position = Vector3(37.5, 2.4, 0)
	add_child(sun_gate.gate_mesh)
	for z in [-3.2, -1.6, 0.0, 1.6, 3.2]:
		Geo.box(sun_gate.gate_mesh, Vector3(0, 1.75, z), Vector3(0.24, 3.5, 0.14), Geo.material(Color("c9a85d")))
		Geo.box(sun_gate.gate_mesh, Vector3(0.02, 1.75, z), Vector3(0.05, 3.4, 0.045), Geo.conduit_material())
	Geo.box(sun_gate.gate_mesh, Vector3(0, 3.55, 0), Vector3(0.55, 0.3, 7.2), trim_material)
	sun_gate.gate_body = StaticBody3D.new()
	sun_gate.gate_body.name = "GateCollision"
	sun_gate.gate_body.position = Vector3(37.5, 4.15, 0)
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(0.45, 3.5, 7.4)
	shape.shape = bounds
	sun_gate.gate_body.add_child(shape)
	add_child(sun_gate.gate_body)
	add_child(sun_gate)
	sun_gate.opened.connect(func():
		Global.chamber_states.daylight_escape.sun_gate_open = true
		hud.show_hint("Two moments, one path. The Sun Gate is now a permanent time anchor.")
		set_checkpoint(2))
	# Continuous low walls prevent walking around the gate in 3D.
	for z in [-3.65, 3.65]:
		var wall := Geo.box(self, Vector3(34, 3.4, z), Vector3(20, 2, 0.3), floor_material, true)
		if z > 0: foreground_walls.append(wall)
	world_label("THE ECHO COURT", Vector3(30, 6, -4.6), Color("dec795"))
	anchor_visual(ANCHORS[2])

func make_plate(at: Vector3, letter: String) -> Area3D:
	var area := Area3D.new()
	area.name = "Plate" + letter
	area.position = at
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(1.5, 0.65, 1.5)
	shape.shape = bounds
	shape.position.y = 0.3
	area.add_child(shape)
	add_child(area)
	var material := Geo.material(Color("826745"), true)
	plates_material.append(material)
	Geo.box(area, Vector3(0, 0.012, 0), Vector3(1.5, 0.04, 1.5), material)
	world_label(letter, at + Vector3(0, 0.55, -0.35), Color("ffdc92"), 22)
	return area

func _build_clockwork_span() -> void:
	floor_block("MonolithDock", 45.0, 2.4, 4, 5)
	monolith = ChronoMonolith.new()
	monolith.name = "ChronoMonolith"
	monolith.position = Vector3(47, 2.5, 0)
	monolith.pillar_dimensions = Vector3(1, 5, 4.8)
	monolith.topple_axis = Vector3.RIGHT
	monolith.max_fall_angle_deg = 90
	add_child(monolith)
	monolith.mesh_instance.material_override = Geo.stone_material(Color("54717b"))
	for y in [1.0, 2.5, 4.0]:
		Geo.box(monolith.base_pivot, Vector3(0.52, y, 0), Vector3(0.04, 0.08, 4.6), Geo.conduit_material())
	Geo.box(self, Vector3(45.2, 2.9, -1.8), Vector3(0.45, 1, 0.45), trim_material)
	Geo.box(self, Vector3(45.2, 3.45, -1.8), Vector3(0.6, 0.12, 0.6), Geo.conduit_material())
	world_label("F  /  LOWER THE SPAN", Vector3(46, 6.5, -4.6), Color("78d5dd"), 20)
	floor_block("SpanLanding", 54, 3.0, 4)
	floor_block("UpperStep", 58, 3.6, 3)
	floor_block("DepthCourt", 62, 3.6, 4, 7)
	lift = ChronoLift.new()
	lift.name = "ChronoLift"
	lift.position = Vector3(67, 3.35, -2)
	add_child(lift)
	for x in [65.4, 68.6]:
		Geo.box(self, Vector3(x, 4.3, -4.0), Vector3(0.1, 3.7, 0.1), trim_material)
	Geo.box(self, Vector3(67, 6.2, -4.0), Vector3(3.4, 0.15, 0.2), Geo.conduit_material())
	floor_block("LiftLanding", 71, 5.4, 4, 3.2, -2)
	floor_block("FinalAnchorFloor", 76, 5.4, 6, 7)
	anchor_visual(ANCHORS[3])
	world_label("THE CLOCKWORK SPAN", Vector3(60, 7, -4.6), Color("bac9cb"))

func _build_daylight_run() -> void:
	floor_block("RunStepA", 81, 6.0, 3)
	floor_block("RunStepB", 85, 6.6, 3)
	crumble("RunCrumble", Vector3(89, 6.95, 0), 0.75)
	floor_block("RunStepC", 93, 7.8, 3)
	floor_block("RunStepD", 97, 8.4, 3)
	floor_block("DaylightFloor", 103, 8.4, 8, 6)
	# A low slit across the full floor is crossed only as a 1D line.
	Geo.box(self, Vector3(102, 10.0, 0), Vector3(0.75, 2.64, 7.5), floor_material, true)
	Geo.box(self, Vector3(102, 8.69, 0), Vector3(0.8, 0.045, 7.6), trim_material)
	Geo.box(self, Vector3(102.5, 8.56, 0), Vector3(6.0, 0.035, 0.065), Geo.conduit_material())
	for z in [-3.1, 3.1]:
		var wall := Geo.box(self, Vector3(103, 9.5, z), Vector3(8, 2.2, 0.25), floor_material, true)
		if z > 0: foreground_walls.append(wall)
	world_label("THE DAYLIGHT RUN", Vector3(85, 10.5, -4.6), Color("ead7a1"))
	# Open stone arch and sunlit exit, reusing the game's portal language.
	for z in [-2.4, 2.4]:
		Geo.column(self, Vector3(106.3, 8.4, z), 0.35, 4.8, floor_material, coping_material, trim_material)
	Geo.box(self, Vector3(106.3, 13.1, 0), Vector3(0.7, 0.5, 5.5), trim_material)
	exit_light = OmniLight3D.new()
	exit_light.position = Vector3(106, 11, 0)
	exit_light.light_color = Color("ffe1a3")
	exit_light.light_energy = 2.2
	exit_light.omni_range = 9
	add_child(exit_light)
	Geo.box(self, Vector3(107.2, 10.6, 0), Vector3(0.02, 4.4, 4.5), Geo.material(Color("e9dbae"), true))
	rising_void = RisingVoid.new()
	rising_void.name = "RisingVoid"
	rising_void.position = Vector3(92, -5, 0)
	rising_void.rise_speed = 0.35
	rising_void.is_active = false
	var shape := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = Vector3(38, 1, 18)
	shape.shape = bounds
	rising_void.add_child(shape)
	add_child(rising_void)
	Geo.box(rising_void, Vector3.ZERO, bounds.size, Geo.material(Color("376477"), true))
	rising_void.player_consumed.connect(func(_body): player.die())

func anchor_visual(at: Vector3) -> void:
	var material := Geo.conduit_material()
	Geo.box(self, at + Vector3(0, -0.02, 0), Vector3(1.8, 0.02, 0.06), material)
	Geo.box(self, at + Vector3(0, -0.02, 0), Vector3(0.06, 0.02, 1.8), material)
	world_label("TIME ANCHOR", at + Vector3(0, 1.8, -1.5), Color("91d9de"), 16)

func world_label(text: String, at: Vector3, color: Color, font_size: int = 26) -> void:
	var label := Label3D.new()
	label.text = text
	label.position = at
	label.font_size = font_size
	label.pixel_size = 0.013
	label.modulate = color
	label.outline_size = 5
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func rail_near(at: Vector3) -> Dictionary:
	if at.x >= 99.5 and at.x <= 105.5 and absf(at.z) < 0.45 and absf(at.y - 8.4) < 0.25:
		return {"start": 99.5, "end": 105.5, "y": 8.56, "z": 0.0, "floor_y": 8.4}
	return {}

func interact() -> void:
	if player.position.distance_to(Vector3(45.2, 2.4, -1.8)) < 3.2:
		monolith.trigger_topple()
		hud.show_hint("The monolith becomes a bridge. Its motion, like the lift, can be rewound with R.")
	else: hud.show_hint("F operates the glowing lever beside the Clockwork Span.", 4)

func _physics_process(_delta: float) -> void:
	if won or respawning or Global.is_rewinding: return
	var x := player.position.x
	if player.position.y < checkpoint_pos.y - 4.5 or absf(player.position.z) > 9:
		player.die()
		return
	if player.is_on_floor():
		if checkpoint_index < 1 and x >= 23: set_checkpoint(1)
		if checkpoint_index < 2 and sun_gate.is_open and x >= 40: set_checkpoint(2)
		if checkpoint_index < 3 and x >= 74 and player.position.y > 5.2: set_checkpoint(3)
		if x >= 106 and player.position.y > 8.2 and player.mode != 1:
			complete_escape()
			return
	if x > 77.5 and not timer_started:
		timer_started = true
		rising_void.position.y = 1.0
		rising_void.is_active = true
		hud.show_hint("The void is rising. Rewind your mistakes, cross the broken stair, and follow the daylight.", 9)
	var next_sector := 0 if x < 26 else (1 if x < 44 else (2 if x < 78 else 3))
	if sector != next_sector:
		sector = next_sector
		hud.section_label.text = SECTOR_TITLES[sector]
	if x > 10 and not shown.has("crumble"):
		shown.crumble = true
		hud.show_hint("Cyan-edged floors crumble underfoot. Hold R before you fall too far; the stone and John return together.", 10)
	if x > 27 and not shown.has("echo"):
		shown.echo = true
		hud.show_hint("3D [3] reaches both seals. Stand on A for a moment, hold R, then release. Your echo can hold A while you reach B.", 14)
	if x > 43 and not shown.has("span"):
		shown.span = true
		hud.show_hint("F lowers the monolith into a bridge. Cross it in 2D [2]; R restores its earlier shape.", 10)
	if x > 61 and not shown.has("lift"):
		shown.lift = true
		hud.show_hint("In 3D [3], step toward the rear lift. Return to 2D [2], ride it upward, then jump to the high landing.", 11)
	if x > 99 and not shown.has("rail"):
		shown.rail = true
		hud.show_hint("One last seal. Align with the cyan rail in 3D, become a line [1], then expand [2] past the stone.", 10)
	for i in plates_material.size():
		var active := sun_gate.a_pressed if i == 0 else sun_gate.b_pressed
		plates_material[i].albedo_color = Color("8ce3da") if active else Color("826745")

func set_checkpoint(index: int) -> void:
	if index <= checkpoint_index: return
	checkpoint_index = index
	checkpoint_pos = ANCHORS[index]
	Global.current_checkpoint_pos = checkpoint_pos
	Global.chamber_states.daylight_escape.anchor = index
	# The gate signal commits progress; it must not teleport John through it.
	player.rewind_controller.reset_timeline()
	for entity in get_tree().get_nodes_in_group("rewindable"): entity.history.clear()
	checkpoint_changed.emit(index)
	SoundManager.play_sfx("unlock")

func respawn() -> void:
	if won or respawning: return
	respawning = true
	player.rewind_controller.reset_timeline()
	for entity in get_tree().get_nodes_in_group("rewindable"): entity.reset_timeline()
	player.reset_at(checkpoint_pos)
	rising_void.is_active = false
	rising_void.position.y = -5
	timer_started = false
	focus = player.position + Vector3(2, 1, 0)
	_update_camera(1.0)
	hud.show_hint("Back at the time anchor. Floors are restored and the Chrono-Lens is recharged.", 6)
	respawning = false

func retry() -> void:
	get_tree().paused = false
	respawn()

func toggle_pause() -> void:
	if won: return
	get_tree().paused = not get_tree().paused

func complete_escape() -> void:
	if won: return
	won = true
	rising_void.is_active = false
	player.rewind_controller.reset_timeline()
	Global.rewind_unlocked = false
	player.locked = true
	Global.chamber_states.chamber_3.escaped = true
	Global.chamber_states.daylight_escape.escaped = true
	escaped.emit()
	SoundManager.play_sfx("victory")
	hud.show_hint("The sky is yours. Length, width, height ... and time.", 6)
	if transition_on_win:
		await get_tree().create_timer(1.4).timeout
		SceneTransition.change_chamber("res://scenes/ui/EndingCutscene.tscn")

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera): return
	# Keep solid boundary collision while removing foreground visual obstruction.
	for wall in foreground_walls: wall.visible = false
	var volume := player.mode == 3
	var blend := minf(1.0, delta * 6.0)
	camera_yaw = lerpf(camera_yaw, -24.0 if volume else 0.0, blend)
	camera_pitch = lerpf(camera_pitch, -20.0 if volume else 0.0, blend)
	var target := player.position + Vector3(2.2, 1.25, 0)
	focus = focus.lerp(target, minf(1.0, delta * 5.0))
	var offset := Vector3(0, 0, 26).rotated(Vector3.RIGHT, deg_to_rad(camera_pitch)).rotated(Vector3.UP, deg_to_rad(camera_yaw))
	camera.position = focus + offset
	camera.look_at(focus)
	camera.size = lerpf(camera.size, 7.3 if volume else 6.5, blend)
