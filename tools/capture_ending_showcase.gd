extends SceneTree

# Tool to capture screenshots of EndingCutscene in Godot for the user walkthrough

const ARTIFACT_DIR = "C:/Users/USER/.gemini/antigravity-ide/brain/6b82e086-38f1-481a-abb8-cd64ea27d565"

func _init() -> void:
	call_deferred("run_capture")

func frames(n: int) -> void:
	for i in n:
		await process_frame

func capture(filename: String) -> void:
	await frames(4)
	var image = root.get_viewport().get_texture().get_image()
	var path = ARTIFACT_DIR + "/" + filename
	image.save_png(path)
	print("Saved showcase image: ", path)

func run_capture() -> void:
	var scene_res = load("res://scenes/ui/EndingCutscene.tscn")
	var scene = scene_res.instantiate()
	root.add_child(scene)
	
	# 1. Capture Panel 1 with typewriter text
	scene.fade_rect.modulate.a = 0.0
	scene.start_page(0)
	scene.text_label.text = scene.full_text
	scene.is_typing = false
	await capture("outro_panel_1_showcase.png")
	
	# 2. Capture Panel 2 (Reclaiming the Chrono-Lens)
	scene.start_page(2) # Panel 2 starts at page 2
	scene.text_label.text = scene.full_text
	scene.is_typing = false
	await capture("outro_panel_2_showcase.png")

	# 3. Capture Panel 3 (The 4th Dimension Revelation)
	scene.start_page(5) # Panel 3 starts at page 5
	scene.text_label.text = scene.full_text
	scene.is_typing = false
	await capture("outro_panel_3_showcase.png")
	
	# 4. Capture Panel 4 (Escape Through Time Rift)
	scene.start_page(8) # Panel 4 starts at page 8
	scene.text_label.text = scene.full_text
	scene.is_typing = false
	await capture("outro_panel_4_showcase.png")
	
	# 5. Capture Panel 5 (The Surface at Dawn)
	scene.start_page(11) # Panel 5 starts at page 11
	scene.text_label.text = scene.full_text
	scene.is_typing = false
	await capture("outro_panel_5_showcase.png")
	
	# 4. Capture Victory Screen
	scene.show_victory_screen()
	scene.victory_container.visible = true
	scene.victory_container.modulate.a = 1.0
	scene.frame_container.modulate.a = 0.0
	scene.text_label.modulate.a = 0.0
	scene.prompt_label.modulate.a = 0.0
	await capture("outro_victory_screen_showcase.png")
	
	print("ALL OUTRO SCREENSHOTS CAPTURED!")
	quit(0)
