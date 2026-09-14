extends Node3D
class_name CameraRig

# Orthogonal dual-gimbal camera rig matching the 123D / FEZ perspective mechanism

@onready var cam_root_1: Node3D = self # Controls Y yaw
@onready var cam_root_2: Node3D = $CamRoot2 # Controls X pitch
@onready var camera_3d: Camera3D = $CamRoot2/Camera3D

@export var target_node: Node3D
@export var ortho_size: float = 5.8

# Angles in 3D mode
const ROT_3D_Y: float = -45.0
const ROT_3D_X: float = -30.0

# Angles in 2D / 1D mode
const ROT_2D_Y: float = 0.0
const ROT_2D_X: float = 0.0

var is_transitioning: bool = false
var current_mode_3d: bool = true

func _ready() -> void:
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.size = ortho_size
	Global.dimension_changed.connect(_on_dimension_changed)
	set_view_immediate(Global.active_dimension == Global.Dimension.DIM_3D)

func _physics_process(_delta: float) -> void:
	if target_node:
		# Smoothly track target
		var target_pos = target_node.global_position
		global_position = global_position.lerp(target_pos, 0.1)

func _on_dimension_changed(new_dim: Global.Dimension, _old: Global.Dimension) -> void:
	var want_3d = (new_dim == Global.Dimension.DIM_3D)
	if want_3d != current_mode_3d:
		transition_to_mode(want_3d)

func transition_to_mode(is_3d: bool) -> void:
	current_mode_3d = is_3d
	is_transitioning = true
	
	var target_y = ROT_3D_Y if is_3d else ROT_2D_Y
	var target_x = ROT_3D_X if is_3d else ROT_2D_X
	
	var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation_degrees:y", target_y, 0.45)
	tween.tween_property(cam_root_2, "rotation_degrees:x", target_x, 0.45)
	tween.chain().tween_callback(func(): is_transitioning = false)

func set_view_immediate(is_3d: bool) -> void:
	current_mode_3d = is_3d
	rotation_degrees.y = ROT_3D_Y if is_3d else ROT_2D_Y
	if cam_root_2:
		cam_root_2.rotation_degrees.x = ROT_3D_X if is_3d else ROT_2D_X
