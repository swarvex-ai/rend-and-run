extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(label: String, ok: bool) -> void:
	print("DEATH_GROUNDING ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func run():
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene);current_scene=scene
	await create_timer(.3).timeout
	scene.pause_controller.resume()
	for other in scene.route.enemies: other.set_physics_process(false)
	scene.player.set_physics_process(false)
	scene.player.global_position=Vector3(4,.01,0)
	await create_timer(1.5).timeout
	var enemy=scene.route.enemies[0]
	enemy.global_position=Vector3(5,1.2,0)
	enemy.set_physics_process(true)
	var direction=-1.0 if OS.get_environment("DEATH_DIRECTION")=="left" else 1.0
	if OS.get_environment("DEATH_SEVERED")=="1":enemy._sever_arm()
	var original_bones=enemy._skeleton.get_bone_count()
	var blood_before=root.get_node("FX").fx_stats.blood
	enemy.take_melee_hit(99,Vector3(3*direction,1,0))
	var start=enemy.global_position
	for i in 120:await physics_frame
	var physics=enemy._death_physics
	var ok=is_instance_valid(physics)
	if ok:
		var pelvis:RigidBody3D=physics.bindings[0][1]
		var landed=pelvis.global_position
		ok=landed.y<.4 and landed.y>.05 and (landed.x-start.x)*direction>0.0
		for binding in physics.bindings:
			var body:RigidBody3D=binding[1]
			print("BODY ",body.name," position=",body.global_position," speed=",body.linear_velocity.length())
			ok=ok and body.global_position.is_finite() and body.linear_velocity.length()<8.0
		ok=ok and physics.bindings.size()==(9 if enemy._severed else 11)
		print("DEATH_GROUNDING start=",start," pelvis=",landed," bodies=",physics.bindings.size())
	ok=ok and enemy.collision_layer==0 and not enemy.is_in_group("enemies")
	ok=ok and enemy._skeleton.get_bone_count()==original_bones and root.get_node("FX").fx_stats.blood==blood_before
	if enemy._severed:
		print("SEVER visible arm=",enemy._arm_mesh.visible," cap=",enemy._cap_mesh.visible)
		ok=ok and not enemy._arm_mesh.visible and enemy._cap_mesh.visible
	print("DEATH_GROUNDING ","PASS" if ok else "FAIL")
	if not OS.get_environment("DEATH_CAPTURE").is_empty():
		enemy.set_physics_process(false)
		for i in 48:
			RenderingServer.force_draw(false,1.0/60.0)
			await process_frame
		root.get_texture().get_image().save_png(OS.get_environment("DEATH_CAPTURE"))
	if OS.get_environment("DEATH_CLEANUP")=="1":
		var corpses=physics.bindings.map(func(binding):return binding[1])
		await create_timer(4.3).timeout
		var cleaned=not is_instance_valid(enemy)
		for body in corpses:cleaned=cleaned and not is_instance_valid(body)
		ok=ok and cleaned
		print("DEATH_CLEANUP ","PASS" if cleaned else "FAIL")
	scene.queue_free()
	for i in 6:await process_frame
	failures += 0 if ok else 1
	print("DEATH_GROUNDING SUMMARY failures=", failures)
	quit(1 if failures else 0)
