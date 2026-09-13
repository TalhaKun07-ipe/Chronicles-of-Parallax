extends StaticBody3D
class_name MechanicalShutter

# Mechanical Shutter for Chamber 2 (The Moving Wall)
# Periodically blocks a conduit until a rear mechanism locks it open permanently.

@export var is_permanently_open: bool = false
@export var cycle_time: float = 3.0
@export var open_duration: float = 1.5

@onready var shutter_mesh: MeshInstance3D = $ShutterMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var warning_light: OmniLight3D = $OmniLight3D
@onready var crush_area: Area3D = $CrushArea

var timer: float = 0.0
var is_open: bool = false
var initial_y: float = 0.0

func _ready() -> void:
	initial_y = shutter_mesh.position.y
	crush_area.body_entered.connect(_on_crush_body_entered)
	if is_permanently_open:
		lock_open()

func _physics_process(delta: float) -> void:
	if is_permanently_open:
		return
		
	timer += delta
	if is_open:
		if timer >= open_duration:
			close_shutter()
	else:
		# Warning flash 0.6s before opening
		if timer >= (cycle_time - 0.6):
			var flash = sin(timer * 25.0) * 0.5 + 0.5
			warning_light.light_color = Color(1.0, 0.3, 0.1)
			warning_light.light_energy = 1.5 * flash
		if timer >= cycle_time:
			open_shutter()

func open_shutter() -> void:
	is_open = true
	timer = 0.0
	warning_light.light_color = Color(0.2, 1.0, 0.4)
	warning_light.light_energy = 1.2
	
	var tween = create_tween()
	tween.tween_property(shutter_mesh, "position:y", initial_y + 2.4, 0.25).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func(): collision_shape.disabled = true)

func close_shutter() -> void:
	is_open = false
	timer = 0.0
	collision_shape.disabled = false
	warning_light.light_color = Color(1.0, 0.2, 0.1)
	warning_light.light_energy = 0.8
	
	var tween = create_tween()
	tween.tween_property(shutter_mesh, "position:y", initial_y, 0.15).set_trans(Tween.TRANS_BOUNCE)
	SoundManager.play_sfx("hurt")

func lock_open() -> void:
	is_permanently_open = true
	is_open = true
	collision_shape.disabled = true
	warning_light.light_color = Color(0.2, 1.0, 0.6)
	warning_light.light_energy = 1.5
	
	var tween = create_tween()
	tween.tween_property(shutter_mesh, "position:y", initial_y + 2.4, 0.4).set_trans(Tween.TRANS_BACK)

func _on_crush_body_entered(body: Node3D) -> void:
	if is_permanently_open or is_open:
		return
	if body is Player:
		# Failed crossing pushes John safely back to rail entrance
		SoundManager.play_sfx("hurt")
		body.velocity = Vector3(-4.0, 0, 0)
