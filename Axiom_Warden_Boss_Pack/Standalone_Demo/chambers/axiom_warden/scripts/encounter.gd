extends Node3D
## Five successful strikes, false defeat, one revival, one finishing strike.
signal boss_hit(total: int)
signal chamber_completed

const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
const Player = preload("res://chambers/axiom_warden/scripts/player.gd")
const Warden = preload("res://chambers/axiom_warden/scripts/warden.gd")
const Hazard = preload("res://chambers/axiom_warden/scripts/hazard.gd")
const Hud = preload("res://chambers/axiom_warden/scripts/hud.gd")
const START: Vector3 = Vector3(-35, -2.35, 0)
const CHECKPOINT: Vector3 = Vector3(-8, 0.06, 0)
const TITLES: Array[String] = ["I / THE MEASURE", "II / THE EDGE", "III / THE PLANE", "IV / THE VOLUME", "V / THE FRACTURE", "VI / LAST DECREE"]
const TAUNTS: Array[String] = ["A line can still cut stone.", "Then I shall sweep away your hiding place.", "You slip between my laws...", "I will close every path.", "The seal... cannot... break."]

var player: Player
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
var focus: Vector3 = START
var camera_blend: float = 1
var message_timer: float = 0
var auto_start: bool = false

func _ready() -> void:
	_build_world()
	player = Player.new()
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
	var stone: Material = Geo.material(Color("6c4b2a"))
	var tile_a: Material = Geo.material(Color("927043"))
	var tile_b: Material = Geo.material(Color("89653a"))
	var gold: Material = Geo.material(Color("d0a156"))
	var dark: Material = Geo.material(Color("362617"))
	var cyan: Material = Geo.material(Color("48cbbf"), true)
	var environment_node: WorldEnvironment = WorldEnvironment.new()
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("170f09")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d6b78a")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment_node.environment = env
	add_child(environment_node)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_color = Color("ffe0ac")
	light.light_energy = 1.15
	light.shadow_enabled = true
	add_child(light)
	# A short four-terrace ascent, generous landings, one-unit gaps, 0.6-unit rises.
	var terraces: Array[Vector3] = [Vector3(-33, -2.4, 8), Vector3(-26, -1.8, 4), Vector3(-21, -1.2, 4), Vector3(-16, -0.6, 4)]
	for t: Vector3 in terraces:
		Geo.box(self, Vector3(t.x, t.y - 1.5, 0), Vector3(t.z, 3, 5.5), stone, true)
		Geo.box(self, Vector3(t.x, t.y - 0.05, 0), Vector3(t.z + 0.08, 0.1, 5.6), gold)
		for x: int in int(t.z):
			for z: int in 5:
				Geo.box(self, Vector3(t.x - t.z / 2 + x + 0.5, t.y + 0.015, z - 2.0), Vector3(0.96, 0.035, 0.96), tile_a if (x + z) % 2 == 0 else tile_b)
	Geo.box(self, Vector3(1, -1.0, 0), Vector3(28, 2, 14), stone, true)
	for x: int in 14:
		for z: int in 7:
			Geo.box(self, Vector3(-12 + x * 2, 0.012, -6 + z * 2), Vector3(1.96, 0.025, 1.96), tile_a if (x + z) % 2 == 0 else tile_b)
	# Visible rails are useful shelter from HIGH attacks, but LOW attacks intersect them.
	for z: float in [-4.0, 0.0, 4.0]:
		Geo.box(self, Vector3(1.3, 0.04, z), Vector3(24.5, 0.06, 0.30), dark)
		Geo.box(self, Vector3(1.3, 0.08, z), Vector3(24.5, 0.035, 0.065), cyan)
		for x: float in [-10.8, 13.4]:
			Geo.box(self, Vector3(x, 0.08, z), Vector3(0.45, 0.08, 0.5), gold)
	for z: float in [-7.0, 7.0]:
		Geo.box(self, Vector3(1, 0.16, z), Vector3(28.4, 0.32, 0.3), gold)
	for x: float in [-11.0, -5.0, 1.0, 7.0, 13.0]:
		Geo.box(self, Vector3(x, 2.2, -8), Vector3(1.0, 4.4, 1.0), stone)
		Geo.box(self, Vector3(x, 4.45, -8), Vector3(1.35, 0.24, 1.35), gold)
		Geo.box(self, Vector3(x, 2.5, -7.47), Vector3(0.13, 1.6, 0.05), gold)
		Geo.ring(self, Vector3(x, 3.45, -7.4), 0.23, 0.025, gold).rotation_degrees.x = 90
	Geo.box(self, Vector3(1, 0.7, -8), Vector3(27, 1.4, 0.55), dark)
	# End portal and its seal stay closed until the sixth, final strike.
	for z: float in [-2.1, 2.1]:
		Geo.box(self, Vector3(14.5, 2.5, z), Vector3(0.8, 5, 0.8), stone)
	Geo.box(self, Vector3(14.5, 5, 0), Vector3(1, 0.4, 5.1), gold)
	exit_seal = Geo.box(self, Vector3(14.5, 2.0, 0), Vector3(0.15, 4.0, 3.4), Geo.material(Color("39685d"), true))
	gate = Geo.box(self, Vector3(-12.7, 1.7, 0), Vector3(0.18, 3.4, 5.5), Geo.material(Color("367d75"), true))
	gate.visible = false
	var ring: MeshInstance3D = Geo.ring(self, Vector3(9, 0.06, 0), 2.5, 0.035, gold)
	ring.name = "WardenDais"
	var checkpoint_ring: MeshInstance3D = Geo.ring(self, Vector3(-8, 0.04, 0), 0.65, 0.045, cyan)
	checkpoint_ring.name = "Checkpoint"

