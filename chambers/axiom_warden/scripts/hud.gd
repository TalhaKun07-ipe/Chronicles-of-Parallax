extends Control
signal advance_requested
signal skip_requested
signal pause_requested
signal retry_requested
signal victory_advance_requested
signal voice_tick

var health: int = 3
var dimension: int = 3
var hits: int = 0
var fight_visible: bool = false
var final_round: bool = false
var objective: String = "Reach the upper sanctum.":
	set(val):
		objective = val
		if is_instance_valid(subtitle_label) and val != "":
			subtitle_label.text = val
			subtitle_timer = 4.5
var phase_name: String = "THE ASCENT"
var hint: String = "A/D move   W/S depth   SPACE jump   1/2/3 form   F strike   ESC pause"
var dialogue_visible: bool = false
var speaker: String = ""
var text_body: String = ""
var revealed: float = 0
var paused: bool = false
var defeated: bool = false
var victory: bool = false
var line_label: Label
var subtitle_label: Label
var subtitle_timer: float = 0.0
var age: float = 0
var font: Font

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	line_label = Label.new()
	line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_label.add_theme_font_size_override("font_size", 23)
	line_label.add_theme_color_override("font_color", Color("f3eddc"))
	line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(line_label)

	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle_label.add_theme_font_size_override("font_size", 24)
	subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	subtitle_label.add_theme_constant_override("outline_size", 6)
	subtitle_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.98))
	subtitle_label.add_theme_constant_override("shadow_offset_x", 2)
	subtitle_label.add_theme_constant_override("shadow_offset_y", 2)
	subtitle_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(subtitle_label)
	if objective != "":
		subtitle_label.text = objective
		subtitle_timer = 4.5

func say(who: String, words: String) -> void:
	speaker = who
	text_body = words
	revealed = 0
	dialogue_visible = true

func show_subtitle(text: String, duration: float = 4.5) -> void:
	objective = text
	subtitle_timer = duration

func _process(delta: float) -> void:
	age += delta
	if dialogue_visible:
		var previous: int = int(revealed)
		if previous < text_body.length():
			var rate: float = 29.0
			if previous > 0 and text_body[previous - 1] in [".", "?", "!", ","]:
				rate = 5.0
			revealed = minf(text_body.length(), revealed + delta * rate)
			if int(revealed) != previous and int(revealed) % 3 == 0:
				voice_tick.emit()
	line_label.visible = dialogue_visible
	line_label.position = Vector2(200, size.y - 175)
	line_label.size = Vector2(maxf(200, size.x - 280), 115)
	line_label.text = "* " + text_body.substr(0, int(revealed))

	if subtitle_timer > 0.0:
		subtitle_timer -= delta
		subtitle_label.visible = not dialogue_visible and not paused and not defeated and subtitle_timer > 0.0
		subtitle_label.modulate.a = clampf(subtitle_timer / 0.35, 0.0, 1.0)
	else:
		subtitle_label.visible = false
	subtitle_label.size = Vector2(minf(1040, size.x - 80), 55)
	subtitle_label.position = Vector2((size.x - subtitle_label.size.x) * 0.5, size.y - 145)

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event is InputEventKey and event.pressed and not event.echo
	var key: int = 0
	if pressed:
		key = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if dialogue_visible:
		if pressed and key == KEY_ESCAPE:
			skip_requested.emit()
			get_viewport().set_input_as_handled()
		elif clicked or (pressed and key in [KEY_SPACE, KEY_ENTER, KEY_Z]):
			if revealed < text_body.length(): revealed = text_body.length()
			else: advance_requested.emit()
			get_viewport().set_input_as_handled()
	elif pressed and key == KEY_ENTER and defeated:
		retry_requested.emit()
		get_viewport().set_input_as_handled()
	elif pressed and key == KEY_ESCAPE and not defeated:
		pause_requested.emit()
		get_viewport().set_input_as_handled()

var john_portrait: Texture2D = preload("res://assets/ui/portraits/john_rod_portrait_determined.png")
var warden_portrait: Texture2D = preload("res://assets/ui/portraits/axiom_warden_portrait.png")
var heart_full_tex: Texture2D = preload("res://assets/ui/heart_full.png")
var heart_empty_tex: Texture2D = preload("res://assets/ui/heart_empty.png")

