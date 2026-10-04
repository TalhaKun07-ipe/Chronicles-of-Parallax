extends "res://scripts/mechanics/ChronoEntity3D.gd"
class_name ChronoLift

@export var travel: Vector3 = Vector3(0, 1.8, 0)
@export var cycle_seconds: float = 5.0
var elapsed: float = 0.0
var origin: Vector3
var body: AnimatableBody3D

func _on_chrono_ready() -> void:
	origin = position
	body = AnimatableBody3D.new()
	body.sync_to_physics = false
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.4, 0.5, 3.6)
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	var geo = load("res://chambers/axiom_warden/scripts/geometry.gd")
	geo.box(self, Vector3.ZERO, box.size, geo.stone_material(Color("405563")))
	geo.box(self, Vector3(0, 0.26, 0), Vector3(3.5, 0.04, 3.7), geo.material(Color("788e89")))
	for z in [-1.55, 1.55]:
		geo.box(self, Vector3(0, 0.3, z), Vector3(3.2, 0.04, 0.06), geo.conduit_material())

func _process_forward(delta: float) -> void:
	elapsed += delta
	position = origin + travel * (0.5 - 0.5 * cos(elapsed * TAU / cycle_seconds))

func _record_custom_state() -> Dictionary:
	return {"elapsed": elapsed}

func _restore_custom_state(custom: Dictionary) -> void:
	elapsed = custom.get("elapsed", 0.0)
