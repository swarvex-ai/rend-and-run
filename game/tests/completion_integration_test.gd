extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V30 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t,true,false,true).timeout
func escape()->void:
	var key:=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.pressed=true;Input.parse_input_event(key)
	key=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.pressed=false;Input.parse_input_event(key)
func run()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var main=get_parent();reparent(get_tree().root)
	var route=main.route;var p=main.player;var ctl=main.pause_controller
	for e in route.enemies:e.set_physics_process(false)
	p.global_position=Vector3(route.MISSION.EXIT_X+1,0.05,0);await wait(0.1)
	check("locked exit cannot complete",not route.completed and not ctl.summary.visible)
	for e in route.enemies:route._enemy_defeated(e)
	await wait(0.2)
	check("open exit completes and pauses",route.completed and get_tree().paused and ctl.summary.visible)
	check("summary uses actual loot",ctl.summary._val_shards.text==str(route.shards) and ctl.summary._val_guards.text=="%d / %d"%[route.MISSION.ENCOUNTERS.size(),route.MISSION.ENCOUNTERS.size()])
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12.json"))
	check("completion persisted",saved is Dictionary and saved.completed and ctl.summary._save_ok)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(OS.get_environment("V30_OUTPUT")+"/complete.png")
	escape();await wait(0.1)
	check("Escape safely resumes exploration",not get_tree().paused and not ctl.summary.visible)
	await wait(0.2)
	check("completion does not reopen every frame",not ctl.summary.visible and route.completed)
	ctl.show_completion({"save_ok":true});ctl.summary._btn_title.pressed.emit();await wait(0.3)
	var start=get_tree().current_scene
	check("return reaches title unpaused",start.scene_file_path=="res://start.tscn" and not get_tree().paused)
	start.menu._btn_continue.pressed.emit();await wait(0.3)
	main=get_tree().current_scene;route=main.route;p=main.player;ctl=main.pause_controller
	check("continue retains completion without modal loop",route.completed and not ctl.summary.visible and not get_tree().paused)
	for e in route.enemies:e.set_physics_process(false)
	route.completed=false
	var tmp:=ProjectSettings.globalize_path("user://rendrun_route_v12.json.tmp")
	DirAccess.make_dir_absolute(tmp)
	p.global_position=Vector3(route.MISSION.EXIT_X+1,0.05,0);await wait(0.2)
	check("real save failure shown",route.save_error and ctl.summary.visible and not ctl.summary._save_ok)
	ctl.summary._btn_title.pressed.emit();await wait(0.05)
	check("failed save exit requires confirmation",get_tree().current_scene==main and ctl.summary._confirm_box.visible)
	ctl.summary._btn_back.pressed.emit();await wait(0.05)
	check("cancel remains in session",get_tree().current_scene==main and ctl.summary._main_box.visible)
	DirAccess.remove_absolute(tmp)
	ctl.summary._btn_title.pressed.emit();ctl.summary._btn_leave.pressed.emit();await wait(0.3)
	check("explicit failure confirmation returns title",get_tree().current_scene.scene_file_path=="res://start.tscn" and not get_tree().paused)
	print("V30 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
