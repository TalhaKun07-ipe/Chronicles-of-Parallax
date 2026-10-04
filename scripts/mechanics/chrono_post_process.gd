extends CanvasLayer
class_name ChronoPostProcess

## Presentation observes the controller; it never changes the simulation clock.
@export var controller: Node
@export var color_rect: ColorRect
@export var rewind_material: ShaderMaterial
@export var energy_bar: ProgressBar
var current_energy: float = 240.0
var max_energy: float = 240.0
var factor: float = 0.0

func _ready() -> void:
	layer = 40
	if not color_rect:
		color_rect = ColorRect.new()
		color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(color_rect)
	if not rewind_material:
		rewind_material = ShaderMaterial.new()
		rewind_material.shader = load("res://shaders/chrono_warp.gdshader")
	color_rect.material = rewind_material
	color_rect.visible = false

func _process(delta: float) -> void:
	factor = move_toward(factor, 1.0 if Global.is_rewinding else 0.0, delta * 5)
	color_rect.visible = factor > 0.001
	rewind_material.set_shader_parameter("rewind_factor", factor)
	if is_instance_valid(controller):
		current_energy = controller.energy_seconds
		max_energy = controller.max_energy_seconds
	if energy_bar: energy_bar.value = current_energy / max_energy * 100.0
