extends Node3D
## Course state and marker-driven interactions for Chamber 1 (The Broken Circuit).
signal charge_collected
signal circuit_completed
signal chamber_completed
signal echo_found
signal plate_activated(upper: bool)

var carrying_charge: bool = false
var powered: bool = false
var completed: bool = false
var found_echo: bool = false
var spatial_mode: int = 3
var charge_mesh: MeshInstance3D
var lit_material: StandardMaterial3D
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
	if has_node("Markers/Charge"):
		charge_mesh.position = $Markers/Charge.position
	else:
		charge_mesh.position = Vector3(56.0, 3.65, 3.5)
	
	# All 3 conduit rails are visible and active
	for rail_name in ["FirstConduit", "RelayConduit", "HighConduit"]:
		var node = get_node_or_null("Mechanisms/" + rail_name)
		if node:
			node.show()
			
	set_spatial_mode(3)

func _physics_process(delta: float) -> void:
	clock += delta
	if charge_mesh and is_instance_valid(charge_mesh):
		charge_mesh.rotation.y += delta
		if has_node("Markers/Charge"):
			charge_mesh.position.y = $Markers/Charge.position.y + sin(clock * 2.5) * .06
			
	# Animate Moving Platform in Section E (Oscillating across gap between X=38.4 and X=41.6)
	var moving_plat = get_node_or_null("Mechanisms/MovingPlatform")
	var moving_trim = get_node_or_null("Mechanisms/MovingPlatformTrim")
	var plat_x: float = 40.0 + sin(clock * 1.4) * 1.6
	if moving_plat:
		moving_plat.position.x = plat_x
	if moving_trim:
		moving_trim.position.x = plat_x

func set_spatial_mode(mode: int) -> void:
	spatial_mode = mode
	update_occlusion(0.0)

func update_occlusion(player_z: float) -> void:
	# Hide foreground wall meshes that occlude John or platforms in 2D side view
	var hide_foreground: bool = (spatial_mode == 2)
	for node in get_tree().get_nodes_in_group("fg_walls"):
		if not is_ancestor_of(node):
			continue
		# Only hide visual mesh, physics collision stays 100% solid
		for mesh in node.find_children("*", "MeshInstance3D", true, false):
			if hide_foreground and node.global_position.z > player_z + 0.6:
				mesh.visible = false
			else:
				mesh.visible = true

func rail_near(at: Vector3) -> Dictionary:
	# Section D: The Narrow Conduit
	if has_node("Markers/Rail1Start") and has_node("Markers/Rail1End"):
		var r1_start: Vector3 = $Markers/Rail1Start.position
		var r1_end: Vector3 = $Markers/Rail1End.position
		if at.x >= r1_start.x - 0.7 and at.x <= r1_end.x + 0.7 \
				and absf(at.z - r1_start.z) < 0.6 and absf(at.y - r1_start.y) < 0.8:
			return {
				"start": r1_start,
				"end": r1_end,
				"floor_y": 2.40,
				"gap_min": 17.0,
				"gap_max": 24.5
			}
	# Backward-compatibility check for old RailStart/RailEnd markers
	elif has_node("Markers/RailStart") and has_node("Markers/RailEnd"):
		var start_pos: Vector3 = $Markers/RailStart.position
		var end_pos: Vector3 = $Markers/RailEnd.position
		if at.x >= start_pos.x - 0.7 and at.x <= end_pos.x + 0.7 \
				and absf(at.z - start_pos.z) < 0.6 and absf(at.y - start_pos.y) < 0.8:
			return {
				"start": start_pos,
				"end": end_pos,
				"floor_y": 2.40,
				"gap_min": 17.0,
				"gap_max": 24.5
			}

	# Section F: Relay Court Conduit
	if has_node("Markers/Rail2Start") and has_node("Markers/Rail2End"):
		var r2_start: Vector3 = $Markers/Rail2Start.position
		var r2_end: Vector3 = $Markers/Rail2End.position
		if at.x >= r2_start.x - 0.7 and at.x <= r2_end.x + 0.7 \
				and absf(at.z - r2_start.z) < 0.6 and absf(at.y - r2_start.y) < 0.8:
			return {
				"start": r2_start,
				"end": r2_end,
				"floor_y": 3.00,
				"gap_min": 52.5,
				"gap_max": 54.5
			}

	# Section G: High Conduit
	if has_node("Markers/HighRailStart") and has_node("Markers/HighRailEnd"):
		var h_start: Vector3 = $Markers/HighRailStart.position
		var h_end: Vector3 = $Markers/HighRailEnd.position
		if at.x >= h_start.x - 0.7 and at.x <= h_end.x + 0.7 \
				and absf(at.z - h_start.z) < 0.6 and absf(at.y - h_start.y) < 0.8:
			return {
				"start": h_start,
				"end": h_end,
				"floor_y": 5.20,
				"gap_min": 80.5,
				"gap_max": 85.0
			}

	return {}

func tick_player(at: Vector3) -> void:
	update_occlusion(at.z)

func try_collect(at: Vector3) -> bool:
	if carrying_charge or powered:
		return false
	if not has_node("Markers/Charge"):
		return false
	if at.distance_to($Markers/Charge.position) > 1.2:
		return false
	carrying_charge = true
	if charge_mesh:
		charge_mesh.hide()
	charge_collected.emit()
	return true

func try_interact(at: Vector3) -> String:
	if has_node("Markers/Receiver") and at.distance_to($Markers/Receiver.position) < 1.6:
		if powered:
			return "The circuit hums with power. Proceed up the runic terrace."
		if not carrying_charge:
			return "An empty circuit socket. Retrieve the spark through the conduit."
		powered = true
		carrying_charge = false
		var socket_mesh = get_node_or_null("Mechanisms/ReceiverSocket/Mesh")
		if socket_mesh:
			socket_mesh.material_override = lit_material
		var seal_mesh = get_node_or_null("Mechanisms/ExitSeal/Mesh")
		if seal_mesh:
			seal_mesh.material_override = lit_material
		# Ignite runic bridge glyphs
		for r_name in ["RuneF64.8", "RuneF66.2", "RuneF67.4"]:
			var node = get_node_or_null("Mechanisms/" + r_name + "/Mesh")
			if node:
				node.material_override = lit_material
		circuit_completed.emit()
		return "Circuit restored! The runic bridge ignites. The ascent is open!"
	return ""

func try_exit(at: Vector3) -> bool:
	if completed or not powered:
		return false
	if has_node("Markers/Exit") and at.distance_to($Markers/Exit.position) < 2.0:
		completed = true
		chamber_completed.emit()
		return true
	return false
