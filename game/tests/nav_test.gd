extends SceneTree
# Robots do not stall: a robot with a supply case between it and Rend climbs over it, and
# the robot dog overtakes a squad mate standing in its lane instead of waiting behind it.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("NAV %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var raider;var dog;var duelist
	for e in r.enemies:
		match e.encounter_id:
			"first":raider=e
			"hound":dog=e
			"duelist":duelist=e
	# 1) A case in the lane.
	p.global_position=Vector3(24.0,.05,0);p.max_hp=99;p.hp=99
	var crate=r.throwables[3];crate.global_position=Vector3(26.5,.31,0);crate.linear_velocity=Vector3.ZERO
	raider.global_position=Vector3(28.5,.05,0);raider.territory_min_x=-100.0;raider.hp=99
	raider.set_physics_process(true);raider.provoke()
	var over:=false
	for i in 300:
		await physics_frame;p._iframes=1.0;p.global_position=Vector3(24.0,.05,0)
		if raider.global_position.x<crate.global_position.x-0.5:over=true;break
	check("a robot gets past a case in its lane",over,"raider x=%.2f crate x=%.2f vaults=%d"%[raider.global_position.x,crate.global_position.x,raider.vaults])
	raider.set_physics_process(false);raider.global_position=Vector3(10,.05,0)
	# 2) The dog behind a standing humanoid.
	p.global_position=Vector3(50.0,.05,0)
	duelist.global_position=Vector3(52.5,.05,0);duelist.set_physics_process(false)
	dog.global_position=Vector3(54.0,.05,0);dog.territory_min_x=-100.0;dog.hp=99
	dog.set_physics_process(true);dog.provoke()
	var passed:=false
	for i in 240:
		await physics_frame;p._iframes=1.0;p.global_position=Vector3(50.0,.05,0)
		if dog.global_position.x<duelist.global_position.x-0.3:passed=true;break
	check("the dog overtakes a squad mate in its lane",passed,"dog x=%.2f z=%.2f"%[dog.global_position.x,dog.global_position.z])
	dog.set_physics_process(false);dog.global_position=Vector3(80,.05,0)
	# 3) A robot coming down the lane of a stacked pair of cases (too tall to climb).
	var stack:Array=r.throwables.filter(func(c):return absf(c.global_position.x-37.4)<0.4)
	p.global_position=Vector3(34.0,.05,-0.7);p.velocity=Vector3.ZERO
	raider.global_position=Vector3(40.0,.05,-0.72);raider.territory_min_x=-100.0;raider.set_physics_process(true);raider.provoke()
	var walled:=0;var cleared:=false
	for i in 240:
		await physics_frame;p._iframes=1.0;p.global_position=Vector3(34.0,.05,-0.7)
		if raider.is_on_wall():walled+=1
		if raider.global_position.x<36.8:cleared=true;break
	check("a robot steers round a stack of cases instead of running into it",cleared and walled<20 and stack.size()==2,"x=%.2f wall frames=%d"%[raider.global_position.x,walled])
	print("NAV SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
