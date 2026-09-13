extends Node3D
class_name ArrivalBrokenCircuit

# Arrival: The Broken Circuit (Chamber 0)
# Introduces 1D conduit sliding, 3D spatial flank around pillar, and 2D runic jumping.

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var receiver: EnergyReceiver = $EnergyReceiver
@onready var exit_trigger: Area3D = $ExitDoorway/ExitTrigger
@onready var door: ChamberDoor = $ChamberDoor

func _ready() -> void:
	if camera_rig and player:
		camera_rig.target_node = player
		
	# In the revised plan, all three spatial dimensions (1D, 2D, 3D) are unlocked
	Global.unlocked_dimensions[Global.Dimension.DIM_1D] = true
	Global.unlocked_dimensions[Global.Dimension.DIM_2D] = true
	Global.unlocked_dimensions[Global.Dimension.DIM_3D] = true
	Global.rewind_unlocked = false
	Global.current_chamber_id = "arrival"
	
	# Start in 2D platforming elevation
	Global.set_dimension(Global.Dimension.DIM_2D)
	
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_reached)
		
	if receiver:
		receiver.powered_on.connect(_on_circuit_completed)

func _on_circuit_completed() -> void:
	Global.chamber_states["arrival"]["receiver_powered"] = true
	# Also open the lower chamber door for backtracking convenience
	if door:
		door.open()

func _on_exit_reached(body: Node3D) -> void:
	if body is Player:
		SoundManager.play_sfx("unlock")
		Global.chamber_states["arrival"]["exit_open"] = true
		# Transition to Chamber 1 (The Hidden Connection) or Main Sanctuary stack
		get_tree().change_scene_to_file("res://scenes/levels/Main.tscn")
