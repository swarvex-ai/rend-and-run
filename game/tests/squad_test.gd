extends SceneTree
# Squad director: a robot that engages radios the idle one nearby; two melee robots coming
# from the same side end up on both sides of Rend (pincer); their wind-ups never overlap.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("SQUAD %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var a;var b
	for e in r.enemies:
		if e.encounter_id=="first":a=e
		if e.encounter_id=="duelist":b=e
	for e in [a,b]:e.hp=99;e.territory_min_x=-100.0;e._enter(e.IDLE)
	p.global_position=Vector3(30.0,.05,0);p.velocity=Vector3.ZERO;p.max_hp=99;p.hp=99
	a.global_position=Vector3(33.0,.05,0);b.global_position=Vector3(40.5,.05,0.4)
	a.set_physics_process(true);b.set_physics_process(true)
	await create_timer(.2).timeout
	a.provoke()
	var radioed:=false
	for i in 90:
		await physics_frame;p._iframes=1.0
		if b._state!=b.IDLE and b._state!=b.ALERT:radioed=true;break
	check("an engaged robot radios the idle one",radioed and r.squad.calls>0,"b state=%d calls=%d"%[b._state,r.squad.calls])
	var both_sides:=false;var overlap:=0;var stalked:=false
	for i in 600:
		await physics_frame;p._iframes=1.0;p.hp=99
		var sa:=signf(a.global_position.x-p.global_position.x);var sb:=signf(b.global_position.x-p.global_position.x)
		if sa!=sb and absf(a.global_position.x-p.global_position.x)<3.0 and absf(b.global_position.x-p.global_position.x)<3.0:both_sides=true
		if a._state==a.WINDUP and b._state==b.WINDUP:overlap+=1
		if a._circling or b._circling:stalked=true
	check("they take Rend in a pincer",both_sides,"a=%.2f b=%.2f rend=%.2f orders=%d"%[a.global_position.x,b.global_position.x,p.global_position.x,r.squad.flank_orders])
	check("their wind-ups never overlap",overlap==0,"overlap frames=%d"%overlap)
	check("the one waiting its turn stalks him instead of standing still",stalked)
	var backup:Array=r.reinforcements.filter(func(m):return is_instance_valid(m) and m.encounter_id.begins_with("duelist_backup"))
	check("the duelist's backup runs in from off screen",backup.size()==1 and backup[0]._state!=backup[0].IDLE,"count=%d"%backup.size())
	print("SQUAD SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
