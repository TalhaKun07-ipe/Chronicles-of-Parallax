extends Node3D
## Five successful strikes, false defeat, one revival, one finishing strike.
signal boss_hit(total: int)
signal chamber_completed

const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
const AxiomPlayer = preload("res://chambers/axiom_warden/scripts/player.gd")
const Warden = preload("res://chambers/axiom_warden/scripts/warden.gd")
const Hazard = preload("res://chambers/axiom_warden/scripts/hazard.gd")
const Hud = preload("res://chambers/axiom_warden/scripts/hud.gd")
const START: Vector3 = Vector3(-35, -2.35, 0)
const CHECKPOINT: Vector3 = Vector3(-8, 0.06, 0)
const TITLES: Array[String] = ["I / THE MEASURE", "II / THE EDGE", "III / THE PLANE", "IV / THE VOLUME", "V / THE FRACTURE", "VI / LAST DECREE"]
const TAUNTS: Array[String] = ["A line can still cut stone.", "Then I shall sweep away your hiding place.", "You slip between my laws...", "I will close every path.", "The seal... cannot... break."]

var player: CharacterBody3D
var boss: Warden
var hud: Hud
var camera: Camera3D
var hazards: Node3D
var state: String = "approach"
var hits: int = 0
var health: int = 3
var phase_time: float = 0
var state_time: float = 0
var next_event: int = 0
var pattern: Array[Dictionary] = []
var pattern_end: float = 0
var core_open: bool = false
var arena_checkpoint: bool = false
var platform_checkpoint: Vector3 = START
var dialogue_pages: Array[Dictionary] = []
var dialogue_index: int = 0
var dialogue_reason: String = "intro"
var defeated_count: int = 0
var gate: MeshInstance3D
var exit_seal: MeshInstance3D
var fragile_bridge: Node3D
var fragile_bridge_broken: bool = false
var focus: Vector3 = START
var camera_blend: float = 1
var message_timer: float = 0
var auto_start: bool = false

func _ready() -> void:
	_build_world()
	player = AxiomPlayer.new()
	player.name = "Player"
	player.position = START
	add_child(player)
	player.struck.connect(try_strike)
	player.fell.connect(_fall)
	player.mode_changed.connect(_dimension_changed)
	player.notice.connect(show_message)
	boss = Warden.new()
	boss.name = "AxiomWarden"
	boss.position = Vector3(9, 0, 0)
	add_child(boss)
	hazards = Node3D.new()
	hazards.name = "Hazards"
	add_child(hazards)
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.name = "EncounterHUD"
	add_child(canvas)
	hud = Hud.new()
	canvas.add_child(hud)
	hud.advance_requested.connect(advance_dialogue)
	hud.skip_requested.connect(skip_dialogue)
	hud.pause_requested.connect(toggle_pause)
	hud.retry_requested.connect(retry)
	hud.voice_tick.connect(func() -> void: sfx("typewriter"))
	camera = Camera3D.new()
	camera.name = "ChamberCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.5
	camera.current = true
	add_child(camera)
	_sync_health()
	var global: Node = get_node_or_null("/root/Global")
	if global:
		global.set("current_chamber_id", "axiom_warden")
		global.set("rewind_unlocked", false)
		global.set("is_rewinding", false)
	_dimension_changed(3)
	var transition: Node = get_node_or_null("/root/SceneTransition")
	if transition and transition.has_method("fade_in_from_black"):
		transition.call("fade_in_from_black", 0.4)
	_update_camera(1.0)

