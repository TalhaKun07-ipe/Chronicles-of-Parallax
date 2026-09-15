extends SceneTree
var demo: Node3D
func _initialize() -> void: call_deferred("run")
func settle() -> void:
	for i in 90: await process_frame
	await RenderingServer.frame_post_draw
func shot(name: String, at: Vector3, mode: int) -> void:
	demo.player.mode=mode
	demo.player.position=at
	demo.player.plane_z=at.z
	demo.chamber.set_spatial_mode(mode)
	demo.player.velocity=Vector3.ZERO
	await settle()
	demo.message_time=0
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/home/user/"+name+".png")
func run() -> void:
	demo=load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	demo.player.input_override=true
	await settle()
	await shot("course_arrival",Vector3(-9.5,.08,0),3)
	demo.chamber.first_rail_live=true
	demo.chamber.get_node("Mechanisms/FirstConduit").show()
	await shot("course_court",Vector3(5,.08,-2.8),3)
	demo.chamber.powered=true
	await shot("course_platforming",Vector3(19.0,.90,-4),2)
	await shot("course_gallery",Vector3(36.5,2.63,2),3)
	quit(0)
