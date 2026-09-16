extends RefCounted
## Reusable, genuinely volumetric construction; collision never follows camera state.

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