func _build_world() -> void:
	var stone: Material = Geo.stone_material(Color("6c4b2a"))
	var paver: Material = Geo.stone_material(Color("89653a"))
	var shadow: Material = Geo.stone_material(Color("382312"))
	var gold: Material = Geo.material(Color("d0a156"))
	var ochre: Material = Geo.material(Color("c29f5c"))
	var dark: Material = Geo.material(Color("261708"))
	var cyan: Material = Geo.material(Color("48cbbf"), true)
	var amber: Material = Geo.material(Color("d9973e"), true)

	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("18120d")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("e2cca0")
	env.ambient_light_energy = 0.52
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.15
	environment_node.environment = env
	add_child(environment_node)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_color = Color("fff3dd")
	sun.light_energy = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 80
	add_child(sun)

	var fill: DirectionalLight3D = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 150, 0)
	fill.light_color = Color("bca068")
	fill.light_energy = 0.28
	add_child(fill)

	# 1. SCREEN-FILLING ARCHITECTURAL FOUNDATION (Zero Black Space)
	# Continuous Lower Abyss Canyon Floor: Spans X=-65 to +35, Z=-25 to +25 at Y=-5.5
	Geo.box(self, Vector3(-15, -6.5, 0), Vector3(105, 2.0, 50), shadow, true)

	# Massive Cavern Backdrop: Spans X=-70 to +40, height Y=-5 to +14 at Z=-13.5
	Geo.box(self, Vector3(-15, 4.5, -13.5), Vector3(110, 18.0, 1.2), shadow)

	# Perimeter Sanctuary Back Wall: Along Z=-8.5 from X=-60 to +30, height Y=0 to 7.0
	Geo.masonry_block(self, Vector3(-15, 3.5, -8.5), Vector3(100, 7.0, 1.2), stone, paver, gold, true)

	# Perimeter Low Retaining Front Wall: Along Z=+8.5 from X=-60 to +30, height Y=0 to 1.5
	var front_wall: Node3D = Geo.masonry_block(self, Vector3(-15, 0.75, 8.5), Vector3(100, 1.5, 0.8), stone, paver, gold, false)
	front_wall.add_to_group("fg_walls")

	# Side Limit Walls
	Geo.box(self, Vector3(-58, 4.0, 0), Vector3(1.2, 9.0, 18.0), stone, true)
	Geo.box(self, Vector3(28, 4.0, 0), Vector3(1.2, 9.0, 18.0), stone, true)

	# Ruined Architectural Columns along Back Wall
	for x in range(-50, 26, 5):
		Geo.column(self, Vector3(x, 0.0, -8.2), 0.5, 7.0, stone, paver, gold)
		if x in [-45, -35, -25, -15, -5, 5, 15]:
			Geo.torch(self, Vector3(x, 3.2, -7.9))

	# 2. STEPPED MULTI-DIMENSIONAL PLATFORMING APPROACH
	# Terrace 0 / Arrival Antechamber: X in [-38, -29.25], top Y=-2.4
	Geo.masonry_block(self, Vector3(-34, -3.9, 0), Vector3(9.5, 3.0, 12.0), stone, paver, gold, true)
	# Wake Plate at arrival
	Geo.box(self, Vector3(-35, -2.36, 0), Vector3(1.4, 0.08, 1.4), ochre, false)
	Geo.box(self, Vector3(-35, -2.32, 0), Vector3(0.9, 0.04, 0.9), amber, false)
	# Lower Conduit Rail Dock
	Geo.box(self, Vector3(-33, -2.34, 0), Vector3(5.5, 0.05, 0.16), cyan, false)

	# Terrace 1: X in [-28, -23], top Y=-1.8
	Geo.masonry_block(self, Vector3(-25.5, -3.6, 0), Vector3(5.5, 3.6, 12.0), stone, paver, gold, true)
	# Terrace 2: X in [-21, -17], top Y=-1.2
	Geo.masonry_block(self, Vector3(-19.0, -3.3, 0), Vector3(4.5, 4.2, 12.0), stone, paver, gold, true)
	# Approach Monolith: blocks straight 2D walking on Z=0, requiring 3D depth navigation
	var approach_monolith: Node3D = Geo.box(self, Vector3(-19.0, 0.4, 0.5), Vector3(1.0, 3.2, 3.5), stone, true)
	approach_monolith.name = "ApproachMonolith"

	# Terrace 3: X in [-15, -12.5], top Y=-0.6
	Geo.masonry_block(self, Vector3(-13.75, -3.0, 0), Vector3(3.0, 4.8, 12.0), stone, paver, gold, true)

	# Decorative Inset Floor Pavers on terraces
	for t: Vector3 in [Vector3(-33, -2.4, 8), Vector3(-26, -1.8, 4), Vector3(-21, -1.2, 4), Vector3(-16, -0.6, 4)]:
		for x_idx: int in int(t.z):
			for z_idx: int in 5:
				Geo.box(self, Vector3(t.x - t.z / 2 + x_idx + 0.5, t.y + 0.015, z_idx - 2.0), Vector3(0.96, 0.035, 0.96), paver if (x_idx + z_idx) % 2 == 0 else stone)

	# Fragile Bridge into Sanctum Arena: X in [-12.5, -8.0], top Y=0.0
	fragile_bridge = Geo.masonry_block(self, Vector3(-10.25, -2.5, 0), Vector3(4.5, 5.0, 7.0), stone, paver, gold, true)
	fragile_bridge.name = "FragileBridge"

	# Grand Sanctum Entrance Gate Archway
	for z_side: float in [-2.5, 2.5]:
		var arch_col: Node3D = Geo.column(self, Vector3(-12.0, 0.0, z_side), 0.45, 5.5, stone, paver, gold)
		if z_side > 0:
			arch_col.add_to_group("fg_walls")
	Geo.box(self, Vector3(-12.0, 4.8, 0), Vector3(1.2, 0.6, 5.5), gold)
	gate = Geo.box(self, Vector3(-12.0, 2.0, 0), Vector3(0.2, 4.0, 4.8), Geo.material(Color("367d75"), true))
	gate.visible = false

	# 3. GRAND SANCTUM ARENA FLOOR (X in [-8, 20], Z in [-7, 7], Y=0.0)
	Geo.masonry_block(self, Vector3(6, -2.5, 0), Vector3(28, 5.0, 14.5), stone, paver, gold, true)
	for x_idx: int in 14:
		for z_idx: int in 7:
			Geo.box(self, Vector3(-7 + x_idx * 2, 0.012, -6 + z_idx * 2), Vector3(1.96, 0.025, 1.96), paver if (x_idx + z_idx) % 2 == 0 else stone)

	# 3 Continuous Rails across Arena floor (Z = -4.0, 0.0, +4.0)
	for z: float in [-4.0, 0.0, 4.0]:
		Geo.box(self, Vector3(6.0, 0.04, z), Vector3(26.0, 0.06, 0.30), dark)
		Geo.box(self, Vector3(6.0, 0.08, z), Vector3(26.0, 0.035, 0.065), cyan)
		for x_end: float in [-6.8, 18.8]:
			Geo.box(self, Vector3(x_end, 0.08, z), Vector3(0.45, 0.08, 0.5), gold)

	# Perimeter gold coping curbs
	for z: float in [-7.1, 7.1]:
		var curb: Node3D = Geo.box(self, Vector3(6.0, 0.16, z), Vector3(28.0, 0.32, 0.3), gold)
		if z > 0:
			curb.add_to_group("fg_walls")

	# Exit Portal Archway
	for z: float in [-2.1, 2.1]:
		var p_col: Node3D = Geo.box(self, Vector3(14.5, 2.5, z), Vector3(0.8, 5, 0.8), stone)
		if z > 0:
			p_col.add_to_group("fg_walls")
	Geo.box(self, Vector3(14.5, 5, 0), Vector3(1, 0.4, 5.1), gold)
	exit_seal = Geo.box(self, Vector3(14.5, 2.0, 0), Vector3(0.15, 4.0, 3.4), Geo.material(Color("39685d"), true))

	# Dais and Checkpoint rings
	var ring: MeshInstance3D = Geo.ring(self, Vector3(9, 0.06, 0), 2.5, 0.035, gold)
	ring.name = "WardenDais"
	var checkpoint_ring: MeshInstance3D = Geo.ring(self, Vector3(-8, 0.04, 0), 0.65, 0.045, cyan)
	checkpoint_ring.name = "Checkpoint"

