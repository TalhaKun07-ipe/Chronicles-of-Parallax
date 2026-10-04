extends "res://scripts/mechanics/ChronoEntity3D.gd"
class_name ChronoPlatform

## A crumbling stone platform that falls when stepped on, but can be
## rewound backward through time to act as an ascending elevator.

enum State { STABLE, CRACKING, FALLING }

@export var platform_size: Vector3 = Vector3(2.5, 0.4, 2.5)
@export var collapse_delay: float = 0.45
@export var fall_acceleration: float = 16.0
@export var terminal_fall_speed: float = 24.0
@export var auto_collapse_on_player: bool = true

var state: State = State.STABLE
var collapse_timer: float = 0.0
var fall_velocity_y: float = 0.0

var mesh_instance: MeshInstance3D
var static_body: AnimatableBody3D
var trigger_area: Area3D
var original_mesh_pos: Vector3 = Vector3.ZERO
var platform_material: StandardMaterial3D

func _on_chrono_ready() -> void:
	_ensure_components()

func _ensure_components() -> void:
	# 1. Mesh setup
	mesh_instance = get_node_or_null("MeshInstance3D")
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = platform_size
		mesh_instance.mesh = box
		add_child(mesh_instance)

	platform_material = StandardMaterial3D.new()
	platform_material.albedo_color = Color("c8d6e5")
	platform_material.roughness = 0.85
	mesh_instance.material_override = platform_material
	original_mesh_pos = mesh_instance.position

	# 2. Solid Collision
	static_body = get_node_or_null("StaticBody3D")
	if not static_body:
		static_body = AnimatableBody3D.new()
		static_body.sync_to_physics = false
		var col = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = platform_size
		col.shape = shape
		static_body.add_child(col)
		add_child(static_body)

	# 3. Detection Area (slightly above surface)
	trigger_area = get_node_or_null("TriggerArea")
	if not trigger_area:
		trigger_area = Area3D.new()
		trigger_area.collision_layer = 0
		trigger_area.collision_mask = 2
		var area_col = CollisionShape3D.new()
		var area_shape = BoxShape3D.new()
		area_shape.size = Vector3(platform_size.x * 0.95, 0.2, platform_size.z * 0.95)
		area_col.position.y = platform_size.y * 0.5 + 0.1
		area_col.shape = area_shape
		trigger_area.add_child(area_col)
		add_child(trigger_area)

	if not trigger_area.body_entered.is_connected(_on_body_entered):
		trigger_area.body_entered.connect(_on_body_entered)

func _process_forward(delta: float) -> void:
	match state:
		State.STABLE:
			mesh_instance.position = original_mesh_pos
		State.CRACKING:
			collapse_timer += delta
			# High-frequency tension vibration
			mesh_instance.position.x = original_mesh_pos.x + (randf() - 0.5) * 0.06
			mesh_instance.position.z = original_mesh_pos.z + (randf() - 0.5) * 0.06
			platform_material.albedo_color = Color("ee5253") # Warning red-orange

			if collapse_timer >= collapse_delay:
				_trigger_fall()
		State.FALLING:
			fall_velocity_y = minf(fall_velocity_y + fall_acceleration * delta, terminal_fall_speed)
			global_position.y -= fall_velocity_y * delta

func _play_sfx(cue: String) -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx(cue)

func _trigger_fall() -> void:
	state = State.FALLING
	_play_sfx("error")
	if platform_material:
		platform_material.albedo_color = Color("576574")

func trigger_collapse() -> void:
	if state == State.STABLE:
		state = State.CRACKING
		collapse_timer = 0.0
		_play_sfx("error")

func _on_body_entered(body: Node3D) -> void:
	if not auto_collapse_on_player:
		return
	if body.is_in_group("player") and not body.is_in_group("chrono_echo"):
		trigger_collapse()

func _record_custom_state() -> Dictionary:
	return {
		"state": state,
		"collapse_timer": collapse_timer,
		"fall_velocity_y": fall_velocity_y
	}

func _restore_custom_state(custom: Dictionary) -> void:
	state = custom.get("state", State.STABLE)
	collapse_timer = custom.get("collapse_timer", 0.0)
	fall_velocity_y = custom.get("fall_velocity_y", 0.0)

	if mesh_instance:
		mesh_instance.position = original_mesh_pos
	if platform_material:
		match state:
			State.STABLE:
				platform_material.albedo_color = Color("c8d6e5")
			State.CRACKING:
				platform_material.albedo_color = Color("ee5253")
			State.FALLING:
				platform_material.albedo_color = Color("ffeaa7") # Chrono-gold when rewinding fall!
