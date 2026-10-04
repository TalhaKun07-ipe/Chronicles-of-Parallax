extends CharacterBody3D
class_name TemporalEcho

## Replays chronological snapshots, then holds the final pose for a puzzle window.
signal echo_completed()
@export var hold_end_seconds: float = 3.0
var trajectory: Array[Dictionary] = []
var sprite_3d: Sprite3D
var collision_shape: CollisionShape3D
var current_step: int = 0
var hold_timer: float = 0.0
var dissolving: bool = false
const ART = "res://chambers/axiom_warden/assets/"

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("player")
	add_to_group("chrono_echo")
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite_3d.texture = load(ART + "john_rod_2d_idle.png")
	sprite_3d.pixel_size = 0.024
	sprite_3d.position.y = 0.576
	sprite_3d.modulate = Color(1.0, 0.77, 0.30, 0.68)
	add_child(sprite_3d)
	collision_shape = CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.42, 1.12, 0.42)
	collision_shape.shape = shape
	collision_shape.position.y = 0.58
	add_child(collision_shape)
	if not trajectory.is_empty(): global_position = trajectory[0].position
	SoundManager.play_sfx("rewind_echo")

func set_trajectory(states: Array[Dictionary]) -> void:
	trajectory = states.duplicate(true)
	current_step = 0
	hold_timer = 0.0
	if not trajectory.is_empty():
		if is_inside_tree(): global_position = trajectory[0].position
		else: position = trajectory[0].position

func _physics_process(delta: float) -> void:
	if dissolving or Global.is_rewinding: return
	if current_step >= trajectory.size():
		hold_timer += delta
		if hold_timer >= hold_end_seconds: _dissolve()
		return
	var state: Dictionary = trajectory[current_step]
	global_position = state.get("position", global_position)
	sprite_3d.flip_h = state.get("sprite_flip_h", false)
	var mode: int = state.get("mode", 2)
	var file := "john_rod_1d_rod.png" if mode == 1 else "john_rod_2d_idle.png"
	sprite_3d.texture = load(ART + file)
	sprite_3d.position.y = 0.0 if mode == 1 else 0.576
	current_step += 1

func _dissolve() -> void:
	if dissolving: return
	dissolving = true
	collision_layer = 0
	echo_completed.emit()
	var tween := create_tween()
	tween.tween_property(sprite_3d, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
