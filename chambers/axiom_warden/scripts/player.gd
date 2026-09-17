extends CharacterBody3D
signal struck
signal fell
signal mode_changed(value: int)
signal notice(message: String)

const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
const ART: String = "res://chambers/axiom_warden/assets/"
const SPEED: float = 5.4
const GRAVITY: float = 18.0
const JUMP: float = 6.5
var mode: int = 3
var plane_z: float = 0.0
var locked: bool = false
var armed: bool = false
var arena_active: bool = false
var input_override: bool = false
var move_input: Vector2 = Vector2.ZERO
var override_jump: bool = false
var invulnerable: float = 0.0
var attack_timer: float = 0.0
var swing_time: float = 0.0
var jump_buffer: float = 0.0
var coyote: float = 0.0
var age: float = 0.0
var facing: float = 1.0
var sprite: Sprite3D
var shape_node: CollisionShape3D
var humanoid: CapsuleShape3D
var rod: BoxShape3D
var weapon: Node3D
var textures: Dictionary = {}

func _ready() -> void:
	floor_snap_length = 0.18
	humanoid = CapsuleShape3D.new()
	humanoid.radius = 0.19
	humanoid.height = 1.14
	rod = BoxShape3D.new()
	rod.size = Vector3(0.62, 0.13, 0.13)
	shape_node = CollisionShape3D.new()
	shape_node.shape = humanoid
	shape_node.position.y = 0.58
	add_child(shape_node)
	sprite = Sprite3D.new()
	sprite.pixel_size = 0.024
	sprite.position.y = 0.576
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(sprite)
	weapon = Node3D.new()
	weapon.position = Vector3(0.25, 0.64, 0)
	add_child(weapon)
	Geo.box(weapon, Vector3(0.42, 0, 0), Vector3(1.25, 0.06, 0.06), Geo.material(Color("fff2bd"), true))
	Geo.box(weapon, Vector3(-0.15, 0, 0), Vector3(0.22, 0.1, 0.1), Geo.material(Color("997137")))
	weapon.visible = false
	_update_sprite()

func _unhandled_key_input(event: InputEvent) -> void:
	if locked or not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_1: request_mode(1)
		KEY_2: request_mode(2)
		KEY_3: request_mode(3)
		KEY_Q: request_mode(3 if mode == 1 else mode - 1)
		KEY_E: request_mode(1 if mode == 3 else mode + 1)
		KEY_SPACE:
			if mode == 2:
				jump_buffer = 0.14
			else:
				jump_buffer = 0.0
		KEY_F: strike()

func strike() -> bool:
	if locked or not armed or attack_timer > 0:
		return false
	attack_timer = 0.45
	swing_time = 0.24
	struck.emit()
	return true

func request_mode(target: int) -> bool:
	if locked or target < 1 or target > 3:
		return false
	if target == mode:
		return true
	jump_buffer = 0.0 # Clear incompatible jump buffer during dimension switch
	var preserved_vy: float = velocity.y
	if target == 1:
		# Three visible parallel rails cross the arena. No mid-air teleport onto a rail.
		var nearest: float = roundf(position.z / 4.0) * 4.0
		if not arena_active or not is_on_floor() or absf(position.z - nearest) > 0.48 or absf(nearest) > 4.1:
			notice.emit("1D needs a cyan floor rail. Align first, then press 1.")
			return false
		plane_z = nearest
		position.z = nearest
		position.y = 0.2
		shape_node.shape = rod
		shape_node.position.y = 0
		coyote = 0.0
	else:
		var at: Vector3 = position
		if mode == 1:
			at.y = 0.05
		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape = humanoid
		query.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, 0.6, 0))
		query.exclude = [get_rid()]
		query.collision_mask = 1
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			notice.emit("No clearance to expand here.")
			return false
		position = at
		plane_z = at.z
		shape_node.shape = humanoid
		shape_node.position.y = 0.58
		if target == 2:
			coyote = 0.12 if is_on_floor() else 0.0
		else:
			coyote = 0.0
	# Keep upward momentum when switching 2D/3D during a jump without resetting or extra impulse
	if target == 1:
		velocity = Vector3.ZERO
	else:
		velocity.y = preserved_vy
	mode = target
	mode_changed.emit(mode)
	_update_sprite()
	return true

