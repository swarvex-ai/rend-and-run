extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V29 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t,true,false,true).timeout
func title()->Node:
	get_tree().change_scene_to_file("res://start.tscn");await wait(0.3)
	return get_tree().current_scene
func run()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var start=get_parent();reparent(get_tree().root);await wait(0.2)
	check("fresh start has no game actors",get_tree().get_nodes_in_group("player").is_empty())
	check("continue disabled without save",start.menu._btn_continue.disabled)
	check("fresh focus on new round",start.menu.focused_id()=="new_run")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(OS.get_environment("V29_OUTPUT")+"/start.png")
	Input.action_press("jump");start.menu._btn_new_run.pressed.emit();await wait(0.4)
	var main=get_tree().current_scene
	check("new round enters unpaused game",main.has_node("Player") and not get_tree().paused)
	check("menu activation input released",not Input.is_action_pressed("jump"))
	main.route.checkpoint=true;main.route.shards=21;main.route._equip_shield(false);main.route._save_progress()
	var saved:=FileAccess.get_file_as_string("user://rendrun_route_v12.json")
	start=await title()
	check("saved continue enabled",not start.menu._btn_continue.disabled)
	check("title leaves save unchanged",FileAccess.get_file_as_string("user://rendrun_route_v12.json")==saved)
	start.menu._btn_continue.pressed.emit();await wait(0.4)
	main=get_tree().current_scene
	check("continue restores equipment and checkpoint",main.route.checkpoint and main.route.shards==21 and main.player.shield_unlocked)
	start=await title();start.menu._btn_new_run.pressed.emit();await wait(0.05)
	check("existing save requires confirmation",start.menu.focused_id()=="confirm_new_run" and get_tree().current_scene==start)
	start.menu._btn_back.pressed.emit();await wait(0.05)
	check("cancel preserves progress",FileAccess.get_file_as_string("user://rendrun_route_v12.json")==saved)
	start.menu._btn_new_run.pressed.emit();start.menu._btn_confirm_new.pressed.emit();await wait(0.4)
	main=get_tree().current_scene
	check("confirmed new round resets route",not main.route.checkpoint and main.route.shards==0 and not main.player.shield_unlocked)
	check("previous save backup exact",FileAccess.get_file_as_string("user://rendrun_route_v12.json.previous")==saved)
	var f:=FileAccess.open("user://rendrun_route_v12.json",FileAccess.WRITE);f.store_string("broken JSON");f.close()
	start=await title()
	check("corrupt save disables continue with explanation",start.menu._btn_continue.disabled and not start.notice.text.is_empty())
	start.menu._btn_new_run.pressed.emit()
	check("corrupt save still requires replacement confirmation",start.menu.focused_id()=="confirm_new_run")
	print("V29 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
