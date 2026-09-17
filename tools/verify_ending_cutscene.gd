extends SceneTree

# Automated verification test for EndingCutscene.tscn

func _init() -> void:
	print("--- Starting Ending Cutscene Verification ---")
	call_deferred("run_test")

func run_test() -> void:
	var scene_res = load("res://scenes/ui/EndingCutscene.tscn")
	assert(scene_res != null, "EndingCutscene.tscn must exist and load")
	
	var scene = scene_res.instantiate()
	assert(scene != null, "EndingCutscene must instantiate")
	root.add_child(scene)
	
	# Wait for ready and tween setup
	for i in 5:
		await process_frame
		
	var panel_rect = scene.get_node_or_null("PanelContainer/CenterPanel/PanelTexture")
	var text_label = scene.get_node_or_null("StoryTextContainer/TextLabel")
	var victory_container = scene.get_node_or_null("VictoryContainer")
	var fade_rect = scene.get_node_or_null("FadeRect")
	
	assert(panel_rect != null, "PanelTexture must exist")
	assert(text_label != null, "TextLabel must exist")
	assert(victory_container != null, "VictoryContainer must exist")
	assert(fade_rect != null, "FadeRect must exist")
	print("PASS: All essential cutscene UI nodes exist")
	
	# Check initial story page
	assert(scene.current_page_idx == 0, "Starts at story page 0")
	assert(scene.STORY_PAGES.size() == 14, "Contains all 14 story beats across 5 panels")
	print("PASS: Story pages and beats initialized properly (14 pages)")
	
	# Test skip to victory screen
	scene.show_victory_screen()
	assert(scene.is_victory_screen, "is_victory_screen must be true after show_victory_screen")
	print("PASS: Victory screen displays successfully on skip or story completion")
	
	print("--- Ending Cutscene Verification PASSED ---")
	quit(0)
