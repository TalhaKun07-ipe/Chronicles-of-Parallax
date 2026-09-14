extends Node

# Global game state manager for Degrees of Escape

enum Dimension {
	DIM_0D,      # 0 DoF: Helpless point, can only pulse the watch
	DIM_1D,      # 1 DoF: Line, travels on conduit rails (A/D)
	DIM_2D,      # 2 DoF: Plane, 2D platformer movement + jumping (A/D + Space)
	DIM_2_5D,    # 2.5 DoF: Discrete depth layers (W/S to shift lanes at pads)
	DIM_3D       # 3 DoF: Full 3D continuous volume movement (A/D + W/S + Space)
}

enum SpriteResolution {
	RES_64,      # 64x64 pixel art resolution
	RES_128      # 128x128 high-definition pixel art resolution
}

signal dimension_changed(new_dim: Dimension, old_dim: Dimension)
signal sprite_resolution_changed(new_res: SpriteResolution)
signal rewind_started()
signal rewind_ended()
signal health_changed(new_hp: int)
signal ability_unlocked(dim: Dimension)
signal checkpoint_reached(chamber_id: String)
signal charge_state_changed(has_charge: bool)

var sprite_resolution: SpriteResolution = SpriteResolution.RES_128
var active_dimension: Dimension = Dimension.DIM_2D
var unlocked_dimensions: Dictionary = {
	Dimension.DIM_0D: true,
	Dimension.DIM_1D: true,   # Unlocked from start of exploration
	Dimension.DIM_2D: true,   # Unlocked from start of exploration
	Dimension.DIM_2_5D: true, # Depth lane shifting unlocked
	Dimension.DIM_3D: true    # Continuous volume unlocked
}

var carried_charge: bool = false
var rewind_unlocked: bool = false
var is_rewinding: bool = false

var max_health: int = 3
var current_health: int = 3

var current_chamber_id: String = "chamber_1"
var current_checkpoint_pos: Vector3 = Vector3.ZERO

var chamber_states: Dictionary = {
	"chamber_1": {"gate_opened": false, "charge_collected": false, "receiver_powered": false, "exit_open": false},
	"chamber_2": {"shutter_passed": false, "lever_a": false, "lever_b": false, "lift_active": false},
	"chamber_3": {"boss_phase": 1, "boss_defeated": false, "rewind_unlocked": false, "stairs_restored": false, "escaped": false}
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func unlock_dimension(dim: Dimension) -> void:
	if not unlocked_dimensions.get(dim, false):
		unlocked_dimensions[dim] = true
		ability_unlocked.emit(dim)
		SoundManager.play_sfx("unlock")

func set_dimension(new_dim: Dimension) -> bool:
	if not unlocked_dimensions.get(new_dim, false):
		SoundManager.play_sfx("error")
		return false
	if active_dimension == new_dim:
		return false
		
	var old_dim = active_dimension
	active_dimension = new_dim
	dimension_changed.emit(new_dim, old_dim)
	SoundManager.play_sfx("transform")
	return true

func cycle_dimension(direction: int) -> void:
	var unlocked_list: Array[Dimension] = []
	for d in [Dimension.DIM_0D, Dimension.DIM_1D, Dimension.DIM_2D, Dimension.DIM_2_5D, Dimension.DIM_3D]:
		if unlocked_dimensions.get(d, false):
			unlocked_list.append(d)
			
	if unlocked_list.size() <= 1:
		return
		
	var current_idx = unlocked_list.find(active_dimension)
	if current_idx == -1:
		current_idx = 0
		
	var next_idx = (current_idx + direction) % unlocked_list.size()
	if next_idx < 0:
		next_idx += unlocked_list.size()
		
	set_dimension(unlocked_list[next_idx])

func take_damage(amount: int = 1) -> void:
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	SoundManager.play_sfx("hurt")
	if current_health <= 0:
		handle_defeat()

func heal(amount: int = 1) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)

func handle_defeat() -> void:
	# Quick reset at chamber checkpoint
	current_health = max_health
	health_changed.emit(current_health)
	get_tree().reload_current_scene()

func unlock_rewind() -> void:
	rewind_unlocked = true
	SoundManager.play_sfx("unlock")

func set_sprite_resolution(new_res: SpriteResolution) -> void:
	if sprite_resolution != new_res:
		sprite_resolution = new_res
		sprite_resolution_changed.emit(new_res)

func collect_charge() -> void:
	if not carried_charge:
		carried_charge = true
		charge_state_changed.emit(true)
		SoundManager.play_sfx("unlock")

func deposit_charge() -> bool:
	if carried_charge:
		carried_charge = false
		charge_state_changed.emit(false)
		SoundManager.play_sfx("unlock")
		return true
	return false
