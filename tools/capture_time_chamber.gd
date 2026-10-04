extends SceneTree

const OUT = "res://docs/screenshots/time_chamber/"

func _initialize() -> void:
	call_deferred("run")

func frames(n: int) -> void:
	for i in n: await physics_frame

func save(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUT + filename)
	print("CAPTURE ", filename, " = ", result)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	change_scene_to_file("res://scenes/levels/DaylightEscape.tscn")
	await frames(90)
	var room = current_scene
	room.transition_on_win = false
	room.player.input_override = true
	room.player.rewind_controller.input_override = true
	print("HUD ICON SIZE ", room.hud.get_child(0).get_node("ChronoLensIcon").size)
	await save("01_arrival.png")
	room.toggle_pause()
	await frames(2)
	await save("09_pause.png")
	room.toggle_pause()
	room.player.reset_at(Vector3(11.3, 1.25, 0))
	room.hud.show_hint("Hold R to restore crumbling floors. Release to leave a replaying echo.", 20)
	await frames(55)
	await save("02_fractured_stair.png")
	room.player.reset_at(Vector3(31, 2.45, 0))
	room.player.request_mode(3)
	room.hud.show_hint("Two seals. Two versions of John. Rewind a moment, then share the present.", 20)
	await frames(65)
	await save("03_echo_court.png")
	room.monolith.trigger_topple()
	await frames(95)
	room.player.reset_at(Vector3(49.5, 3.05, 0))
	room.hud.show_hint("A fallen monolith becomes a bridge. Hold R and watch it return to its earlier shape.", 20)
	await frames(65)
	await save("04_clockwork_span.png")
	room.player.reset_at(Vector3(62.5, 3.65, -2))
	room.player.request_mode(3)
	room.hud.show_hint("Ride the reversible lift to the high landing, then jump in 2D.", 20)
	await frames(65)
	await save("05_clockwork_lift.png")
	room.player.reset_at(Vector3(96.5, 8.45, 0))
	room.hud.show_hint("The daylight waits beyond the last seal. Become a line along the cyan rail.", 20)
	await frames(65)
	await save("06_daylight.png")
	room.player.rewind_controller.rewind_requested = true
	await frames(25)
	await save("07_rewind.png")
	room.player.rewind_controller.rewind_requested = false
	room.set_process(false)
	room.hud.visible = false
	room.get_node("ChronoPostProcess").visible = false
	room.camera.position = Vector3(53, 24, 85)
	room.camera.look_at(Vector3(53, 4, 0))
	room.camera.size = 67
	await frames(2)
	await save("08_overview.png")
	quit(0)
