extends SceneTree
# The maintenance door has no puzzle: walking up to it opens it, in any depth lane,
# and the playtest jump (Page Down) reaches the next living encounter.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("DOOR %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	check("door starts closed",not r.shortcut_open and not r.shortcut.is_open())
	p.global_position=Vector3(r.shortcut_pos.x-3.0,.05,1.0)
	Input.action_press("move_right");await create_timer(1.6).timeout;Input.action_release("move_right")
	check("walking up opens it in a side lane",r.shortcut_open and r.shortcut.is_open(),"x=%.2f"%p.global_position.x)
	await create_timer(1.0).timeout
	Input.action_press("move_right");await create_timer(0.8).timeout;Input.action_release("move_right")
	check("Rend walks through",p.global_position.x>r.shortcut_pos.x+0.5,"x=%.2f"%p.global_position.x)
	var key:=InputEventKey.new();key.keycode=KEY_PAGEDOWN;key.pressed=true
	var before:float=p.global_position.x
	r._unhandled_key_input(key)
	var near:Array=r.enemies.filter(func(e):return is_instance_valid(e) and not e._dead and e.global_position.x-p.global_position.x>3.0 and e.global_position.x-p.global_position.x<5.0)
	check("playtest jump lands just before the next encounter",p.global_position.x>before and not near.is_empty(),"x=%.2f"%p.global_position.x)
	print("DOOR SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
