extends Node
class_name RewindController

# Records player state history for up to 4.0 seconds (240 ticks at 60Hz)

const MAX_HISTORY: int = 240
var history: Array[Dictionary] = []

var is_rewinding: bool = false
@onready var player: CharacterBody3D = get_parent()

func _physics_process(_delta: float) -> void:
	if not Global.rewind_unlocked:
		return
		
	if Input.is_action_pressed("rewind") and history.size() > 0:
		if not is_rewinding:
			start_rewind()
		step_rewind()
	else:
		if is_rewinding:
			stop_rewind()
		record_state()

func record_state() -> void:
	var state = {
		"position": player.global_position,
		"velocity": player.velocity,
		"dimension": Global.active_dimension,
		"sprite_flip_h": player.sprite_3d.flip_h if player.sprite_3d else false,
		"anim": player.current_anim if "current_anim" in player else "idle"
	}
	history.append(state)
	if history.size() > MAX_HISTORY:
		history.pop_front()

func start_rewind() -> void:
	is_rewinding = true
	Global.is_rewinding = true
	Global.rewind_started.emit()
	SoundManager.start_rewind_loop()

func step_rewind() -> void:
	if history.is_empty():
		stop_rewind()
		return
		
	var state = history.pop_back()
	player.global_position = state["position"]
	player.velocity = Vector3.ZERO
	if Global.active_dimension != state["dimension"]:
		Global.set_dimension(state["dimension"])
		
	if player.sprite_3d:
		player.sprite_3d.flip_h = state["sprite_flip_h"]
	if "current_anim" in player:
		player.play_anim(state["anim"])

func stop_rewind() -> void:
	is_rewinding = false
	Global.is_rewinding = false
	Global.rewind_ended.emit()
	SoundManager.stop_rewind_loop()
	# Restore ground collision check
	player.velocity = Vector3.ZERO
