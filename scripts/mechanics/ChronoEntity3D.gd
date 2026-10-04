extends Node3D
class_name ChronoEntity3D

## Base class for 4D time-rewindable objects in Degrees of Escape.
## Implements bounded physics history (240 ticks / 4.0s at 60 Hz)
## inspired by Prince of Persia: The Sands of Time.

signal rewind_started()
signal rewind_ended()
signal state_recorded(snapshot: Dictionary)
signal state_restored(snapshot: Dictionary)

@export var time_immune: bool = false
@export var max_history_frames: int = 240 # 4.0 seconds at 60 Hz

var history: Array[Dictionary] = []
var was_rewinding: bool = false
var initial_transform: Transform3D
var initial_custom_state: Dictionary = {}

func _ready() -> void:
	initial_transform = global_transform
	_on_chrono_ready()
	initial_custom_state = _record_custom_state().duplicate(true)
	add_to_group("rewindable")

func is_rewinding_active() -> bool:
	var global = get_node_or_null("/root/Global")
	return bool(global.get("is_rewinding")) if global else false

func _physics_process(delta: float) -> void:
	if time_immune:
		_process_forward(delta)
		return

	if is_rewinding_active():
		if not was_rewinding:
			was_rewinding = true
			rewind_started.emit()
			_on_rewind_started()
		_step_rewind()
	else:
		if was_rewinding:
			was_rewinding = false
			rewind_ended.emit()
			_on_rewind_ended()
		_process_forward(delta)
		_record_frame()

## Virtual hooks for child implementations
func _on_chrono_ready() -> void:
	pass

func _process_forward(_delta: float) -> void:
	pass

func _on_rewind_started() -> void:
	pass

func _on_rewind_ended() -> void:
	pass

func _record_custom_state() -> Dictionary:
	return {}

func _restore_custom_state(_custom: Dictionary) -> void:
	pass

## Core bounded history logic
func _record_frame() -> void:
	var snapshot: Dictionary = {
		"transform": global_transform,
		"custom": _record_custom_state()
	}
	history.append(snapshot)
	if history.size() > max_history_frames:
		history.pop_front()
	state_recorded.emit(snapshot)

func _step_rewind() -> void:
	if history.is_empty():
		return

	var snapshot: Dictionary = history.pop_back()
	global_transform = snapshot["transform"]
	if snapshot.has("custom"):
		_restore_custom_state(snapshot["custom"])
	state_restored.emit(snapshot)

func reset_timeline() -> void:
	history.clear()
	was_rewinding = false
	global_transform = initial_transform
	_restore_custom_state(initial_custom_state.duplicate(true))
