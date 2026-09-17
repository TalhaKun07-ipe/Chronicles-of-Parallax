extends Node3D
## Course state and marker-driven interactions for Chamber 1 (The Broken Circuit).
signal charge_collected
signal circuit_completed
signal chamber_completed
signal echo_found
signal plate_activated(upper: bool)
signal relay_activated

var carrying_charge: bool = false
var powered: bool = false
var completed: bool = false
var found_echo: bool = false
var spatial_mode: int = 3
var relay_active: bool = false
var bridge_reconstructed: bool = false
var charge_mesh: MeshInstance3D
var lit_material: Material
var clock: float = 0.0

func _ready() -> void:
	var holo_shader = load("res://shaders/hologram_bridge.gdshader")
	if holo_shader:
		var sm := ShaderMaterial.new()
		sm.shader = holo_shader
		lit_material = sm
	else:
		var std := StandardMaterial3D.new()
		std.albedo_color = Color("ebd8b0")
		std.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lit_material = std
	
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
	
	# Initially submerge runic bridge pieces into chasm and disable collision
	for bridge_name in ["RunicBridge1", "RunicBridge2"]:
		var b = get_node_or_null("Mechanisms/" + bridge_name)
		if b:
			b.position.y = -4.5
			var col = b.get_node_or_null("Collision")
			if col:
				col.disabled = true
				
	for r_name in ["RuneF64.2", "RuneF65.6", "RuneF67.0"]:
		var r = get_node_or_null("Mechanisms/" + r_name)
		if r:
			r.position.y = -4.5
	
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
		var should_hide: bool = hide_foreground and node.global_position.z > player_z + 0.6
		# Only hide visual mesh, physics collision stays 100% solid
		for mesh in node.find_children("*", "MeshInstance3D", true, false):
			mesh.visible = not should_hide
		_update_cutaway_outline(node, should_hide)

func _update_cutaway_outline(node: Node3D, show_outline: bool) -> void:
	# Blueprint-style glowing edge marking the wall's cross-section where a foreground
	# wall gets hidden in 2D, instead of the geometry just vanishing outright.
	var outline: Node3D = node.get_node_or_null("CutawayOutline")
	if not show_outline:
		if outline:
			outline.visible = false
		return
	if outline:
		outline.visible = true
		return
	var meshes: Array = node.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		return
	var mesh_inst: MeshInstance3D = meshes[0]
	var aabb: AABB = mesh_inst.get_aabb()
	if aabb.size.length() < 0.01:
		return
	var w: float = aabb.size.x
	var h: float = aabb.size.y
	var center: Vector3 = mesh_inst.position + aabb.position + aabb.size * 0.5
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.9, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.25, 0.9, 1.0)
	mat.emission_energy_multiplier = 2.2
	var root := Node3D.new()
	root.name = "CutawayOutline"
	var thick := 0.035
	var depth := 0.02
	var edges: Array = [
		[Vector3(0, h * 0.5, 0), Vector3(w, thick, depth)],
		[Vector3(0, -h * 0.5, 0), Vector3(w, thick, depth)],
		[Vector3(-w * 0.5, 0, 0), Vector3(thick, h, depth)],
		[Vector3(w * 0.5, 0, 0), Vector3(thick, h, depth)],
	]
	for edge: Array in edges:
		var m := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = edge[1]
		m.mesh = box
		m.material_override = mat
		m.position = center + edge[0]
		root.add_child(m)
	node.add_child(root)

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

	# Section F: Relay Court Conduit (Requires Relay Activation!)
	if has_node("Markers/Rail2Start") and has_node("Markers/Rail2End"):
		var r2_start: Vector3 = $Markers/Rail2Start.position
		var r2_end: Vector3 = $Markers/Rail2End.position
		if at.x >= r2_start.x - 0.7 and at.x <= r2_end.x + 0.7 \
				and absf(at.z - r2_start.z) < 0.6 and absf(at.y - r2_start.y) < 0.8:
			if not relay_active:
				return {}
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

