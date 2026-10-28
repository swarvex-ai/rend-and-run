extends SceneTree
# Close-up review of Rend's hit reaction: fixed side camera, attacker on the right,
# one blow per strike type. HITPOSE_OUTPUT=<dir>, windowed.
const TIMES := [0.0, 0.06, 0.12, 0.2, 0.3, 0.45, 0.65, 0.9]
func _initialize():call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var out:=OS.get_environment("HITPOSE_OUTPUT")
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player
	for e in main.route.enemies:e.set_physics_process(false)
	var foe=main.route.enemies[0]
	main.set_process(false)  # the camera stays where we put it
	var cam:Camera3D=main.get_node("Camera3D")
	for spec in [["side","side",1],["overhead","overhead",1],["uppercut","uppercut",1],["thrust","thrust",1]]:
		p.global_position=Vector3(5.0,.05,0.6);p.velocity=Vector3.ZERO;p.facing=1.0;p.hp=p.max_hp;p.reset_state();p._iframes=0
		foe.global_position=Vector3(6.4,.05,0.6)
		cam.global_position=Vector3(5.5,1.05,3.6);cam.rotation=Vector3.ZERO;cam.fov=40
		await create_timer(1.0).timeout
		foe.role=1;foe.forced_strike=spec[1];foe._strike=spec[1]
		p.take_damage(spec[2],foe.global_position,foe)
		var last:=0.0
		for t in TIMES:
			await create_timer(maxf(t-last,0.001),true,false,true).timeout;last=t
			await RenderingServer.frame_post_draw
			if not out.is_empty():root.get_texture().get_image().save_png("%s/%s_%03d.png"%[out,spec[0],int(t*100)])
	main.queue_free();for i in 4:await process_frame
	quit()
