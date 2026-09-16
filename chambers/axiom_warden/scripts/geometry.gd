extends RefCounted
## Reusable, genuinely volumetric construction; collision never follows camera state.

const STONE_SHADER = preload("res://chambers/broken_circuit/stone.gdshader")

static func material(color: Color, glow: bool = false) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.85
	if glow:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.4
	return m

static func stone_material(color: Color) -> Material:
	if STONE_SHADER:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = STONE_SHADER
		sm.set_shader_parameter("stone_color", color)
		sm.set_shader_parameter("mortar_color", Color(color.r * 0.4, color.g * 0.4, color.b * 0.4, 1.0))
		sm.set_shader_parameter("highlight_color", Color(minf(1.0, color.r * 1.3), minf(1.0, color.g * 1.3), minf(1.0, color.b * 1.25), 1.0))
		return sm
	return material(color)

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var shape: BoxMesh = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)
	if solid:
		var body: StaticBody3D = StaticBody3D.new()
		var collider: CollisionShape3D = CollisionShape3D.new()
		var bounds: BoxShape3D = BoxShape3D.new()
		bounds.size = size
		collider.shape = bounds
		body.add_child(collider)
		mesh.add_child(body)
	return mesh

static func masonry_block(parent: Node3D, at: Vector3, size: Vector3, mat_body: Material, mat_coping: Material, mat_band: Material = null, solid: bool = true) -> MeshInstance3D:
	# Main structural body
	var body_mesh: MeshInstance3D = box(parent, at - Vector3(0, 0.05, 0), Vector3(size.x, maxf(0.1, size.y - 0.1), size.z), mat_body, solid)
	# Top beveled coping
	box(parent, Vector3(at.x, at.y + size.y * 0.5 - 0.05, at.z), Vector3(size.x + 0.1, 0.1, size.z + 0.1), mat_coping)
	# Front decorative band if specified
	if mat_band:
		box(parent, Vector3(at.x, at.y + size.y * 0.5 - 0.18, at.z + size.z * 0.5 + 0.02), Vector3(size.x, 0.06, 0.04), mat_band)
	return body_mesh

static func column(parent: Node3D, at: Vector3, radius: float, height: float, mat_base: Material, mat_pillar: Material, mat_cap: Material) -> Node3D:
	var root: Node3D = Node3D.new()
	root.position = at
	parent.add_child(root)
	# Base plinth
	box(root, Vector3(0, 0.25, 0), Vector3(radius * 2.5, 0.5, radius * 2.5), mat_base)
	box(root, Vector3(0, 0.55, 0), Vector3(radius * 2.2, 0.1, radius * 2.2), mat_cap)
	# Pillar shaft
	var shaft: MeshInstance3D = MeshInstance3D.new()
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 1.05
	cyl.height = height - 1.0
	cyl.radial_segments = 16
	shaft.mesh = cyl
	shaft.material_override = mat_pillar
	shaft.position = Vector3(0, (height - 1.0) * 0.5 + 0.6, 0)
	root.add_child(shaft)
	# Capital
	box(root, Vector3(0, height - 0.25, 0), Vector3(radius * 2.6, 0.5, radius * 2.6), mat_cap)
	return root

static func torch(parent: Node3D, at: Vector3, color: Color = Color("ffc97a"), energy: float = 0.9, light_range: float = 6.0) -> OmniLight3D:
	var dark: Material = material(Color("261708"))
	var gold: Material = material(Color("d0a156"))
	var flame: Material = material(Color("ffbb44"), true)
	# Bracket
	box(parent, at + Vector3(0, -0.2, 0.05), Vector3(0.08, 0.45, 0.06), dark)
	box(parent, at + Vector3(0, 0.0, 0.15), Vector3(0.08, 0.06, 0.25), dark)
	# Cup
	box(parent, at + Vector3(0, 0.08, 0.26), Vector3(0.22, 0.14, 0.22), gold)
	# Flame ember
	box(parent, at + Vector3(0, 0.22, 0.26), Vector3(0.12, 0.18, 0.12), flame)
	# Light
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at + Vector3(0, 0.35, 0.35)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)
	return light

static func ring(parent: Node3D, at: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh: MeshInstance3D = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = radius - thickness
	torus.outer_radius = radius + thickness
	torus.rings = 40
	torus.ring_segments = 8
	mesh.mesh = torus
	mesh.material_override = mat
	mesh.position = at
	parent.add_child(mesh)
	return mesh
