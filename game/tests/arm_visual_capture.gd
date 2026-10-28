extends SceneTree
func _initialize(): call_deferred("run")
func capture(name: String):
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("ARM_OUTPUT")+"/"+name+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout
	main.pause_controller.resume()
	var p=main.player; var r=main.route
	for enemy in r.enemies: enemy.set_physics_process(false)
	p.set_physics_process(false);p.global_position=Vector3(1.0,.05,0)
	await create_timer(.4).timeout
	await capture("01_arm_discovery")
	p.global_position=Vector3(1.8,.05,0);r.collect_start_arm()
	p._hero_anim.play("idle",0);p._hero_anim.advance(0.3);p._hero_anim.pause()
	await capture("02_arm_equipped")
	p._start_attack(1);p._hero_anim.play("slash_light",0);p._hero_anim.seek(.26,true);p._hero_anim.pause()
	await capture("03_arm_strike")
	p._cancel_attack();p.crouching=true;p._play("idle",1,true)
	await create_timer(.5).timeout
	await capture("04_arm_crouch")
	main.queue_free();await process_frame;await process_frame;quit()
