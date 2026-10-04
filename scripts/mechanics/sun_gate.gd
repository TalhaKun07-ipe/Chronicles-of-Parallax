extends Node3D
class_name SunGate

signal opened()
@export var plate_a: Area3D
@export var plate_b: Area3D
@export var gate_mesh: Node3D
@export var gate_body: StaticBody3D
var a_pressed: bool = false
var b_pressed: bool = false
var is_open: bool = false
var occupants_a: Array[Node3D] = []
var occupants_b: Array[Node3D] = []

func _ready() -> void:
	if plate_a:
		plate_a.collision_layer = 0
		plate_a.collision_mask = 2
		plate_a.body_entered.connect(_on_plate_a_entered)
		plate_a.body_exited.connect(_on_plate_a_exited)
	if plate_b:
		plate_b.collision_layer = 0
		plate_b.collision_mask = 2
		plate_b.body_entered.connect(_on_plate_b_entered)
		plate_b.body_exited.connect(_on_plate_b_exited)

func _physics_process(_delta: float) -> void:
	occupants_a = occupants_a.filter(func(body): return is_instance_valid(body) and not body.is_queued_for_deletion())
	occupants_b = occupants_b.filter(func(body): return is_instance_valid(body) and not body.is_queued_for_deletion())
	a_pressed = not occupants_a.is_empty()
	b_pressed = not occupants_b.is_empty()
	if not is_open and a_pressed and b_pressed: _open_gate()

func _open_gate() -> void:
	is_open = true # Solved gates are time anchors; rewind cannot undo progress.
	if gate_body: gate_body.set_deferred("collision_layer", 0)
	if gate_mesh:
		var tween := create_tween()
		tween.tween_property(gate_mesh, "position:y", gate_mesh.position.y + 4.5, 0.8)
	SoundManager.play_sfx("unlock")
	opened.emit()

func _on_plate_a_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not occupants_a.has(body):
		occupants_a.append(body)
		a_pressed = true

func _on_plate_a_exited(body: Node3D) -> void:
	occupants_a.erase(body)
	a_pressed = not occupants_a.is_empty()

func _on_plate_b_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not occupants_b.has(body):
		occupants_b.append(body)
		b_pressed = true

func _on_plate_b_exited(body: Node3D) -> void:
	occupants_b.erase(body)
	b_pressed = not occupants_b.is_empty()
