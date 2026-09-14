extends Node3D
class_name Chamber1DimensionalTrial

# Chamber 1: The Dimensional Trial
# High-engagement isometric diorama testing 1D, 2D, 2.5D, and 3D immediately.

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var door: ChamberDoor = $PortcullisDoor
@onready var receiver: EnergyReceiver = $CentralMonolith/EnergyReceiver
@onready var exit_trigger: Area3D = $RaisedMezzanine/ExitPortal
@onready var runic_platform_1: RunicPlatform = $RunicPlatforms/RunicPlatform1
@onready var runic_platform_2: RunicPlatform = $RunicPlatforms/RunicPlatform2
@onready var runic_platform_3: RunicPlatform = $RunicPlatforms/RunicPlatform3

func _ready() -> void:
	if camera_rig and player:
		camera_rig.target_node = player
		
	# Ensure all 4 spatial dimensions are unlocked from the start of Chamber 1
	Global.unlocked_dimensions[Global.Dimension.DIM_1D] = true
	Global.unlocked_dimensions[Global.Dimension.DIM_2D] = true
	Global.unlocked_dimensions[Global.Dimension.DIM_2_5D] = true
	Global.unlocked_dimensions[Global.Dimension.DIM_3D] = true
	Global.rewind_unlocked = false
	Global.current_chamber_id = "chamber_1"
	
	# Start in 2D platforming mode
	Global.set_dimension(Global.Dimension.DIM_2D)
	
	if receiver:
		receiver.powered_on.connect(_on_receiver_powered)
		
	if exit_trigger:
		exit_trigger.body_entered.connect(_on_exit_reached)
		
	# Smooth fade in from black on chamber start
	if SceneTransition:
		SceneTransition.fade_in_from_black(0.4)

func _on_receiver_powered() -> void:
	Global.chamber_states["chamber_1"]["receiver_powered"] = true
	
	# Power on the 3 runic steps across the chasm
	if runic_platform_1:
		runic_platform_1.activate()
	if runic_platform_2:
		runic_platform_2.activate()
	if runic_platform_3:
		runic_platform_3.activate()
		
	# Also open the lower entrance portcullis for backtracking convenience
	if door:
		door.open()

func _on_exit_reached(body: Node3D) -> void:
	if body is Player:
		Global.chamber_states["chamber_1"]["exit_open"] = true
		# Trigger black-screen transition to Chamber 2
		if SceneTransition:
			SceneTransition.change_chamber("res://scenes/levels/Chamber2_ClockworkAscent.tscn")
