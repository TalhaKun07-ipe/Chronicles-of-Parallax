extends SceneTree
var demo: Node3D
func _initialize() -> void:
	call_deferred("run")
func settle() -> void:
	for i in 80:
		await process_frame
	await RenderingServer.frame_post_draw
func run() -> void:
	demo = load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	demo.establishing_time = 0
	demo.player.input_override = true
	demo.overview = true
	demo.get_node("HUD").hide()
	await settle()
	root.get_texture().get_image().save_png("/home/user/chamber_overview.png")
	demo.overview = false
	demo.player.position = Vector3(-9.5,0.04,0)
	await settle()
	root.get_texture().get_image().save_png("/home/user/chamber_arrival.png")
	demo.chamber.powered = true
	demo.player.position = Vector3(2.4,0.04,-2.5)
	demo.player.request_mode(2)
	await settle()
	root.get_texture().get_image().save_png("/home/user/chamber_plane.png")
	quit(0)
