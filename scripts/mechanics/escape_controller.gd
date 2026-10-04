extends Node
class_name EscapeController

@export var player: Node3D
@export var rising_void: Node3D
@export var camera: Camera3D
@export var win_y_threshold: float = 50.0

var chamber_won: bool = false

func _process(delta: float) -> void:
	if chamber_won or not is_instance_valid(player) or not is_instance_valid(camera):
		return

	# Vertical scroller camera logic
	# Keep player in frame, but don't let camera go below the void's threat level
	var target_y = player.global_position.y

	if is_instance_valid(rising_void):
		# Ensure the void is visible at the bottom of the screen
		var void_y = rising_void.global_position.y
		var min_camera_y = void_y + 5.0 # Keep camera slightly above the void
		target_y = max(target_y, min_camera_y)

	# Smoothly interpolate camera Y
	var current_pos = camera.global_position
	current_pos.y = lerp(current_pos.y, target_y, 5.0 * delta)
	camera.global_position = current_pos

	# Check win condition
	if player.global_position.y >= win_y_threshold:
		chamber_won = true
		print("CHAMBER 3 COMPLETE: Ascended the Daylight Escape!")