func _physics_process(delta: float) -> void:
	state_time += delta
	message_timer = maxf(0, message_timer - delta)
	update_occlusion(player.position.z)
	if state == "approach":
		if not fragile_bridge_broken and player.position.x >= -12.0:
			fragile_bridge_broken = true
			sfx("stone_grind")
			if is_instance_valid(fragile_bridge):
				for c in fragile_bridge.find_children("*", "CollisionShape3D", true, false):
					c.disabled = true
				var tw := create_tween()
				tw.tween_property(fragile_bridge, "position:y", fragile_bridge.position.y - 12.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		if player.position.x > -27 and player.is_on_floor(): platform_checkpoint = Vector3(-26, -1.75, 0)
		if player.position.x > -22 and player.is_on_floor(): platform_checkpoint = Vector3(-21, -1.15, 0)
		if player.position.x > -17 and player.is_on_floor(): platform_checkpoint = Vector3(-16, -0.55, 0)
		if player.position.x > -8.0 and player.is_on_floor(): begin_intro()
	elif state == "draw_weapon":
		player.armed = true
		player.weapon.scale.x = clampf(state_time / 0.8, 0.05, 1.0)
		if state_time > 1.4: begin_phase()
	elif state == "combat" or state == "surge":
		phase_time += delta
		while next_event < pattern.size() and phase_time >= float(pattern[next_event].time):
			spawn_attack(str(pattern[next_event].kind))
			next_event += 1
		if phase_time >= pattern_end:
			clear_hazards()
			core_open = true
			boss.exposed = true
			boss.set_pose("idle")
			_set_state("opening")
			show_message("CORE EXPOSED — get close in 1D or 2D and press F.")
			sfx("boss_core_open")
	elif state == "opening":
		# Concrete difficulty adjustment: recovery window increased by 20% (7.0s -> 8.4s)
		if hits < 5 and state_time > 8.4: begin_phase()
	elif state == "stagger":
		if state_time > 1.25: begin_phase()
	elif state == "false_defeat":
		if state_time > 2.5: begin_revival()
	elif state == "collapse":
		if state_time > 2.0:
			_set_state("victory")
			hud.victory = true
			exit_seal.visible = false
			chamber_completed.emit()
	if state in ["combat", "surge", "opening"] and player.mode == 3 and player.position.distance_to(boss.position) < 1.8:
		hurt_player()
	_update_hud()

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera): return
	var in_arena: bool = state != "approach"
	var flat: bool = player.mode == 2
	var goal: Vector3
	var target_size: float
	if not in_arena:
		# Close tracking during platforming approach - screen filled with rich masonry
		goal = player.position + Vector3(1.2, 0.9, 0)
		target_size = 6.8
	else:
		if state in ["dialogue", "draw_weapon", "revival_dialogue"]:
			goal = Vector3(2.5, 1.4, 0.0)
			target_size = 9.2
		else:
			# Screen-filling arena framing: frames John & Warden heroically with zero void borders
			goal = Vector3(2.0, 1.2, 0.0)
			target_size = 11.6 if not flat else 10.4
	focus = focus.lerp(goal, minf(delta * 5, 1.0))
	camera_blend = lerpf(camera_blend, 0.0 if flat else 1.0, minf(delta * 7, 1))
	var offset: Vector3 = Vector3(0, 0, 20).lerp(Vector3(-10, 13, 15), camera_blend)
	camera.position = focus + offset
	camera.look_at(focus)
	camera.size = lerpf(camera.size, target_size, minf(delta * 5, 1))

