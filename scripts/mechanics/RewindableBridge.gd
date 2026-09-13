extends Node3D
class_name RewindableBridge

# A collapsing stone bridge that can be restored with Time Rewind

enum State { INTACT, CRACKING, COLLAPSED }

var current_state: State = State.INTACT
var history: Array[State] = []
const MAX_HISTORY: int = 240

@onready var mesh_intact: MeshInstance3D = $MeshIntact
@onready var mesh_cracked: MeshInstance3D = $MeshCracked
@onready var static_body: StaticBody3D = $StaticBody3D
@onready var trigger_area: Area3D = $TriggerArea

var collapse_timer: float = 0.0
const COLLAPSE_DELAY: float = 0.6

func _ready() -> void:
	trigger_area.body_entered.connect(_on_body_entered)
	update_visuals()

func _physics_process(delta: float) -> void:
	if Global.is_rewinding:
		if history.size() > 0:
			current_state = history.pop_back()
			update_visuals()
		return
		
	# Record state
	history.append(current_state)
	if history.size() > MAX_HISTORY:
		history.pop_front()
		
	if current_state == State.CRACKING:
		collapse_timer += delta
		# Shake bridge
		mesh_cracked.position.x = (randf() - 0.5) * 0.05
		if collapse_timer >= COLLAPSE_DELAY:
			collapse_bridge()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and current_state == State.INTACT:
		current_state = State.CRACKING
		collapse_timer = 0.0
		update_visuals()
		SoundManager.play_sfx("error")

func collapse_bridge() -> void:
	current_state = State.COLLAPSED
	update_visuals()
	SoundManager.play_sfx("hurt")

func update_visuals() -> void:
	match current_state:
		State.INTACT:
			mesh_intact.visible = true
			mesh_cracked.visible = false
			static_body.process_mode = Node.PROCESS_MODE_INHERIT
		State.CRACKING:
			mesh_intact.visible = false
			mesh_cracked.visible = true
			static_body.process_mode = Node.PROCESS_MODE_INHERIT
		State.COLLAPSED:
			mesh_intact.visible = false
			mesh_cracked.visible = false
			static_body.process_mode = Node.PROCESS_MODE_DISABLED