func label(at: Vector2, words: String, color: Color = Color("e9d8b2"), font_size: int = 18) -> void:
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	# Clean floating retro pixel hearts in top-left margin (matching Chamber 1)
	for i: int in 3:
		var tex: Texture2D = heart_full_tex if i < health else heart_empty_tex
		if tex:
			var heart_rect: Rect2 = Rect2(32 + i * 36, 24, 28, 28)
			draw_texture_rect(tex, heart_rect, false, Color.WHITE if i < health else Color(0.5, 0.5, 0.5, 0.5))

	# Clean contextual control hints (no brown bar, matching Chamber 1)
	var active_hint: String = hint
	if dimension == 2:
		active_hint = "WASD Move   •   SPACE Jump   •   1/2/3 Dimension   •   F Strike"
	elif dimension == 3:
		active_hint = "WASD Move Across Depth   •   1/2/3 Dimension   •   F Strike"
	elif dimension == 1:
		active_hint = "A/D Slide Along Conduit   •   1/2/3 Dimension   •   F Strike"
	var hint_pos: Vector2 = Vector2(w * 0.5 - active_hint.length() * 4.5, h - 24)
	draw_string(font, hint_pos + Vector2(1, 1), active_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0, 0, 0, 0.8))
	draw_string(font, hint_pos, active_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.96, 0.94, 0.90, 0.9))
	if fight_visible and not dialogue_visible:
		var x: float = w * 0.18
		var bw: float = w * 0.64
		# Grand, bold, majestic boss title — strictly "AXIOM WARDEN"
		var boss_title: String = "AXIOM WARDEN"
		var title_size: int = 30
		var title_pos: Vector2 = Vector2(x, h - 88)
		# Deep drop shadow & outline
		for ox: float in [-2.0, 0.0, 2.0]:
			for oy: float in [-2.0, 0.0, 2.0]:
				if ox != 0.0 or oy != 0.0:
					draw_string(font, title_pos + Vector2(ox + 2.0, oy + 2.0), boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color(0, 0, 0, 0.95))
		# Multi-pass bold fill in radiant gold
		for bx: float in [-1.0, 0.0, 1.0]:
			for by: float in [-0.5, 0.0, 0.5]:
				draw_string(font, title_pos + Vector2(bx, by), boss_title, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size, Color("fae4b5"))

		draw_rect(Rect2(x - 3, h - 73, bw + 6, 25), Color("d6b572"))
		draw_rect(Rect2(x, h - 70, bw, 19), Color("30211c"))
		var count: int = 1 if final_round else 5
		var remaining: int = (1 if hits < 6 else 0) if final_round else maxi(0, 5 - hits)
		for i: int in remaining:
			draw_rect(Rect2(x + i * bw / count + 2, h - 68, bw / count - 4, 15), Color("f39540") if final_round else Color("bc4637"))
	if dialogue_visible:
		var rect: Rect2 = Rect2(32, h - 231, w - 64, 188)
		draw_rect(rect.grow(5), Color.WHITE)
		draw_rect(rect.grow(2), Color.BLACK)
		draw_rect(rect, Color.WHITE, false, 2)
		draw_rect(rect.grow(-3), Color.BLACK)
		label(Vector2(200, h - 190), speaker, Color("f1c981"), 21)
		# Draw authentic pixel portrait matching Chamber 1
		var portrait_box: Rect2 = Rect2(48, h - 212, 136, 136)
		draw_rect(portrait_box.grow(3), Color("c9bea4"))
		draw_rect(portrait_box, Color(0.08, 0.06, 0.04))
		if speaker == "JOHN ROD":
			if john_portrait:
				draw_texture_rect(john_portrait, portrait_box, false)
		else:
			if warden_portrait:
				draw_texture_rect(warden_portrait, portrait_box, false)
		label(Vector2(w - 265, h - 57), "Z / SPACE / ENTER    ▾", Color("b8b4ac"), 14)
	if paused or defeated:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.01, 0.72))
		var title: String = "PAUSED" if paused else "THE WATCH STILL TICKS"
		label(Vector2(w * 0.27, h * 0.44), title, Color("f4d69d"), 34)
		var detail: String = "ESC to return" if paused else "ENTER to retry at the arena checkpoint"
		label(Vector2(w * 0.27, h * 0.51), detail, Color("e3dbca"), 20)
