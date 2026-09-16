extends Control
signal advance_requested
signal skip_requested
signal pause_requested
signal retry_requested
signal voice_tick

var health: int = 3
var dimension: int = 3
var hits: int = 0
var fight_visible: bool = false
var final_round: bool = false
var objective: String = "Reach the upper sanctum."
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

func say(who: String, words: String) -> void:
	speaker = who
	text_body = words
	revealed = 0
	dialogue_visible = true

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
	line_label.position = Vector2(190, size.y - 170)
	line_label.size = Vector2(maxf(200, size.x - 260), 112)
	line_label.text = "* " + text_body.substr(0, int(revealed))
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
	elif pressed and key == KEY_ESCAPE and not defeated and not victory:
		pause_requested.emit()
		get_viewport().set_input_as_handled()

func label(at: Vector2, words: String, color: Color = Color("e9d8b2"), font_size: int = 18) -> void:
	draw_string(font, at, words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(0, 0, w, 70), Color(0.055, 0.035, 0.02, 0.92))
	draw_line(Vector2(0, 70), Vector2(w, 70), Color("8c6835"), 2)
	label(Vector2(24, 29), "02 / THE AXIOM SANCTUM", Color("e4bd73"), 20)
	label(Vector2(24, 54), objective, Color("c9bea4"), 16)
	label(Vector2(w - 250, 30), "%dD   /   JOHN ROD" % dimension, Color("6af3e8"), 18)
	for i: int in 3:
		label(Vector2(w - 135 + i * 34, 58), "♥", Color("ec574b") if i < health else Color("574238"), 27)
	draw_rect(Rect2(0, h - 32, w, 32), Color(0.04, 0.025, 0.015, 0.94))
	label(Vector2(24, h - 10), hint, Color("c9bea4"), 16)
	if fight_visible and not dialogue_visible:
		var x: float = w * 0.18
		var bw: float = w * 0.64
		label(Vector2(x, h - 84), "AXIOM WARDEN  /  " + phase_name, Color("f1d8a2"), 18)
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
		label(Vector2(190, h - 190), speaker, Color("f1c981"), 21)
		var center: Vector2 = Vector2(105, h - 157)
		if speaker == "JOHN ROD":
			# John has a hollow head and wire limbs, never a human face.
			draw_arc(center, 22, 0, TAU, 32, Color("dee3e7"), 4)
			draw_line(center + Vector2(0, 23), center + Vector2(0, 71), Color("dee3e7"), 4)
			draw_polyline(PackedVector2Array([center + Vector2(0, 31), center + Vector2(-25, 46), center + Vector2(-8, 61)]), Color("dee3e7"), 4)
			draw_polyline(PackedVector2Array([center + Vector2(0, 31), center + Vector2(24, 45), center + Vector2(35, 25)]), Color("dee3e7"), 4)
		else:
			draw_arc(center, 41, 0, TAU, 12, Color("ba8a39"), 5)
			draw_rect(Rect2(center - Vector2(24, 30), Vector2(48, 68)), Color("75502a"))
			draw_rect(Rect2(center - Vector2(24, 30), Vector2(48, 68)), Color("ddb464"), false, 3)
			draw_line(center - Vector2(0, 18), center + Vector2(0, 24), Color("4aeada"), 5)
		label(Vector2(w - 265, h - 57), "Z / SPACE / ENTER    ▾", Color("b8b4ac"), 14)
	if paused or defeated or victory:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.01, 0.72))
		var title: String = "PAUSED" if paused else ("THE WARDEN HAS FALLEN" if victory else "THE WATCH STILL TICKS")
		label(Vector2(w * 0.27, h * 0.44), title, Color("f4d69d"), 34)
		var detail: String = "ESC to return" if paused else ("Chamber complete. Time remains sealed for now." if victory else "ENTER to retry at the arena checkpoint")
		label(Vector2(w * 0.27, h * 0.51), detail, Color("e3dbca"), 20)
