extends StaticBody3D
class_name RunicPlatform

# Runic platform for Degrees of Escape
# Solid in 2D mode, translucent non-colliding outline in 3D / 1D mode.

@export var is_powered: bool = true # If false, requires an EnergyReceiver to illuminate
@export var platform_size: Vector3 = Vector3(1.6, 0.2, 0.8)

@onready var platform_mesh: MeshInstance3D = $PlatformMesh
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var runic_light: OmniLight3D = $OmniLight3D

var mat_solid: StandardMaterial3D
var mat_faint: StandardMaterial3D

func _ready() -> void:
	collision_layer = 1
	setup_materials()
	Global.dimension_changed.connect(_on_dimension_changed)
	update_platform_state()

func setup_materials() -> void:
	mat_solid = StandardMaterial3D.new()
	mat_solid.albedo_color = Color(0.1, 0.3, 0.25, 1.0)
	mat_solid.emission_enabled = true
	mat_solid.emission = Color(0.2, 1.0, 0.6, 1.0)
	mat_solid.emission_energy_multiplier = 2.0
	
	mat_faint = StandardMaterial3D.new()
	mat_faint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_faint.albedo_color = Color(0.2, 0.8, 0.5, 0.22)
	mat_faint.emission_enabled = true
	mat_faint.emission = Color(0.2, 0.8, 0.5, 1.0)
	mat_faint.emission_energy_multiplier = 0.4

func _on_dimension_changed(_new_dim: Global.Dimension, _old_dim: Global.Dimension) -> void:
	update_platform_state()

func activate() -> void:
	is_powered = true
	update_platform_state()
	
	# Flare effect when receiving power
	var tween = create_tween()
	tween.tween_property(runic_light, "light_energy", 2.2, 0.15)
	tween.tween_property(runic_light, "light_energy", 0.8 if Global.active_dimension == Global.Dimension.DIM_2D else 0.1, 0.25)

func update_platform_state() -> void:
	if not is_powered:
		collision_shape.disabled = true
		platform_mesh.material_override = mat_faint
		runic_light.light_energy = 0.0
		return
		
	var is_2d = (Global.active_dimension == Global.Dimension.DIM_2D)
	
	collision_shape.disabled = not is_2d
	
	var tween = create_tween()
	if is_2d:
		platform_mesh.material_override = mat_solid
		tween.tween_property(runic_light, "light_energy", 1.0, 0.2)
	else:
		platform_mesh.material_override = mat_faint
		tween.tween_property(runic_light, "light_energy", 0.1, 0.2)
