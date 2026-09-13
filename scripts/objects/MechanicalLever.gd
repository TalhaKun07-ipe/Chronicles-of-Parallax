extends Node3D
class_name MechanicalLever

# Ancient interactive lever used to lock shutters, activate lifts, or reveal footholds

signal pulled

@export var linked_targets: Array[NodePath] = []
@export var is_pulled: bool = false

@onready var handle_mesh: MeshInstance3D = $BaseMesh/HandleMesh
@onready var interact_area: Area3D = $InteractArea
@onready var indicator_light: OmniLight3D = $OmniLight3D

var player_in_range: bool = false

func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	if is_pulled:
		handle_mesh.rotation.x = deg_to_rad(45.0)
		indicator_light.light_color = Color(0.2, 1.0, 0.5)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and not is_pulled:
		if event.is_action_pressed("interact_strike"):
			pull()

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		player_in_range = false

func pull() -> void:
	if is_pulled:
		return
	is_pulled = true
	SoundManager.play_sfx("transform")
	
	var tween = create_tween()
	tween.tween_property(handle_mesh, "rotation:x", deg_to_rad(45.0), 0.25).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(indicator_light, "light_color", Color(0.2, 1.0, 0.5), 0.25)
	tween.parallel().tween_property(indicator_light, "light_energy", 1.8, 0.25)
	
	pulled.emit()
	
	for target_path in linked_targets:
		var node = get_node_or_null(target_path)
		if node:
			if node.has_method("lock_open"):
				node.lock_open()
			elif node.has_method("activate"):
				node.activate()
			elif node.has_method("open"):
				node.open()
