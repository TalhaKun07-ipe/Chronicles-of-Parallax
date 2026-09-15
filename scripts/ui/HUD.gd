extends CanvasLayer

@onready var watch_icon: TextureRect = $Control/WatchContainer/WatchIcon
@onready var dim_label: Label = $Control/WatchContainer/DimLabel
@onready var hp_container: HBoxContainer = $Control/HPContainer
@onready var rewind_bar: ProgressBar = $Control/RewindContainer/RewindBar
@onready var controls_label: Label = $Control/ControlsHint

const DIM_NAMES = {
	Global.Dimension.DIM_0D: "0D: POINT",
	Global.Dimension.DIM_1D: "1D: LINE",
	Global.Dimension.DIM_2D: "2D: PLANE",
	Global.Dimension.DIM_2_5D: "2.5D: LAYERS",
	Global.Dimension.DIM_3D: "3D: VOLUME"
}

func _ready() -> void:
	Global.dimension_changed.connect(_on_dimension_changed)
	Global.health_changed.connect(_on_health_changed)
	Global.ability_unlocked.connect(_on_ability_unlocked)
	Global.charge_state_changed.connect(_on_charge_state_changed)
	update_hud()

func _on_charge_state_changed(_has_charge: bool) -> void:
	update_controls_hint()
	# Pulse watch icon with cyan glow
	var tween = create_tween()
	tween.tween_property(watch_icon, "modulate", Color(0.2, 0.9, 1.0) if _has_charge else Color.WHITE, 0.2)

func _on_dimension_changed(new_dim: Global.Dimension, _old: Global.Dimension) -> void:
	update_dim_display(new_dim)
	update_controls_hint()

const HEART_FULL = preload("res://assets/ui/heart_full.png")
const HEART_EMPTY = preload("res://assets/ui/heart_empty.png")

func _on_health_changed(hp: int) -> void:
	for i in range(hp_container.get_child_count()):
		var pip = hp_container.get_child(i)
		if pip is TextureRect:
			pip.texture = HEART_FULL if i < hp else HEART_EMPTY
			pip.modulate = Color(1, 1, 1, 1) if i < hp else Color(0.6, 0.6, 0.6, 0.7)
		else:
			pip.modulate = Color(1, 1, 1, 1) if i < hp else Color(0.3, 0.3, 0.3, 0.4)

func _on_ability_unlocked(_dim: Global.Dimension) -> void:
	update_controls_hint()
	# Pulse watch icon
	var tween = create_tween()
	tween.tween_property(watch_icon, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(watch_icon, "scale", Vector2(1.0, 1.0), 0.15)

func update_hud() -> void:
	update_dim_display(Global.active_dimension)
	_on_health_changed(Global.current_health)
	update_controls_hint()

func update_dim_display(dim: Global.Dimension) -> void:
	dim_label.text = DIM_NAMES.get(dim, "")
	# Highlight glow
	match dim:
		Global.Dimension.DIM_0D:
			dim_label.modulate = Color(0.6, 0.8, 1.0)
		Global.Dimension.DIM_1D:
			dim_label.modulate = Color(0.0, 1.0, 0.9)
		Global.Dimension.DIM_2D:
			dim_label.modulate = Color(0.4, 1.0, 0.5)
		Global.Dimension.DIM_2_5D:
			dim_label.modulate = Color(1.0, 0.8, 0.3)
		Global.Dimension.DIM_3D:
			dim_label.modulate = Color(1.0, 0.4, 0.7)

func update_controls_hint() -> void:
	var hints: Array[String] = []
	match Global.active_dimension:
		Global.Dimension.DIM_0D:
			hints.append("[SPACE]: Pulse")
		Global.Dimension.DIM_1D:
			hints.append("[A/D]: Slide Rail | [2]: Plane | [3]: Volume")
		Global.Dimension.DIM_2D:
			hints.append("[A/D]: Run | [SPACE]: Jump | [S]: Crouch | [1]: Rail | [3]: Volume")
		Global.Dimension.DIM_3D:
			hints.append("[WASD]: Move 3D | [SPACE]: Jump | [F]: Interact | [1]: Rail | [2]: Plane")
		Global.Dimension.DIM_2_5D:
			hints.append("[A/D]: Walk | [W/S]: Switch Layer | [SPACE]: Jump")
			
	if Global.carried_charge:
		hints.insert(0, "[★ ENERGY CHARGED]")
		
	if Global.rewind_unlocked:
		hints.append("[HOLD R]: Rewind 4D")
		$Control/RewindContainer.visible = true
	else:
		$Control/RewindContainer.visible = false
		
	hints.append("[F8]: 128/64px")
	controls_label.text = " | ".join(hints)
