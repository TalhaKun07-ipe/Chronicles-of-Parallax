extends Node3D
## Course state and marker-driven interactions. All lengths are in meters.
signal charge_collected
signal circuit_completed
signal chamber_completed
signal echo_found
signal plate_activated(upper: bool)

var carrying_charge: bool = false
var powered: bool = false
var completed: bool = false
var found_echo: bool = false
var first_rail_live: bool = false
var spatial_mode: int = 3
var charge_mesh: MeshInstance3D
var lit_material: StandardMaterial3D
var outline_material: StandardMaterial3D
var clock: float = 0.0

func _ready() -> void:
	lit_material = StandardMaterial3D.new()
	lit_material.albedo_color = Color("ebd8b0")
	lit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	charge_mesh = MeshInstance3D.new()
	var crystal := PrismMesh.new()
	crystal.size = Vector3(.28, .45, .28)
	charge_mesh.mesh = crystal
	charge_mesh.material_override = lit_material
	add_child(charge_mesh)
	charge_mesh.position = $Markers/Charge.position
	
	$Mechanisms/FirstConduit.hide()
	if has_node("Mechanisms/HighConduit"):
		$Mechanisms/HighConduit.hide()
	set_spatial_mode(3)

func _process(delta: float) -> void:
	clock += delta
	charge_mesh.rotation.y += delta
	charge_mesh.position.y = $Markers/Charge.position.y + sin(clock * 2.5) * .06

func set_spatial_mode(mode: int) -> void:
	spatial_mode = mode
	# Cut away near perimeter in side view; collisions stay in place.
	for name in ["ArrivalFrontWall", "CourtFrontWall"]:
		var node = get_node_or_null("Geometry/" + name)
		if node:
			node.visible = mode == 3
			
	# Terrace blocks are ALWAYS permanently visible 3D masonry blocks!
	for step in get_tree().get_nodes_in_group("bc_steps"):
		if not is_ancestor_of(step): continue
		# Ensure collision is solid for physical walking and jumping
		var col = step.get_node_or_null("Collision")
		if col:
			col.set_deferred("disabled", false)
		# Ensure meshes are always fully visible solid masonry
		for mesh in step.find_children("*", "MeshInstance3D"):
			if not mesh.has_meta("solid_material"):
				mesh.set_meta("solid_material", mesh.material_override)
			mesh.material_override = mesh.get_meta("solid_material")

func rail_near(at: Vector3) -> Dictionary:
	if first_rail_live:
		var start_pos: Vector3 = $Markers/RailStart.position
		var end_pos: Vector3 = $Markers/RailEnd.position
		if at.x >= start_pos.x - .5 and at.x <= end_pos.x + .5 and absf(at.z - start_pos.z) < .45 and absf(at.y - start_pos.y) < .45:
			return {
				"start": start_pos,
				"end": end_pos,
				"floor_y": 0.0,
				"gap_min": -3.0,
				"gap_max": 1.0
			}
	if powered and has_node("Markers/HighRailStart") and has_node("Markers/HighRailEnd"):
		var h_start: Vector3 = $Markers/HighRailStart.position
		var h_end: Vector3 = $Markers/HighRailEnd.position
		if at.x >= h_start.x - .55 and at.x <= h_end.x + .55 and absf(at.z - h_start.z) < .5 and absf(at.y - h_start.y) < .55:
			return {
				"start": h_start,
				"end": h_end,
				"floor_y": 0.85,
				"gap_min": 21.0,
				"gap_max": 26.0
			}
	return {}

func tick_player(at: Vector3) -> void:
	if not first_rail_live and Vector2(at.x, at.z).distance_to(Vector2(-9, 0)) < .8 and absf(at.y) < .25:
		first_rail_live = true
		$Mechanisms/FirstConduit.show()
		$Mechanisms/WakePlateInset/Mesh.material_override = lit_material
		plate_activated.emit(false)

func try_collect(at: Vector3) -> bool:
	if carrying_charge or powered: return false
	if at.distance_to($Markers/Charge.position) > 0.8: return false
	carrying_charge = true
	charge_mesh.hide()
	charge_collected.emit()
	return true

func try_interact(at: Vector3) -> String:
	if at.distance_to($Markers/Receiver.position) < 1.45:
		if powered: return "The terraces await. Jump up in 2D, then traverse front in 3D."
		if not carrying_charge: return "An empty socket. Bring the spark from the conduit."
		powered = true
		carrying_charge = false
		$Mechanisms/ReceiverSocket/Mesh.material_override = lit_material
		if has_node("Mechanisms/ExitSeal/Mesh"):
			$Mechanisms/ExitSeal/Mesh.material_override = lit_material
		if has_node("Mechanisms/HighConduit"):
			$Mechanisms/HighConduit.show()
		# Ignite runic terrace glyphs
		for r_name in ["Rune15.5", "Rune17.5", "Rune19.5"]:
			var node = get_node_or_null("Mechanisms/" + r_name + "/Mesh")
			if node: node.material_override = lit_material
		set_spatial_mode(spatial_mode)
		circuit_completed.emit()
		return "Circuit restored! The terrace runes ignite. Jump up in 2D!"
	if not found_echo and at.distance_to($Markers/Echo.position) < 1.5:
		found_echo = true
		echo_found.emit()
		return "Watch echo: Change your space to change your path."
	return ""

func try_exit(at: Vector3) -> bool:
	if completed or not powered: return false
	if at.distance_to($Markers/Exit.position) < 1.5:
		completed = true
		chamber_completed.emit()
		return true
	return false
