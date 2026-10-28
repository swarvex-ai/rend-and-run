extends SceneTree
class DrawClock extends Node:
	func _process(delta:float):RenderingServer.force_draw(false,delta)
var checks:=0
var failures:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("TRIAL ","PASS " if ok else "FAIL ",label)
func _initialize():
	Engine.max_fps=120
	call_deferred("run")
func capture(name:String):
	if DisplayServer.get_name()=="headless" or OS.get_environment("TRIAL_OUTPUT").is_empty():return
	for i in 48:
		await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("TRIAL_OUTPUT")+"/"+name+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	root.size=Vector2i(1280,720)
	if DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
		var clock=DrawClock.new();clock.process_mode=Node.PROCESS_MODE_ALWAYS;clock.process_priority=10000;root.add_child(clock)
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player;p.set_physics_process(false)
	for enemy in r.enemies:enemy.set_physics_process(false);enemy.hide();enemy.collision_layer=0
	p.global_position=r.ENTRY_WORKBENCH_POS
	r.equipment.grant("robot_arm");r.equipment.equip_weapon("robot_arm");p.equip_weapon("robot_arm")
	main.pause_controller.open_shop(r.workbench_state())
	await process_frame;await physics_frame;await process_frame
	check("not unlocked before reinforcement",not r.start_servo_trial().ok)
	r.equipment.credit(6);r.equipment.purchase("reinforced_arm");r.equipment.equip_weapon("reinforced_arm");p.equip_weapon("reinforced_arm");r.shards=0;r.cleared.append("first")
	main.pause_controller.shop.update_state(r.workbench_state())
	await capture("01_workbench")
	check("optional route button",main.pause_controller.shop._trial_action.visible and not main.pause_controller.shop._trial_action.disabled)
	check("start from first bench",r.start_servo_trial().ok and r.servo_run.run_id==1)
	check("cannot reset active run",not r.start_servo_trial().ok)
	main.pause_controller.resume();await process_frame
	var epoch:int=r.servo_run.run_id
	for i in 5:
		for wait in 400:
			await process_frame
			if is_instance_valid(r.servo_trial.foe) and not r.servo_trial.foe._dead:break
		var foe=r.servo_trial.foe
		check("mechanical source %d"%i,is_instance_valid(foe) and foe._mechanical and not foe._dead)
		if not is_instance_valid(foe):quit(1);return
		foe.set_physics_process(false)
		if i==4:
			check("specialist withstands upgraded strike",foe.hp==5)
			for pickup in r.servo_trial.pickups.values():pickup.set_physics_process(false)
			foe.global_position=Vector3(6,0.05,0);p.global_position=Vector3(4,0.05,0)
			main.get_node("Camera3D").global_position=Vector3(5.3,1.05,7.2)
			main.get_node("Camera3D").rotation=Vector3.ZERO
			main.get_node("Camera3D").fov=35
			await capture("02_specialist")
			p.global_position=r.ENTRY_WORKBENCH_POS
			for pickup in r.servo_trial.pickups.values():pickup.set_physics_process(true)
		foe.take_melee_hit(99,Vector3(1,3 if i==4 else 0,0))
		await create_timer(.15).timeout
		check("defeat recorded %d"%i,r.servo_run.defeated_mask & (1<<i) != 0)
	await create_timer(.1).timeout
	check("physical pending salvage groups",r.servo_trial.pickups.size()==6)
	await capture("03_salvage")
	var restored=load("res://lab_route.gd").new();restored._load_progress()
	check("pending specialist survives reload",not restored.servo_run.pending(epoch,4).is_empty());restored.free()
	var before=r.servo_run.export_state()
	DirAccess.make_dir_absolute(r.SAVE_PATH+".tmp")
	check("failed pickup save rolls back receipt and wallet",not r.collect_servo_reward(epoch,4) and r.servo_run.export_state()==before and r.shards==0 and r.equipment.prefixes.servo==0)
	DirAccess.remove_absolute(r.SAVE_PATH+".tmp")
	for i in 6:check("collect group %d"%i,r.collect_servo_reward(epoch,i))
	check("exact run rewards",r.shards==12 and r.equipment.prefixes.servo in [1,2])
	check("duplicate pickup has no payout",not r.collect_servo_reward(epoch,4) and r.shards==12)
	main.pause_controller.open_shop(r.workbench_state())
	await process_frame;await physics_frame;await process_frame
	check("explicit restart",r.start_servo_trial().ok and r.servo_run.run_id==epoch+1)
	check("old run callback ignored",not r.record_servo_defeat(epoch,0) and not r.collect_servo_reward(epoch,0))
	main.pause_controller.resume()
	for wait in 400:
		await process_frame
		if is_instance_valid(r.servo_trial.foe) and not r.servo_trial.foe._dead:break
	r.servo_trial.foe.set_physics_process(false)
	r.servo_trial.foe.take_melee_hit(99,Vector3(1,0,0))
	p.global_position=Vector3(3,0.05,0)
	await create_timer(1.2).timeout
	check("physical pickup credits new run once",r.shards==14 and r.servo_run.pending(epoch+1,0).is_empty())

	p.global_position=r.ENTRY_WORKBENCH_POS
	for i in range(1,5):
		for wait in 400:
			await process_frame
			if is_instance_valid(r.servo_trial.foe) and not r.servo_trial.foe._dead:break
		r.servo_trial.foe.set_physics_process(false)
		r.servo_trial.foe.take_melee_hit(99,Vector3(1,0,0))
		await create_timer(.15).timeout
	for i in range(1,6):r.collect_servo_reward(epoch+1,i)
	check("two real runs guarantee recipe",r.shards==24 and r.equipment.prefixes.servo>=2)
	main.pause_controller.open_shop(r.workbench_state());await process_frame;await physics_frame;await process_frame
	var shop=main.pause_controller.shop
	shop._servo_action.pressed.emit();shop._servo_action.pressed.emit()
	check("farmed components become visible upgrade",r.shards==12 and r.equipment.prefixes.owns_module("servo_i") and p._servo_installed and p._servo_model.visible)
	var final_save=load("res://lab_route.gd").new();final_save._load_progress()
	check("whole farming loop persists",final_save.equipment.prefixes.installed("reinforced_arm")=="servo_i" and final_save.shards==12)
	final_save.free()
	paused=false;main.queue_free();await create_timer(.3).timeout
	print("TRIAL SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
