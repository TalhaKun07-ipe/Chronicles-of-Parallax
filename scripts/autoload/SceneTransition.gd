extends Node

# Global Scene Transition Manager for Degrees of Escape
# Provides retro black-screen iris / fade animations with sound cues between dungeon chambers.

var canvas_layer: CanvasLayer
var color_rect: ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100
	add_child(canvas_layer)
	
	color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.modulate.a = 0.0
	canvas_layer.add_child(color_rect)

func change_chamber(target_scene_path: String, duration: float = 0.35) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_sfx"):
		sm.play_sfx("unlock")
	
	# Fade out to black
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished
	
	# Change scene
	var err = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to load chamber: " + target_scene_path)
		color_rect.modulate.a = 0.0
		is_transitioning = false
		return
	
	# Wait brief moment for new scene tree initialization
	await get_tree().process_frame
	await get_tree().create_timer(0.06).timeout
	
	# Fade in from black
	var fade_in = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fade_in.tween_property(color_rect, "modulate:a", 0.0, duration)
	await fade_in.finished
	
	is_transitioning = false

func fade_in_from_black(duration: float = 0.5) -> void:
	if is_transitioning:
		return
	color_rect.modulate.a = 1.0
	var tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
