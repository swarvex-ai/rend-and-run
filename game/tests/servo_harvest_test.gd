extends SceneTree
const RUN=preload("res://modules/loot/servo_run_ledger.gd")
class DrawClock extends Node:
	func _process(delta:float):RenderingServer.force_draw(false,delta)
var checks:=0
var failures:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("HARVEST ","PASS " if ok else "FAIL ",label)
func _initialize():
	Engine.max_fps=120
	call_deferred("run")
func capture(label:String):
	if DisplayServer.get_name()=="headless" or OS.get_environment("TRIAL_OUTPUT").is_empty():return
	for i in 48:await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("TRIAL_OUTPUT")+"/"+label+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	for early_collect in [false,true]:
		var ledger=RUN.new();ledger.begin(71)
		check("early arm before carrier refused",not ledger.expose_servo(1,Vector3(4,.28,0)))
		for i in 4:ledger.defeat(1,i)
		check("expose at severance",ledger.expose_servo(1,Vector3(4,.28,0)))
		var before=ledger.export_state()
		check("retry does not reroll or move",ledger.expose_servo(1,Vector3(8,.28,0)) and before==ledger.export_state())
		var amount:int=ledger.specialist_servo
		check("only component before death",ledger.pending(1,4)=={"shards":0,"servo":amount})
		var paid:=0
		if early_collect:paid=int(ledger.collect(1,4).servo)
		var copy=RUN.new()
		check("early save reload",copy.import_state(JSON.parse_string(JSON.stringify(ledger.export_state()))) and copy.export_state()==ledger.export_state())
		ledger=copy
		var pity:int=ledger.bonus_misses
		ledger.defeat(1,4)
		check("death does not reroll",ledger.specialist_servo==amount and ledger.bonus_misses==pity)
		check("remaining death reward",ledger.pending(1,4)=={"shards":2,"servo":0 if early_collect else amount})
		var shards:=0
		for i in 6:
			var reward=ledger.collect(1,i);shards+=int(reward.shards);paid+=int(reward.servo)
		check("exact full run budget",shards==12 and paid==amount and ledger.can_begin())
		check("no double component",ledger.collect(1,4).is_empty())
	# Real legacy v1, both pending and already collected.
	for paid in [false,true]:
		var legacy={"version":1,"run_id":1,"seed":71,"initialized":true,"defeated_mask":63,"collected_mask":16 if paid else 0,"bonus_misses":1,"specialist_servo":1}
		var migrated=RUN.new()
		check("legacy paid/pending migration",migrated.import_state(JSON.parse_string(JSON.stringify(legacy))) and migrated.servo_collected==paid and migrated.pending(1,4)==({} if paid else {"shards":2,"servo":1}))
	root.size=Vector2i(1280,720)
	if DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
		var clock=DrawClock.new();clock.process_mode=Node.PROCESS_MODE_ALWAYS;clock.process_priority=10000;root.add_child(clock)
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player;p.set_physics_process(false)
	for enemy in r.enemies:enemy.set_physics_process(false);enemy.hide();enemy.collision_layer=0
	p.global_position=Vector3(3,.05,0)
	r.servo_run.begin(71)
	for i in 4:r.record_servo_defeat(1,i)
	for i in 4:r.collect_servo_reward(1,i)
	for wait in 400:
		await process_frame
		if is_instance_valid(r.servo_trial.foe):break
	var foe=r.servo_trial.foe;foe.set_physics_process(false)
	foe.global_position=Vector3(6,.05,0)
	var camera=main.get_node("Camera3D");camera.global_position=Vector3(5.3,1.05,7.2);camera.rotation=Vector3.ZERO;camera.fov=35
	check("carrier module attached",is_instance_valid(r.servo_trial.carrier_module) and r.servo_trial.carrier_module.visible)
	print("CARRIER module position=",r.servo_trial.carrier_module.global_position," scale=",r.servo_trial.carrier_module.global_basis.get_scale()," forearm rest=",foe._skeleton.get_bone_rest(foe._skeleton.find_bone("LeftForeArm")))
	await capture("01_carrier")
	foe.take_melee_hit(2,Vector3(1,0,0));await create_timer(.2).timeout
	var arm_before=r.servo_run.export_state()
	DirAccess.make_dir_absolute(r.SAVE_PATH+".tmp")
	check("failed exposure leaves reward and pity unchanged",not r.record_servo_arm(1,foe.global_position+Vector3.UP) and r.servo_run.export_state()==arm_before)
	DirAccess.remove_absolute(r.SAVE_PATH+".tmp")
	foe.take_melee_hit(2,Vector3(1,3.2,0));await create_timer(.2).timeout
	check("nonlethal combo detaches arm",foe.hp==1 and not foe._dead and foe._severed and not r.servo_trial.carrier_module.visible)
	check("physical early servo without kill",r.servo_trial.pickups.has(4) and r.servo_run.defeated_mask==15 and int(r.servo_run.pending(1,4).servo)>0)
	await capture("02_harvest")
	var before=r.servo_run.export_state()
	DirAccess.make_dir_absolute(r.SAVE_PATH+".tmp")
	check("failed early collection rolls back",not r.collect_servo_reward(1,4) and r.servo_run.export_state()==before and r.equipment.prefixes.servo==0 and r.shards==8)
	DirAccess.remove_absolute(r.SAVE_PATH+".tmp")
	check("early pickup succeeds",r.collect_servo_reward(1,4) and r.shards==8 and r.equipment.prefixes.servo>0)
	var amount:int=r.equipment.prefixes.servo
	var restored=load("res://lab_route.gd").new();restored._load_progress()
	check("early collected save persists",restored.servo_run.servo_collected and restored.servo_run.defeated_mask==15 and restored.equipment.prefixes.servo==amount);restored.free()
	foe.take_melee_hit(1,Vector3(1,0,0));await create_timer(.2).timeout
	check("death leaves only shards",r.servo_run.pending(1,4)=={"shards":2,"servo":0})
	r.collect_servo_reward(1,4);r.collect_servo_reward(1,5)
	check("whole scene exact payout",r.shards==12 and r.equipment.prefixes.servo==amount and r.servo_run.can_begin())
	main.queue_free();await create_timer(.3).timeout
	print("HARVEST SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
