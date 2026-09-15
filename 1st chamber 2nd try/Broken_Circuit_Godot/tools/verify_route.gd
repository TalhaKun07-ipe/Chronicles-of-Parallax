extends SceneTree
var demo: Node3D
var player: CharacterBody3D
var chamber: Node3D
var checks: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, description: String) -> void:
	if not ok:
		push_error("FAIL: "+description+" at "+str(player.position))
		quit(1)
		assert(ok,description)
	checks+=1
	print("PASS: "+description)
func frames(n: int) -> void:
	for i in n: await physics_frame
func walk(goal: Vector2, limit: int = 450) -> bool:
	for i in limit:
		var d := Vector3(goal.x-player.position.x,0,goal.y-player.position.z)
		if d.length()<.075:
			player.move_input=Vector2.ZERO
			await frames(3)
			return true
		d=d.normalized()
		if player.mode==3:d=d.rotated(Vector3.UP,deg_to_rad(45.0))
		player.move_input=Vector2(d.x,d.z)
		await physics_frame
	player.move_input=Vector2.ZERO
	return false
func jump_to(x: float, height: float) -> void:
	player.override_jump=true
	await frames(1)
	check(await walk(Vector2(x,-4),110),"Reaches landing X="+str(x))
	await frames(40)
	check(player.is_on_floor() and absf(player.position.y-height)<.09,"Lands at Y="+str(height))
func run() -> void:
	demo=load("res://chambers/broken_circuit/Demo.tscn").instantiate()
	root.add_child(demo)
	player=demo.get_node("Player")
	chamber=demo.get_node("Chamber")
	player.input_override=true
	await frames(8)
	check(not player.request_mode(1),"Rejects 1D away from a live rail")
	check(await walk(Vector2(-9,0)),"Reaches arrival pressure plate")
	check(chamber.first_rail_live,"Pressure plate wakes first rail")
	check(await walk(Vector2(-5.5,0)),"Walks across broad arrival court")
	check(player.request_mode(1),"Enters first rail")
	check(await walk(Vector2(-1.1,0)),"Passes below bulkhead across four-meter rift")
	check(not player.request_mode(3),"Rejects unsafe expansion over first rift")
	check(await walk(Vector2(3,0)),"Reaches far landing")
	check(chamber.carrying_charge,"Picks up spark")
	check(player.request_mode(2),"Expands at safe landing")
	player.move_input=Vector2.RIGHT
	await frames(85)
	player.move_input=Vector2.ZERO
	check(player.position.x<6,"Masonry stops the initial flat route")
	check(player.request_mode(3),"Restores depth movement")
	check(await walk(Vector2(5,-4)),"Follows rear aisle")
	check(await walk(Vector2(6.6,-4)),"Finds receiver")
	chamber.try_interact(player.position)
	await frames(2)
	check(chamber.powered and not chamber.carrying_charge,"Receiver latches circuit")
	check(chamber.get_node("Mechanisms/RunicTerrace1/Collision").disabled,"Terraces non-solid in 3D")
	check(await walk(Vector2(6.6,-5)),"Walks behind receiver")
	check(await walk(Vector2(13.6,-5)),"Crosses generous rear court")
	check(await walk(Vector2(14.3,-4)),"Aligns to climb plane")
	check(player.request_mode(2),"2D locks current depth")
	check(absf(player.plane_z+4)<.08,"No depth teleport")
	await frames(3)
	await jump_to(15.6,.85)
	check(await walk(Vector2(19.05,-4)),"Can walk across first 4.5m terrace")
	await jump_to(21.05,1.7)
	check(await walk(Vector2(25.05,-4)),"Can walk across second 5m terrace")
	await jump_to(27.05,2.55)
	check(await walk(Vector2(33.2,-4)),"Crosses third terrace onto permanent gallery")
	check(player.gallery_reached,"Gallery checkpoint stored")
	player.move_input=Vector2.RIGHT
	await frames(45)
	player.move_input=Vector2.ZERO
	check(player.position.x<34.7,"Upper divider blocks 2D")
	check(player.request_mode(3),"Expands on safe upper gallery")
	check(await walk(Vector2(34,2)),"Explores foreground aisle in 3D")
	check(await walk(Vector2(37,2)),"Reaches upper pressure plate")
	check(chamber.upper_rail_live,"Upper plate wakes second conduit")
	check(await walk(Vector2(38.5,2)),"Reaches upper rail dock")
	check(player.request_mode(1),"Rail entry supports elevated Y and nonzero Z")
	# Enter during a full opening; the timing window is intentionally generous.
	for i in 350:
		if fmod(chamber.shutter_clock,4.8)<.08:break
		await physics_frame
	check(await walk(Vector2(45.5,2),220),"Times the upper shutter and crosses rift")
	check(player.request_mode(3),"Expands onto exit terrace at correct height")
	check(await walk(Vector2(48,1)),"Walks into exit doorway")
	check(chamber.completed,"Completes the full obstacle course")
	player.respawn()
	await frames(5)
	check(chamber.powered and chamber.upper_rail_live,"Recovery preserves both puzzle states")
	check(player.position.y>2.4,"Recovers on upper gallery")
	check(absf(demo.camera.size-5.2)<.1,"Gameplay camera stays close")
	print("COURSE VALIDATED: %d checks" % checks)
	quit(0)
