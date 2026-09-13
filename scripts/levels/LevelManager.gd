extends Node3D
class_name LevelManager

# Orchestrates room progression, ability unlocks, and camera transitions

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var hud: CanvasLayer = $HUD

# Chamber trigger areas
@onready var chamber1_trigger: Area3D = $Triggers/Chamber1Unlock
@onready var chamber2_trigger: Area3D = $Triggers/Chamber2Unlock
@onready var chamber3_trigger: Area3D = $Triggers/Chamber3Unlock
@onready var chamber4_trigger: Area3D = $Triggers/Chamber4Unlock
@onready var boss_trigger: Area3D = $Triggers/BossTrigger

@onready var boss: GuardianBoss = $BossArena/GuardianBoss
@onready var boss_bridge: RewindableBridge = $BossArena/RewindableBridge
@onready var exit_door: Node3D = $BossArena/ExitDoor

func _ready() -> void:
	if camera_rig and player:
		camera_rig.target_node = player
	# Initial state: 0D Point awakened at the bottom of the cavern
	Global.active_dimension = Global.Dimension.DIM_0D
	Global.unlocked_dimensions[Global.Dimension.DIM_0D] = true
	
	if chamber1_trigger: chamber1_trigger.body_entered.connect(_on_chamber1_reached)
	if chamber2_trigger: chamber2_trigger.body_entered.connect(_on_chamber2_reached)
	if chamber3_trigger: chamber3_trigger.body_entered.connect(_on_chamber3_reached)
	if chamber4_trigger: chamber4_trigger.body_entered.connect(_on_chamber4_reached)
	if boss_trigger: boss_trigger.body_entered.connect(_on_boss_reached)
	
	if boss:
		boss.boss_defeated.connect(_on_boss_defeated)
		boss.arena_collapsed.connect(_on_boss_collapse)

func _physics_process(_delta: float) -> void:
	pass

func _on_chamber1_reached(body: Node3D) -> void:
	if body is Player:
		Global.unlock_dimension(Global.Dimension.DIM_1D)
		Global.set_dimension(Global.Dimension.DIM_1D)

func _on_chamber2_reached(body: Node3D) -> void:
	if body is Player:
		Global.unlock_dimension(Global.Dimension.DIM_2D)
		Global.set_dimension(Global.Dimension.DIM_2D)

func _on_chamber3_reached(body: Node3D) -> void:
	if body is Player:
		Global.unlock_dimension(Global.Dimension.DIM_2_5D)
		Global.set_dimension(Global.Dimension.DIM_2_5D)

func _on_chamber4_reached(body: Node3D) -> void:
	if body is Player:
		Global.unlock_dimension(Global.Dimension.DIM_3D)
		Global.set_dimension(Global.Dimension.DIM_3D)

func _on_boss_reached(body: Node3D) -> void:
	if body is Player:
		# Unlock Time Rewind for boss battle
		Global.unlock_rewind()

func _on_boss_collapse() -> void:
	if boss_bridge:
		boss_bridge.collapse_bridge()

func _on_boss_defeated() -> void:
	if exit_door:
		var tween = create_tween()
		tween.tween_property(exit_door, "position:y", 3.0, 1.5)
