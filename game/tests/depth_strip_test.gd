extends SceneTree
# Beat-'em-up floor strip: Rend walks into the depth within its limits, robots line up
# with his depth before striking, and interactions ignore depth.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("DEPTH %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func hold(action: String, seconds: float) -> void:
	Input.action_press(action);await create_timer(seconds).timeout;Input.action_release(action)
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player
	for e in main.route.enemies:e.set_physics_process(false)
	p.global_position=Vector3(6,.05,0);await create_timer(.3).timeout  # free floor (a case stands at x 3)
	await hold("move_up",0.5)
	check("move_up walks away from camera",p.global_position.z<-0.6,"z=%.2f"%p.global_position.z)
	await hold("move_up",1.5)
	check("back edge holds",is_equal_approx(p.global_position.z,p.depth_min),"z=%.2f"%p.global_position.z)
	await hold("move_down",2.5)
	check("front edge holds",is_equal_approx(p.global_position.z,p.depth_max),"z=%.2f"%p.global_position.z)
	check("walking into depth animates",p._anim_state in ["walk","run","idle"],p._anim_state)
	# A robot two metres away closes in on Rend's depth before it may strike.
	var foe=main.route.enemies[0]
	p.global_position=Vector3(foe.global_position.x-2.2,.05,1.0);foe.global_position.z=-0.6
	foe.set_physics_process(true);foe._enter(foe.CHASE)
	var struck_off_lane:=false
	for i in 90:
		await physics_frame
		if foe._state==foe.WINDUP and absf(p.global_position.z-foe.global_position.z)>foe.STRIKE_DEPTH:struck_off_lane=true
	check("robot follows into depth",absf(p.global_position.z-foe.global_position.z)<0.5,"dz=%.2f"%(p.global_position.z-foe.global_position.z))
	check("robot only strikes on Rend's depth",not struck_off_lane)
	foe.set_physics_process(false)
	# Interactions use side and height only.
	p.global_position=Vector3(main.route.shield_pos.x,.05,1.1)
	check("interaction reach ignores depth",main.route.reach_distance(main.route.shield_pos)<0.2)
	print("DEPTH SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
