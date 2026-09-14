extends SceneTree
## Automated verification for camera angles, screen-filling ortho scale, and Q/E dimensional cycling

func _initialize() -> void:
	call_deferred("run_test")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func run_test() -> void:
	print("--- Starting Mechanism & Camera Verification Test ---")
	
	var demo_scn = load("res://chambers/broken_circuit/Demo.tscn")
	assert(demo_scn != null, "Demo.tscn must exist")
	var demo = demo_scn.instantiate()
	root.add_child(demo)
	
	var player = demo.get_node("Player")
	var camera = demo.get_node("Camera3D")
	var chamber = demo.get_node("Chamber")
	
	player.input_override = true
	await frames(10)
	
	# 1. Verify Camera Setup (Size & Angles)
	print("Checking initial 3D camera state...")
	assert(player.mode == 3, "Player must start in 3D")
	assert(demo.yaw == -45.0, "Camera 3D yaw must be -45.0 degrees (got %f)" % demo.yaw)
	assert(demo.pitch == -30.0, "Camera 3D pitch must be -30.0 degrees (got %f)" % demo.pitch)
	assert(absf(camera.size - 5.2) < 0.5, "Camera size must be intimate ~5.2 for screen-filling platforming (got %f)" % camera.size)
	print("PASS: 3D Camera framing is isometric (-45°/-30°) and screen-filling (size ~5.2)")
	
	# 2. Test Q button: Count DOWN dimension (3D -> 2D)
	print("Testing Q button (Count DOWN 3D -> 2D)...")
	player.count_down_dimension()
	assert(player.mode == 2, "Q must switch 3D to 2D (got %d)" % player.mode)
	
	# Allow camera to blend
	for i in 30:
		await physics_frame
		
	assert(absf(demo.yaw) < 1.0, "Camera yaw in 2D must blend to 0.0 (got %f)" % demo.yaw)
	assert(absf(demo.pitch) < 1.0, "Camera pitch in 2D must blend to 0.0 (got %f)" % demo.pitch)
	print("PASS: Q button successfully flattens to 2D and camera rotates to 0°/0° flat plane")
	
	# 3. Test E button: Count UP dimension (2D -> 3D)
	print("Testing E button (Count UP 2D -> 3D)...")
	player.count_up_dimension()
	assert(player.mode == 3, "E must switch 2D to 3D (got %d)" % player.mode)
	
	for i in 30:
		await physics_frame
		
	assert(absf(demo.yaw - (-45.0)) < 1.0, "Camera yaw must return to -45.0 in 3D (got %f)" % demo.yaw)
	assert(absf(demo.pitch - (-30.0)) < 1.0, "Camera pitch must return to -30.0 in 3D (got %f)" % demo.pitch)
	print("PASS: E button successfully expands to 3D and camera smoothly returns to isometric")
	
	# 4. Verify 1D transition constraints
	print("Testing 1D constraint away from conduit...")
	assert(not player.request_mode(1), "1D must be rejected when not on conduit")
	print("PASS: 1D entry correctly guarded away from conduit")
	
	# 5. Verify camera tracking follows player
	var initial_cam_pos = camera.position
	player.position = Vector3(5.0, 1.5, -2.5)
	for i in 20:
		await physics_frame
	assert(camera.position != initial_cam_pos, "Camera must follow player position")
	print("PASS: Camera tracks player position smoothly across depth Z and height Y")
	
	print("--- All Mechanism & Camera Checks PASSED! ---")
	quit(0)
