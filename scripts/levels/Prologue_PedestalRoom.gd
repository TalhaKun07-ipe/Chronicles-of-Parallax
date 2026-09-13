extends Node3D
class_name ProloguePedestalRoom

# Prologue Chamber where the explorer discovers the Ancient Watch and experiences the First Fall

@onready var player: Player = $Player
@onready var camera_rig: CameraRig = $CameraRig
@onready var pedestal: Pedestal = $Pedestal
@onready var trapdoor_floor: StaticBody3D = $DaisStructure/TrapdoorFloor
@onready var hud: CanvasLayer = $HUD
@onready var story_label: Label = $StoryCanvas/StoryBox/StoryLabel
@onready var story_box: PanelContainer = $StoryCanvas/StoryBox

var is_cutscene_active: bool = false
var camera_base_pos: Vector3 = Vector3.ZERO
var shake_amount: float = 0.0

func _ready() -> void:
	camera_rig.target_node = player
	# Explorer starts in full natural 3D mode
	Global.unlocked_dimensions[Global.Dimension.DIM_3D] = true
	Global.set_dimension(Global.Dimension.DIM_3D)
	
	pedestal.watch_taken.connect(_on_watch_taken)
	story_box.visible = false

func _physics_process(delta: float) -> void:
	if is_cutscene_active and shake_amount > 0:
		camera_rig.global_position = camera_base_pos + Vector3(
			(randf() - 0.5) * shake_amount,
			(randf() - 0.5) * shake_amount,
			0
		)
		shake_amount = move_toward(shake_amount, 0, delta * 0.4)

func _on_watch_taken() -> void:
	is_cutscene_active = true
	camera_base_pos = camera_rig.global_position
	shake_amount = 0.25
	
	# Freeze player controls for dramatic fall
	player.set_physics_process(false)
	
	# Drop trapdoor
	var tween = create_tween()
	tween.tween_property(trapdoor_floor, "position:y", -10.0, 0.5).set_trans(Tween.TRANS_BACK)
	
	# Player falls and loses dimensions
	var fall_tween = create_tween()
	fall_tween.tween_property(player, "global_position:y", -6.0, 1.8).set_trans(Tween.TRANS_QUAD)
	
	# Dimension breakdown sequence: 3D -> 2D -> 1D -> 0D
	fall_tween.parallel().tween_callback(func():
		show_story_text("The dungeon rumbles! The trapdoor opens!")
	).set_delay(0.2)
	
	fall_tween.parallel().tween_callback(func():
		Global.set_dimension(Global.Dimension.DIM_2D)
		show_story_text("Depth collapses! Stripped to a 2D plane!")
	).set_delay(0.6)
	
	fall_tween.parallel().tween_callback(func():
		Global.set_dimension(Global.Dimension.DIM_1D)
		show_story_text("Height vanishes! Flattened to a 1D line!")
	).set_delay(1.1)
	
	fall_tween.parallel().tween_callback(func():
		Global.set_dimension(Global.Dimension.DIM_0D)
		show_story_text("Length gone! Only a 0D point remains...")
	).set_delay(1.6)
	
	fall_tween.tween_callback(_on_fall_completed)

func show_story_text(txt: String) -> void:
	story_box.visible = true
	story_label.text = txt
	var t = create_tween()
	story_box.modulate.a = 0.0
	t.tween_property(story_box, "modulate:a", 1.0, 0.15)

func _on_fall_completed() -> void:
	# Lock player into 0D at the bottom pit
	Global.unlocked_dimensions = {
		Global.Dimension.DIM_0D: true,
		Global.Dimension.DIM_1D: false,
		Global.Dimension.DIM_2D: false,
		Global.Dimension.DIM_2_5D: false,
		Global.Dimension.DIM_3D: false
	}
	Global.set_dimension(Global.Dimension.DIM_0D)
	
	show_story_text("The watch preserves your soul at the cavern floor.\nPress [SPACE] to pulse the watch core.")
	player.set_physics_process(true)
	is_cutscene_active = false
