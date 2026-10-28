extends SceneTree
var checks:=0
var failures:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("RESUME ","PASS " if ok else "FAIL ",label)
func _initialize():Engine.max_fps=120;call_deferred("run")
func load_room():
	var room=load("res://main.tscn").instantiate();root.add_child(room);current_scene=room
	await create_timer(.3).timeout;room.pause_controller.resume();room.set_process(false)
	room.player.set_physics_process(false);room.player.global_position=Vector3(4,.05,0)
	for enemy in room.route.enemies:enemy.set_physics_process(false);enemy.hide();enemy.collision_layer=0
	return room
func carrier(room):
	for wait in 400:
		await process_frame
		if is_instance_valid(room.route.servo_trial.foe):
			room.route.servo_trial.foe.set_physics_process(false)
			return room.route.servo_trial.foe
	return null
func close_room(room):
	room.queue_free();await create_timer(.3).timeout
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var room=await load_room();var r=room.route
	r.servo_run.begin(91)
	for i in 4:r.record_servo_defeat(1,i);r.collect_servo_reward(1,i)
	var foe=await carrier(room)
	if not is_instance_valid(foe):check("carrier spawns",false);quit(1);return
	foe.global_position=Vector3(7,.05,0)
	foe.take_melee_hit(2,Vector3(1,0,0));await create_timer(.2).timeout
	foe.take_melee_hit(2,Vector3(1,3.2,0));await create_timer(.2).timeout
	var original:Dictionary=r.servo_run.export_state()
	var amount:int=r.servo_run.specialist_servo
	var drop:Vector3=r.servo_run.reward_position(4)
	check("cut saved before closing",foe._severed and amount>0 and not r.servo_run.servo_collected)
	await close_room(room)
	room=await load_room();r=room.route;foe=await carrier(room)
	check("actual scene restores current carrier only",is_instance_valid(foe) and foe.name=="ServoTrial_1_4" and r.servo_run.defeated_mask==15)
	check("cut visuals restored without repeat emission",foe._severed and not foe._arm_mesh.visible and foe._cap_mesh.visible and not r.servo_trial.carrier_module.visible)
	check("pending drop and bonus identical",r.servo_run.export_state()==original and r.servo_run.reward_position(4)==drop)
	check("one pending component node",r.servo_trial.pickups.size()==1 and r.servo_trial.pickups.has(4))
	room.player.global_position=Vector3(drop.x,drop.y-.28,0)
	await create_timer(1.3).timeout
	check("physical pickup after reload",r.equipment.prefixes.servo==amount and r.servo_run.servo_collected and r.shards==8)
	await close_room(room)
	room=await load_room();r=room.route;foe=await carrier(room)
	check("collected early component cannot respawn",r.servo_run.pending(1,4).is_empty() and not r.servo_trial.pickups.has(4) and r.equipment.prefixes.servo==amount and foe._severed)
	foe.take_melee_hit(99,Vector3(1,0,0));await create_timer(.2).timeout
	check("kill after reload pays no second servo",r.servo_run.pending(1,4)=={"shards":2,"servo":0})
	r.collect_servo_reward(1,4);r.collect_servo_reward(1,5)
	check("resumed full run budget",r.shards==12 and r.equipment.prefixes.servo==amount and r.servo_run.can_begin())
	await close_room(room)
	print("RESUME SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
