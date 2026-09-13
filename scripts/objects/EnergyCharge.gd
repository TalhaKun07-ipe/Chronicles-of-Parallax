extends Area3D
class_name EnergyCharge

# Collectible energy charge for Degrees of Escape
# Used to power ancient receivers and unlock chamber pathways.

@export var charge_id: String = "arrival_charge"

@onready var core_mesh: MeshInstance3D = $CoreMesh
@onready var glow_light: OmniLight3D = $OmniLight3D

var is_collected: bool = false
var base_y: float = 0.0

func _ready() -> void:
	base_y = position.y
	body_entered.connect(_on_body_entered)
	
	# Check if already collected in saved chamber state
	if Global.carried_charge:
		# Player is already holding a charge
		pass

func _process(delta: float) -> void:
	if not is_collected:
		# Floating bob and gentle rotation
		core_mesh.rotation.y += delta * 1.5
		core_mesh.rotation.x += delta * 0.8
		position.y = base_y + sin(Time.get_ticks_msec() * 0.0035) * 0.12

func _on_body_entered(body: Node3D) -> void:
	if is_collected:
		return
	if body is Player:
		collect()

func collect() -> void:
	is_collected = true
	Global.collect_charge()
	
	# Pickup celebration tween
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(core_mesh, "scale", Vector3(1.8, 1.8, 1.8), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_property(glow_light, "light_energy", 3.0, 0.2)
	tween.chain().tween_property(core_mesh, "scale", Vector3(0.0, 0.0, 0.0), 0.18).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(glow_light, "light_energy", 0.0, 0.18)
	tween.tween_callback(func(): visible = false)
