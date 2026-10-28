extends SceneTree
# Supply cases: Rend shoves a loose case, lifts it with interact, throws it with attack and
# the case strikes a robot; a blow knocks it out of his hands; it can be set down again.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("CRATE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func tap(action: String) -> void:
	Input.action_press(action);await create_timer(.08).timeout;Input.action_release(action);await create_timer(.08).timeout
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	var crate:RigidBody3D=r.throwables[3]  # the single case at x 25.9, free floor around it
	await create_timer(.6).timeout
	check("cases rest on the floor",absf(crate.global_position.y-.31)<.08,"y=%.2f"%crate.global_position.y)
	# Shove: walk into it along its depth.
	var x0:=crate.global_position.x
	p.global_position=Vector3(x0-1.6,.05,crate.global_position.z);p.velocity=Vector3.ZERO;p.facing=1.0
	Input.action_press("move_right");await create_timer(1.0).timeout;Input.action_release("move_right")
	check("walking into a case shoves it",crate.global_position.x>x0+.15,"dx=%.2f"%(crate.global_position.x-x0))
	# Lift.
	p.global_position=Vector3(crate.global_position.x-.8,.05,crate.global_position.z);p.velocity=Vector3.ZERO;p.facing=1.0
	await create_timer(.3).timeout
	check("a case in front is in reach",p.throwable_in_reach()==crate)
	await tap("interact")
	check("interact lifts it",p.carried==crate and crate.carried)
	await create_timer(1.0).timeout  # bend down, lift, stand up
	check("it rides at his chest",crate.global_position.y>.8 and absf(crate.global_position.x-p.global_position.x)<.8,"y=%.2f"%crate.global_position.y)
	# Throw at the first robot.
	# Clear lane: carry it to the middle of the strip (the entry workbench stands at the back).
	p.global_position.z=0.0;await create_timer(.2).timeout
	var foe=r.enemies[0];foe.set_physics_process(true);foe.hp=99;foe.territory_min_x=-10.0
	foe.global_position=Vector3(p.global_position.x+3.2,.05,0.0);foe._enter(foe.IDLE)
	var hits0:int=foe.hits_taken
	await tap("attack");await create_timer(.45).timeout
	check("attack throws it",p.carried==null and crate.is_thrown())
	for i in 90:
		await physics_frame
		if foe.hits_taken>hits0:break
	check("the thrown case strikes the robot",foe.hits_taken>hits0,"crate x=%.2f foe x=%.2f"%[crate.global_position.x,foe.global_position.x])
	foe.set_physics_process(false)
	await create_timer(1.0).timeout
	# Lift again, then get hit: it falls from his hands.
	p.global_position=Vector3(crate.global_position.x-.8,.05,crate.global_position.z);p.velocity=Vector3.ZERO;p.facing=1.0;p.hp=p.max_hp;p._iframes=0
	await create_timer(.3).timeout
	await tap("interact");await create_timer(1.0).timeout
	check("lifted again",p.carried==crate)
	p.take_damage(1,p.global_position+Vector3(1,0,0),null)
	check("a blow knocks it out of his hands",p.carried==null and not crate.carried)
	print("CRATE SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
