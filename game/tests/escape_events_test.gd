extends SceneTree
# Escape set pieces: a security camera that sees Rend running calls the robots nearby, but
# not a crouching Rend; the hanging blank drops and attacks as he passes beneath; welding
# robots work in the assembly bays; the last robot of a fight falls in slow motion.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("EVENTS %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player;var fx=root.get_node("FX")
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var arms:Array=r.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()==load("res://modules/world/welding_arm.gd"))
	var welded:=false
	for i in 40:
		await create_timer(.2).timeout
		if arms.any(func(a):return a.welding):welded=true;break
	check("welding robots work in the assembly bays",arms.size()==4 and welded,"arms=%d"%arms.size())
	var cams:Array=r.find_children("*","Node3D",true,false).filter(func(n):return n.get_script()==load("res://modules/world/security_camera.gd"))
	var cam=cams[2]  # x ~42.9
	p.global_position=Vector3(cam.global_position.x-3.0,.05,1.15)  # front lane, clear of the SMG guard;p.velocity=Vector3.ZERO
	Input.action_press("crouch");Input.action_press("move_right");await create_timer(1.5).timeout
	Input.action_release("move_right");Input.action_release("crouch")
	check("a camera does not see him sneaking",cam.spotted==0)
	p.global_position=Vector3(cam.global_position.x-4.0,.05,1.15);p.velocity=Vector3.ZERO
	await create_timer(.2).timeout
	Input.action_press("move_right");await create_timer(1.0).timeout;Input.action_release("move_right")
	check("a camera that sees him running raises the alarm",cam.spotted==1)
	# The blank over the corridor.
	p.global_position=Vector3(r.AWAKENING_X-3.0,.05,0);p.velocity=Vector3.ZERO;p.max_hp=99;p.hp=99
	Input.action_press("move_right");await create_timer(.6).timeout;Input.action_release("move_right")
	await create_timer(.8).timeout
	check("the hanging blank drops and attacks",is_instance_valid(r.awakened) and r.awakened._state!=r.awakened.IDLE)
	# Last of the fight.
	var slow0:int=fx.slowmos
	if is_instance_valid(r.awakened):
		for m in r.reinforcements:if is_instance_valid(m):m.set_physics_process(false)
		r.awakened.take_melee_hit(99,Vector3(5,1,0))
	await create_timer(1.0,true,false,true).timeout
	check("the last robot of a fight falls in slow motion",fx.slowmos>slow0)
	print("EVENTS SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
