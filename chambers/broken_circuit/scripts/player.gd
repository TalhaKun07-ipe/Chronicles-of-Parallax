extends CharacterBody3D
## Demo controller. Keep your own controller when integrating the room.
signal mode_changed(mode: int)
signal notice(text: String)

const SPEED: float = 4.0
const GRAVITY: float = 18.0
const JUMP: float = 6.5
const ART: String = "res://chambers/broken_circuit/assets/sprites/"
var mode: int = 3
var plane_z: float = 0.0
var active_rail: Dictionary = {}
var gallery_reached: bool = false
var checkpoint: Vector3 = Vector3(-11.5, 0.08, 0)
var shape_node: CollisionShape3D
var humanoid: CapsuleShape3D
var rod: BoxShape3D
var sprite: Sprite3D
var shadow_mesh: MeshInstance3D
var charge_orb: MeshInstance3D
var animation_time: float = 0.0
var move_input: Vector2 = Vector2.ZERO
var input_override: bool = false
var override_jump: bool = false
var texture_cache: Dictionary = {}
var coyote: float = 0.0
var jump_buffer: float = 0.0
var pulse_cooldown: float = 0.0
var invulnerable_timer: float = 0.0
@onready var chamber: Node3D = get_parent().get_node("Chamber")

func _ready() -> void:
	floor_snap_length = 0.16
	humanoid = CapsuleShape3D.new()
	humanoid.radius = 0.16
	humanoid.height = 1.14
	rod = BoxShape3D.new()
	rod.size = Vector3(0.58, 0.12, 0.12)
	shape_node = CollisionShape3D.new()
	shape_node.shape = humanoid
	shape_node.position.y = 0.575
	add_child(shape_node)
	sprite = Sprite3D.new()
	sprite.pixel_size = 0.024
	sprite.position.y = 0.576
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.no_depth_test = false
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(sprite)
	
	# Grounding Dynamic Drop Shadow
	shadow_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.65, 0.45)
	shadow_mesh.mesh = quad
	var shadow_shader = load("res://shaders/character_shadow.gdshader")
	if shadow_shader:
		var sm := ShaderMaterial.new()
		sm.shader = shadow_shader
		shadow_mesh.material_override = sm
	shadow_mesh.rotation_degrees.x = -90.0
	shadow_mesh.position.y = 0.02
	add_child(shadow_mesh)
	charge_orb = MeshInstance3D.new()
	var orb := SphereMesh.new()
	orb.radius = 0.1
	orb.height = 0.2
	charge_orb.mesh = orb
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("ebd8b0")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	charge_orb.material_override = mat
	charge_orb.position.y = 1.45
	add_child(charge_orb)
	_update_sprite()

func action_pressed(action: String) -> bool:
	return InputMap.has_action(action) and Input.is_action_pressed(action)

func _unhandled_key_input(event: InputEvent) -> void:
	for pair in [["dimension_0",0],["dimension_1",1],["dimension_2",2],["dimension_3",3]]:
		if InputMap.has_action(pair[0]) and event.is_action_pressed(pair[0]):
			request_mode(pair[1])
			return
	for pair in [["cycle_prev",-1],["cycle_next",1]]:
		if InputMap.has_action(pair[0]) and event.is_action_pressed(pair[0]):
			request_mode(clampi(mode + pair[1], 1, 3))
			return
	if InputMap.has_action("jump") and event.is_action_pressed("jump"):
		if mode == 2:
			jump_buffer = 0.12
		return
	if InputMap.has_action("interact_strike") and event.is_action_pressed("interact_strike"):
		var mapped_message: String = chamber.try_interact(global_position)
		if not mapped_message.is_empty(): notice.emit(mapped_message)
		return
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: request_mode(1)
		KEY_2: request_mode(2)
		KEY_3: request_mode(3)
		KEY_Q, KEY_Z: request_mode(maxi(1, mode - 1))
		KEY_E, KEY_X: request_mode(mini(3, mode + 1))
		KEY_SPACE:
			if mode == 2:
				jump_buffer = 0.12
		KEY_F:
			var message: String = chamber.try_interact(global_position)
			if not message.is_empty():
				notice.emit(message)
		KEY_BACKSPACE: respawn()

