extends SceneTree
const UI_TEXT = preload("res://data/ui_texts.gd")
class DrawClock extends Node:
	func _process(delta:float):RenderingServer.force_draw(false,delta)
var failures:=0
var checks:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("SERVO UPGRADE ","PASS " if ok else "FAIL ",label)
func _initialize():Engine.max_fps=120;call_deferred("run")
func capture(name:String):
	if DisplayServer.get_name()=="headless" or OS.get_environment("SERVO_CAPTURE").is_empty():return
	for i in 48:await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SERVO_CAPTURE")+"/"+name+".png")
func attack(p,seq:int,servo:bool) -> Dictionary:
	p._cancel_attack();p.set_arm_servo(servo);p.velocity=Vector3.ZERO
	p.set_physics_process(true)
	await physics_frame
	p._start_attack(seq)
	var counts={1:0,2:0,3:0}
	var speeds={}
	for i in 150:
		await physics_frame
		if p._attack_phase==0:break
		counts[p._attack_phase]+=1
		if not speeds.has(p._attack_phase):speeds[p._attack_phase]=p._hero_anim.get_playing_speed()
	p.set_physics_process(false)
	return {"counts":counts,"speeds":speeds}
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	root.size=Vector2i(1280,720)
	if DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
		var clock=DrawClock.new();clock.process_mode=Node.PROCESS_MODE_ALWAYS;clock.process_priority=10000;root.add_child(clock)
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player;p.set_physics_process(false)
	for e in r.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
	r.equipment.grant("robot_arm");r.equipment.equip_weapon("robot_arm");r.equipment.credit(18);r.equipment.purchase("reinforced_arm");r.equipment.equip_weapon("reinforced_arm");r.shards=r.equipment.shards;r.cleared.append("first")
	p.equip_weapon("reinforced_arm");p.global_position=Vector3(4,.05,0)
	main.get_node("Camera3D").global_position=Vector3(5.3,1.05,7.2);main.get_node("Camera3D").rotation=Vector3.ZERO;main.get_node("Camera3D").fov=35
	p._hero_anim.play("idle");p._hero_anim.seek(.3,true);p._hero_anim.pause()
	await capture("before_servo")
	p.global_position=r.ENTRY_WORKBENCH_POS
	main.pause_controller.open_shop(r.workbench_state());await process_frame;await physics_frame;await process_frame
	var shop=main.pause_controller.shop
	check("craft disabled without components",shop._servo_action.disabled)
	r.equipment.prefixes.credit_servo(2);shop.update_state(r.workbench_state())
	check("craft enabled at exact cost",not shop._servo_action.disabled)
	shop._servo_action.pressed.emit()
	check("UI craft charges exact price",r.shards==0 and r.equipment.prefixes.servo==0 and r.equipment.prefixes.owns_module("servo_i"))
	check("craft not auto installed",not p._servo_installed and not p._servo_model.visible)
	shop._servo_action.pressed.emit()
	check("UI install shows authored module",p._servo_installed and p._servo_model.visible and shop._servo_action.text==UI_TEXT.t("workbench_servo_remove"))
	for size in [Vector2i(1280,720),Vector2i(640,360)]:
		root.size=size;await process_frame;await process_frame
		check("servo label does not overlap button",shop._servo_info.get_global_rect().end.x<shop._servo_action.get_global_rect().position.x)
		check("feedback stays above trial",shop._feedback_label.get_global_rect().end.y<=shop._trial_action.get_global_rect().position.y)
		check("menu fits viewport",shop._panel.get_global_rect().end.y<=size.y)
		await capture("menu_"+str(size.x))
	root.size=Vector2i(1280,720)
	main.pause_controller.resume();await create_timer(.1).timeout
	p.global_position=Vector3(4,.05,0);p.velocity=Vector3.ZERO
	p._hero_anim.play("idle");p._hero_anim.seek(.3,true);p._hero_anim.pause()
	await capture("after_servo")
	for seq in [1,3]:
		var normal=await attack(p,seq,false)
		p.global_position=Vector3(4,.05,0)
		var servo=await attack(p,seq,true)
		print("TIMING ",seq," base=",normal," servo=",servo)
		check("startup frame count unchanged %d"%seq,normal.counts[1]==servo.counts[1])
		check("active frame count unchanged %d"%seq,normal.counts[2]==servo.counts[2])
		check("recovery shorter %d"%seq,servo.counts[3]<=normal.counts[3]-2)  # whole strike runs ATTACK_TEMPO faster since 24.10.
		check("active clip playback unchanged %d"%seq,is_equal_approx(normal.speeds[2],servo.speeds[2]))
		check("only recovery clip accelerated %d"%seq,normal.speeds[3]>0 and is_equal_approx(servo.speeds[3],normal.speeds[3]/.8))
	p._cancel_attack();p.global_position=r.ENTRY_WORKBENCH_POS
	main.pause_controller.open_shop(r.workbench_state());await process_frame;await physics_frame;await process_frame
	shop._servo_action.pressed.emit()
	check("remove retains module without cost",not p._servo_installed and not p._servo_model.visible and r.equipment.prefixes.owns_module("servo_i") and r.shards==0)
	shop._servo_action.pressed.emit()
	var restored=load("res://lab_route.gd").new();restored._load_progress()
	check("installation survives real reload",restored.equipment.prefixes.installed("reinforced_arm")=="servo_i");restored.free()
	p.equip_weapon("robot_arm")
	check("starter does not show upgraded visual",not p._servo_model.is_visible_in_tree())
	p._start_attack(1);check("starter never gains recovery bonus",p._attack_recovery_factor==1.0)
	paused=false;main.queue_free();await create_timer(.3).timeout
	var reloaded=load("res://main.tscn").instantiate();root.add_child(reloaded);current_scene=reloaded
	await create_timer(.3).timeout
	check("new scene restores equipped visible servo",reloaded.player._servo_installed and reloaded.player._servo_model.is_visible_in_tree() and reloaded.player.weapon_id=="reinforced_arm")
	paused=false;reloaded.queue_free();await create_timer(.3).timeout
	print("SERVO UPGRADE SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
