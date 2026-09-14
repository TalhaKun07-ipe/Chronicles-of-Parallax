extends CharacterBody3D
class_name Player

# Player controller implementing all Degrees of Freedom (0D, 1D, 2D, 2.5D, 3D)
# Fully supporting John Rod sprite models in 128px (primary) and 64px (retro) modes.

const SPEED_1D = 3.5
const SPEED_2D = 4.5
const SPEED_3D = 4.0
const JUMP_VELOCITY = 6.5
const GRAVITY = 18.0

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var pulse_effect: Sprite3D = $PulseEffect
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var rewind_controller: RewindController = $RewindController
@onready var ghost_preview: Sprite3D = $GhostPreview
@onready var shadow: Sprite3D = $Shadow
@onready var charge_orb: Sprite3D = get_node_or_null("ChargeOrb")

var current_anim: String = "idle"
var walk_frame_timer: float = 0.0
var walk_frame: int = 1

# Discrete Z-lanes for 2.5D mode
var current_lane: int = 1 # 0: Back, 1: Mid, 2: Front
const LANE_Z_COORDS = [-1.5, 0.0, 1.5]
var is_shifting_lane: bool = false
var can_shift_lanes: bool = false # Set by connection pads

# 1D rail movement direction & alignment
var rail_dir: Vector3 = Vector3.RIGHT
var current_conduit: Node3D = null # Set when player touches a ConduitRail area

# 2D frozen depth coordinate
var locked_2d_z: float = 0.0

var was_in_air: bool = false
var last_facing_axis: String = "iso"

# Texture catalog keys
const TEXTURE_KEYS = [
	"0d_point", "0d_pulse",
	"1d_rod", "1d_rod_active",
	"2d_idle", "2d_walk_1", "2d_walk_2", "2d_walk_3", "2d_walk_4", "2d_crouch", "2d_jump", "2d_land",
	"25d_idle", "25d_front", "25d_back", "25d_turn", "25d_walk_1", "25d_walk_2",
	"3d_front_idle", "3d_front_walk_1", "3d_front_walk_2",
	"3d_back_idle", "3d_back_walk_1", "3d_back_walk_2",
	"3d_side_idle", "3d_side_walk_1", "3d_side_walk_2",
	"3d_iso_idle", "3d_iso_walk_1", "3d_iso_walk_2"
]

var cached_texture_sets: Dictionary = {}
var active_textures: Dictionary = {}

func _ready() -> void:
	init_texture_caches()
	locked_2d_z = global_position.z
	Global.dimension_changed.connect(_on_dimension_changed)
	Global.sprite_resolution_changed.connect(_on_sprite_resolution_changed)
	Global.charge_state_changed.connect(_on_charge_state_changed)
	Global.rewind_started.connect(_on_rewind_started)
	Global.rewind_ended.connect(_on_rewind_ended)
	_on_charge_state_changed(Global.carried_charge)
	update_visual_mode(Global.active_dimension)

func init_texture_caches() -> void:
	cached_texture_sets[Global.SpriteResolution.RES_128] = _load_textures_for_res("res://assets/sprites/sprites_128/")
	cached_texture_sets[Global.SpriteResolution.RES_64] = _load_textures_for_res("res://assets/sprites/sprites_64/")
	active_textures = cached_texture_sets.get(Global.sprite_resolution, cached_texture_sets[Global.SpriteResolution.RES_128])

func _load_textures_for_res(folder: String) -> Dictionary:
	var dict = {}
	for k in TEXTURE_KEYS:
		var path = folder + "john_rod_" + k + ".png"
		if ResourceLoader.exists(path):
			dict[k] = load(path)
		else:
			dict[k] = load("res://assets/sprites/john_rod_" + k + ".png")
	return dict

func get_tex(key: String) -> Texture2D:
	if active_textures.has(key):
		return active_textures[key]
	var fallback_path = "res://assets/sprites/john_rod_" + key + ".png"
	if ResourceLoader.exists(fallback_path):
		return load(fallback_path)
	return null