func has_clearance(at: Vector3) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = humanoid
	query.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, 0.59, 0))
	query.exclude = [get_rid()]
	query.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func request_mode(target: int) -> bool:
	if target < 1 or target > 3:
		return false
	if target == mode:
		return true
	jump_buffer = 0.0 # Clear incompatible jump buffers during dimension changes
	var preserved_vy: float = velocity.y
	
	if target == 1:
		var found: Dictionary = chamber.rail_near(position)
		if found.is_empty():
			if not chamber.relay_active:
				notice.emit("The conduit rail is dormant. Awaken the Relay Terminal first.")
			else:
				notice.emit("Stand on a powered conduit to enter 1D.")
			return false
		active_rail = found
		position = Vector3(clampf(position.x, found.start.x, found.end.x), found.start.y, found.start.z)
		shape_node.shape = rod
		shape_node.position.y = 0
		sprite.position.y = 0
		sprite.scale = Vector3.ONE
		velocity = Vector3.ZERO
		coyote = 0.0
	else:
		var destination := position
		# Restore feet to floor height when leaving the rail, without changing X/Z.
		if mode == 1:
			destination.y = float(active_rail.floor_y) + 0.04
			if destination.x > float(active_rail.gap_min) and destination.x < float(active_rail.gap_max):
				notice.emit("No foothold here. Slide to the far socket.")
				return false
		if not has_clearance(destination):
			notice.emit("No room to expand. Stay flat a little longer.")
			return false
		position = destination
		shape_node.shape = humanoid
		shape_node.position.y = 0.575
		sprite.position.y = 0.576
		sprite.scale = Vector3.ONE
		plane_z = position.z
		# Preserve existing vertical velocity across 2D <-> 3D transitions without extra impulse or jump reset
		velocity.y = preserved_vy
		velocity.z = 0.0
		if target != 2:
			coyote = 0.0
	mode = target
	if shadow_mesh:
		shadow_mesh.visible = (mode != 1)
	chamber.set_spatial_mode(mode)
	mode_changed.emit(mode)
	_update_sprite()
	return true

func pulse() -> void:
	if pulse_cooldown > 0.0:
		return
	pulse_cooldown = 0.4
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("pulse")
	_create_pulse_ring()
	var msg: String = chamber.try_pulse(global_position)
	if not msg.is_empty():
		notice.emit(msg)