func _physics_process(delta: float) -> void:
	age += delta
	invulnerable = maxf(0, invulnerable - delta)
	attack_timer = maxf(0, attack_timer - delta)
	swing_time = maxf(0, swing_time - delta)
	weapon.visible = armed
	weapon.position.y = 0.02 if mode == 1 else 0.64
	weapon.rotation.z = sin((0.24 - swing_time) / 0.24 * PI) * 1.3 if swing_time > 0 else -0.25
	weapon.rotation.y = 0 if facing > 0 else PI
	if locked:
		velocity = Vector3.ZERO
		_update_sprite()
		return
	if not input_override:
		move_input = Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if absf(move_input.x) > 0.1:
		facing = signf(move_input.x)
	if mode == 1:
		velocity = Vector3(move_input.x * 7.0, 0, 0)
		move_and_slide()
		position.x = clampf(position.x, -10.8, 13.4)
		position.y = 0.2
		position.z = plane_z
	elif mode == 3:
		# 3D Mode: Ground navigation only. Jumping is strictly disabled.
		jump_buffer = 0.0
		coyote = 0.0
		if override_jump:
			override_jump = false # Space / jump ignored in 3D
		var input_z: float = move_input.y if is_on_floor() else 0.0
		var direction: Vector3 = Vector3(move_input.x, 0, input_z).rotated(Vector3.UP, deg_to_rad(-35.0))
		direction = direction.limit_length(1.0)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED if is_on_floor() else 0.0
		velocity.y -= GRAVITY * delta
		move_and_slide()
		if arena_active:
			position.x = clampf(position.x, -10.8, 13.4)
			position.z = clampf(position.z, -6.1, 6.1)
	elif mode == 2:
		# 2D Mode: Platforming with running and jumping
		var direction: Vector3 = Vector3(move_input.x, 0, 0.0)
		direction = direction.limit_length(1.0)
		velocity.x = direction.x * SPEED
		velocity.z = 0.0
		coyote = 0.11 if is_on_floor() else maxf(0, coyote - delta)
		jump_buffer = maxf(0, jump_buffer - delta)
		if override_jump:
			jump_buffer = 0.14
			override_jump = false
		if jump_buffer > 0 and coyote > 0:
			velocity.y = JUMP
			jump_buffer = 0.0
			coyote = 0.0
		else:
			velocity.y -= GRAVITY * delta
		move_and_slide()
		position.z = plane_z
		if arena_active:
			position.x = clampf(position.x, -10.8, 13.4)
	if position.y < -3.8:
		fell.emit()
	_update_sprite()

func reset_at(at: Vector3) -> void:
	position = at
	velocity = Vector3.ZERO
	mode = 3
	plane_z = at.z
	shape_node.shape = humanoid
	shape_node.position.y = 0.58
	move_input = Vector2.ZERO
	jump_buffer = 0
	invulnerable = 1.5
	mode_changed.emit(mode)

func _update_sprite() -> void:
	var moving: bool = move_input.length() > 0.1 and not locked
	var file: String = "john_rod_3d_iso_idle.png"
	if mode == 1:
		file = "john_rod_1d_rod_active.png" if moving else "john_rod_1d_rod.png"
	elif mode == 2:
		file = "john_rod_2d_walk_%d.png" % (1 + int(age * 9) % 4) if moving else "john_rod_2d_idle.png"
		if not is_on_floor() and not locked:
			file = "john_rod_2d_jump.png"
	elif moving:
		file = "john_rod_3d_iso_walk_%d.png" % (1 + int(age * 7) % 2)
	if not textures.has(file):
		textures[file] = load(ART + file)
	sprite.texture = textures[file]
	sprite.position.y = 0 if mode == 1 else 0.576
	sprite.flip_h = facing < 0
	sprite.visible = invulnerable <= 0 or int(invulnerable * 15) % 2 == 0