func _on_sprite_resolution_changed(new_res: Global.SpriteResolution) -> void:
	if cached_texture_sets.has(new_res):
		active_textures = cached_texture_sets[new_res]
	else:
		active_textures = _load_textures_for_res(
			"res://assets/sprites/sprites_128/" if new_res == Global.SpriteResolution.RES_128 else "res://assets/sprites/sprites_64/"
		)
	update_visual_mode(Global.active_dimension)
	play_anim(current_anim)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			var next_res = Global.SpriteResolution.RES_64 if Global.sprite_resolution == Global.SpriteResolution.RES_128 else Global.SpriteResolution.RES_128
			Global.set_sprite_resolution(next_res)
			SoundManager.play_sfx("transform")

func _on_rewind_started() -> void:
	sprite_3d.modulate = Color(1.3, 1.15, 0.6)

func _on_rewind_ended() -> void:
	sprite_3d.modulate = Color.WHITE

func _physics_process(delta: float) -> void:
	if Global.is_rewinding:
		return
		
	handle_dimension_switching()
	
	match Global.active_dimension:
		Global.Dimension.DIM_0D:
			process_0d(delta)
		Global.Dimension.DIM_1D:
			process_1d(delta)
		Global.Dimension.DIM_2D:
			process_2d(delta)
		Global.Dimension.DIM_2_5D:
			process_2_5d(delta)
		Global.Dimension.DIM_3D:
			process_3d(delta)
			
	move_and_slide()
	check_landing()

# --- 0D MODE (POINT) ---
func process_0d(delta: float) -> void:
	velocity = Vector3.ZERO
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		
	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact_strike"):
		SoundManager.play_sfx("pulse")
		trigger_0d_pulse()

func trigger_0d_pulse() -> void:
	# Bouncy metallic bead pulse
	var tween = create_tween()
	sprite_3d.scale = Vector3(1.4, 1.4, 1.4)
	tween.tween_property(sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	# Expanding concentric metallic shockwave
	if pulse_effect:
		pulse_effect.texture = get_tex("0d_pulse")
		pulse_effect.visible = true
		pulse_effect.scale = Vector3(0.3, 0.3, 0.3)
		pulse_effect.modulate.a = 1.0
		var p_tween = create_tween()
		p_tween.tween_property(pulse_effect, "scale", Vector3(2.4, 2.4, 2.4), 0.35).set_trans(Tween.TRANS_QUAD)
		p_tween.parallel().tween_property(pulse_effect, "modulate:a", 0.0, 0.35)
		p_tween.tween_callback(func(): pulse_effect.visible = false)

func _process(_delta: float) -> void:
	if charge_orb and charge_orb.visible:
		charge_orb.position.y = 1.35 + sin(Time.get_ticks_msec() * 0.005) * 0.06

func _on_charge_state_changed(has_charge: bool) -> void:
	if charge_orb:
		charge_orb.visible = has_charge

# --- 1D MODE (LINE / RAIL) ---
func process_1d(delta: float) -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	if input_dir != 0:
		velocity.x = input_dir * SPEED_1D
		sprite_3d.flip_h = input_dir < 0
		sprite_3d.texture = get_tex("1d_rod_active")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED_1D)
		sprite_3d.texture = get_tex("1d_rod")
		
	velocity.z = 0
	velocity.y = 0 # 1D rail locks vertical axis
	
	if current_conduit and current_conduit.has_method("constrain_player_1d"):
		current_conduit.constrain_player_1d(self)

