extends SceneTree
var failures:=0
var checks:=0
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("PREFIX TX ","PASS " if ok else "FAIL ",label)
func _initialize():
	Engine.max_fps=120
	call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player;p.set_physics_process(false)
	for e in r.enemies:e.set_physics_process(false)
	r.equipment.grant("robot_arm");r.equipment.equip_weapon("robot_arm")
	r.equipment.credit(18);r.equipment.purchase("reinforced_arm")
	r.equipment.prefixes.credit_servo(2);r.shards=r.equipment.shards
	p.global_position=r.workbench_pos;p._attack_phase=0;p._dash_left=0
	r._save_progress()
	var old_bytes=FileAccess.get_file_as_bytes(r.SAVE_PATH)
	check("closed shop refuses transaction",r.apply_prefix_action("servo_i").reason=="not_at_workbench")
	main.pause_controller.open_shop(r.workbench_state())
	p._attack_phase=1;check("attack refuses transaction",r.apply_prefix_action("servo_i").reason=="busy");p._attack_phase=0
	var before=r.equipment.export_state()
	DirAccess.make_dir_absolute(r.SAVE_PATH+".tmp")
	check("disk failure reported",r.apply_prefix_action("servo_i").reason=="save_failed")
	check("failure restores materials and module ownership",before==r.equipment.export_state() and r.shards==12)
	check("disk remains original",FileAccess.get_file_as_bytes(r.SAVE_PATH)==old_bytes)
	DirAccess.remove_absolute(r.SAVE_PATH+".tmp")
	check("retry succeeds exactly once",r.apply_prefix_action("servo_i").ok and r.shards==0 and r.equipment.prefixes.servo==0)
	check("repeat cannot charge twice",r.apply_prefix_action("servo_i").reason=="already_owned")
	DirAccess.make_dir_absolute(r.SAVE_PATH+".tmp")
	check("failed installation rolled back",r.apply_prefix_action("servo_i",true).reason=="save_failed" and r.equipment.prefixes.installed("reinforced_arm").is_empty())
	DirAccess.remove_absolute(r.SAVE_PATH+".tmp")
	check("installation persists",r.apply_prefix_action("servo_i",true).ok)
	var fresh=load("res://lab_route.gd").new();fresh._load_progress()
	check("real route reload",fresh.equipment.prefixes.installed("reinforced_arm")=="servo_i" and fresh.shards==0 and fresh.equipment.prefixes.servo==0)
	fresh.free()
	paused=false;main.queue_free()
	await create_timer(.2).timeout
	print("PREFIX TX SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
