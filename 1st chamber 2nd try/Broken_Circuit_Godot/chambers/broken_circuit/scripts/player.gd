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
var charge_orb: MeshInstance3D
var animation_time: float = 0.0
var move_input: Vector2 = Vector2.ZERO
var input_override: bool = false
var override_jump: bool = false
var texture_cache: Dictionary = {}
var coyote: float = 0.0
var jump_buffer: float = 0.0
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
	for pair in [["dimension_1",1],["dimension_2",2],["dimension_3",3]]:
		if InputMap.has_action(pair[0]) and event.is_action_pressed(pair[0]):
			request_mode(pair[1])
			return
	for pair in [["cycle_prev",-1],["cycle_next",1]]:
		if InputMap.has_action(pair[0]) and event.is_action_pressed(pair[0]):
			request_mode(clampi(mode + pair[1],1,3))
			return
	if InputMap.has_action("jump") and event.is_action_pressed("jump"):
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
		KEY_SPACE: jump_buffer = 0.12
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
	if target == mode:
		return true
	if target == 1:
		var found: Dictionary = chamber.rail_near(position)
		if found.is_empty():
			notice.emit("Stand on a powered conduit to enter 1D.")
			return false
		active_rail = found
		position = Vector3(clampf(position.x, found.start.x, found.end.x), found.start.y, found.start.z)
		shape_node.shape = rod
		shape_node.position.y = 0
		sprite.position.y = 0
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
		plane_z = position.z
	mode = target
	velocity = Vector3.ZERO
	chamber.set_spatial_mode(mode)
	mode_changed.emit(mode)
	_update_sprite()
	return true

func _physics_process(delta: float) -> void:
	animation_time += delta
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
		var direction := Vector3(move_input.x, 0, move_input.y if mode == 3 else 0.0)
		# Ground controls follow the angled camera in volume mode.
		if mode == 3:
			direction = direction.rotated(Vector3.UP, deg_to_rad(-45.0))
		if direction.length() > 1:
			direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		coyote = 0.1 if is_on_floor() else maxf(0, coyote - delta)
		jump_buffer = maxf(0, jump_buffer - delta)
		if override_jump:
			jump_buffer = 0.12
			override_jump = false
		if jump_buffer > 0 and coyote > 0:
			velocity.y = JUMP
			jump_buffer = 0
			coyote = 0
		else:
			velocity.y -= GRAVITY * delta
		move_and_slide()
		if mode == 2:
			position.z = plane_z
	chamber.tick_player(global_position)
	if position.x > 1.8 and checkpoint.x < 1:
		checkpoint = Vector3(3, 0.08, 0)
	if chamber.powered and not gallery_reached:
		checkpoint = Vector3(13.5, 0.08, -4)
	if position.x > 32.2 and position.x < 40 and position.y > 2.4:
		gallery_reached = true
		checkpoint = Vector3(33, 2.63, -4)
	if gallery_reached and position.y < 1.5:
		respawn()
	elif position.y < -2.8:
		respawn()
	if mode == 1 and chamber.upper_rail_live and not chamber.shutter_open and absf(position.x - 42) < 0.45 and position.y > 2:
		position = Vector3(38.5, 2.75, 2)
		notice.emit("The shutter closed. Your spark is safe; try again.")
	chamber.try_collect(global_position)
	chamber.try_exit(global_position)
	charge_orb.visible = chamber.carrying_charge
	charge_orb.position.y = (0.5 if mode == 1 else 1.45) + sin(animation_time * 3) * 0.05
	_update_sprite()

func respawn() -> void:
	position = checkpoint
	velocity = Vector3.ZERO
	mode = 3
	plane_z = position.z
	shape_node.shape = humanoid
	shape_node.position.y = 0.575
	sprite.position.y = 0.576
	chamber.set_spatial_mode(3)
	mode_changed.emit(3)
	notice.emit("Back on solid ground. Your circuit progress is safe.")

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