# --- 2D MODE (PLANE) ---
func process_2d(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		play_anim("jump")
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			SoundManager.play_sfx("jump")
			play_anim("jump")
			trigger_jump_stretch()
			
	var input_x = Input.get_axis("move_left", "move_right")
	if input_x != 0:
		velocity.x = input_x * SPEED_2D
		sprite_3d.flip_h = input_x < 0
		if is_on_floor():
			play_anim("walk")
			update_walk_frames(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED_2D)
		if is_on_floor():
			if Input.is_action_pressed("move_down"):
				play_anim("crouch")
			else:
				play_anim("idle")
			
	# Constrained to current frozen 2D plane (depth is preserved)
	velocity.z = 0
	if not is_shifting_lane:
		global_position.z = locked_2d_z
		
	# While on a LayerSwitchPad in 2D, allow W/S to shift discrete depth lanes
	if can_shift_lanes and not is_shifting_lane:
		if Input.is_action_just_pressed("move_up") and current_lane > 0:
			shift_lane(current_lane - 1)
		elif Input.is_action_just_pressed("move_down") and current_lane < 2:
			shift_lane(current_lane + 1)

# --- 2.5D MODE (DISCRETE LAYERS) ---
func process_2_5d(delta: float) -> void:
	# Normal 2D horizontal movement + jumping
	process_2d(delta)
	
	# Discrete lane change (W / S) at connection pads
	if can_shift_lanes and not is_shifting_lane:
		if Input.is_action_just_pressed("move_up") and current_lane > 0:
			shift_lane(current_lane - 1)
		elif Input.is_action_just_pressed("move_down") and current_lane < 2:
			shift_lane(current_lane + 1)

func shift_lane(target_lane: int) -> void:
	var going_forward = target_lane > current_lane
	current_lane = target_lane
	is_shifting_lane = true
	sprite_3d.texture = get_tex("25d_front") if going_forward else get_tex("25d_back")
	var target_z = LANE_Z_COORDS[current_lane]
	locked_2d_z = target_z
	var mid_z = (global_position.z + target_z) * 0.5
	var tween = create_tween()
	tween.tween_property(self, "global_position:z", mid_z, 0.11).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func(): sprite_3d.texture = get_tex("25d_turn"))
	tween.tween_property(self, "global_position:z", target_z, 0.11).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		is_shifting_lane = false
		sprite_3d.texture = get_tex("25d_idle")
		locked_2d_z = target_z
	)
	SoundManager.play_sfx("transform")

