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
var checkpoint: Vector3 = Vector3(-11.3, 0.05, 0)
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

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: request_mode(1)
		KEY_2: request_mode(2)
		KEY_3: request_mode(3)
		KEY_Q: request_mode(3 if mode == 1 else mode - 1)
		KEY_E: request_mode(1 if mode == 3 else mode + 1)
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
		if position.x < -10.45 or position.x > -1.95 or absf(position.z) > 0.34 or absf(position.y - 0.2) > 0.35:
			notice.emit("1D needs a conduit. Stand on its marked socket.")
			return false
		position = Vector3(clampf(position.x, -10.0, -2.4), 0.2, 0)
		shape_node.shape = rod
		shape_node.position.y = 0
		sprite.position.y = 0
	else:
		var destination := position
		# Restore feet to floor height when leaving the rail, without changing X/Z.
		if mode == 1:
			destination.y = 0.04
			if destination.x > -7.8 and destination.x < -4.3:
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
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if mode == 1:
		velocity = Vector3(move_input.x * 3.5, 0, 0)
		move_and_slide()
		position.x = clampf(position.x, -10.0, -2.4)
		position.y = 0.2
		position.z = 0
	else:
		var direction := Vector3(move_input.x, 0, move_input.y if mode == 3 else 0.0)
		# Ground controls follow the angled camera in volume mode.
		if mode == 3:
			direction = direction.rotated(Vector3.UP, deg_to_rad(-32.0))
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
	if position.x > -4.0 and checkpoint.x < -4.0:
		checkpoint = Vector3(-2.6, 0.05, 0)
	if chamber.powered:
		checkpoint = Vector3(2.5, 0.05, -2.5)
	if position.y < -2.8:
		respawn()
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
