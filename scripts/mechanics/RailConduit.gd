extends Area3D
class_name RailConduit

# Marked 1D hairline conduit that can only be entered and traversed in 1D mode

@export var exit_marker: Marker3D
@export var rail_direction: Vector3 = Vector3.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		if Global.active_dimension == Global.Dimension.DIM_1D:
			# Player slips smoothly through conduit
			body.rail_dir = rail_direction
		else:
			# Too big to pass through
			SoundManager.play_sfx("error")
