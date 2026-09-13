extends Node3D
class_name ConduitRail

# 1D Conduit Rail for Degrees of Escape
# Allows John Rod to collapse into 1D and traverse along a narrow energy conduit.

@export var length: float = 6.0
@export var rail_direction: Vector3 = Vector3.RIGHT
@export var passes_under_barrier: bool = false

@onready var rail_mesh: MeshInstance3D = $RailMesh
@onready var area_3d: Area3D = $Area3D
@onready var collision_shape: CollisionShape3D = $Area3D/CollisionShape3D
@onready var start_cap: MeshInstance3D = $StartCap
@onready var end_cap: MeshInstance3D = $EndCap
@onready var omni_light: OmniLight3D = $OmniLight3D

func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)
	area_3d.body_exited.connect(_on_body_exited)
	setup_visuals()

func setup_visuals() -> void:
	# Position end caps
	if start_cap:
		start_cap.position = -rail_direction * (length * 0.5)
	if end_cap:
		end_cap.position = rail_direction * (length * 0.5)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.current_conduit = self
		# Subtle pulse on the rail
		var tween = create_tween()
		tween.tween_property(omni_light, "light_energy", 1.8, 0.15)
		tween.tween_property(omni_light, "light_energy", 1.0, 0.25)

func _on_body_exited(body: Node3D) -> void:
	if body is Player and body.current_conduit == self:
		if Global.active_dimension != Global.Dimension.DIM_1D:
			body.current_conduit = null

# Constrain player along the rail line while in 1D
func constrain_player_1d(player: Player) -> void:
	var rail_center = global_position
	var half_len = length * 0.5
	var min_pos = rail_center - rail_direction * half_len
	var max_pos = rail_center + rail_direction * half_len
	
	player.global_position.y = rail_center.y
	player.global_position.z = rail_center.z
	
	if rail_direction.x != 0:
		player.global_position.x = clamp(player.global_position.x, min(min_pos.x, max_pos.x), max(min_pos.x, max_pos.x))