func activate_relay() -> String:
	if relay_active:
		return "The relay terminal is already humming with power."
	relay_active = true
	var socket = get_node_or_null("Mechanisms/RelayTerminalSocket/Mesh")
	if socket:
		socket.material_override = lit_material
	var rail = get_node_or_null("Mechanisms/RelayConduit/Mesh")
	if rail:
		rail.material_override = lit_material
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("unlock")
		sm.play_sfx("energy_pulse")
	relay_activated.emit()
	return "Ancient Relay awakened! The conduit rail is energized for 1D transit."

func try_pulse(at: Vector3) -> String:
	if has_node("Markers/Relay") and at.distance_to($Markers/Relay.position) < 3.2:
		return activate_relay()
	return ""

func try_interact(at: Vector3) -> String:
	if has_node("Markers/Relay") and at.distance_to($Markers/Relay.position) < 2.5:
		return activate_relay()
		
	if has_node("Markers/Receiver") and at.distance_to($Markers/Receiver.position) < 1.6:
		if powered:
			return "The circuit hums with power. Proceed across the reconstructed bridge."
		if not carrying_charge:
			return "An empty circuit socket. Retrieve the energy charge through the 1D conduit."
		powered = true
		carrying_charge = false
		var socket_mesh = get_node_or_null("Mechanisms/ReceiverSocket/Mesh")
		if socket_mesh:
			socket_mesh.material_override = lit_material
		var seal_mesh = get_node_or_null("Mechanisms/ExitSeal/Mesh")
		if seal_mesh:
			seal_mesh.material_override = lit_material
		reconstruct_bridge()
		circuit_completed.emit()
		return "Circuit restored! Ancient mechanisms awaken — the Runic Bridge rises!"
	return ""

func reconstruct_bridge() -> void:
	if bridge_reconstructed:
		return
	bridge_reconstructed = true
	
	# 1. Light up receiver and bridge feed traces
	for trace_name in ["ReceiverTrace54.0", "ReceiverTrace56.0", "ReceiverTrace57.5", "BridgeFeedTrace60.5", "BridgeFeedTrace61.8"]:
		var trace = get_node_or_null("Details/" + trace_name + "/Mesh")
		if trace:
			trace.material_override = lit_material
			
	# 2. Audio feedback
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("stone_grind")
		
	# 3. Animate Bridge Segments rising from Y = -4.5 to Y = 3.325
	var b1 = get_node_or_null("Mechanisms/RunicBridge1")
	var b2 = get_node_or_null("Mechanisms/RunicBridge2")
	var r1 = get_node_or_null("Mechanisms/RuneF64.2")
	var r2 = get_node_or_null("Mechanisms/RuneF65.6")
	var r3 = get_node_or_null("Mechanisms/RuneF67.0")
	
	var tween = create_tween()
	tween.set_parallel(true)
	if b1:
		tween.tween_property(b1, "position:y", 3.325, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if r1:
		tween.tween_property(r1, "position:y", 3.62, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if b2:
		tween.tween_property(b2, "position:y", 3.325, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if r2:
		tween.tween_property(r2, "position:y", 3.62, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if r3:
		tween.tween_property(r3, "position:y", 3.62, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	tween.chain().tween_callback(func():
		# Enable solid collisions when segments are seated
		if b1:
			var col1 = b1.get_node_or_null("Collision")
			if col1: col1.disabled = false
		if b2:
			var col2 = b2.get_node_or_null("Collision")
			if col2: col2.disabled = false
		for r_name in ["RuneF64.2", "RuneF65.6", "RuneF67.0"]:
			var r_node = get_node_or_null("Mechanisms/" + r_name + "/Mesh")
			if r_node:
				r_node.material_override = lit_material
		if sm and sm.has_method("play_sfx"):
			sm.play_sfx("stone_lock")
	)

func try_exit(at: Vector3) -> bool:
	if completed or not powered:
		return false
	if has_node("Markers/Exit") and at.distance_to($Markers/Exit.position) < 2.0:
		completed = true
		chamber_completed.emit()
		return true
	return false
