extends SceneTree
# Depth no longer hides Rend: a gunner shoots him in another depth lane, and the robot dog
# finds its way round the security cover to him instead of attacking the cover.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("DEPTH %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player;p.max_hp=99;p.hp=99
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var guard;var dog
	for e in r.enemies:
		if e.encounter_id=="guard":guard=e
		if e.encounter_id=="hound":dog=e
	# 1) A gunner, Rend a lane and a half off its line.
	guard.territory_min_x=30.0
	p.global_position=Vector3(guard.global_position.x-4.5,.05,-0.9);p.velocity=Vector3.ZERO;p._iframes=0
	guard.global_position.z=0.3;guard.set_physics_process(true)
	var hp0:int=p.hp
	for i in 600:
		await physics_frame
		p._iframes=0;p.global_position=Vector3(guard.global_position.x-4.5,.05,-0.9)
		if p.hp<hp0:break
	check("a gunner hits Rend in another depth lane",p.hp<hp0,"shots=%d"%guard.shots_fired)
	guard.set_physics_process(false);guard.global_position=Vector3(90,.05,0)
	# 2) The dog behind the security cover, Rend on the far side.
	p.hp=99;p.global_position=Vector3(39.0,.05,0)
	dog.global_position=Vector3(43.5,.05,0);dog.territory_min_x=-100.0;dog.set_physics_process(true)
	var attacked:=false
	for i in 480:
		await physics_frame
		p._iframes=1.0;p.global_position=Vector3(39.0,.05,0)
		if dog._state==dog.WINDUP and dog.global_position.x<40.6:attacked=true;break
	check("the dog comes round the cover and attacks",attacked,"dog x=%.2f z=%.2f state=%d"%[dog.global_position.x,dog.global_position.z,dog._state])
	print("DEPTH SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
