extends Control
class_name IntroCutscene

# Undertale-style nostalgic story intro for Degrees of Escape

@onready var panel_rect: TextureRect = $PanelContainer/CenterPanel/PanelTexture
@onready var frame_container: PanelContainer = $PanelContainer/CenterPanel
@onready var text_label: Label = $StoryTextContainer/TextLabel
@onready var prompt_label: Label = $PromptLabel
@onready var title_container: VBoxContainer = $TitleContainer
@onready var title_label: Label = $TitleContainer/TitleLabel
@onready var start_prompt: Label = $TitleContainer/StartPrompt
@onready var fade_rect: ColorRect = $FadeRect

const PANELS = [
	preload("res://assets/intro/intro_panel_1.png"),
	preload("res://assets/intro/intro_panel_2.png"),
	preload("res://assets/intro/intro_panel_3.png"),
	preload("res://assets/intro/intro_panel_4.png"),
	preload("res://assets/intro/intro_panel_5.png"),
	preload("res://assets/intro/intro_panel_6.png"),
]

const STORY_PAGES = [
	{
		"panel": 0,
		"text": "Long ago, the fabric of reality was anchored by an ancient relic..."
	},
	{
		"panel": 0,
		"text": "The Chrono-Lens, forged beyond the boundaries of known dimensions."
	},
	{
		"panel": 1,
		"text": "Drawn by whispers of lost dimensions, John Rod sought the forgotten vault."
	},
	{
		"panel": 1,
		"text": "Armed with only a lantern, he ventured deep into the silent chasm."
	},
	{
		"panel": 2,
		"text": "At the heart of the inner sanctum, he discovered the Dais."
	},
	{
		"panel": 2,
		"text": "Upon the pedestal rested the Ancient Watch, humming with mysterious power."
	},
	{
		"panel": 3,
		"text": "Unable to resist the cosmic calling, John Rod reached out to touch the crown."
	},
	{
		"panel": 3,
		"text": "In an instant... reality began to fracture!"
	},
	{
		"panel": 4,
		"text": "The sanctuary groaned! The floor gave way beneath his sliding feet!"
	},
	{
		"panel": 4,
		"text": "Plunging down the bottomless chasm, his dimensions unraveled one by one..."
	},
	{
		"panel": 5,
		"text": "Depth vanished... height dissolved..."
	},
	{
		"panel": 5,
		"text": "Until upon the cold cavern floor, only a 0-dimensional point remained."
	},
	{
		"panel": 5,
		"text": "Suddenly... the Chrono-Lens flickers back to life!"
	},
	{
		"panel": 5,
		"text": "Line, Plane, and Volume unite! John Rod awakens to escape the broken chasm..."
	}
]

var current_page_idx: int = 0
var current_panel_idx: int = -1
var full_text: String = ""
var displayed_chars: int = 0
var char_timer: float = 0.0
var char_delay: float = 0.038
var is_typing: bool = false
var is_title_screen: bool = false
var sound_tick_counter: int = 0

func _ready() -> void:
	title_container.visible = false
	prompt_label.modulate.a = 0.7
	fade_rect.modulate.a = 1.0
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_bgm"):
		sm.play_bgm("intro_outro", -8.0, true, 0.0, 1.0)
	
	# Initial fade in from black
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	t.tween_callback(start_page.bind(0))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		skip_to_game()
		return
		
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if is_title_screen:
			start_game()
		elif is_typing:
			# Fast-forward typing
			displayed_chars = full_text.length()
			text_label.text = full_text
			is_typing = false
		else:
			# Advance to next sentence
			advance_story()

func _process(delta: float) -> void:
	if not is_typing:
		return
		
	char_timer += delta
	if char_timer >= char_delay:
		char_timer = 0.0
		if displayed_chars < full_text.length():
			displayed_chars += 1
			var next_char = full_text[displayed_chars - 1]
			text_label.text = full_text.substr(0, displayed_chars)
			
			# Typewriter audio blip (skip spaces and punctuation)
			if next_char != " " and next_char != "." and next_char != ",":
				sound_tick_counter += 1
				if sound_tick_counter % 2 == 0:
					var sm = get_node_or_null("/root/SoundManager")
					if sm: sm.play_sfx("typewriter")
					
			# Natural pauses on commas and periods like Undertale
			if next_char == ",":
				char_delay = 0.18
			elif next_char == "." or next_char == "!":
				char_delay = 0.32
			else:
				char_delay = 0.035
		else:
			is_typing = false

func start_page(idx: int) -> void:
	if idx >= STORY_PAGES.size():
		show_title_screen()
		return
		
	current_page_idx = idx
	var page_data = STORY_PAGES[idx]
	var target_panel = page_data["panel"]
	
	# Transition panel if changed
	if target_panel != current_panel_idx:
		current_panel_idx = target_panel
		panel_rect.modulate.a = 0.0
		panel_rect.texture = PANELS[target_panel]
		var pt = create_tween()
		pt.tween_property(panel_rect, "modulate:a", 1.0, 0.4)
		
	full_text = page_data["text"]
	displayed_chars = 0
	text_label.text = ""
	is_typing = true
	char_timer = 0.0
	char_delay = 0.035

func advance_story() -> void:
	current_page_idx += 1
	start_page(current_page_idx)

func show_title_screen() -> void:
	is_title_screen = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm: sm.play_sfx("story_chord")
	
	# Fade out illustration and text
	var t = create_tween()
	t.tween_property(frame_container, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(text_label, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(prompt_label, "modulate:a", 0.0, 0.6)
	
	# Fade in Title Screen
	t.tween_callback(func():
		title_container.visible = true
		title_container.modulate.a = 0.0
		var tt = create_tween()
		tt.tween_property(title_container, "modulate:a", 1.0, 0.8)
		
		# Start breathing pulse on start prompt
		var pt = create_tween().set_loops()
		pt.tween_property(start_prompt, "modulate:a", 0.3, 0.7)
		pt.tween_property(start_prompt, "modulate:a", 1.0, 0.7)
	)

func start_game() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("unlock")
		if sm.has_method("stop_bgm"): sm.stop_bgm(0.7)
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.7)
	t.tween_callback(func():
		get_tree().change_scene_to_file("res://chambers/broken_circuit/Demo.tscn")
	)

func skip_to_game() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("stop_bgm"): sm.stop_bgm(0.3)
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.3)
	t.tween_callback(func():
		get_tree().change_scene_to_file("res://chambers/broken_circuit/Demo.tscn")
	)
