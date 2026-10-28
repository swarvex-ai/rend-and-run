extends SceneTree
class DrawClock extends Node:
	func _process(delta:float):RenderingServer.force_draw(false,delta)
var p:CharacterBody3D
func _initialize():Engine.max_fps=120;call_deferred("run")
func walk(x:float):
	for i in 360:
		var dx:float=x-p.global_position.x
		Input.action_release("move_right");Input.action_release("move_left")
		if absf(dx)<.12:break
		Input.action_press("move_right" if dx>0 else "move_left")
		await physics_frame
	Input.action_release("move_right");Input.action_release("move_left")
	for i in 12:await physics_frame
func tap(action:String):
	Input.action_press(action);await process_frame;await process_frame;Input.action_release(action)
func snap(label):
	if DisplayServer.get_name()=="headless" or OS.get_environment("LOOP_OUTPUT").is_empty():return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("LOOP_OUTPUT")+"/"+label+".png")
func run():
	assert(OS.get_user_data_dir().begins_with("/tmp/"))
	if DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
		var clock=DrawClock.new();clock.process_mode=Node.PROCESS_MODE_ALWAYS;clock.process_priority=10000;root.add_child(clock)
	root.size=Vector2i(1280,720)
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout
	for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
	main.pause_controller.set_process_input(false);main.pause_controller.resume()
	p=main.player;var r=main.route;var foe=r.enemies[0]
	await walk(1.3);await tap("interact")
	for i in 900:
		await physics_frame
		if foe._dead or p._dying:break
		var dx:float=foe.global_position.x-p.global_position.x
		Input.action_release("move_left");Input.action_release("move_right")
		if absf(dx)>.7:Input.action_press("move_right" if dx>0 else "move_left")
		if i%16==0:Input.action_press("attack")
		elif i%16==2:Input.action_release("attack")
	for action in ["attack","move_right","move_left"]:Input.action_release(action)
	assert(foe._dead and not p._dying)
	await walk(3.4)
	Input.action_press("move_right");await physics_frame;Input.action_release("move_right")
	Input.action_press("crouch")
	for i in 6:await physics_frame
	for i in 180:
		if r.supply_crates[0].is_broken():break
		if i%45==0:Input.action_press("attack")
		elif i%45==2:Input.action_release("attack")
		await physics_frame
	Input.action_release("attack");Input.action_release("crouch")
	print("CRATE CONTACT x=",p.global_position," hp=",r.supply_crates[0]._hp," crouch=",p.crouching)
	assert(r.supply_crates[0].is_broken())
	await walk(4);await create_timer(.8).timeout
	if r.pending_shards.has(r.FIRST_SALVAGE_ID):
		await walk(r.first_salvage_position.x);await create_timer(.8).timeout
	assert(r.shards==6)
	await walk(r.ENTRY_WORKBENCH_POS.x);await create_timer(.5).timeout
	await snap("04_workbench_ready")
	await tap("interact");await process_frame
	var shop=main.pause_controller.shop;assert(shop.visible and not shop._vibro_action.disabled)
	await snap("05_upgrade_menu_final")
	shop._vibro_action.pressed.emit();await process_frame
	shop._vibro_action.pressed.emit();await process_frame
	assert(p.weapon_id=="reinforced_arm" and r.shards==0)
	main.pause_controller.resume()
	await create_timer(.5).timeout;await snap("06_upgrade_equipped")

	var summary=[]
	for cycle in 3:
		await walk(r.ENTRY_WORKBENCH_POS.x);await create_timer(.25).timeout
		await tap("interact");await process_frame
		assert(shop.visible and not shop._trial_action.disabled)
		if cycle==2:
			shop._servo_action.pressed.emit();await process_frame
			shop._servo_action.pressed.emit();await process_frame
			assert(p._servo_installed and r.shards==12)
		shop._trial_action.pressed.emit();await create_timer(.15).timeout
		# Each trial starts at full health: this test covers the farming loop, not a bot surviving 18 fights unhealed.
		p.hp=p.max_hp
		var start_ms=Time.get_ticks_msec();var start_hp=p.hp
		var carrier_captured=false
		for frame in 2400:
			await physics_frame
			if p._dying:break
			if r.servo_run.defeated_mask==63:break
			var target=r.servo_trial.foe
			Input.action_release("move_left");Input.action_release("move_right")
			if is_instance_valid(target) and not target._dead:
				if not carrier_captured and str(target.encounter_id).ends_with("_4"):
					carrier_captured=true;await snap("carrier_run_"+str(cycle+1))
				var dx:float=target.global_position.x-p.global_position.x
				var dz:float=target.global_position.z-p.global_position.z
				if absf(dx)>.7:Input.action_press("move_right" if dx>0 else "move_left")
				# Line up in depth so the arm sweep reaches the robot on the floor strip.
				Input.action_release("move_up");Input.action_release("move_down")
				if absf(dz)>.2:Input.action_press("move_down" if dz>0 else "move_up")
				if frame%16==0:Input.action_press("attack")
				elif frame%16==2:Input.action_release("attack")
			else:
				Input.action_release("attack")
				# Between foes: back into the trial arena (the next one only spawns at x <= 11).
				if p.global_position.x>9.5:Input.action_press("move_left")
		for action in ["attack","move_left","move_right","move_up","move_down"]:Input.action_release(action)
		print("FARM COMBAT run=",cycle+1," mask=",r.servo_run.defeated_mask," hp=",p.hp," pos=",p.global_position)
		if p._dying or r.servo_run.defeated_mask!=63:
			var stuck=r.servo_trial.foe
			if is_instance_valid(stuck):print("FARM FOE pos=",stuck.global_position," state=",stuck._state," dead=",stuck._dead," hp=",stuck.hp," stun=",stuck._stun)
			print("FARM INPUT FAIL: fight incomplete");quit(1);return
		await create_timer(.3).timeout
		for i in 6:
			if not r.servo_run.pending(r.servo_run.run_id,i).is_empty():
				await walk(r.servo_run.reward_position(i).x);await create_timer(.7).timeout
		print("FARM PICKUPS run=",cycle+1," mask=",r.servo_run.collected_mask," shards=",r.shards," servo=",r.equipment.prefixes.servo)
		if r.servo_run.collected_mask!=63:
			print("FARM INPUT FAIL: physical pickups incomplete");quit(1);return
		summary.append({"run":cycle+1,"seconds":(Time.get_ticks_msec()-start_ms)/1000.0,"hp_before":start_hp,"hp_after":p.hp,"shards":r.shards,"servo":r.equipment.prefixes.servo})
	await walk(r.ENTRY_WORKBENCH_POS.x);await create_timer(.25).timeout
	await tap("interact");await process_frame
	assert(shop.visible and not shop._servo_action.disabled)
	assert(p._servo_installed and p._servo_model.visible and r.shards==24)
	await snap("07_earned_servo")
	main.pause_controller.resume();await create_timer(.3).timeout
	print("FARM INPUT SUMMARY ",JSON.stringify(summary))
	print("FARM INPUT PASS: fresh save, actual input fights and physical collection, two base runs, craft/install and third run using servo; HP=",p.hp)
	main.queue_free();for i in 8:await process_frame
	quit()
