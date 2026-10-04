extends CanvasLayer

signal pause_requested()
signal retry_requested()
var player: ChronoPlayer
var room: Node3D
var time_bar: ProgressBar
var time_label: Label
var mode_label: Label
var section_label: Label
var hint_label: Label
var controls_label: Label
var pause_panel: Control
var hint_timer: float = 0.0

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	var card := Panel.new()
	card.position = Vector2(14, 14)
	card.size = Vector2(368, 114)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.035, 0.055, 0.07, 0.88)
	for corner in ["corner_radius_top_left", "corner_radius_top_right", "corner_radius_bottom_left", "corner_radius_bottom_right"]:
		card_style.set(corner, 8)
	card.add_theme_stylebox_override("panel", card_style)
	ui.add_child(card)
	var watch := TextureRect.new()
	watch.name = "ChronoLensIcon"
	watch.texture = load("res://assets/ui/ancient_watch_hud.png")
	watch.position = Vector2(26, 23)
	watch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	watch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	watch.size = Vector2(62, 62)
	ui.add_child(watch)
	watch.set_deferred("size", Vector2(62, 62))
	time_label = label(ui, "CHRONO-LENS", Vector2(104, 20), Vector2(270, 28), 19, Color("dccb96"))
	time_bar = ProgressBar.new()
	time_bar.position = Vector2(104, 52)
	time_bar.size = Vector2(245, 10)
	time_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("67d7db")
	fill.corner_radius_top_left = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_right = 3
	time_bar.add_theme_stylebox_override("fill", fill)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("24323e")
	time_bar.add_theme_stylebox_override("background", background)
	ui.add_child(time_bar)
	time_bar.size = Vector2(245, 10)
	section_label = label(ui, "I  /  THE FRACTURED STAIR", Vector2(28, 98), Vector2(500, 28), 17, Color("c9bea4"))
	mode_label = label(ui, "2D · PLANE", Vector2.ZERO, Vector2(230, 34), 21, Color("9ddeed"))
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint_label = label(ui, "", Vector2.ZERO, Vector2.ZERO, 23, Color("fff0c6"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_label = label(ui, "", Vector2.ZERO, Vector2.ZERO, 17, Color("d8d6cc"))
	controls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(pause_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.035, 0.045, 0.92)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.position -= Vector2(180, 130)
	box.custom_minimum_size = Vector2(360, 0)
	box.add_theme_constant_override("separation", 20)
	pause_panel.add_child(box)
	var title := Label.new()
	title.text = "TIME STANDS STILL"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	for choice in ["Resume", "Retry from time anchor"]:
		var button := Button.new()
		button.text = choice
		button.custom_minimum_size.y = 46
		box.add_child(button)
		if choice == "Resume": button.pressed.connect(func(): pause_requested.emit())
		else: button.pressed.connect(func(): retry_requested.emit())
	pause_panel.visible = false

func label(parent: Control, text: String, at: Vector2, bounds: Vector2, font_size: int, color: Color) -> Label:
	var item := Label.new()
	item.text = text
	item.position = at
	item.size = bounds
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.add_theme_constant_override("outline_size", 4)
	item.add_theme_color_override("font_outline_color", Color("10151a"))
	parent.add_child(item)
	return item

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_requested.emit()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_BACKSPACE:
		retry_requested.emit()
		get_viewport().set_input_as_handled()

func show_hint(text: String, duration: float = 7.0) -> void:
	hint_label.text = text
	hint_timer = duration
	hint_label.modulate.a = 1.0

func _process(delta: float) -> void:
	if not is_instance_valid(player): return
	var viewport_size := get_viewport().get_visible_rect().size
	mode_label.position = Vector2(viewport_size.x - 255, 25)
	hint_label.position = Vector2(40, viewport_size.y - 150)
	hint_label.size = Vector2(viewport_size.x - 80, 70)
	controls_label.position = Vector2(20, viewport_size.y - 47)
	controls_label.size = Vector2(viewport_size.x - 40, 28)
	pause_panel.visible = get_tree().paused
	var clock := player.rewind_controller
	time_bar.value = clock.energy_seconds / clock.max_energy_seconds * 100.0
	time_label.text = "REWINDING" if clock.is_rewinding else "REWIND  %.1fs  /  HOLD R" % clock.available_seconds()
	mode_label.text = {1: "1D · CONDUIT", 2: "2D · PLANE", 3: "3D · VOLUME"}[player.mode]
	controls_label.text = "A/D Move  ·  SPACE Jump  ·  1/2/3 Dimension  ·  R Rewind  ·  F Interact  ·  ESC Pause"
	if player.mode == 3: controls_label.text = "WASD Move Across Depth  ·  2 Jump Mode  ·  R Rewind  ·  F Interact  ·  ESC Pause"
	elif player.mode == 1: controls_label.text = "A/D Slide  ·  2/3 Expand  ·  R Rewind  ·  ESC Pause"
	if not get_tree().paused:
		hint_timer = maxf(0, hint_timer - delta)
		hint_label.modulate.a = minf(1.0, hint_timer)