func _create_pulse_ring() -> void:
	var ring = MeshInstance3D.new()
	var torus = TorusMesh.new()
	torus.inner_radius = 0.4
	torus.outer_radius = 0.6
	ring.mesh = torus
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("ebd8b0")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring.material_override = mat
	add_child(ring)
	ring.position = Vector3(0, 0.2, 0)
	ring.scale = Vector3(0.2, 0.2, 0.2)
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(ring, "scale", Vector3(3.5, 0.2, 3.5), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	t.chain().tween_callback(ring.queue_free)

func _physics_process(delta: float) -> void:
	animation_time += delta
	if pulse_cooldown > 0.0:
		pulse_cooldown = maxf(0.0, pulse_cooldown - delta)
	if not input_override:
		move_input = Vector2(
			float(action_pressed("move_right") or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(action_pressed("move_left") or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(action_pressed("move_down") or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(action_pressed("move_up") or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if mode == 1:
		velocity = Vector3(move_input.x * 3.5, 0, 0)
		move_and_slide()
		position.x = clampf(position.x, active_rail.start.x, active_rail.end.x)
		position.y = active_rail.start.y
		position.z = active_rail.start.z
	else:
		var on_floor := is_on_floor()
		var direction := Vector3.ZERO
		if mode == 3:
			# Depth steering requires being grounded so player cannot bypass puzzles by midair lane steering
			var input_z: float = move_input.y if on_floor else 0.0
			direction = Vector3(move_input.x, 0, input_z)
			direction = direction.rotated(Vector3.UP, deg_to_rad(-45.0))
			if direction.length() > 1:
				direction = direction.normalized()
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED if on_floor else 0.0
		else: # mode == 2
			direction = Vector3(move_input.x, 0, 0.0)
			if direction.length() > 1:
				direction = direction.normalized()
			velocity.x = direction.x * SPEED
			velocity.z = 0.0

		coyote = 0.1 if (on_floor and mode == 2) else maxf(0, coyote - delta)
		jump_buffer = maxf(0, jump_buffer - delta)
		if override_jump:
			if mode == 2:
				jump_buffer = 0.12
			override_jump = false

		# Only 2D can initiate a jump!
		if mode == 2 and jump_buffer > 0 and coyote > 0:
			velocity.y = JUMP
			jump_buffer = 0
			coyote = 0
		else:
			velocity.y -= GRAVITY * delta

		move_and_slide()
		if mode == 2:
			position.z = plane_z
	chamber.tick_player(global_position)
	
	# Checkpoint zones across the 8 sections
	if position.x >= 90.0:
		checkpoint = Vector3(91.0, 5.88, 0.0)
	elif position.x >= 69.0:
		checkpoint = Vector3(69.5, 4.28, -3.5)
	elif position.x >= 49.0:
		checkpoint = Vector3(49.5, 3.08, 0.0)
	elif position.x >= 26.0:
		checkpoint = Vector3(26.5, 2.48, -4.0)
	elif position.x >= 15.0:
		checkpoint = Vector3(15.5, 2.48, -4.0)
	elif position.x >= 6.0:
		checkpoint = Vector3(6.5, 2.48, 0.0)
		
	if position.y < -6.0:
		respawn()
		
	chamber.try_collect(global_position)
	chamber.try_exit(global_position)
	charge_orb.visible = chamber.carrying_charge
	charge_orb.position.y = (0.5 if mode == 1 else 1.45) + sin(animation_time * 3) * 0.05
	
	# Invulnerability blink
	if invulnerable_timer > 0.0:
		invulnerable_timer = maxf(0.0, invulnerable_timer - delta)
		sprite.visible = int(invulnerable_timer * 16.0) % 2 == 0
	else:
		sprite.visible = true
		
	_update_sprite()

func take_damage(amount: int, from_pos: Vector3) -> void:
	if invulnerable_timer > 0.0:
		return
	invulnerable_timer = 1.2
	
	var g = get_node_or_null("/root/Global")
	if g and g.has_method("take_damage"):
		g.take_damage(amount)
		
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("hurt")
		
	# Knockback impulse away from attacker
	var kb_dir := (global_position - from_pos)
	kb_dir.y = 0.0
	if kb_dir.length() > 0.01:
		kb_dir = kb_dir.normalized()
	else:
		kb_dir = Vector3.BACK
	velocity = kb_dir * 4.5 + Vector3.UP * 3.0
	
	notice.emit("Flat Guardian strikes! Switch to 2D to slip through its slice!")
	
	if g and "current_health" in g and g.current_health <= 0:
		respawn()

func respawn() -> void:
	position = checkpoint
	velocity = Vector3.ZERO
	var target_mode: int = 2 if ((position.x >= 26.0 and position.x < 48.0) or (position.x >= 68.0 and position.x < 71.0)) else 3
	mode = target_mode
	plane_z = position.z
	shape_node.shape = humanoid
	shape_node.position.y = 0.575
	sprite.position.y = 0.576
	sprite.scale = Vector3.ONE
	invulnerable_timer = 0.0
	sprite.visible = true
	chamber.set_spatial_mode(mode)
	mode_changed.emit(mode)
	
	var g = get_node_or_null("/root/Global")
	if g:
		if g.has_method("reset_health"):
			g.reset_health()
		elif "current_health" in g:
			g.current_health = g.max_health if "max_health" in g else 3
			if g.has_signal("health_changed"):
				g.health_changed.emit(g.current_health)
		
	notice.emit("Back on solid ground. Your health and progress are restored.")

func _update_sprite() -> void:
	var moving: bool = move_input.length() > 0.1
	var file: String
	if mode == 1:
		file = "john_rod_1d_rod_active.png" if moving else "john_rod_1d_rod.png"
	elif mode == 2:
		if not is_on_floor():
			file = "john_rod_2d_jump.png"
		elif moving:
			file = "john_rod_2d_walk_%d.png" % (1 + int(animation_time * 8) % 4)
		else:
			file = "john_rod_2d_idle.png"
	else:
		var angle := "front"
		if absf(move_input.x) > 0.1:
			angle = "iso" if absf(move_input.y) > 0.1 else "side"
		elif move_input.y < -0.1:
			angle = "back"
		file = "john_rod_3d_%s_%s.png" % [angle, ("walk_%d" % (1 + int(animation_time * 7) % 2)) if moving else "idle"]
	if not texture_cache.has(file):
		texture_cache[file] = load(ART + file)
	sprite.texture = texture_cache[file]
	if move_input.x != 0:
		sprite.flip_h = move_input.x < 0
