extends SceneTree
const TEXT = preload("res://data/route_texts.gd")
class DrawClock extends Node:
	func _process(delta:float):RenderingServer.force_draw(false,delta)
var checks:=0
var failures:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("GUIDANCE ","PASS " if ok else "FAIL ",label)
func _initialize():Engine.max_fps=120;call_deferred("run")
func capture(label:String):
	if DisplayServer.get_name()=="headless" or OS.get_environment("GUIDANCE_OUTPUT").is_empty():return
	for i in 48:await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("GUIDANCE_OUTPUT")+"/"+label+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	root.size=Vector2i(1280,720)
	if DisplayServer.get_name()!="headless":
		RenderingServer.render_loop_enabled=false
		var clock=DrawClock.new();clock.process_mode=Node.PROCESS_MODE_ALWAYS;clock.process_priority=10000;root.add_child(clock)
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player;p.set_physics_process(false);r.servo_trial.set_process(false)
	for enemy in r.enemies:enemy.set_physics_process(false);enemy.hide();enemy.collision_layer=0
	p.global_position=Vector3(4,.05,0)
	check("initial arm objective retained",r._mission_objective()==TEXT.t("objective_take_arm"))
	r.equipment.grant("robot_arm");r.equipment.credit(6);r.equipment.purchase("reinforced_arm");r.equipment.equip_weapon("reinforced_arm");p.equip_weapon("reinforced_arm");r.cleared.append("first")
	check("optional source offered",r._mission_objective()==TEXT.t("objective_servo_optional"))
	r.servo_run.begin(71)
	for i in 2:r.servo_run.defeat(1,i)
	check("fight progress counted",r._mission_objective()==TEXT.t("objective_servo_progress")%2)
	main.get_node("Camera3D").global_position=Vector3(5.3,1.05,7.2);main.get_node("Camera3D").rotation=Vector3.ZERO;main.get_node("Camera3D").fov=35
	await capture("01_active_farm")
	for i in range(2,4):r.servo_run.defeat(1,i)
	check("targeted arm action explained",r._mission_objective()==TEXT.t("objective_servo_bearer"))
	r.servo_run.expose_servo(1,Vector3(8,.28,0))
	check("early drop distinguished from kill",r._mission_objective()==TEXT.t("objective_servo_exposed"))
	r.servo_run.defeat(1,4)
	for i in 4:r.servo_run.collect(1,i)
	check("remaining salvage points right",r._mission_objective()==TEXT.t("objective_servo_collect")%"→")
	p.global_position.x=10
	check("remaining salvage points left",r._mission_objective()==TEXT.t("objective_servo_collect")%"←")
	p.global_position.x=20
	check("main path objective outside room",r._farming_objective().is_empty())
	p.global_position=r.ENTRY_WORKBENCH_POS
	for i in range(4,6):r.servo_run.collect(1,i)
	r.shards=12;r.equipment.shards=12;r.equipment.prefixes.credit_servo(2)
	check("recipe available guidance",r._mission_objective()==TEXT.t("objective_servo_craft"))
	main.pause_controller.open_shop(r.workbench_state());await process_frame;await physics_frame;await process_frame
	var shop=main.pause_controller.shop
	check("recipe shows inventory versus cost",shop._servo_info.text.contains("12/12") and shop._servo_info.text.contains("2/2"))
	for misses in [0,3]:
		r.servo_run.bonus_misses=misses;shop.update_state(r.workbench_state())
		check("bonus deadline reflects saved pity",shop._trial_info.text.contains("in %d"%(4-misses)))
	for size in [Vector2i(1280,720),Vector2i(640,360)]:
		root.size=size;await process_frame;await process_frame
		check("trial explanation fits width",shop._trial_info.get_theme_font("font").get_string_size(shop._trial_info.text,HORIZONTAL_ALIGNMENT_LEFT,-1,shop._trial_info.get_theme_font_size("font_size")).x<=shop._trial_info.size.x)
		await capture("02_workbench_"+str(size.x))
	paused=false;main.queue_free();await create_timer(.3).timeout
	print("GUIDANCE SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
