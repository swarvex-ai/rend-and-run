extends SceneTree
# Riot shields: light blows and bullets from the front are blocked, a blow from behind
# lands, a heavy blow knocks the shield aside (robot open), three of them knock it off.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("SHIELD %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	var duelist
	for e in r.enemies:if e.encounter_id=="duelist":duelist=e
	check("the duelist carries a shield",is_instance_valid(duelist._shield))
	duelist.hp=99;duelist.global_position=Vector3(32.5,.05,0);duelist.get_node("VisualPivot").rotation.y=PI  # faces -x (toward Rend)
	p.global_position=Vector3(31.0,.05,0)
	duelist.set_physics_process(true);duelist._enter(duelist.IDLE)
	await create_timer(.3).timeout;duelist.set_physics_process(false);duelist.get_node("VisualPivot").rotation.y=PI
	var front:=Vector3(5.5,1.1,0)  # blow travelling +x: Rend strikes from its front
	duelist._stun=0;duelist._shield_open=0;duelist._enter(duelist.CHASE)  # guard up (not mid-strike)
	duelist.take_melee_hit(1,front)
	check("a light blow from the front is blocked",duelist.hp==99 and duelist.blocks==1,"hp=%d blocks=%d"%[duelist.hp,duelist.blocks])
	duelist._stun=0;duelist._shield_open=0;duelist._enter(duelist.CHASE)
	duelist.take_melee_hit(1,Vector3(-5.5,1.1,0))
	check("a blow from behind lands",duelist.hp==98)
	duelist._stun=0;duelist._shield_open=0;duelist._kb_timer=0;duelist._enter(duelist.CHASE)
	var shot=load("res://modules/combat/gun.gd").make("pistol");main.add_child(shot)
	shot.global_position=Vector3(30.0,1.2,0);await process_frame
	shot.fire(Vector3(1,0,0),1|2,p,[p.get_rid()])
	await create_timer(.4).timeout
	check("a bullet from the front is blocked",duelist.hp==98 and duelist.blocks>=2,"hp=%d blocks=%d"%[duelist.hp,duelist.blocks])
	duelist._stun=0;duelist._shield_open=0;duelist._enter(duelist.CHASE)
	duelist.take_melee_hit(2,Vector3(7.5,3.2,0))
	check("a heavy blow knocks the shield aside",duelist.hp==98 and duelist._stun>0 and duelist.shield_breaks_left==2)
	for i in 2:
		duelist._stun=0;duelist._shield_open=0;duelist._enter(duelist.CHASE)
		duelist.take_melee_hit(2,Vector3(7.5,3.2,0))
	check("three heavy blows knock it off",not is_instance_valid(duelist._shield))
	print("SHIELD SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
