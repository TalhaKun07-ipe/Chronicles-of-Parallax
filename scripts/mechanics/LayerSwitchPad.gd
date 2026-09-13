extends Area3D
class_name LayerSwitchPad

# Allows player to switch between foreground and background depth lanes in 2.5D mode

@onready var indicator: Sprite3D = $Indicator

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if indicator:
		indicator.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		body.can_shift_lanes = true
		if indicator:
			indicator.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.can_shift_lanes = false
		if indicator:
			indicator.visible = false
