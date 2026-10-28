extends SceneTree
# Light humanoid strikes: each lands with its own counterplay, and Rend's reaction follows
# the blow. STRIKE_OUTPUT=<dir> stores attacker and reaction frames per strike (windowed).
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("STRIKE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
# Lets the robot attack once with the given strike; returns true if Rend lost health.
func attack(main, foe, p, strike: String, rend_z := 0.6, crouch := false, shots := "") -> bool:
	p.global_position=Vector3(5.0,.05,rend_z);p.velocity=Vector3.ZERO;p.facing=1.0;p.hp=p.max_hp;p.reset_state();p._iframes=0
	foe.global_position=Vector3(6.6,.05,0.6);foe.velocity=Vector3.ZERO;foe._stun=0;foe._kb_timer=0
	foe.forced_strike=strike;foe.territory_min_x=-10.0
	if crouch:Input.action_press("crouch")
	await create_timer(.4).timeout
	foe.set_physics_process(true);foe._enter(foe.WINDUP)
	var cam:Camera3D=main.get_node("Camera3D");var hp0:int=p.hp;var frame:=0
	var out:=OS.get_environment("STRIKE_OUTPUT")
	for i in 75:
		await physics_frame
		foe.global_position.z=0.6  # keep the robot on its line; Rend's depth decides
		if foe._state==foe.CHASE:foe.set_physics_process(false)
		if not shots.is_empty() and not out.is_empty() and i%6==0 and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("%s/%s_%02d.png"%[out,shots,frame]);frame+=1
	foe.set_physics_process(false)
	Input.action_release("crouch")
	return p.hp<hp0
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player
	for e in main.route.enemies:e.set_physics_process(false)
	var foe=main.route.enemies[0]
	main.set_process(false)
	var cam:Camera3D=main.get_node("Camera3D");cam.global_position=Vector3(5.8,1.1,4.4);cam.rotation=Vector3.ZERO;cam.fov=40
	for strike in ["side","overhead","uppercut","thrust"]:
		check(strike+" lands on a standing Rend",await attack(main,foe,p,strike,0.6,false,strike))
	check("side swing is ducked",not await attack(main,foe,p,"side",0.6,true))
	check("overhead cannot be ducked",await attack(main,foe,p,"overhead",0.6,true))
	check("thrust misses one step aside in depth",not await attack(main,foe,p,"thrust",0.95))
	check("side swing still reaches that step",await attack(main,foe,p,"side",0.95))
	print("STRIKE SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