func _set_state(value: String) -> void:
	state = value
	state_time = 0

func begin_intro() -> void:
	arena_checkpoint = true
	player.arena_active = true
	player.locked = true
	player.reset_at(CHECKPOINT)
	health = 3
	_sync_health()
	gate.visible = true
	dialogue_reason = "intro"
	dialogue_pages = [
		{"speaker": "AXIOM WARDEN", "text": "That watch held this sanctuary together. You pulled it free."},
		{"speaker": "JOHN ROD", "text": "I didn't know. I'm trying to find a way out."},
		{"speaker": "AXIOM WARDEN", "text": "Then return the Chrono-Lens. No stolen freedom passes this gate."},
		{"speaker": "JOHN ROD", "text": "You want me to become a point again? ...No. I'm leaving on my own two feet."},
		{"speaker": "AXIOM WARDEN", "text": "Hide in a line. Flatten into a plane. My blade and my light will still find you."},
		{"speaker": "JOHN ROD", "text": "The watch is shaping something... A rod of light. All right. Let's see what it can do."}
	]
	dialogue_index = 0
	_set_state("dialogue")
	_show_page()

func _show_page() -> void:
	var page: Dictionary = dialogue_pages[dialogue_index]
	hud.say(str(page.speaker), str(page.text))

func advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_pages.size(): finish_dialogue()
	else: _show_page()

