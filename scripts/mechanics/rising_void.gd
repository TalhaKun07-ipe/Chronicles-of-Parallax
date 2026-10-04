extends Area3D
class_name RisingVoid
signal player_consumed(body: Node3D)

@export var rise_speed: float = 2.0
@export var is_active: bool = true

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_active:
		return

	# Pause rising during rewind
	var global = get_node_or_null("/root/Global")
	var is_rewinding = global.get("is_rewinding") if global else false

	if not is_rewinding:
		global_position.y += rise_speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not body.is_in_group("chrono_echo") and not Global.is_rewinding:
		player_consumed.emit(body)
		if body.has_method("die"):
			body.die()
