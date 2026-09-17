extends RefCounted
## Reusable, genuinely volumetric construction; collision never follows camera state.

const STONE_SHADER = preload("res://chambers/broken_circuit/stone.gdshader")
const CONDUIT_SHADER = preload("res://shaders/energy_conduit.gdshader")
const HOLOGRAM_SHADER = preload("res://shaders/hologram_bridge.gdshader")
const SHOCKWAVE_SHADER = preload("res://shaders/shockwave_ring.gdshader")

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

static func conduit_material(core_col: Color = Color(0.88, 0.98, 1.0, 1.0), plasma_col: Color = Color(0.20, 0.82, 0.86, 1.0)) -> Material:
	if CONDUIT_SHADER:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = CONDUIT_SHADER
		sm.set_shader_parameter("core_color", core_col)
		sm.set_shader_parameter("plasma_color", plasma_col)
		return sm
	return material(plasma_col, true)

static func hologram_material(glow_col: Color = Color(0.96, 0.68, 0.15, 1.0), core_col: Color = Color(1.0, 0.96, 0.82, 1.0)) -> Material:
	if HOLOGRAM_SHADER:
		var sm: ShaderMaterial = ShaderMaterial.new()
		sm.shader = HOLOGRAM_SHADER
		sm.set_shader_parameter("rune_glow_color", glow_col)
		sm.set_shader_parameter("rune_core_color", core_col)
		sm.set_shader_parameter("rune_edge_color", Color(glow_col.r * 0.5, glow_col.g * 0.5, glow_col.b * 0.5, 1.0))
		return sm
	return material(glow_col, true)

static func shockwave_material(core_col: Color = Color(1.0, 0.55, 0.2, 1.0), edge_col: Color = Color(0.4, 0.1, 0.02, 1.0)) -> ShaderMaterial:
	var sm: ShaderMaterial = ShaderMaterial.new()
	sm.shader = SHOCKWAVE_SHADER
	sm.set_shader_parameter("core_color", core_col)
	sm.set_shader_parameter("edge_color", edge_col)
	return sm

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
	var flame_mesh: MeshInstance3D = box(parent, at + Vector3(0, 0.22, 0.26), Vector3(0.12, 0.18, 0.12), flame)
	# Light
	var light: OmniLight3D = OmniLight3D.new()
	light.position = at + Vector3(0, 0.35, 0.35)
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)
	_flicker(light, flame_mesh, energy)
	return light

static func _flicker(light: OmniLight3D, flame: MeshInstance3D, base_energy: float) -> void:
	# Living fire instead of a static glow: a looping chain of randomized energy/scale
	# keyframes so nearby torches don't flicker in obvious unison.
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var tween: Tween = light.create_tween()
	tween.set_loops()
	for i in 8:
		var e: float = base_energy * rng.randf_range(0.7, 1.3)
		var d: float = rng.randf_range(0.06, 0.16)
		tween.tween_property(light, "light_energy", e, d)
		if flame:
			var s: float = rng.randf_range(0.82, 1.2)
			tween.parallel().tween_property(flame, "scale", Vector3(s, rng.randf_range(0.85, 1.25), s), d)

static func impact_burst(parent: Node3D, at: Vector3, color: Color = Color("ffb15c"), count: int = 22) -> void:
	# Deliberately NOT parented under `parent` directly: hazard.gd's caller passes its own
	# parent (the shared "Hazards" container), and other code (including the verify suite)
	# assumes every child there is a Hazard with a `.kind` property. Attaching to the scene
	# root instead keeps this purely-visual burst invisible to that assumption.
	var host: Node = parent
	if parent.get_tree():
		host = parent.get_tree().current_scene if parent.get_tree().current_scene else parent.get_tree().root
	var particles: GPUParticles3D = GPUParticles3D.new()
	particles.amount = count
	particles.lifetime = 0.55
	particles.one_shot = true
	particles.explosiveness = 1.0
	host.add_child(particles)
	particles.global_position = at
	var p_mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
	p_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	p_mat.emission_sphere_radius = 0.15
	p_mat.direction = Vector3(0, 1, 0)
	p_mat.spread = 60.0
	p_mat.initial_velocity_min = 2.0
	p_mat.initial_velocity_max = 4.5
	p_mat.gravity = Vector3(0, -6.0, 0)
	p_mat.scale_min = 0.05
	p_mat.scale_max = 0.14
	p_mat.color = color
	particles.process_material = p_mat
	var quad: QuadMesh = QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var quad_mat: StandardMaterial3D = StandardMaterial3D.new()
	quad_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad_mat.albedo_color = color
	quad_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = quad_mat
	particles.draw_pass_1 = quad
	particles.emitting = true
	var timer: SceneTreeTimer = parent.get_tree().create_timer(particles.lifetime + 0.2)
	timer.timeout.connect(func(): if is_instance_valid(particles): particles.queue_free())

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