func _physics_process(delta: float) -> void:
	state_time += delta
	message_timer = maxf(0, message_timer - delta)
	if state == "approach":
		if player.position.x > -27 and player.is_on_floor(): platform_checkpoint = Vector3(-26, -1.75, 0)
		if player.position.x > -22 and player.is_on_floor(): platform_checkpoint = Vector3(-21, -1.15, 0)
		if player.position.x > -17 and player.is_on_floor(): platform_checkpoint = Vector3(-16, -0.55, 0)
		if player.position.x > -10.0 and player.is_on_floor(): begin_intro()
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
			sfx("unlock")
	elif state == "opening":
		# Final opening remains available; early missed openings repeat the same phase.
		if hits < 5 and state_time > 7.0: begin_phase()
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
		# Contact is volumetric; all explicit weapon/energy hazards are geometric.
		hurt_player()
	_update_hud()

func _process(delta: float) -> void:
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera): return
	var in_arena: bool = state != "approach"
	var flat: bool = player.mode == 2
	var goal: Vector3 = Vector3(1.0, 1.6, 0) if in_arena else player.position + Vector3(2.2, 1.4, 0)
	var target_size: float = (18.5 if not flat else 17.0) if in_arena else 9.5
	if state in ["dialogue", "draw_weapon", "revival_dialogue"]:
		goal = Vector3(1.0, 1.8, 0)
		target_size = 15.5
	focus = focus.lerp(goal, minf(delta * 5, 1.0))
	camera_blend = lerpf(camera_blend, 0.0 if flat else 1.0, minf(delta * 7, 1))
	var offset: Vector3 = Vector3(0, 0, 24).lerp(Vector3(-12, 15, 18), camera_blend)
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
		sfx("transform")
		show_message("John draws a rod of light from the Chrono-Lens.")
	else:
		boss.set_pose("revive")
		begin_phase()

func events_for_phase(index: int) -> Array[Dictionary]:
	match index:
		0: return [{"time": 1.0, "kind": "bolts"}, {"time": 3.5, "kind": "sweep"}]
		1: return [{"time": 0.8, "kind": "sweep"}, {"time": 3.2, "kind": "beam"}, {"time": 5.4, "kind": "bolts"}]
		2: return [{"time": 0.8, "kind": "beam"}, {"time": 3.2, "kind": "lane"}, {"time": 5.4, "kind": "sweep"}]
		3: return [{"time": 0.8, "kind": "lane"}, {"time": 3.4, "kind": "bolts"}, {"time": 5.8, "kind": "beam"}, {"time": 8.0, "kind": "sweep"}]
		4: return [{"time": 0.8, "kind": "sweep"}, {"time": 3.0, "kind": "beam"}, {"time": 5.2, "kind": "lane"}, {"time": 7.6, "kind": "bolts"}, {"time": 10.0, "kind": "sweep"}]
	return [{"time": 1.0, "kind": "sweep"}, {"time": 3.3, "kind": "beam"}, {"time": 5.6, "kind": "bolts"}, {"time": 8.2, "kind": "lane"}, {"time": 10.5, "kind": "sweep"}, {"time": 12.8, "kind": "beam"}]

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
	pattern_end = float(pattern[-1].time) + (4.6 if str(pattern[-1].kind) == "bolts" else 4.3)
	_set_state("surge" if hits == 5 else "combat")
	hud.fight_visible = true
	show_message("FINAL SURGE — survive the last decree." if hits == 5 else TITLES[hits])

func spawn_attack(kind: String) -> void:
	boss.set_pose(kind)
	match kind:
		"sweep":
			spawn_hazard("sweep", Vector3(9, 0.85, 0), 1.05, 3.0)
			show_message("HIGH SWEEP — jump, or flatten onto a cyan rail with 1.")
		"beam":
			spawn_hazard("beam", Vector3(1, 0.20, player.position.z), 1.3, 0.65)
			show_message("LOW LASER — 1D is exposed. Press 2 + SPACE, or sidestep in 3D.")
		"lane":
			spawn_hazard("lane", Vector3(1, 1.55, player.position.z), 1.45, 0.7)
			show_message("DEPTH LOCK — press 3 and leave the amber floor lane.")
		"bolts":
			var count: int = 3 if hits < 3 else 5
			for i: int in count:
				var h: Hazard = spawn_hazard("bolt", Vector3(7.8, 0.95, (i - (count - 1) * 0.5) * 0.5), 0.85, 3.6)
				var aim: Vector3 = player.position - h.position
				aim.y = 0
				h.direction = aim.normalized().rotated(Vector3.UP, (i - (count - 1) * 0.5) * 0.14)
				h.speed = 6.5 + hits * 0.25
			show_message("PRISM VOLLEY — jump in 2D, sidestep in 3D, or slide under in 1D.")
	sfx("transform")

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
	sfx("transform")

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
