extends Node3D
class_name SwingingHazard

# Swinging pendulum / crushing barrier hazard for Chamber 1
# Sweeps across the middle track (Z = 0), requiring John Rod to shift to the back lane in 2.5D or dodge in 3D.

@export var swing_speed: float = 2.4
@export var max_angle_deg: float = 45.0
@export var damage_amount: int = 1

@onready var pivot: Node3D = $Pivot
@onready var hitbox: Area3D = $Pivot/BladeMesh/Hitbox
@onready var hum_light: OmniLight3D = $Pivot/BladeMesh/OmniLight3D

var time_passed: float = 0.0

func _ready() -> void:
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	time_passed += delta * swing_speed
	# Sinusoidal pendulum swing along Z axis
	var angle = sin(time_passed) * deg_to_rad(max_angle_deg)
	if pivot:
		pivot.rotation.x = angle
		
	# Subtle light pulsing at apex
	if hum_light:
		hum_light.light_energy = 1.0 + abs(sin(time_passed)) * 1.5

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body is Player:
		Global.take_damage(damage_amount)
