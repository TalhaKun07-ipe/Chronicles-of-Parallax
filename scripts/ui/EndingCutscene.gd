extends Control
class_name EndingCutscene

# Undertale-style nostalgic story outro for Degrees of Escape

@onready var panel_rect: TextureRect = $PanelContainer/CenterPanel/PanelTexture
@onready var frame_container: PanelContainer = $PanelContainer/CenterPanel
@onready var text_label: Label = $StoryTextContainer/TextLabel
@onready var prompt_label: Label = $PromptLabel
@onready var victory_container: VBoxContainer = $VictoryContainer
@onready var victory_title: Label = $VictoryContainer/TitleLabel
@onready var victory_subtitle: Label = $VictoryContainer/SubtitleLabel
@onready var victory_credits: Label = $VictoryContainer/CreditsLabel
@onready var restart_prompt: Label = $VictoryContainer/RestartPrompt
@onready var fade_rect: ColorRect = $FadeRect

const PANELS = [
	preload("res://assets/ending/ending_panel_1.png"),
	preload("res://assets/ending/ending_panel_2.png"),
	preload("res://assets/ending/ending_panel_3.png"),
	preload("res://assets/ending/ending_panel_4.png"),
	preload("res://assets/ending/ending_panel_5.png"),
]

const STORY_PAGES = [
	{
		"panel": 0,
		"text": "With a blinding flash, the colossal Axiom Warden shatters into fragments of light and ancient dust."
	},
	{
		"panel": 0,
		"text": "The oppressive hum of dimensional suppression fades. The iron crown clatters onto the silent flagstones."
	},
	{
		"panel": 1,
		"text": "John Rod steps forward through the drifting cinders toward the sacred central dais."
	},
	{
		"panel": 1,
		"text": "Upon the cracked pedestal rests the relic he sought: the ancient Chrono-Lens."
	},
	{
		"panel": 1,
		"text": "As his hand closes around the cool bronze casing, the fractured glass mends before his eyes."
	},
	{
		"panel": 2,
		"text": "Suddenly, the hands of the watch begin to move—spinning counter-clockwise in impossible trajectories!"
	},
	{
		"panel": 2,
		"text": "A profound truth resonates through his mind: Line, Plane, and Volume were only spatial boundaries..."
	},
	{
		"panel": 2,
		"text": "The fourth degree of freedom is not a direction in space... it is Time itself."
	},
	{
		"panel": 3,
		"text": "The subterranean sanctum begins to collapse inward, dissolving into ribbons of temporal distortion."
	},
	{
		"panel": 3,
		"text": "Holding the Chrono-Lens aloft, John channels the rewind flow, ascending across fractured echoes of reality."
	},
	{
		"panel": 3,
		"text": "With a leap of faith, he plunges upward through the rift toward the distant sky!"
	},
	{
		"panel": 4,
		"text": "Crisp morning wind sweeps across his face as the crushing darkness yields to golden sunlight."
	},
	{
		"panel": 4,
		"text": "High upon the emerald cliffs overlooking an endless horizon, John Rod stands victorious."
	},
	{
		"panel": 4,
		"text": "Length, Width, Height, and Time unite. All degrees of freedom restored. The escape is complete."
	}
]

var current_page_idx: int = 0
var current_panel_idx: int = -1
var full_text: String = ""
var displayed_chars: int = 0
var char_timer: float = 0.0
var char_delay: float = 0.035
var is_typing: bool = false
var is_victory_screen: bool = false
var sound_tick_counter: int = 0

func _ready() -> void:
	if victory_container:
		victory_container.visible = false
	if prompt_label:
		prompt_label.modulate.a = 0.7
	fade_rect.modulate.a = 1.0
	
	var sm = get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_bgm"):
		sm.play_bgm("intro_outro", -7.0, true, 0.0, 1.2)
	
	# Initial fade in from black
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	t.tween_callback(start_page.bind(0))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		show_victory_screen()
		return
		
	if event.is_action_pressed("jump") or event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed):
		if is_victory_screen:
			restart_game()
		elif is_typing:
			# Fast-forward typing
			displayed_chars = full_text.length()
			text_label.text = full_text
			is_typing = false
		else:
			# Advance to next page
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
		show_victory_screen()
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

func show_victory_screen() -> void:
	if is_victory_screen:
		return
	is_victory_screen = true
	var sm = get_node_or_null("/root/SoundManager")
	if sm: sm.play_sfx("story_chord")
	
	# Fade out illustration and text
	var t = create_tween()
	t.tween_property(frame_container, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(text_label, "modulate:a", 0.0, 0.6)
	t.parallel().tween_property(prompt_label, "modulate:a", 0.0, 0.6)
	
	# Fade in Victory Screen
	t.tween_callback(func():
		victory_container.visible = true
		victory_container.modulate.a = 0.0
		var tt = create_tween()
		tt.tween_property(victory_container, "modulate:a", 1.0, 0.8)
		
		# Start breathing pulse on restart prompt
		var pt = create_tween().set_loops()
		pt.tween_property(restart_prompt, "modulate:a", 0.3, 0.7)
		pt.tween_property(restart_prompt, "modulate:a", 1.0, 0.7)
	)

func restart_game() -> void:
	var sm = get_node_or_null("/root/SoundManager")
	if sm:
		sm.play_sfx("unlock")
		if sm.has_method("stop_bgm"):
			sm.stop_bgm(0.7)
	var t = create_tween()
	t.tween_property(fade_rect, "modulate:a", 1.0, 0.7)
	t.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/ui/IntroCutscene.tscn")
	)
