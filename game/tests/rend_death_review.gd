extends SceneTree
# Rend's death: the jointed ragdoll (same as the robots') takes over from his pose and
# settles on the floor; respawn clears it. REND_DEATH_OUTPUT=<dir> stores frames (window).
const TIMES := [0.0, 0.15, 0.35, 0.6, 1.0, 1.6, 2.2]
func _initialize():call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var out:=OS.get_environment("REND_DEATH_OUTPUT")
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player;var foe=main.route.enemies[0]
	for e in main.route.enemies:e.set_physics_process(false)
	main.set_process(false)
	var cam:Camera3D=main.get_node("Camera3D")
	p.global_position=Vector3(5.0,.05,0.6);p.facing=1.0;foe.global_position=Vector3(6.6,.05,0.6)
	cam.global_position=Vector3(5.6,1.1,4.2);cam.rotation=Vector3.ZERO;cam.fov=40
	await create_timer(1.0).timeout
	p.hp=1;p._iframes=0;p.take_damage(1,foe.global_position,foe)
	var last:=0.0;var failures:=0
	for t in TIMES:
		await create_timer(maxf(t-last,0.001),true,false,true).timeout;last=t
		await RenderingServer.frame_post_draw
		if not out.is_empty():root.get_texture().get_image().save_png("%s/death_%03d.png"%[out,int(t*100)])
	var ragdoll=p._death_physics
	var ok:bool=is_instance_valid(ragdoll)
	print("DEATH %s ragdoll built"%["PASS" if ok else "FAIL"]);if not ok:failures+=1
	if ok:
		# Modifier poses are not readable afterwards; the head proxy body is where the head is.
		var head:Vector3=ragdoll.physics_root.get_node("mixamorig_Head").global_position
		var down:bool=head.y-p.global_position.y<0.6
		print("DEATH %s head on the floor y=%.2f"%["PASS" if down else "FAIL",head.y-p.global_position.y]);if not down:failures+=1
	await create_timer(1.0).timeout
	var cleared:bool=not is_instance_valid(p._death_physics) and p.hp==p.max_hp
	print("DEATH %s respawn clears the ragdoll"%["PASS" if cleared else "FAIL"]);if not cleared:failures+=1
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
