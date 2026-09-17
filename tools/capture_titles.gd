extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# 1. Capture Intro Title Screen
	var intro_scene = load("res://scenes/ui/IntroCutscene.tscn").instantiate()
	root.add_child(intro_scene)
	intro_scene.show_title_screen()
	intro_scene.title_container.visible = true
	intro_scene.title_container.modulate.a = 1.0
	intro_scene.frame_container.modulate.a = 0.0
	intro_scene.text_label.modulate.a = 0.0
	intro_scene.prompt_label.modulate.a = 0.0
	intro_scene.fade_rect.modulate.a = 0.0
	for i in 10: await process_frame
	
	var img = root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/6b82e086-38f1-481a-abb8-cd64ea27d565/intro_title_chronicles.png")
	print("Captured intro_title_chronicles.png")
	intro_scene.queue_free()
	for i in 5: await process_frame
	
	# 2. Capture Ending Victory Screen
	var ending_scene = load("res://scenes/ui/EndingCutscene.tscn").instantiate()
	root.add_child(ending_scene)
	ending_scene.show_victory_screen()
	ending_scene.victory_container.visible = true
	ending_scene.victory_container.modulate.a = 1.0
	ending_scene.frame_container.modulate.a = 0.0
	ending_scene.text_label.modulate.a = 0.0
	ending_scene.prompt_label.modulate.a = 0.0
	ending_scene.fade_rect.modulate.a = 0.0
	for i in 10: await process_frame
	
	img = root.get_viewport().get_texture().get_image()
	img.save_png("C:/Users/USER/.gemini/antigravity-ide/brain/6b82e086-38f1-481a-abb8-cd64ea27d565/outro_victory_chronicles.png")
	print("Captured outro_victory_chronicles.png")
	ending_scene.queue_free()
	
	quit(0)
