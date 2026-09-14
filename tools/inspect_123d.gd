extends SceneTree

func _initialize():
	var scn = ResourceLoader.load("c:/Users/USER/Desktop/game making/temp_123d_extracted/.godot/exported/133200997/export-a0e3b9705693730b5d95ac4e5fa5ae36-cam_root_1.scn")
	var inst = scn.instantiate()
	print_node(inst, "")
	
	print("\n--- Inspecting block.scn ---")
	var block_scn = ResourceLoader.load("c:/Users/USER/Desktop/game making/temp_123d_extracted/.godot/exported/133200997/export-ef63a898266488b4a55e5e40097e3f39-block.scn")
	var block_inst = block_scn.instantiate()
	print_node(block_inst, "")
	
	print("\n--- Inspecting stair_block.scn ---")
	var stair_scn = ResourceLoader.load("c:/Users/USER/Desktop/game making/temp_123d_extracted/.godot/exported/133200997/export-53ea373a4d009928444b4c1276222143-stair_block.scn")
	var stair_inst = stair_scn.instantiate()
	print_node(stair_inst, "")
	quit(0)

func print_node(n, indent):
	var extra = ""
	if n is Node3D:
		extra += " pos=" + str(n.position) + " rot=" + str(n.rotation_degrees)
	if n is Camera3D:
		extra += " proj=" + str(n.projection) + " size=" + str(n.size) + " fov=" + str(n.fov)
	if n is CollisionShape3D and n.shape:
		extra += " shape=" + str(n.shape.get_class())
		if n.shape is BoxShape3D:
			extra += " size=" + str(n.shape.size)
	print(indent + n.name + " (" + n.get_class() + ")" + extra)
	for c in n.get_children():
		print_node(c, indent + "  ")
