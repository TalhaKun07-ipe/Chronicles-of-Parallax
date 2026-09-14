extends Node3D
## Reusable room logic. No dependency on Global, Player.gd or another autoload.
signal charge_collected
signal circuit_completed
signal chamber_completed
signal echo_found

var carrying_charge: bool = false
var powered: bool = false
var completed: bool = false
var found_echo: bool = false
var spatial_mode: int = 3
var charge_mesh: MeshInstance3D
var lit_material: StandardMaterial3D
var outline_material: StandardMaterial3D
var clock: float = 0.0

func _ready() -> void:
	lit_material = StandardMaterial3D.new()
	lit_material.albedo_color = Color("d9b779")
	lit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(0.76, 0.62, 0.36, 0.32)
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	charge_mesh = MeshInstance3D.new()
	var crystal := PrismMesh.new()
	crystal.size = Vector3(0.3, 0.48, 0.3)
	charge_mesh.mesh = crystal
	charge_mesh.material_override = lit_material
	add_child(charge_mesh)
	charge_mesh.position = $Markers/Charge.position
	set_spatial_mode(3)

func _process(delta: float) -> void:
	clock += delta
	charge_mesh.rotation.y += delta
	charge_mesh.position.y = $Markers/Charge.position.y + sin(clock * 2.5) * 0.06

func set_spatial_mode(mode: int) -> void:
	spatial_mode = mode
	for step in get_tree().get_nodes_in_group("bc_steps"):
		if not is_ancestor_of(step):
			continue
		var active: bool = powered and mode == 2
		step.get_node("Collision").set_deferred("disabled", not active)
		step.get_node("Mesh").material_override = lit_material if active else outline_material
		step.get_child(2).visible = active

func try_collect(at: Vector3) -> bool:
	if carrying_charge or powered:
		return false
	if Vector2(at.x, at.z).distance_to(Vector2(-3.1, 0)) > 0.65 or absf(at.y - 0.2) > 0.65:
		return false
	carrying_charge = true
	charge_mesh.hide()
	charge_collected.emit()
	return true

func try_interact(at: Vector3) -> String:
	if at.distance_to($Markers/Receiver.global_position) < 1.35:
		if powered:
			return "The circuit is awake. Its steps belong to the plane."
		if not carrying_charge:
			return "An empty socket. Follow its broken gold line."
		carrying_charge = false
		powered = true
		$Mechanisms/ReceiverSocket/Mesh.material_override = lit_material
		$Mechanisms/ExitSeal/Mesh.material_override = lit_material
		set_spatial_mode(spatial_mode)
		circuit_completed.emit()
		return "The stairs remember their shape. Press 2."
	if not found_echo and at.distance_to($Markers/Echo.global_position) < 1.4:
		found_echo = true
		echo_found.emit()
		return "Watch echo: 'Less space can reveal another way.'"
	return ""

func try_exit(at: Vector3) -> bool:
	if completed or not powered:
		return false
	if at.distance_to($Markers/Exit.global_position) < 0.95:
		completed = true
		chamber_completed.emit()
		return true
	return false
