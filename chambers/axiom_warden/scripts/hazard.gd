extends Node3D
## Continuous collision in world space. Dimension-reactive hazards.
const Geo = preload("res://chambers/axiom_warden/scripts/geometry.gd")
signal hit_player

var kind: String = "beam"
# Concrete difficulty adjustment: increased warning time by 20% (1.15 -> 1.38s)
var warning: float = 1.38
var duration: float = 0.7
var age: float = 0.0
var direction: Vector3 = Vector3.LEFT
# Concrete difficulty adjustment: reduced projectile speed by 15% (7.0 -> 5.95)
var speed: float = 5.95
var radius: float = 0.3
var previous_radius: float = 0.3
var previous_position: Vector3
var damaged: bool = false
var damage_enabled: bool = true
var target: CharacterBody3D
var visual: Node3D
var warning_mat: StandardMaterial3D
var active_mat: StandardMaterial3D
var sound_played: bool = false

# Dimension-aware collision flags
var collision_layer: int = 1
var collision_mask: int = 1
var wall_body: StaticBody3D

func _ready() -> void:
	warning_mat = Geo.material(Color("d9973e"), true)
	active_mat = Geo.material(Color("60f8ed"), true)
	previous_position = global_position
	match kind:
		"beam":
			visual = Geo.box(self, Vector3.ZERO, Vector3(25, 0.07, 0.12), warning_mat)
		"lane":
			visual = Geo.box(self, Vector3(0, -position.y + 0.035, 0), Vector3(25, 0.04, 1.35), warning_mat)
		"sweep":
			visual = Geo.ring(self, Vector3.ZERO, 1.0, 0.05, warning_mat)
		"slam":
			visual = Geo.ring(self, Vector3(0, 0.04, 0), 0.8, 0.08, warning_mat)
		"bolt":
			visual = Geo.box(self, Vector3.ZERO, Vector3(0.34, 0.34, 0.34), active_mat)
		"body":
			visual = Geo.ring(self, Vector3.ZERO, 1.8, 0.07, warning_mat)
		"guardian":
			# Dedicated Flat Guardian projectile: travels toward player, becomes ethereal in 2D
			var spr := Sprite3D.new()
			spr.texture = load("res://chambers/broken_circuit/assets/sprites/flat_guardian.png")
			spr.pixel_size = 0.028
			spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			spr.position.y = 0.8
			visual = spr
			add_child(visual)

			var eye := OmniLight3D.new()
			eye.name = "GuardianEye"
			eye.light_color = Color("d9973e")
			eye.light_energy = 1.2
			eye.omni_range = 3.5
			eye.position.y = 0.95
			add_child(eye)

			speed = 6.4
			duration = 4.5
		"rising_wall":
			# 3D Lateral Hazard: Physical stone wall rising in player's path
			visual = Geo.box(self, Vector3(0, 0.04, 0), Vector3(1.2, 0.08, 2.8), warning_mat)
			warning = 1.20
			duration = 3.8
	_play_sfx("boss_warning" if kind not in ["bolt", "guardian"] else "boss_bolts")

func _play_sfx(cue: String) -> void:
	var sound: Node = get_node_or_null("/root/SoundManager")
	if sound and sound.has_method("play_sfx"):
		sound.call("play_sfx", cue)

func is_dangerous() -> bool:
	return age >= warning and age < warning + duration

func intersects(feet: Vector3, height: float, player_radius: float, player_mode: int) -> bool:
	if not is_dangerous() or not damage_enabled:
		return false
	var low: float = feet.y
	var high: float = feet.y + height
	if player_mode == 1:
		low -= 0.065
		high = low + 0.13

	# Concrete difficulty reduction: 10% reduced hitbox margins
	match kind:
		"beam":
			return absf(feet.x - global_position.x) < 12.5 + player_radius and absf(feet.z - global_position.z) < 0.18 + player_radius and low < global_position.y + 0.13 and high > global_position.y - 0.13
		"lane":
			return absf(feet.x - global_position.x) < 12.5 + player_radius and absf(feet.z - global_position.z) < 0.675 + player_radius and low < 3.3
		"sweep":
			var dist: float = Vector2(feet.x - global_position.x, feet.z - global_position.z).length()
			return dist >= previous_radius - player_radius - 0.14 and dist <= radius + player_radius + 0.14 and low < global_position.y + 0.14 and high > global_position.y - 0.14
		"slam":
			var dist: float = Vector2(feet.x - global_position.x, feet.z - global_position.z).length()
			return dist >= previous_radius - player_radius - 0.22 and dist <= radius + player_radius + 0.22 and low < 0.32 and high > -0.2
		"bolt":
			var center: Vector3 = feet + Vector3.UP * (height * 0.5 if player_mode != 1 else 0.0)
			var closest: Vector3 = Geometry3D.get_closest_point_to_segment(center, previous_position, global_position)
			return Vector2(center.x - closest.x, center.z - closest.z).length() < player_radius + 0.19 and low < closest.y + 0.20 and high > closest.y - 0.20
		"body":
			return player_mode == 3 and feet.distance_to(global_position) < 1.7
		"guardian":
			# Harmless in 2D mode!
			if player_mode == 2:
				return false
			var center: Vector3 = feet + Vector3.UP * (height * 0.5 if player_mode != 1 else 0.0)
			var closest: Vector3 = Geometry3D.get_closest_point_to_segment(center, previous_position, global_position)
			return Vector2(center.x - closest.x, center.z - closest.z).length() < player_radius + 0.32 and low < closest.y + 0.9 and high > closest.y - 0.3
		"rising_wall":
			# Only damages if caught directly inside rising geometry at moment of eruption
			if age - warning < 0.4:
				return absf(feet.x - global_position.x) < 0.55 + player_radius and absf(feet.z - global_position.z) < 1.35 + player_radius
			return false
	return false

