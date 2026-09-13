extends Area3D
class_name EnergyReceiver

# Ancient Receiver terminal that accepts an energy charge to power mechanisms

signal powered_on

@export var receiver_id: String = "arrival_receiver"
@export var linked_targets: Array[NodePath] = []

@onready var pedestal_mesh: MeshInstance3D = $PedestalMesh
@onready var socket_core: MeshInstance3D = $SocketCore
@onready var omni_light: OmniLight3D = $OmniLight3D

var is_powered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	socket_core.visible = false
	omni_light.light_energy = 0.2

func _on_body_entered(body: Node3D) -> void:
	if is_powered:
		return
		
	if body is Player:
		if Global.carried_charge:
			activate()
		else:
			# Player touched without charge — hint pulse
			var tween = create_tween()
			tween.tween_property(omni_light, "light_energy", 0.8, 0.1)
			tween.tween_property(omni_light, "light_energy", 0.2, 0.2)

func activate() -> void:
	if is_powered:
		return
	is_powered = true
	Global.deposit_charge()
	
	socket_core.visible = true
	socket_core.scale = Vector3(0.01, 0.01, 0.01)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(socket_core, "scale", Vector3(1.0, 1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK)
	tween.tween_property(omni_light, "light_energy", 2.5, 0.3)
	
	SoundManager.play_sfx("unlock")
	powered_on.emit()
	
	# Trigger linked targets (doors, platforms, levers)
	for target_path in linked_targets:
		var node = get_node_or_null(target_path)
		if node:
			if node.has_method("activate"):
				node.activate()
			elif node.has_method("open"):
				node.open()
			elif "is_active" in node:
				node.is_active = true
