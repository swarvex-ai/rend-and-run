extends Node
## H16 end-to-end actual door traversal, interaction and persistence.
var failures:=0
func check(label: String,ok: bool) -> void:
	if not ok:failures+=1
	print("H16-ROUTE %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
	var scene=get_tree().current_scene
	await wait(0.25)
	var p=scene.player
	for e in scene.route.enemies:e.set_physics_process(false)
	var door=scene.route.shortcut
	check("actual door loaded",door!=null)
	# Keep the route's proximity auto-open out of the locked-collision check so only
	# the closed door itself can stop Rend.
	scene.route.set_process(false)
	p.global_position=Vector3(15,0.03,0);p.velocity=Vector3.ZERO
	await wait(0.2);Input.action_press("move_right");await wait(0.5);Input.action_release("move_right")
	check("locked lower passage blocks actual movement",p.global_position.x<16.3)
	scene.route.set_process(true)
	Input.action_press("interact");await wait(0.08);Input.action_release("interact");await wait(0.08)
	check("west interaction opens main route without optional armor",door.is_open() and not scene.route.equipment.owns("lab_armor"))
	# Door's own visible open state: try_open clears the collision layer deferred
	# (shortcut_door.gd:136-138, _sync_collision at :184).
	check("door shows open state after west interaction",door.is_open() and door.get_body().collision_layer==0)
	Input.action_press("move_right");await wait(0.55);Input.action_release("move_right")
	check("main route traversable without upper armor detour",p.global_position.x>17.0 and p.global_position.y<0.15)
	# Reset fixture for the separate east-approach check.
	door.restore_open(false);scene.route.shortcut_open=false
	check("closed shortcut stays solid after reset",not door.is_open() and door.get_body().collision_layer==1 and door.panel_offset_y()<0.01)
	p.global_position=Vector3(8.5,0.03,0);p.velocity=Vector3.ZERO;await wait(0.5)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V16_OUTPUT")+"/shortcut_closed.png")
	# The upper maintenance route is gone (lab_route.gd builds no walkway), so the
	# east approach starts on the far side of the closed door as a fixture.
	p.global_position=Vector3(20.6,0.03,0);p.velocity=Vector3.ZERO;await wait(0.5)
	Input.action_press("move_left")
	for frame in 100:
		await get_tree().physics_frame
		if p.global_position.x<17.5:break
	Input.action_release("move_left");await wait(0.1)
	check("can reach east latch at floor height",p.global_position.x>16.8 and p.global_position.x<18 and p.global_position.y<0.15)
	Input.action_press("interact");await wait(0.08);Input.action_release("interact");await wait(0.75)
	check("east interaction opens and stores route state",door.is_open() and scene.route.shortcut_open)
	check("door shows open state after east interaction",door.is_open() and door.get_body().collision_layer==0)
	check("raised panel clears upper jumping route",door.panel_offset_y()>5.9)
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12.json"))
	var fresh=load("res://lab_route.gd").new();fresh._restore_progress(saved)
	check("fresh route restores permanent shortcut",fresh.shortcut_open)
	fresh.free()
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V16_OUTPUT")+"/shortcut.png")
	Input.action_press("move_left");await wait(0.6);Input.action_release("move_left")
	check("open shortcut permits ground return",p.global_position.x<15.8 and p.global_position.y<0.15)
	var extra=load("res://modules/world/shortcut_door.gd").new();scene.add_child(extra)
	extra.position=Vector3(100,0,0)
	extra.try_open(Vector3(100.5,0,0));extra.restore_open(false);await get_tree().process_frame
	check("same-frame restore defeats stale deferred open",not extra.is_open() and extra.get_body().collision_layer==1)
	print("H16-ROUTE SUMMARY failures=",failures)
	reparent(get_tree().root);scene.queue_free();scene=null;p=null;door=null;extra=null;fresh=null
	await wait(0.2);get_tree().quit(1 if failures else 0)
