extends Node3D
## Articulated 3D interpretation of the approved Axiom Warden sprite design.
const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
var torso: Node3D
var axe_arm: Node3D
var emitter_arm: Node3D
var halo: MeshInstance3D
var core: MeshInstance3D
var left_door: Node3D
var right_door: Node3D
var core_light: OmniLight3D
var age: float = 0.0
var pose: String = "idle"
var pose_time: float = 0.0
var exposed: bool = false
var stone: Material
var brass: Material
var dark: Material
var energy: Material

func block(parent: Node3D, at: Vector3, size: Vector3) -> MeshInstance3D:
	Geo.box(parent, at - Vector3(0, size.y / 2, 0), Vector3(size.x + 0.06, 0.08, size.z + 0.06), dark)
	var part: MeshInstance3D = Geo.box(parent, at + Vector3(0, 0.025, 0), size, stone)
	Geo.box(parent, at + Vector3(0, size.y / 2, 0), Vector3(size.x + 0.04, 0.08, size.z + 0.04), brass)
	return part

func _ready() -> void:
	stone = Geo.material(Color("896033"))
	brass = Geo.material(Color("d1a24f"))
	dark = Geo.material(Color("332416"))
	energy = Geo.material(Color("4df9e8"), true)
	for x: float in [-0.65, 0.65]:
		block(self, Vector3(x, 0.25, 0.15), Vector3(0.95, 0.5, 1.3))
		block(self, Vector3(x, 0.95, 0), Vector3(0.65, 0.9, 0.7))
		block(self, Vector3(x, 1.65, 0), Vector3(0.7, 0.55, 0.75))
	torso = Node3D.new()
	torso.position.y = 1.85
	add_child(torso)
	block(torso, Vector3(0, 0.15, 0), Vector3(1.4, 0.45, 0.9))
	# Open cubic chest cage: front, back, and side edges enclose a floating core.
	for x: float in [-0.67, 0.67]:
		for z: float in [-0.52, 0.52]:
			Geo.box(torso, Vector3(x, 1.0, z), Vector3(0.14, 1.45, 0.14), brass)
	for y: float in [0.32, 1.7]:
		for z: float in [-0.52, 0.52]:
			Geo.box(torso, Vector3(0, y, z), Vector3(1.5, 0.14, 0.15), brass)
		for x: float in [-0.67, 0.67]:
			Geo.box(torso, Vector3(x, y, 0), Vector3(0.15, 0.14, 1.1), brass)
	core = Geo.box(torso, Vector3(0, 1.0, 0), Vector3(0.53, 0.53, 0.53), energy)
	core_light = OmniLight3D.new()
	core_light.position = Vector3(0, 1.0, 0.7)
	core_light.light_color = Color("52e5e1")
	core_light.omni_range = 5.5
	core_light.light_energy = 0.9
	torso.add_child(core_light)
	for side: int in [-1, 1]:
		var door: Node3D = Node3D.new()
		door.position = Vector3(side * 0.7, 1.0, 0.56)
		torso.add_child(door)
		Geo.box(door, Vector3(-side * 0.31, 0, 0), Vector3(0.59, 1.15, 0.13), brass)
		Geo.box(door, Vector3(-side * 0.31, 0, 0.08), Vector3(0.45, 0.95, 0.05), stone)
		if side < 0: left_door = door
		else: right_door = door
	block(torso, Vector3(0, 2.2, 0), Vector3(0.8, 0.95, 0.65))
	Geo.box(torso, Vector3(0, 2.2, 0.35), Vector3(0.09, 0.65, 0.06), energy)
	halo = Geo.ring(torso, Vector3(0, 2.22, -0.5), 0.94, 0.085, brass)
	halo.rotation_degrees.x = 90
	for side: int in [-1, 1]:
		var arm: Node3D = Node3D.new()
		arm.position = Vector3(side * 1.03, 1.5, 0)
		torso.add_child(arm)
		block(arm, Vector3(side * 0.22, -0.15, 0), Vector3(0.86, 0.92, 0.98))
		block(arm, Vector3(side * 0.3, -1.0, 0.1), Vector3(0.62, 0.78, 0.65))
		Geo.box(arm, Vector3(side * 0.3, -1.1, 0.46), Vector3(0.2, 0.22, 0.07), energy)
		if side < 0: axe_arm = arm
		else: emitter_arm = arm
	Geo.box(axe_arm, Vector3(-0.45, -0.55, 0.5), Vector3(0.11, 3.9, 0.11), brass)
	var blade: MeshInstance3D = Geo.box(axe_arm, Vector3(-0.82, 1.08, 0.5), Vector3(0.85, 1.2, 0.2), brass)
	blade.rotation.z = -0.2
	Geo.box(axe_arm, Vector3(-1.22, 1.1, 0.5), Vector3(0.06, 1.2, 0.22), Geo.material(Color("ffde86"), true))
	rotation_degrees.y = -70

func set_pose(value: String) -> void:
	pose = value
	pose_time = 0

func _process(delta: float) -> void:
	age += delta
	pose_time += delta
	core.rotation += Vector3(0.5, 0.7, 0.2) * delta
	core.position.y = 1.0 + sin(age * 2.3) * 0.06
	var open_angle: float = 1.3 if exposed else 0.22
	left_door.rotation.y = lerpf(left_door.rotation.y, -open_angle, delta * 8)
	right_door.rotation.y = lerpf(right_door.rotation.y, open_angle, delta * 8)
	var knee: float = 0.0
	var tilt: float = 0.0
	var swing: float = -0.12
	var palm: float = 0.0
	match pose:
		"sweep": swing = -1.8 if pose_time < 0.65 else sin(minf((pose_time - 0.65) * 6, PI)) * 1.6
		"slam": swing = -2.4 if pose_time < 0.60 else 0.8; tilt = -0.35 if pose_time >= 0.60 else 0.1
		"nova": palm = -1.25; swing = 0.6
		"beam", "bolts", "lane": palm = -1.15
		"hit": tilt = sin(minf(pose_time * 5, PI)) * -0.3
		"fallen", "dead": knee = -1.05; tilt = 0.6
		"revive": knee = lerpf(-1.05, 0, minf(pose_time, 1.0))
	torso.position.y = lerpf(torso.position.y, 1.85 + knee + sin(age * 1.5) * 0.025, delta * 8)
	torso.rotation.x = lerpf(torso.rotation.x, tilt, delta * 9)
	axe_arm.rotation.z = lerpf(axe_arm.rotation.z, swing, delta * 10)
	emitter_arm.rotation.x = lerpf(emitter_arm.rotation.x, palm, delta * 7)
	core_light.light_energy = 0.0 if pose == "dead" else (1.7 if exposed else 0.8)
	if pose == "dead":
		core.visible = false
		halo.rotation.z = lerpf(halo.rotation.z, 0.7, delta * 4)
