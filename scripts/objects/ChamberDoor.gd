extends StaticBody3D
class_name ChamberDoor

# Ancient Chamber Door with a low conduit clearance slot beneath

@export var is_open: bool = false
@export var open_height: float = 3.5

@onready var door_mesh: MeshInstance3D = $DoorMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var initial_y: float = 0.0

func _ready() -> void:
	initial_y = door_mesh.position.y
	if is_open:
		door_mesh.position.y = initial_y + open_height
		collision_shape.disabled = true

func open() -> void:
	if is_open:
		return
	is_open = true
	SoundManager.play_sfx("transform")
	
	var tween = create_tween()
	tween.tween_property(door_mesh, "position:y", initial_y + open_height, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): collision_shape.disabled = true)

func close() -> void:
	if not is_open:
		return
	is_open = false
	collision_shape.disabled = false
	SoundManager.play_sfx("transform")
	
	var tween = create_tween()
	tween.tween_property(door_mesh, "position:y", initial_y, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