func skip_dialogue() -> void:
	finish_dialogue()

func finish_dialogue() -> void:
	if state not in ["dialogue", "revival_dialogue"]: return
	hud.dialogue_visible = false
	if dialogue_reason == "intro":
		_set_state("draw_weapon")
		player.armed = true
		player.weapon.scale.x = 0.05
		sfx("unlock")
		show_message("John draws a rod of light from the Chrono-Lens.")
	else:
		boss.set_pose("revive")
		begin_phase()

func events_for_phase(index: int) -> Array[Dictionary]:
	match index:
		0: return [{"time": 0.4, "kind": "bolts"}, {"time": 2.0, "kind": "sweep"}]
		1: return [{"time": 0.4, "kind": "sweep"}, {"time": 1.9, "kind": "guardian"}, {"time": 3.4, "kind": "beam"}]
		2: return [{"time": 0.4, "kind": "beam"}, {"time": 1.8, "kind": "rising_wall"}, {"time": 3.2, "kind": "lane"}, {"time": 4.6, "kind": "slam"}]
		3: return [{"time": 0.4, "kind": "lane"}, {"time": 1.8, "kind": "guardian"}, {"time": 3.2, "kind": "dual_beam"}, {"time": 4.6, "kind": "rising_wall"}]
		4: return [{"time": 0.4, "kind": "nova"}, {"time": 2.0, "kind": "guardian"}, {"time": 3.4, "kind": "rising_wall"}, {"time": 4.8, "kind": "sweep"}, {"time": 6.2, "kind": "lane"}]
	# Phase 5: Final Surge ("VI / LAST DECREE") - synthesis of dimensional attacks
	return [
		{"time": 0.4, "kind": "rising_wall"},
		{"time": 1.8, "kind": "guardian"},
		{"time": 3.2, "kind": "slam"},
		{"time": 4.6, "kind": "lane"},
		{"time": 6.0, "kind": "rising_wall"},
		{"time": 7.4, "kind": "guardian"},
		{"time": 8.8, "kind": "nova"}
	]

func begin_phase() -> void:
	player.locked = false
	player.armed = true
	player.weapon.scale = Vector3.ONE
	core_open = false
	boss.exposed = false
	boss.set_pose("idle")
	phase_time = 0
	next_event = 0
	pattern = events_for_phase(hits)
	pattern_end = float(pattern[-1].time) + (2.4 if str(pattern[-1].kind) in ["bolts", "nova", "guardian", "rising_wall"] else 2.2)
	_set_state("surge" if hits == 5 else "combat")
	hud.fight_visible = true
	show_message("FINAL SURGE — survive the last decree." if hits == 5 else TITLES[hits])

