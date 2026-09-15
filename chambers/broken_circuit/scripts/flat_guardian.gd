extends CharacterBody3D
class_name FlatGuardian

## The Flat Guardian: A paper-thin dimensional sentinel (inspired by 1 2 3D / To The Third).
## In 3D: Active physical entity that pursues John Rod and strikes with devastating slashes.
## In 2D: Collapses into an ethereal, paper-thin silhouette that John Rod can slip right through!

@export var speed: float = 2.8
@export var detection_radius: float = 8.0
@export var attack_radius: float = 1.35

var sprite: Sprite3D
var eye_light: OmniLight3D
var collision_shape: CollisionShape3D
var home_pos: Vector3
var patrol_dir: float = 1.0
var attack_cooldown: float = 0.0
var is_ethereal_2d: bool = false
var mode: int = 3
var float_clock: float = 0.0

@onready var player: CharacterBody3D = get_parent().get_node_or_null("Player")

func _ready() -> void:
	home_pos = global_position
	
	collision_shape = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.6
	collision_shape.shape = cap
	collision_shape.position.y = 0.8
	add_child(collision_shape)
	
	sprite = Sprite3D.new()
	sprite.texture = load("res://chambers/broken_circuit/assets/sprites/flat_guardian.png")
	sprite.pixel_size = 0.028
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.position.y = 0.8
	add_child(sprite)
	
	eye_light = OmniLight3D.new()
	eye_light.light_color = Color(1.0, 0.2, 0.15)
	eye_light.light_energy = 1.2
	eye_light.omni_range = 3.5
	eye_light.position.y = 0.95
	add_child(eye_light)

func _physics_process(delta: float) -> void:
	float_clock += delta * 4.0
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	
	if not player or not is_instance_valid(player):
		player = get_parent().get_node_or_null("Player")
		if not player: return
		
	var in_2d: bool = ("mode" in player and player.mode == 2)
	is_ethereal_2d = in_2d
	mode = 2 if in_2d else 3
	
	if in_2d:
		# 2D MODE: Ethereal paper-thin phase — John Rod can slip right through!
		collision_layer = 0
		collision_mask = 0
		sprite.modulate = Color(0.4, 0.8, 1.0, 0.22)
		eye_light.light_energy = 0.25
		velocity = Vector3.ZERO
		# Gentle ethereal hover
		sprite.position.y = 0.8 + sin(float_clock) * 0.06
	else:
		# 3D MODE: Active chasing guardian sentinel!
		collision_layer = 1
		collision_mask = 1
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		eye_light.light_energy = 1.35
		sprite.position.y = 0.8 + sin(float_clock * 1.5) * 0.04
		
		var to_player := Vector3(player.global_position.x - global_position.x, 0, player.global_position.z - global_position.z)
		var dist := to_player.length()
		
		if dist < detection_radius:
			# Face and pursue player
			sprite.flip_h = to_player.x < 0
			var chase_dir = to_player.normalized()
			velocity.x = chase_dir.x * speed
			velocity.z = chase_dir.z * speed
			move_and_slide()
			
			# Attack range
			if dist < attack_radius and attack_cooldown <= 0.0:
				attack_cooldown = 1.2
				_perform_attack()
		else:
			# Patrol near home arena
			velocity.x = patrol_dir * 1.2
			velocity.z = 0.0
			if absf(global_position.x - home_pos.x) > 3.2:
				patrol_dir *= -1.0
			move_and_slide()

func _perform_attack() -> void:
	# Telegraph lunge
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector3(1.4, 1.4, 1.4), 0.1)
	tween.tween_property(sprite, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	
	if player and player.has_method("take_damage"):
		player.take_damage(1, global_position)
