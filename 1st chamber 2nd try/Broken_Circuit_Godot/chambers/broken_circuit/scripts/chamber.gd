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
var upper_rail_live: bool = false
var shutter_open: bool = false
var spatial_mode: int = 3
var charge_mesh: MeshInstance3D
var lit_material: StandardMaterial3D
var outline_material: StandardMaterial3D
var clock: float = 0.0
var shutter_clock: float = 0.0
var indicator_material: Material

func _ready() -> void:
	indicator_material = $Mechanisms/ShutterIndicator/Mesh.material_override
	lit_material = StandardMaterial3D.new()
	lit_material.albedo_color = Color("ebd8b0")
	lit_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material = StandardMaterial3D.new()
	outline_material.albedo_color = Color(0.65,0.56,0.38,0.14)
	outline_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	charge_mesh = MeshInstance3D.new()
	var crystal := PrismMesh.new()
	crystal.size = Vector3(.28,.45,.28)
	charge_mesh.mesh = crystal
	charge_mesh.material_override = lit_material
	add_child(charge_mesh)
	charge_mesh.position = $Markers/Charge.position
	$Mechanisms/FirstConduit.hide()
	$Mechanisms/UpperConduit.hide()
	set_spatial_mode(3)

func _process(delta: float) -> void:
	clock += delta
	charge_mesh.rotation.y += delta
	charge_mesh.position.y = $Markers/Charge.position.y + sin(clock * 2.5) * .06
	if upper_rail_live:
		shutter_clock += delta
	var cycle: float = fmod(shutter_clock,4.8)
	shutter_open = upper_rail_live and cycle < 3.0
	$Mechanisms/Shutter.position.y = 5.4 if shutter_open else 3.42
	$Mechanisms/Shutter/Collision.set_deferred("disabled",shutter_open)
	$Mechanisms/ShutterIndicator/Mesh.material_override = lit_material if shutter_open else indicator_material
	if upper_rail_live and cycle > 2.4 and cycle < 3.0:
		$Mechanisms/ShutterIndicator.visible = int(clock*10) % 2 == 0
	else:
		$Mechanisms/ShutterIndicator.show()

func set_spatial_mode(mode: int) -> void:
	spatial_mode = mode
	# Cut away the near perimeter in side view; collisions stay in place.
	for name in ["ArrivalFrontWall","CourtFrontWall","ExitFrontWall"]:
		get_node("Geometry/"+name).visible = mode == 3
	for step in get_tree().get_nodes_in_group("bc_steps"):
		if not is_ancestor_of(step): continue
		var active: bool = powered and mode == 2
		step.get_node("Collision").set_deferred("disabled",not active)
		for mesh in step.find_children("*","MeshInstance3D"):
			if not mesh.has_meta("solid_material"):
				mesh.set_meta("solid_material",mesh.material_override)
			mesh.material_override = mesh.get_meta("solid_material") if active else outline_material

func rail_near(at: Vector3) -> Dictionary:
	var rails: Array[Dictionary] = []
	if first_rail_live:
		rails.append({"start":$Markers/RailStart.position,"end":$Markers/RailEnd.position,"floor_y":0.0,"gap_min":-3.0,"gap_max":1.0})
	if upper_rail_live:
		rails.append({"start":$Markers/UpperRailStart.position,"end":$Markers/UpperRailEnd.position,"floor_y":2.55,"gap_min":40.0,"gap_max":44.0})
	for rail in rails:
		if at.x >= rail.start.x-.4 and at.x <= rail.end.x+.4 and absf(at.z-rail.start.z)<.35 and absf(at.y-rail.start.y)<.4:
			return rail
	return {}

func tick_player(at: Vector3) -> void:
	if not first_rail_live and Vector2(at.x,at.z).distance_to(Vector2(-9,0)) < .8 and absf(at.y)<.25:
		first_rail_live = true
		$Mechanisms/FirstConduit.show()
		$Mechanisms/WakePlateInset/Mesh.material_override = lit_material
		plate_activated.emit(false)
	if powered and not upper_rail_live and at.distance_to($Markers/UpperPlate.position)<1.0:
		upper_rail_live = true
		shutter_clock = 0
		$Mechanisms/UpperConduit.show()
		$Mechanisms/UpperPlateInset/Mesh.material_override = lit_material
		plate_activated.emit(true)

func try_collect(at: Vector3) -> bool:
	if carrying_charge or powered: return false
	if at.distance_to($Markers/Charge.position)>0.8: return false
	carrying_charge = true
	charge_mesh.hide()
	charge_collected.emit()
	return true

func try_interact(at: Vector3) -> String:
	if at.distance_to($Markers/Receiver.position)<1.45:
		if powered: return "The terraces await. Choose 2D on the rear gold path."
		if not carrying_charge: return "An empty socket. Bring the spark from the conduit."
		powered = true
		carrying_charge = false
		$Mechanisms/ReceiverSocket/Mesh.material_override = lit_material
		$Mechanisms/ExitSeal/Mesh.material_override = lit_material
		set_spatial_mode(spatial_mode)
		circuit_completed.emit()
		return "Circuit restored. The rear terraces take shape in 2D."
	if not found_echo and at.distance_to($Markers/Echo.position)<1.5:
		found_echo = true
		echo_found.emit()
		return "Watch echo: Change your space to change your path."
	return ""

func try_exit(at: Vector3) -> bool:
	if completed or not powered or not upper_rail_live: return false
	if at.distance_to($Markers/Exit.position)<1.0:
		completed = true
		chamber_completed.emit()
		return true
	return false
