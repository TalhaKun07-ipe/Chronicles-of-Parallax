extends "res://scripts/mechanics/ChronoEntity3D.gd"
class_name ChronoMonolith

## An ancient standing monolith that can topple over into the abyss,
## and be rewound backward through time to act as a catapult/ascender.

signal monolith_toppled()
signal monolith_upright()

@export var pillar_dimensions: Vector3 = Vector3(2.2, 14.0, 2.2)
@export var topple_axis: Vector3 = Vector3.FORWARD # Direction it falls
@export var max_fall_angle_deg: float = 95.0
@export var angular_acceleration: float = 120.0 # deg/sec^2

var current_angle_deg: float = 0.0
var angular_velocity: float = 0.0
var is_toppling: bool = false
var has_fallen: bool = false

var base_pivot: Node3D
var mesh_instance: MeshInstance3D
var static_body: AnimatableBody3D

func _on_chrono_ready() -> void:
	_setup_monolith()

func _setup_monolith() -> void:
	base_pivot = Node3D.new()
	add_child(base_pivot)

	# Mesh: positioned so pivot is at base
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = pillar_dimensions
	mesh_instance.mesh = box
	mesh_instance.position.y = pillar_dimensions.y * 0.5

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("718093")
	mat.roughness = 0.9
	mesh_instance.material_override = mat
	base_pivot.add_child(mesh_instance)

	# Static collision follows pivot
	static_body = AnimatableBody3D.new()
	static_body.sync_to_physics = false
	static_body.position.y = pillar_dimensions.y * 0.5
	var col = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = pillar_dimensions
	col.shape = shape
	static_body.add_child(col)
	base_pivot.add_child(static_body)

func _play_sfx(cue: String) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx(cue)

func trigger_topple() -> void:
	if not is_toppling and not has_fallen:
		is_toppling = true
		angular_velocity = 8.0 # Initial nudge
		_play_sfx("error")
		monolith_toppled.emit()

func _process_forward(delta: float) -> void:
	if is_toppling:
		angular_velocity += angular_acceleration * delta
		current_angle_deg += angular_velocity * delta

		if current_angle_deg >= max_fall_angle_deg:
			current_angle_deg = max_fall_angle_deg
			is_toppling = false
			has_fallen = true
			_play_sfx("hurt")

		_apply_rotation()

func _apply_rotation() -> void:
	if base_pivot:
		base_pivot.rotation = Vector3.ZERO
		var axis = Vector3.UP.cross(topple_axis).normalized()
		if axis.length_squared() < 0.01:
			axis = Vector3.RIGHT
		base_pivot.rotate(axis, deg_to_rad(current_angle_deg))

func _record_custom_state() -> Dictionary:
	return {
		"angle": current_angle_deg,
		"ang_vel": angular_velocity,
		"is_toppling": is_toppling,
		"has_fallen": has_fallen
	}

func _restore_custom_state(custom: Dictionary) -> void:
	var previous_angle := current_angle_deg
	current_angle_deg = custom.get("angle", 0.0)
	angular_velocity = custom.get("ang_vel", 0.0)
	is_toppling = custom.get("is_toppling", false)
	has_fallen = custom.get("has_fallen", false)
	_apply_rotation()

	if current_angle_deg <= 0.5 and previous_angle > 0.5:
		monolith_upright.emit()
