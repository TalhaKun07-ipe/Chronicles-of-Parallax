extends CharacterBody3D
class_name ChronoPlayer

signal mode_changed(mode: int)
signal notice(message: String)
signal interacted()
signal died()
const SPEED: float = 4.8
const JUMP: float = 6.5
const GRAVITY: float = 18.0
const ART = "res://chambers/axiom_warden/assets/"
var mode: int = 2
var plane_z: float = 0.0
var sprite_3d: Sprite3D
var shadow: MeshInstance3D
var shape_node: CollisionShape3D
var humanoid: CapsuleShape3D
var rod: BoxShape3D
var rewind_controller: RewindController
var rail: Dictionary = {}
var input_override: bool = false
var move_input: Vector2 = Vector2.ZERO
var override_jump: bool = false
var locked: bool = false
var coyote: float = 0.0
var jump_buffer: float = 0.0
var age: float = 0.0
var textures: Dictionary = {}

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 0.16
	add_to_group("player")
	humanoid = CapsuleShape3D.new()
	humanoid.radius = 0.18
	humanoid.height = 1.14
	rod = BoxShape3D.new()
	rod.size = Vector3(0.58, 0.12, 0.12)
	shape_node = CollisionShape3D.new()
	shape_node.shape = humanoid
	shape_node.position.y = 0.575
	add_child(shape_node)
	sprite_3d = Sprite3D.new()
	sprite_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite_3d.pixel_size = 0.024
	sprite_3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite_3d.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite_3d.position.y = 0.576
	add_child(sprite_3d)
	shadow = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.4)
	shadow.mesh = quad
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/character_shadow.gdshader")
	shadow.material_override = material
	shadow.rotation_degrees.x = -90
	shadow.position.y = 0.025
	add_child(shadow)
	rewind_controller = RewindController.new()
	rewind_controller.name = "RewindController"
	add_child(rewind_controller)
	_sync_dimension()
	_update_sprite()

func _unhandled_key_input(event: InputEvent) -> void:
	if locked or Global.is_rewinding or not event is InputEventKey or not event.pressed or event.echo: return
	var key: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	match key:
		KEY_1: request_mode(1)
		KEY_2: request_mode(2)
		KEY_3: request_mode(3)
		KEY_Q, KEY_Z: request_mode(3 if mode == 1 else mode - 1)
		KEY_E, KEY_X: request_mode(1 if mode == 3 else mode + 1)
		KEY_SPACE:
			if mode == 2: jump_buffer = 0.14
		KEY_F: interacted.emit()

func request_mode(target: int) -> bool:
	if locked or Global.is_rewinding or target < 1 or target > 3: return false
	if target == mode: return true
	var at := position
	if target == 1:
		var found: Dictionary = get_parent().rail_near(position)
		if found.is_empty() or not is_on_floor():
			notice.emit("1D needs a cyan conduit. Find the rail near the daylight arch.")
			return false
		rail = found
		at.y = found.y
		at.z = found.z
	elif mode == 1:
		at.y = rail.floor_y + 0.04
	if target != 1:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = humanoid
		query.transform = Transform3D(Basis.IDENTITY, at + Vector3(0, 0.59, 0))
		query.exclude = [get_rid()]
		query.collision_mask = 1
		if not get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			notice.emit("No clearance to expand. Slide past the stone seal first.")
			return false
	position = at
	plane_z = at.z
	mode = target
	jump_buffer = 0
	coyote = 0
	if mode == 1: velocity = Vector3.ZERO
	else: velocity.z = 0
	_apply_shape()
	_sync_dimension()
	mode_changed.emit(mode)
	SoundManager.play_sfx("transform")
	return true

func _physics_process(delta: float) -> void:
	if locked: return
	if Global.is_rewinding:
		_update_sprite()
		return
	age += delta
	if not input_override:
		move_input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if mode == 1:
		velocity = Vector3(move_input.x * SPEED, 0, 0)
		move_and_slide()
		position.x = clampf(position.x, rail.start, rail.end)
		position.y = rail.y
		position.z = rail.z
	else:
		var direction := Vector3(move_input.x, 0, move_input.y if mode == 3 else 0.0).limit_length(1.0)
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		coyote = 0.11 if is_on_floor() else maxf(0, coyote - delta)
		jump_buffer = maxf(0, jump_buffer - delta)
		if override_jump:
			if mode == 2: jump_buffer = 0.14
			override_jump = false
		if mode == 2 and jump_buffer > 0 and coyote > 0:
			velocity.y = JUMP
			coyote = 0
			jump_buffer = 0
			SoundManager.play_sfx("jump")
		else: velocity.y -= GRAVITY * delta
		move_and_slide()
		if mode == 2: position.z = plane_z
	if absf(move_input.x) > 0.1: sprite_3d.flip_h = move_input.x < 0
	_update_sprite()

func capture_time_state() -> Dictionary:
	return {"position": global_position, "velocity": velocity, "mode": mode,
		"plane_z": plane_z, "rail": rail.duplicate(), "sprite_flip_h": sprite_3d.flip_h}

func restore_time_state(state: Dictionary) -> void:
	global_position = state.position
	velocity = Vector3.ZERO
	mode = state.mode
	plane_z = state.plane_z
	rail = state.rail.duplicate()
	sprite_3d.flip_h = state.sprite_flip_h
	coyote = 0
	jump_buffer = 0
	_apply_shape()
	_sync_dimension()

func _apply_shape() -> void:
	shape_node.shape = rod if mode == 1 else humanoid
	shape_node.position.y = 0 if mode == 1 else 0.575
	sprite_3d.position.y = 0 if mode == 1 else 0.576
	shadow.visible = mode != 1

func _sync_dimension() -> void:
	var dimensions := {1: Global.Dimension.DIM_1D, 2: Global.Dimension.DIM_2D, 3: Global.Dimension.DIM_3D}
	if Global.active_dimension != dimensions[mode]: Global.set_dimension(dimensions[mode])

func reset_at(at: Vector3) -> void:
	position = at
	velocity = Vector3.ZERO
	mode = 2
	plane_z = at.z
	rail.clear()
	coyote = 0
	jump_buffer = 0
	override_jump = false
	move_input = Vector2.ZERO
	locked = false
	_apply_shape()
	_sync_dimension()
	_update_sprite()

func die() -> void:
	if locked: return
	locked = true
	died.emit()

func _update_sprite() -> void:
	var moving := move_input.length() > 0.1
	var file := "john_rod_2d_idle.png"
	if mode == 1: file = "john_rod_1d_rod_active.png" if moving else "john_rod_1d_rod.png"
	elif mode == 3: file = "john_rod_3d_iso_walk_%d.png" % (1 + int(age * 7) % 2) if moving else "john_rod_3d_iso_idle.png"
	elif not is_on_floor(): file = "john_rod_2d_jump.png"
	elif moving: file = "john_rod_2d_walk_%d.png" % (1 + int(age * 9) % 4)
	if not textures.has(file): textures[file] = load(ART + file)
	sprite_3d.texture = textures[file]
	sprite_3d.modulate = Color(0.65, 1.0, 1.0) if Global.is_rewinding else Color.WHITE
