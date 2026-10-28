extends SceneTree
# Standing props block the floor strip: Rend cannot walk through benches, consoles or
# crates, and a chasing robot steps around a crate in depth instead of sticking to it.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("PROPS %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func walk_into(p, from: Vector3, seconds := 0.9) -> float:
	p.global_position = from;p.velocity = Vector3.ZERO
	await create_timer(.15).timeout
	Input.action_press("move_right");await create_timer(seconds).timeout;Input.action_release("move_right")
	return p.global_position.x
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for name in ["WorkbenchFootprint","EntryWorkbenchFootprint","CheckpointConsoleFootprint","RelayCheckpointFootprint"]:
		var body:StaticBody3D=r.get_node_or_null(name)
		if body==null:check(name+" exists",false);continue
		var size:Vector3=body.get_child(0).shape.size
		var stop:=await walk_into(p,Vector3(body.global_position.x-size.x*.5-1.5,.05,body.global_position.z))
		check(name+" blocks Rend",stop<body.global_position.x-size.x*.5+0.05,"stop=%.2f face=%.2f"%[stop,body.global_position.x-size.x*.5])
	var crate=r.supply_crates[0]
	var stop:=await walk_into(p,Vector3(crate.global_position.x-2.0,.05,crate.global_position.z))
	check("entry crate blocks Rend",stop<crate.global_position.x-0.2,"stop=%.2f crate=%.2f"%[stop,crate.global_position.x])
	# A robot behind the crate reaches Rend on the other side by stepping around it.
	var foe=r.enemies[0];foe.set_physics_process(true);foe.territory_min_x=-10.0
	p.global_position=Vector3(crate.global_position.x-3.0,.05,crate.global_position.z);p.velocity=Vector3.ZERO
	foe.global_position=Vector3(crate.global_position.x+1.6,.05,crate.global_position.z);foe._enter(foe.CHASE)
	var passed:=false
	for i in 240:
		await physics_frame
		if foe.global_position.x<crate.global_position.x-0.6:passed=true;break
	check("robot steps around the crate",passed,"x=%.2f z=%.2f"%[foe.global_position.x,foe.global_position.z])
	# Bodies: a chasing robot stops at Rend instead of walking through him.
	p.global_position=Vector3(30.0,.05,0.0);p.velocity=Vector3.ZERO
	foe.global_position=Vector3(32.5,.05,0.0);foe.territory_min_x=-10.0;foe._enter(foe.CHASE)
	var closest:=99.0
	for i in 120:
		await physics_frame
		closest=minf(closest,Vector2(foe.global_position.x-p.global_position.x,foe.global_position.z-p.global_position.z).length())
	check("robot cannot walk through Rend",closest>0.5,"closest=%.2f"%closest)
	foe.set_physics_process(false)
	# A dodge still slips past a robot.
	p.global_position=Vector3(foe.global_position.x-1.2,.05,foe.global_position.z);p.velocity=Vector3.ZERO;p.facing=1.0
	p.hp=p.max_hp;p.reset_state()  # the chase above may have left him reeling from a blow
	await create_timer(.4).timeout
	Input.action_press("move_right");Input.action_press("dodge");await create_timer(.3).timeout
	Input.action_release("dodge");Input.action_release("move_right")
	check("a dodge passes through a robot",p.global_position.x>foe.global_position.x+0.3,"rend=%.2f robot=%.2f"%[p.global_position.x,foe.global_position.x])
	print("PROPS SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
