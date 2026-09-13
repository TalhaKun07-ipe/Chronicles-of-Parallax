extends CharacterBody3D
class_name GuardianBoss

# The Ancient Dungeon Guardian - Spatial Puzzle Boss (Revised Plan)
# Rewind is UNAVAILABLE during this battle. Defeating the Guardian unlocks 4D rewind.

signal boss_defeated()
signal slam_occurred(conduit_exposed: bool)
signal footholds_revealed(active: bool)

enum BossPhase { PHASE_1, PHASE_2, DEFEATED }

@export var max_health: int = 2
var current_health: int = 2
var phase: BossPhase = BossPhase.PHASE_1

@export var linked_conduit: NodePath
@export var linked_runic_footholds: Array[NodePath] = []
@export var linked_rear_lever: NodePath

@onready var sprite_3d: Sprite3D = $Sprite3D
@onready var core_area: Area3D = $ExposedCoreArea
@onready var sweep_hitbox: Area3D = $SweepHitbox

var is_core_vulnerable: bool = false
var is_slamming: bool = false
var slam_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	if core_area:
		core_area.body_entered.connect(_on_core_entered)
	if sweep_hitbox:
		sweep_hitbox.body_entered.connect(_on_sweep_hit)
		
	# Wire up rear lever if present
	if linked_rear_lever:
		var lever = get_node_or_null(linked_rear_lever)
		if lever and lever.has_signal("pulled"):
			lever.pulled.connect(_on_rear_mechanism_activated)
			
	set_core_vulnerable(false)
	trigger_slam()

func _physics_process(delta: float) -> void:
	if phase == BossPhase.DEFEATED:
		return
		
	slam_timer += delta
	if not is_core_vulnerable and slam_timer >= (4.5 if phase == BossPhase.PHASE_1 else 3.5):
		slam_timer = 0.0
		trigger_slam()

func trigger_slam() -> void:
	is_slamming = true
	SoundManager.play_sfx("hurt")
	
	# Telegraph jump and smash down
	var tween = create_tween()
	tween.tween_property(sprite_3d, "position:y", 2.2, 0.3).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(sprite_3d, "position:y", 0.0, 0.15).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(func():
		is_slamming = false
		slam_occurred.emit(true)
		# Expose maintenance conduit slot
		var conduit = get_node_or_null(linked_conduit)
		if conduit and conduit.has_method("setup_visuals"):
			conduit.visible = true
	)

func _on_rear_mechanism_activated() -> void:
	# 3D flank succeeded — activate 2D runic footholds leading to vulnerable core!
	footholds_revealed.emit(true)
	set_core_vulnerable(true)
	SoundManager.play_sfx("unlock")
	
	for path in linked_runic_footholds:
		var platform = get_node_or_null(path)
		if platform and platform.has_method("activate"):
			platform.activate()

func set_core_vulnerable(vulnerable: bool) -> void:
	is_core_vulnerable = vulnerable
	if core_area:
		core_area.monitoring = vulnerable
	if vulnerable:
		sprite_3d.modulate = Color(1.3, 0.4, 0.4, 0.9)
	else:
		sprite_3d.modulate = Color.WHITE

func take_core_strike() -> void:
	current_health -= 1
	SoundManager.play_sfx("hurt")
	set_core_vulnerable(false)
	
	# Stagger animation
	var tween = create_tween()
	tween.tween_property(sprite_3d, "scale", Vector3(1.4, 1.4, 1.4), 0.1)
	tween.tween_property(sprite_3d, "scale", Vector3(1.0, 1.0, 1.0), 0.15)
	
	if current_health <= 0:
		defeat()
	else:
		phase = BossPhase.PHASE_2
		slam_timer = 0.0
		# Reset footholds for cycle 2
		footholds_revealed.emit(false)

func defeat() -> void:
	phase = BossPhase.DEFEATED
	set_core_vulnerable(false)
	SoundManager.play_sfx("unlock")
	
	# Release the time seal on John Rod's watch!
	Global.unlock_rewind()
	boss_defeated.emit()
	
	var tween = create_tween()
	tween.tween_property(sprite_3d, "modulate:a", 0.0, 1.8)
	tween.tween_callback(queue_free)

func _on_core_entered(body: Node3D) -> void:
	if body is Player and is_core_vulnerable:
		take_core_strike()

func _on_sweep_hit(body: Node3D) -> void:
	if body is Player and is_slamming:
		Global.take_damage(1)