func spawn_attack(kind: String) -> void:
	boss.set_pose(kind if kind in ["sweep", "slam", "nova"] else "beam")
	match kind:
		"sweep":
			# Concrete balance adjustment: 0.70s -> 0.85s warning (+21.4%)
			spawn_hazard("sweep", Vector3(9, 0.85, 0), 0.85, 2.4)
			show_message("HIGH SWEEP — jump in 2D, or flatten onto a cyan rail with 1.")
		"beam":
			# Concrete balance adjustment: 0.75s -> 0.90s warning (+20%)
			spawn_hazard("beam", Vector3(1, 0.20, player.position.z), 0.90, 0.60)
			show_message("LOW LASER — 1D is exposed. Press 2 + SPACE, or sidestep in 3D.")
		"dual_beam":
			# Concrete balance adjustment: 0.75s/0.85s -> 0.90s/1.02s warning (+20%)
			spawn_hazard("beam", Vector3(1, 0.20, player.position.z - 1.6), 0.90, 0.60)
			spawn_hazard("beam", Vector3(1, 0.20, player.position.z + 1.6), 1.02, 0.60)
			show_message("DUAL LASER GRID — find the safe gap or time your jump in 2D.")
		"lane":
			# Concrete balance adjustment: 0.80s -> 0.96s warning (+20%)
			spawn_hazard("lane", Vector3(1, 1.55, player.position.z), 0.96, 0.75)
			show_message("DEPTH LOCK — press 3 and leave the amber floor lane.")
		"slam":
			# Concrete balance adjustment: 0.65s -> 0.80s warning (+23%)
			spawn_hazard("slam", Vector3(9, 0.05, 0), 0.80, 2.4)
			show_message("SEISMIC SLAM — flatten into 2D and press SPACE to jump the shockwave!")
		"bolts":
			# Concrete balance adjustment: 0.60s -> 0.72s warning (+20%), speed -15%
			var count: int = 3 if hits < 3 else 5
			for i: int in count:
				var h: Hazard = spawn_hazard("bolt", Vector3(7.8, 0.95, (i - (count - 1) * 0.5) * 0.5), 0.72, 3.2)
				var aim: Vector3 = player.position - h.position
				aim.y = 0
				h.direction = aim.normalized().rotated(Vector3.UP, (i - (count - 1) * 0.5) * 0.14)
				h.speed = 8.0 + hits * 0.30
			show_message("PRISM VOLLEY — jump in 2D, sidestep in 3D, or slide under in 1D.")
		"nova":
			# Concrete balance adjustment: 0.65s -> 0.78s warning (+20%), speed -15%
			for i: int in 8:
				var h: Hazard = spawn_hazard("bolt", Vector3(9.0, 1.0, 0.0), 0.78, 3.2)
				var angle: float = i * (TAU / 8.0)
				h.direction = Vector3(cos(angle), 0, sin(angle))
				h.speed = 7.2 + hits * 0.25
			show_message("DIMENSIONAL NOVA — weave through the expanding prism burst!")
		"guardian":
			# Dedicated Flat Guardian projectile: becomes ethereal in 2D, solid in 3D
			var h: Hazard = spawn_hazard("guardian", Vector3(9.0, 0.0, player.position.z), 0.90, 4.5)
			h.direction = Vector3.LEFT
			h.speed = 6.2
			show_message("FLAT GUARDIAN — flatten into 2D with [2] to slip right through!")
		"rising_wall":
			# 3D Lateral Hazard: rising stone barrier player must navigate around
			var wall_z: float = clampf(roundf(player.position.z / 2.0) * 2.0, -4.0, 4.0)
			spawn_hazard("rising_wall", Vector3(clampf(player.position.x + 3.0, -2.0, 6.0), 0.0, wall_z), 1.20, 3.8)
			show_message("RISING WALL — navigate around in 3D across depth!")
	sfx("boss_warning")

func spawn_hazard(kind: String, at: Vector3, delay: float, lifetime: float) -> Hazard:
	var hazard: Hazard = Hazard.new()
	hazard.kind = kind
	hazard.position = at
	hazard.warning = delay
	hazard.duration = lifetime
	hazard.target = player
	hazards.add_child(hazard)
	hazard.hit_player.connect(hurt_player)
	return hazard

func try_strike() -> bool:
	if not player.armed or player.locked or state not in ["combat", "opening", "surge"]: return false
	if player.position.distance_to(Vector3(boss.position.x, player.position.y, boss.position.z)) > 2.8 or absf(player.position.y) > 1.4:
		show_message("Get closer to the Warden, then press F.")
		return false
	if player.mode == 3:
		show_message("3D armor deflects the rod. Strike in 1D or 2D.")
		sfx("error")
		return false
	if not core_open:
		show_message("Its core is sealed. Survive this pattern to expose it.")
		return false
	hits += 1
	core_open = false
	boss.exposed = false
	clear_hazards()
	boss_hit.emit(hits)
	sfx("hurt")
	if hits == 5:
		boss.set_pose("fallen")
		player.locked = true
		_set_state("false_defeat")
		show_message("The Warden falls silent...")
	elif hits == 6:
		boss.set_pose("dead")
		player.locked = true
		_set_state("collapse")
		sfx("victory")
		var global: Node = get_node_or_null("/root/Global")
		if global:
			global.set("rewind_unlocked", false)
	else:
		boss.set_pose("hit")
		_set_state("stagger")
		show_message(TAUNTS[hits - 1])
	return true