# --- 3D MODE (FULL VOLUME) ---
func process_3d(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		play_anim("jump")
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			SoundManager.play_sfx("jump")
			play_anim("jump")
			trigger_jump_stretch()
			
	var raw_input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	
	if raw_input.length() > 0:
		raw_input = raw_input.normalized()
		# In isometric 3D (camera rotated at -45 deg), rotate input to match screen axes
		var iso_dir = raw_input.rotated(deg_to_rad(45.0))
		velocity.x = iso_dir.x * SPEED_3D
		velocity.z = iso_dir.y * SPEED_3D
		if raw_input.x != 0:
			sprite_3d.flip_h = raw_input.x < 0
		if is_on_floor():
			play_anim("walk")
			update_walk_frames(delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED_3D)
		velocity.z = move_toward(velocity.z, 0, SPEED_3D)
		if is_on_floor():
			play_anim("idle")

# --- INPUT HANDLING FOR DIMENSIONS ---
func handle_dimension_switching() -> void:
	if Input.is_action_just_pressed("dimension_1"):
		attempt_switch_dimension(Global.Dimension.DIM_1D)
	elif Input.is_action_just_pressed("dimension_2"):
		attempt_switch_dimension(Global.Dimension.DIM_2D)
	elif Input.is_action_just_pressed("dimension_3") or Input.is_action_just_pressed("dimension_4"):
		attempt_switch_dimension(Global.Dimension.DIM_3D)
	elif Input.is_action_just_pressed("cycle_prev"):
		Global.cycle_dimension(-1)
	elif Input.is_action_just_pressed("cycle_next"):
		Global.cycle_dimension(1)

func attempt_switch_dimension(target_dim: Global.Dimension) -> void:
	if not Global.unlocked_dimensions.get(target_dim, false):
		SoundManager.play_sfx("error")
		return
	if target_dim == Global.active_dimension:
		return
		
	# 1D alignment rule: enter 1D only when touching or closely aligned with a visible conduit
	if target_dim == Global.Dimension.DIM_1D:
		if current_conduit == null:
			SoundManager.play_sfx("error")
			show_blocked_indicator()
			return
		global_position.y = current_conduit.global_position.y
		global_position.z = current_conduit.global_position.z

	# 2D depth lock rule: freeze current depth coordinate
	if target_dim == Global.Dimension.DIM_2D:
		if not check_dimension_clearance(target_dim):
			SoundManager.play_sfx("error")
			show_blocked_indicator()
			return
		locked_2d_z = global_position.z

	# 3D clearance rule
	if target_dim == Global.Dimension.DIM_3D:
		if not check_dimension_clearance(target_dim):
			SoundManager.play_sfx("error")
			show_blocked_indicator()
			return
			
	Global.set_dimension(target_dim)

func check_dimension_clearance(target_dim: Global.Dimension) -> bool:
	if target_dim in [Global.Dimension.DIM_2D, Global.Dimension.DIM_3D]:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsShapeQueryParameters3D.new()
		var box = BoxShape3D.new()
		box.size = Vector3(0.45, 1.1, 0.45 if target_dim == Global.Dimension.DIM_3D else 0.1)
		query.shape = box
		query.transform = Transform3D(Basis(), global_position + Vector3(0, 0.58, 0))
		query.collision_mask = 1 # Solid geometry
		query.exclude = [self]
		var hits = space_state.intersect_shape(query, 1)
		if hits.size() > 0:
			return false
	return true

func show_blocked_indicator() -> void:
	var tween = create_tween()
	sprite_3d.modulate = Color.RED
	tween.tween_property(sprite_3d, "modulate", Color.WHITE, 0.2)

# --- VISUALS & ANIMATION ---
func _on_dimension_changed(new_dim: Global.Dimension, _old_dim: Global.Dimension) -> void:
	update_visual_mode(new_dim)
	if new_dim == Global.Dimension.DIM_2D:
		locked_2d_z = global_position.z

func check_landing() -> void:
	if not was_in_air and not is_on_floor():
		was_in_air = true
	elif was_in_air and is_on_floor():
		was_in_air = false
		trigger_land_squash()

func trigger_jump_stretch() -> void:
	var tween = create_tween()
	sprite_3d.scale = Vector3(0.82, 1.25, 0.82)
	tween.tween_property(sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.25).set_trans(Tween.TRANS_QUAD)

func trigger_land_squash() -> void:
	if Global.active_dimension == Global.Dimension.DIM_2D:
		sprite_3d.texture = get_tex("2d_land")
	var tween = create_tween()
	sprite_3d.scale = Vector3(1.25, 0.78, 1.25)
	tween.tween_property(sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func():
		if is_on_floor() and velocity.x == 0 and Global.active_dimension == Global.Dimension.DIM_2D:
			sprite_3d.texture = get_tex("2d_idle")
	)

func update_visual_mode(dim: Global.Dimension) -> void:
	var h_px_size = 0.012 if Global.sprite_resolution == Global.SpriteResolution.RES_128 else 0.024
	var low_px_size = 0.012 if Global.sprite_resolution == Global.SpriteResolution.RES_128 else 0.024
	
	match dim:
		Global.Dimension.DIM_0D:
			sprite_3d.texture = get_tex("0d_point")
			sprite_3d.pixel_size = low_px_size
			sprite_3d.position.y = 0.22
			collision_shape.shape.size = Vector3(0.3, 0.3, 0.3)
			if shadow: shadow.visible = false
		Global.Dimension.DIM_1D:
			sprite_3d.texture = get_tex("1d_rod")
			sprite_3d.pixel_size = low_px_size
			sprite_3d.position.y = 0.20
			collision_shape.shape.size = Vector3(0.8, 0.2, 0.1)
			if shadow: shadow.visible = false
		Global.Dimension.DIM_2D:
			sprite_3d.texture = get_tex("2d_idle")
			sprite_3d.pixel_size = h_px_size
			sprite_3d.position.y = 0.58
			collision_shape.shape.size = Vector3(0.5, 1.2, 0.1)
			if shadow:
				shadow.visible = true
				shadow.pixel_size = 0.008
		Global.Dimension.DIM_2_5D:
			sprite_3d.texture = get_tex("25d_idle")
			sprite_3d.pixel_size = h_px_size
			sprite_3d.position.y = 0.58
			collision_shape.shape.size = Vector3(0.5, 1.2, 0.2)
			if shadow:
				shadow.visible = true
				shadow.pixel_size = 0.008
		Global.Dimension.DIM_3D:
			sprite_3d.texture = get_tex("3d_iso_idle")
			sprite_3d.pixel_size = h_px_size
			sprite_3d.position.y = 0.58
			collision_shape.shape.size = Vector3(0.5, 1.2, 0.5)
			if shadow:
				shadow.visible = true
				shadow.pixel_size = 0.0085
				
	if ghost_preview:
		ghost_preview.texture = get_tex("2d_idle")
		ghost_preview.pixel_size = h_px_size

func play_anim(anim_name: String) -> void:
	current_anim = anim_name
	if Global.active_dimension == Global.Dimension.DIM_2D:
		if anim_name == "idle":
			sprite_3d.texture = get_tex("2d_idle")
		elif anim_name == "jump":
			sprite_3d.texture = get_tex("2d_jump")
		elif anim_name == "crouch":
			sprite_3d.texture = get_tex("2d_crouch")
		elif anim_name == "land":
			sprite_3d.texture = get_tex("2d_land")
	elif Global.active_dimension == Global.Dimension.DIM_2_5D:
		if not is_shifting_lane:
			if anim_name == "idle":
				sprite_3d.texture = get_tex("25d_idle")
			elif anim_name == "jump":
				sprite_3d.texture = get_tex("2d_jump")
	elif Global.active_dimension == Global.Dimension.DIM_3D:
		if anim_name == "idle":
			match last_facing_axis:
				"iso":
					sprite_3d.texture = get_tex("3d_iso_idle")
				"side":
					sprite_3d.texture = get_tex("3d_side_idle")
				"back":
					sprite_3d.texture = get_tex("3d_back_idle")
				"front":
					sprite_3d.texture = get_tex("3d_front_idle")
				_:
					sprite_3d.texture = get_tex("3d_iso_idle")
		elif anim_name == "jump":
			sprite_3d.texture = get_tex("2d_jump")

func update_walk_frames(delta: float) -> void:
	walk_frame_timer += delta
	if walk_frame_timer >= 0.11:
		walk_frame_timer = 0.0
		walk_frame = (walk_frame % 4) + 1
		
		if Global.active_dimension == Global.Dimension.DIM_2D:
			sprite_3d.texture = get_tex("2d_walk_" + str(walk_frame))
		elif Global.active_dimension == Global.Dimension.DIM_2_5D:
			var walk_25d_idx = ((walk_frame - 1) % 2) + 1
			sprite_3d.texture = get_tex("25d_walk_" + str(walk_25d_idx))
		elif Global.active_dimension == Global.Dimension.DIM_3D:
			# Directional walk in 3D (camera at -45 deg)
			var raw_x = Input.get_axis("move_left", "move_right")
			var raw_y = Input.get_axis("move_up", "move_down")
			
			var moving_diagonal = abs(raw_x) > 0.2 and abs(raw_y) > 0.2
			var walk_idx = ((walk_frame - 1) % 2) + 1
			
			if moving_diagonal:
				last_facing_axis = "iso"
				sprite_3d.texture = get_tex("3d_iso_walk_" + str(walk_idx))
				sprite_3d.flip_h = raw_x < 0
			elif abs(raw_x) > abs(raw_y):
				last_facing_axis = "side"
				sprite_3d.texture = get_tex("3d_side_walk_" + str(walk_idx))
				sprite_3d.flip_h = raw_x < 0
			elif raw_y < 0:
				last_facing_axis = "back"
				sprite_3d.texture = get_tex("3d_back_walk_" + str(walk_idx))
				sprite_3d.flip_h = false
			else:
				last_facing_axis = "front"
				sprite_3d.texture = get_tex("3d_front_walk_" + str(walk_idx))
				sprite_3d.flip_h = false
