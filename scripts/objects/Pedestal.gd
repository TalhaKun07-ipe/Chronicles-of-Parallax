extends Node3D
class_name Pedestal

# Pedestal holding the Ancient Watch artifact

signal watch_taken()

var is_player_near: bool = false
var has_been_taken: bool = false
var float_time: float = 0.0

@onready var watch_sprite: Sprite3D = $WatchSprite
@onready var watch_light: OmniLight3D = $WatchLight
@onready var prompt_label: Label3D = $PromptLabel
@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	area_3d.body_entered.connect(_on_body_entered)
	area_3d.body_exited.connect(_on_body_exited)
	prompt_label.visible = false

func _process(delta: float) -> void:
	if not has_been_taken:
		float_time += delta * 2.5
		# Gentle bobbing
		watch_sprite.position.y = 1.25 + sin(float_time) * 0.06
		# Light pulse
		watch_light.light_energy = 1.0 + sin(float_time * 2.0) * 0.3
		
		if is_player_near and Input.is_action_just_pressed("interact_strike"):
			take_watch()

func _on_body_entered(body: Node3D) -> void:
	if body is Player and not has_been_taken:
		is_player_near = true
		prompt_label.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		is_player_near = false
		prompt_label.visible = false

func take_watch() -> void:
	has_been_taken = true
	prompt_label.visible = false
	SoundManager.play_sfx("unlock")
	
	# Animate watch flying up and vanishing
	var tween = create_tween()
	tween.tween_property(watch_sprite, "position:y", 2.0, 0.4)
	tween.parallel().tween_property(watch_sprite, "scale", Vector3(1.5, 1.5, 1.5), 0.4)
	tween.parallel().tween_property(watch_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): 
		watch_sprite.visible = false
		watch_light.visible = false
	)
	
	watch_taken.emit()