func begin_revival() -> void:
	clear_hazards()
	dialogue_reason = "revival"
	dialogue_pages = [
		{"speaker": "AXIOM WARDEN", "text": "Five seals broken... but my final law remains."},
		{"speaker": "JOHN ROD", "text": "Of course it does."},
		{"speaker": "AXIOM WARDEN", "text": "LET EVERY DIMENSION BURN."}
	]
	dialogue_index = 0
	_set_state("revival_dialogue")
	_show_page()

func hurt_player() -> void:
	if state not in ["combat", "surge", "opening"] or player.invulnerable > 0: return
	health = maxi(0, health - 1)
	player.invulnerable = 1.2
	_sync_health()
	sfx("hurt")
	if health == 0:
		clear_hazards()
		player.locked = true
		_set_state("defeated")
		hud.defeated = true
		defeated_count += 1

func _fall() -> void:
	if state == "approach":
		if fragile_bridge_broken or player.position.x >= -12.5:
			# Fell through collapsed fragile bridge into boss arena!
			begin_intro()
		else:
			player.reset_at(platform_checkpoint)
			show_message("The watch catches you. Try the next jump again.")
	else:
		player.reset_at(CHECKPOINT)
		player.invulnerable = 0
		hurt_player()

func retry() -> void:
	if state != "defeated": return
	clear_hazards()
	hits = 0
	health = 3
	hud.defeated = false
	hud.final_round = false
	player.reset_at(CHECKPOINT)
	player.arena_active = true
	player.armed = true
	boss.core.visible = true
	_sync_health()
	begin_phase()

func toggle_pause() -> void:
	hud.paused = not hud.paused
	get_tree().paused = hud.paused

func clear_hazards() -> void:
	for hazard: Node in hazards.get_children():
		hazard.set_physics_process(false)
		hazards.remove_child(hazard)
		hazard.queue_free()

func _sync_health() -> void:
	if is_instance_valid(hud): hud.health = health
	var global: Node = get_node_or_null("/root/Global")
	if global:
		# Do not call Global.take_damage: its legacy defeat handler reloads the approach.
		global.set("current_health", health)
		global.emit_signal("health_changed", health)

func _dimension_changed(mode: int) -> void:
	var global: Node = get_node_or_null("/root/Global")
	if global and global.has_method("set_dimension"):
		global.call("set_dimension", 4 if mode == 3 else mode)
	update_occlusion(player.position.z)
	sfx("transform")

func update_occlusion(player_z: float) -> void:
	var hide_foreground: bool = is_instance_valid(player) and player.mode == 2
	for node in get_tree().get_nodes_in_group("fg_walls"):
		if not is_ancestor_of(node): continue
		for mesh in node.find_children("*", "MeshInstance3D", true, false):
			if hide_foreground and node.global_position.z > player_z + 0.6:
				mesh.visible = false
			else:
				mesh.visible = true

func show_message(message: String) -> void:
	if is_instance_valid(hud): hud.objective = message
	message_timer = 3.0

func _update_hud() -> void:
	hud.health = health
	hud.dimension = player.mode
	hud.hits = hits
	hud.final_round = hits >= 5 and state != "false_defeat"
	hud.phase_name = TITLES[mini(hits, 5)]
	if core_open: hud.phase_name += "  /  CORE OPEN — F"

func sfx(cue: String) -> void:
	var sound: Node = get_node_or_null("/root/SoundManager")
	if sound and sound.has_method("play_sfx"): sound.call("play_sfx", cue)
