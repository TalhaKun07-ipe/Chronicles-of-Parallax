extends Node
class_name RewindController

## One clock owns player/world rewind and its energy budget. HUDs only observe it.
const MAX_HISTORY: int = 240
@export var enable_temporal_echo: bool = true
@export var max_energy_seconds: float = 4.0
@export var recharge_rate: float = 0.8
var energy_seconds: float = 4.0
var history: Array[Dictionary] = []
var rewound_trajectory: Array[Dictionary] = []
var active_echo: TemporalEcho
var is_rewinding: bool = false
var input_override: bool = false
var rewind_requested: bool = false
var must_release: bool = false
var release_velocity: Vector3 = Vector3.ZERO
@onready var player: CharacterBody3D = get_parent()

func _ready() -> void:
	process_physics_priority = -100
	energy_seconds = max_energy_seconds

func _physics_process(delta: float) -> void:
	var held := rewind_requested if input_override else Input.is_action_pressed("rewind")
	if not held: must_release = false
	if not Global.rewind_unlocked:
		if is_rewinding: stop_rewind(false)
		return
	if held and not must_release:
		if not is_rewinding and not start_rewind(): must_release = true
		if is_rewinding:
			if history.is_empty() or energy_seconds < delta:
				stop_rewind()
				must_release = true
			else:
				step_rewind()
				energy_seconds = maxf(0.0, energy_seconds - delta)
				return
	elif is_rewinding:
		stop_rewind()
	energy_seconds = minf(max_energy_seconds, energy_seconds + delta * recharge_rate)
	record_state()

func record_state() -> void:
	var state: Dictionary
	if player.has_method("capture_time_state"):
		state = player.capture_time_state()
	else:
		state = {"position": player.global_position, "velocity": player.velocity,
			"dimension": Global.active_dimension, "sprite_flip_h": player.sprite_3d.flip_h,
			"anim": player.current_anim}
	history.append(state)
	if history.size() > MAX_HISTORY: history.pop_front()

func start_rewind() -> bool:
	if is_rewinding: return true
	if not Global.rewind_unlocked or history.size() < 2 or energy_seconds <= 0.02: return false
	clear_echo()
	is_rewinding = true
	rewound_trajectory.clear()
	Global.is_rewinding = true
	Global.rewind_started.emit()
	SoundManager.start_rewind_loop()
	return true

func step_rewind() -> void:
	if history.is_empty(): return
	var state: Dictionary = history.pop_back()
	rewound_trajectory.append(state)
	release_velocity = state.get("velocity", Vector3.ZERO)
	if player.has_method("restore_time_state"):
		player.restore_time_state(state)
	else:
		player.global_position = state.position
		player.velocity = Vector3.ZERO
		Global.set_dimension(state.dimension)
		player.sprite_3d.flip_h = state.sprite_flip_h
		player.play_anim(state.anim)

func stop_rewind(spawn_echo: bool = true) -> void:
	if not is_rewinding: return
	is_rewinding = false
	Global.is_rewinding = false
	Global.rewind_ended.emit()
	SoundManager.stop_rewind_loop()
	player.velocity = release_velocity
	if spawn_echo and enable_temporal_echo and rewound_trajectory.size() >= 18:
		_spawn_temporal_echo()

func _spawn_temporal_echo() -> void:
	clear_echo()
	var states: Array[Dictionary] = rewound_trajectory.duplicate(true)
	states.reverse()
	var echo := TemporalEcho.new()
	echo.set_trajectory(states)
	player.get_parent().add_child(echo)
	active_echo = echo
	echo.echo_completed.connect(func():
		if active_echo == echo: active_echo = null)

func clear_echo() -> void:
	if is_instance_valid(active_echo):
		active_echo.collision_layer = 0
		active_echo.queue_free()
	active_echo = null

func reset_timeline(refill: bool = true) -> void:
	stop_rewind(false)
	clear_echo()
	history.clear()
	rewound_trajectory.clear()
	release_velocity = Vector3.ZERO
	must_release = Input.is_action_pressed("rewind") or rewind_requested
	if refill: energy_seconds = max_energy_seconds

func available_seconds() -> float:
	return minf(energy_seconds, float(history.size()) / Engine.physics_ticks_per_second)

func _exit_tree() -> void:
	if is_rewinding:
		Global.is_rewinding = false
		SoundManager.stop_rewind_loop()
