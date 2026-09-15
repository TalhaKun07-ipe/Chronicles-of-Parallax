extends CanvasLayer
class_name UndertaleDialogueBox

## Undertale-style retro dialogue system for Degrees of Escape
## Faithful to the reference: crisp white double border, character portrait,
## typewriter letter crawl with retro voice blips, and natural punctuation pacing.

signal dialogue_started
signal line_started(index: int)
signal line_completed(index: int)
signal dialogue_finished

@onready var root_control: Control = $DialogueRoot
@onready var box_panel: PanelContainer = $DialogueRoot/BoxPanel
@onready var portrait_rect: TextureRect = $DialogueRoot/BoxPanel/MarginContainer/HBoxContainer/PortraitBox/PortraitTexture
@onready var text_label: Label = $DialogueRoot/BoxPanel/MarginContainer/HBoxContainer/TextContainer/DialogueText
@onready var arrow_indicator: Label = $DialogueRoot/BoxPanel/MarginContainer/HBoxContainer/TextContainer/ArrowIndicator
@onready var stat_box: PanelContainer = $DialogueRoot/StatBox
@onready var stat_label: Label = $DialogueRoot/StatBox/MarginContainer/StatLabel

const PORTRAITS = {
	"dazed": preload("res://assets/ui/portraits/john_rod_portrait_dazed.png"),
	"watch": preload("res://assets/ui/portraits/john_rod_portrait_watch.png"),
	"revelation": preload("res://assets/ui/portraits/john_rod_portrait_revelation.png"),
	"determined": preload("res://assets/ui/portraits/john_rod_portrait_determined.png")
}

const DEFAULT_SCRIPT = [
	{
		"portrait": "dazed",
		"text": "* ...Where am I?\n* How did I survive that fall?",
		"sfx_cue": ""
	},
	{
		"portrait": "watch",
		"text": "* (The Ancient Watch pulses with an ethereal glow.)\n* You're still glowing.\n* What did you do to me?",
		"sfx_cue": "pulse"
	},
	{
		"portrait": "revelation",
		"text": "* A line... a plane... a whole body.\n* I can change between them!\n* I can bend the very degrees of space!",
		"sfx_cue": "transform"
	},
	{
		"portrait": "determined",
		"text": "* (The broken circuit ascends into the deep cavern.)\n* That’s a long way up.\n* ...All right. One step at a time.",
		"sfx_cue": "unlock"
	}
]

var dialogue_script: Array = []
var current_line_idx: int = -1
var full_text: String = ""
var displayed_chars: int = 0
var char_timer: float = 0.0
var char_delay: float = 0.035
var is_typing: bool = false
var is_active: bool = false
var sound_tick: int = 0
var portrait_bob_timer: float = 0.0
var arrow_blink_timer: float = 0.0

func _ready() -> void:
	root_control.visible = false
	arrow_indicator.visible = false
	if stat_box:
		stat_box.visible = false

func start_dialogue(custom_script: Array = []) -> void:
	if custom_script.is_empty():
		dialogue_script = DEFAULT_SCRIPT.duplicate(true)
	else:
		dialogue_script = custom_script.duplicate(true)
		
	is_active = true
	root_control.visible = true
	root_control.modulate.a = 0.0
	if stat_box:
		stat_box.visible = true
		
	var tw = create_tween()
	tw.tween_property(root_control, "modulate:a", 1.0, 0.2)
	
	dialogue_started.emit()
	current_line_idx = 0
	_display_line(current_line_idx)

func _display_line(idx: int) -> void:
	if idx >= dialogue_script.size():
		close_dialogue()
		return
		
	current_line_idx = idx
	var page = dialogue_script[idx]
	
	# Set portrait
	var p_key = page.get("portrait", "dazed")
	if PORTRAITS.has(p_key):
		portrait_rect.texture = PORTRAITS[p_key]
		
	# Play optional ambient sound cue
	var sfx_cue = page.get("sfx_cue", "")
	var sm = get_node_or_null("/root/SoundManager")
	if not sfx_cue.is_empty() and sm:
		sm.play_sfx(sfx_cue)
		
	full_text = page.get("text", "")
	displayed_chars = 0
	text_label.text = ""
	is_typing = true
	char_timer = 0.0
	char_delay = 0.035
	arrow_indicator.visible = false
	
	line_started.emit(idx)

func _process(delta: float) -> void:
	if not is_active:
		return
		
	if is_typing:
		portrait_bob_timer += delta * 14.0
		portrait_rect.position.y = int(sin(portrait_bob_timer)) * 1
		
		char_timer += delta
		if char_timer >= char_delay:
			char_timer = 0.0
			if displayed_chars < full_text.length():
				displayed_chars += 1
				var c = full_text[displayed_chars - 1]
				text_label.text = full_text.substr(0, displayed_chars)
				
				# Audio blip on alphanumeric characters
				if c != " " and c != "\n" and c != "*" and c != "(" and c != ")":
					sound_tick += 1
					if sound_tick % 2 == 0:
						_play_voice_blip()
						
				# Punctuation pauses for natural Undertale cadence
				if c == ",":
					char_delay = 0.16
				elif c == "." or c == "!" or c == "?":
					char_delay = 0.30
				elif c == "\n":
					char_delay = 0.12
				else:
					char_delay = 0.032
			else:
				_finish_typing()
	else:
		portrait_rect.position.y = 0
		# Blink arrow prompt
		arrow_blink_timer += delta * 4.0
		arrow_indicator.visible = int(arrow_blink_timer) % 2 == 0

func _play_voice_blip() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("typewriter")
	else:
		# Fallback synthesized tone
		var p = AudioStreamPlayer.new()
		var s = AudioStreamWAV.new()
		s.format = AudioStreamWAV.FORMAT_16_BITS
		s.mix_rate = 22050
		var n = int(22050 * 0.03)
		var b = PackedByteArray()
		b.resize(n * 2)
		for i in n:
			var env = 1.0 - float(i)/n
			b.encode_s16(i*2, int(sin(TAU * 380.0 * i / 22050.0) * env * 3500))
		s.data = b
		p.stream = s
		add_child(p)
		p.finished.connect(p.queue_free)
		p.play()

func fast_forward() -> void:
	_finish_typing()

func _finish_typing() -> void:
	is_typing = false
	displayed_chars = full_text.length()
	text_label.text = full_text
	arrow_indicator.visible = true
	line_completed.emit(current_line_idx)

func _advance() -> void:
	if is_typing:
		# Fast forward current line
		_finish_typing()
	else:
		# Go to next line
		_display_line(current_line_idx + 1)

func close_dialogue() -> void:
	is_active = false
	var tw = create_tween()
	tw.tween_property(root_control, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func():
		root_control.visible = false
		dialogue_finished.emit()
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
		
	# Skip/cancel key
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE):
		close_dialogue()
		get_viewport().set_input_as_handled()
		return
		
	# Advance keys: Z, Space, Enter, or left mouse click
	var is_advance_key: bool = false
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("interact_strike"):
		is_advance_key = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_Z, KEY_SPACE, KEY_ENTER, KEY_C]:
			is_advance_key = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_advance_key = true
		
	if is_advance_key:
		_advance()
		get_viewport().set_input_as_handled()
