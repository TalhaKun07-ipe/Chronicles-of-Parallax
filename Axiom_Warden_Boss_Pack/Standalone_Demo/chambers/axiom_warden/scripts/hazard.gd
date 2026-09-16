extends Node3D
## Continuous collision in world space. No blanket immunity by dimension.
const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
signal hit_player
var kind: String = "beam"
var warning: float = 1.15
var duration: float = 0.7
var age: float = 0.0
var direction: Vector3 = Vector3.LEFT
var speed: float = 7.0
var radius: float = 0.3
var previous_radius: float = 0.3
var previous_position: Vector3
var damaged: bool = false
var target: CharacterBody3D
var visual: MeshInstance3D
var warning_mat: StandardMaterial3D
var active_mat: StandardMaterial3D

func _ready() -> void:
	warning_mat = Geo.material(Color("d9973e"), true)
	active_mat = Geo.material(Color("60f8ed"), true)
	previous_position = global_position
	match kind:
		"beam": visual = Geo.box(self, Vector3.ZERO, Vector3(25, 0.07, 0.12), warning_mat)
		"lane": visual = Geo.box(self, Vector3(0, -position.y + 0.035, 0), Vector3(25, 0.04, 1.5), warning_mat)
		"sweep": visual = Geo.ring(self, Vector3.ZERO, 1.0, 0.05, warning_mat)
		"bolt": visual = Geo.box(self, Vector3.ZERO, Vector3(0.38, 0.38, 0.38), active_mat)
		"body": visual = Geo.ring(self, Vector3.ZERO, 1.8, 0.07, warning_mat)

func is_dangerous() -> bool:
	return age >= warning and age < warning + duration

func intersects(feet: Vector3, height: float, player_radius: float, player_mode: int) -> bool:
	if not is_dangerous(): return false
	var low: float = feet.y
	var high: float = feet.y + height
	if player_mode == 1:
		low -= 0.065
		high = low + 0.13
	match kind:
		"beam":
			return absf(feet.x - global_position.x) < 12.5 + player_radius and absf(feet.z - global_position.z) < 0.2 + player_radius and low < global_position.y + 0.14 and high > global_position.y - 0.14
		"lane":
			return absf(feet.x - global_position.x) < 12.5 + player_radius and absf(feet.z - global_position.z) < 0.75 + player_radius and low < 3.3
		"sweep":
			var dist: float = Vector2(feet.x - global_position.x, feet.z - global_position.z).length()
			return dist >= previous_radius - player_radius - 0.16 and dist <= radius + player_radius + 0.16 and low < global_position.y + 0.15 and high > global_position.y - 0.15
		"bolt":
			var center: Vector3 = feet + Vector3.UP * (height * 0.5 if player_mode != 1 else 0.0)
			var closest: Vector3 = Geometry3D.get_closest_point_to_segment(center, previous_position, global_position)
			return Vector2(center.x - closest.x, center.z - closest.z).length() < player_radius + 0.22 and low < closest.y + 0.22 and high > closest.y - 0.22
		"body":
			return player_mode == 3 and feet.distance_to(global_position) < 1.9
	return false

func _physics_process(delta: float) -> void:
	age += delta
	previous_position = global_position
	previous_radius = radius
	if is_dangerous():
		visual.material_override = active_mat
		if kind == "bolt":
			global_position += direction * speed * delta
			visual.rotation += Vector3(1, 2, 1) * delta
		elif kind == "sweep":
			radius = 1.0 + (age - warning) * speed
			visual.scale = Vector3(radius, 1, radius)
		elif kind == "lane":
			visual.position.y = 0
			visual.scale.y = 75
		elif kind == "beam":
			visual.scale = Vector3(1, 3.0, 2.5)
	elif kind == "sweep":
		visual.scale = Vector3(1.7, 1, 1.7)
	if is_instance_valid(target) and not damaged and intersects(target.global_position, 1.14, 0.19, int(target.get("mode"))):
		damaged = true
		hit_player.emit()
	if age > warning + duration:
		queue_free()