func _physics_process(delta: float) -> void:
	age += delta
	previous_position = global_position
	previous_radius = radius

	# Dynamic dimension-reactivity for Flat Guardian projectile
	if kind == "guardian":
		var eye: OmniLight3D = get_node_or_null("GuardianEye")
		if age < warning:
			# Warning telegraph: lock gaze onto player and pulse warning amber
			if is_instance_valid(target):
				var to_player: Vector3 = target.global_position - global_position
				to_player.y = 0
				if to_player.length_squared() > 0.01:
					direction = to_player.normalized()
			var pulse: float = sin(age * 16.0) * 0.5 + 0.5
			if eye:
				eye.light_color = Color("d9973e")
				eye.light_energy = 1.0 + pulse * 0.8
			if visual is Sprite3D:
				visual.scale = Vector3.ONE * (1.0 + pulse * 0.08)
				visual.modulate = Color(1.0, 0.9, 0.7, 1.0)
		else:
			var in_2d: bool = is_instance_valid(target) and int(target.get("mode")) == 2
			if in_2d:
				collision_layer = 0
				collision_mask = 0
				damage_enabled = false
				if visual is Sprite3D:
					visual.modulate = Color(0.4, 0.8, 1.0, 0.28) # Paper-thin ethereal in 2D
					visual.scale = Vector3.ONE
				if eye:
					eye.light_color = Color(0.4, 0.8, 1.0)
					eye.light_energy = 0.4
			else:
				collision_layer = 1
				collision_mask = 1
				damage_enabled = true
				if visual is Sprite3D:
					visual.modulate = Color(1.0, 1.0, 1.0, 1.0) # Solid physical in 3D
					visual.scale = Vector3.ONE
				if eye:
					eye.light_color = Color(1.0, 0.2, 0.15) # Fierce crimson in 3D
					eye.light_energy = 1.6

	if is_dangerous():
		if not sound_played:
			sound_played = true
			match kind:
				"beam": _play_sfx("boss_beam")
				"sweep": _play_sfx("boss_sweep")
				"lane": _play_sfx("boss_lane")
				"slam": _play_sfx("boss_slam")
				"rising_wall": _play_sfx("stone_grind")
				"guardian": _play_sfx("transform")
		if visual is MeshInstance3D:
			visual.material_override = active_mat
		if kind == "bolt":
			global_position += direction * speed * delta
			visual.rotation += Vector3(1, 2, 1) * delta
		elif kind == "guardian":
			# Active charge: target and steer dynamically towards the player
			if is_instance_valid(target):
				var to_target: Vector3 = target.global_position - global_position
				to_target.y = 0
				# Only home while the player is in front of the charging guardian
				if direction.dot(to_target) > 0.0 and to_target.length_squared() > 0.2:
					var target_dir: Vector3 = to_target.normalized()
					var steer_rate: float = 3.8 # Radians per second (~218 deg/s)
					var cur_ang: float = atan2(direction.z, direction.x)
					var tgt_ang: float = atan2(target_dir.z, target_dir.x)
					var diff_ang: float = wrapf(tgt_ang - cur_ang, -PI, PI)
					var max_turn: float = steer_rate * delta
					var new_ang: float = cur_ang + clampf(diff_ang, -max_turn, max_turn)
					direction = Vector3(cos(new_ang), 0.0, sin(new_ang)).normalized()

			global_position += direction * speed * delta
			visual.position.y = 0.8 + sin(age * 8.0) * 0.12
			visual.rotation.z = -direction.z * 0.3
		elif kind == "rising_wall":
			var rise: float = clampf((age - warning) / 0.35, 0.0, 1.0)
			visual.scale = Vector3(1.0, lerpf(0.1, 35.0, rise), 1.0)
			visual.position.y = lerpf(0.04, 1.4, rise)
			if not is_instance_valid(wall_body) and rise > 0.5:
				wall_body = StaticBody3D.new()
				var col := CollisionShape3D.new()
				var b := BoxShape3D.new()
				b.size = Vector3(1.2, 2.8, 2.8)
				col.shape = b
				col.position.y = 1.4
				wall_body.add_child(col)
				add_child(wall_body)
		elif kind == "sweep":
			radius = 1.0 + (age - warning) * speed
			visual.scale = Vector3(radius, 1, radius)
		elif kind == "slam":
			radius = 0.8 + (age - warning) * speed
			visual.scale = Vector3(radius, 1, radius)
		elif kind == "lane":
			visual.position.y = 0
			visual.scale.y = 75
		elif kind == "beam":
			visual.scale = Vector3(1, 3.0, 2.5)
	elif kind in ["sweep", "slam"]:
		visual.scale = Vector3(1.4, 1, 1.4)

	if is_instance_valid(target) and not damaged and intersects(target.global_position, 1.14, 0.19, int(target.get("mode"))):
		damaged = true
		hit_player.emit()
	if age > warning + duration:
		queue_free()

