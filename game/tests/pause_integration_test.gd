extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V28 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t,true,false,true).timeout
func escape()->void:
	var key:=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.keycode=KEY_ESCAPE;key.pressed=true
	Input.parse_input_event(key)
	key=InputEventKey.new();key.physical_keycode=KEY_ESCAPE;key.keycode=KEY_ESCAPE;key.pressed=false;Input.parse_input_event(key)
func run()->void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var main=get_parent();var route=main.route;var p=main.player;var ctl=main.pause_controller
	reparent(get_tree().root)
	await wait(0.2)
	route.checkpoint=true;route.shards=9;route._equip_shield(false);route._save_progress()
	var saved:=FileAccess.get_file_as_string("user://rendrun_route_v12.json")
	Input.action_press("move_right");Input.action_press("attack");await wait(0.08)
	escape();await wait(0.05)
	check("Escape pauses and opens menu",get_tree().paused and ctl.menu.visible)
	check("gameplay input released",not Input.is_action_pressed("attack") and not Input.is_action_pressed("move_right"))
	check("Continue receives focus",get_viewport().gui_get_focus_owner()==ctl.menu._btn_resume)
	var pos:Vector3=p.global_position;var foe=route.enemies[0];var timer:float=foe._state_t
	await wait(0.3)
	check("player and AI frozen",p.global_position==pos and foe._state_t==timer)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(OS.get_environment("V28_OUTPUT")+"/pause.png")
	ctl.menu._btn_restart.pressed.emit();await wait(0.03)
	check("restart requires confirmation",get_tree().current_scene==main and get_tree().paused and ctl.menu.is_confirming())
	ctl.menu._btn_back.pressed.emit();await wait(0.03)
	check("cancel preserves scene and save",get_tree().current_scene==main and FileAccess.get_file_as_string("user://rendrun_route_v12.json")==saved)
	Input.action_press("attack");ctl.menu._btn_resume.pressed.emit();await wait(0.05)
	check("resume clears paused inputs",not get_tree().paused and not ctl.menu.visible and not Input.is_action_pressed("attack"))
	var pad:=InputEventJoypadButton.new();pad.button_index=JOY_BUTTON_START;pad.pressed=true;Input.parse_input_event(pad)
	await wait(0.03)
	check("controller Start pauses",get_tree().paused and ctl.menu.visible)
	escape();await wait(0.03)
	check("Escape resumes",not get_tree().paused)
	main._on_player_died();await wait(0.1)
	saved=FileAccess.get_file_as_string("user://rendrun_route_v12.json")
	ctl.open_menu();var dead_pos:Vector3=p.global_position
	await wait(1.3)
	check("death respawn waits during pause",p._dying and p.global_position==dead_pos)
	ctl.menu._btn_restart.pressed.emit();ctl.menu._btn_reload.pressed.emit()
	await wait(0.4)
	var fresh=get_tree().current_scene
	check("confirmed restart reloads unpaused",fresh!=main and not get_tree().paused)
	print("V28 reload state checkpoint=%s shards=%d cache=%d shield=%s"%[fresh.route.checkpoint,fresh.route.shards,fresh.route.death_cache.amount(),fresh.player.shield_unlocked])
	# Farming v0.2: collected shards survive death; no reclaim cache is created.
	check("checkpoint equipment and shards survive death and reload",fresh.route.checkpoint and fresh.route.shards==9 and fresh.route.death_cache.amount()==0 and fresh.player.shield_unlocked)
	check("saved file unchanged",FileAccess.get_file_as_string("user://rendrun_route_v12.json")==saved)
	check("new scene menu hidden",not fresh.pause_controller.menu.visible)
	fresh.pause_controller.open_menu();fresh.pause_controller.menu._btn_quit.pressed.emit();fresh.pause_controller.menu.rows[1].node.pressed.emit()
	check("quit exits pause",fresh.pause_controller._leaving and not get_tree().paused)
	print("V28 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
