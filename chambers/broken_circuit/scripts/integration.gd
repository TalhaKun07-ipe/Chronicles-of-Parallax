extends Node
## Optional bridge for the autoload names documented in dev-log Sessions 8–9.
## Standalone demo has no autoloads; this node then does nothing.
var global_state: Node
var transition: Node
var dimension_ids: Dictionary = {}
func _ready() -> void:
	global_state=get_node_or_null("/root/Global")
	transition=get_node_or_null("/root/SceneTransition")
	if global_state==null:return
	_set_existing("current_chamber_id","broken_circuit")
	var source: Script=global_state.get_script()
	if source:
		var constants: Dictionary=source.get_script_constant_map()
		dimension_ids=constants.get("Dimension",{})
	for key in ["DIM_1D","DIM_2D","DIM_3D"]:
		if dimension_ids.has(key) and global_state.has_method("unlock_dimension"):
			global_state.call("unlock_dimension",dimension_ids[key])
	var room: Node=get_parent().get_node("Chamber")
	var player: Node=get_parent().get_node("Player")
	room.charge_collected.connect(_charge)
	room.circuit_completed.connect(_power)
	room.chamber_completed.connect(_complete)
	player.mode_changed.connect(_dimension)
	_dimension(3)
	if transition and transition.has_method("fade_in_from_black"):
		transition.call("fade_in_from_black",0.4)
func _set_existing(key: String,value: Variant) -> void:
	for property in global_state.get_property_list():
		if property.name==key:
			global_state.set(key,value)
			return
func _charge_signal(value: bool) -> void:
	for entry in global_state.get_signal_list():
		if entry.name=="charge_state_changed":
			if entry.args.size()==0:global_state.emit_signal("charge_state_changed")
			elif entry.args.size()==1:global_state.emit_signal("charge_state_changed",value)
func _charge() -> void:
	_set_existing("carried_charge",true)
	_charge_signal(true)
func _power() -> void:
	_set_existing("carried_charge",false)
	_set_existing("receiver_powered",true)
	_charge_signal(false)
func _dimension(mode: int) -> void:
	var key: String="DIM_%dD" % mode
	if dimension_ids.has(key) and global_state.has_method("set_dimension"):
		global_state.call("set_dimension",dimension_ids[key])
func _complete() -> void:
	_set_existing("exit_open",true)
	await get_tree().create_timer(1.6).timeout
	var next_room: String="res://scenes/levels/Chamber1_DimensionalTrial.tscn"
	if transition and transition.has_method("change_chamber") and ResourceLoader.exists(next_room):
		transition.call("change_chamber",next_room)
