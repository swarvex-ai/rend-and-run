extends SceneTree
## UX Q4: R is reload only; the route-restart shortcut in play is gone.
## A real R key press must not pause the tree, open the pause menu or its
## restart confirmation; restart stays under Pause -> "To checkpoint".
var failures:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
	print("RELOADKEY %s %s"%["PASS" if ok else "FAIL",label])
	if not ok:failures+=1
func run()->void:
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(0.2).timeout
	var key:=InputEventKey.new();key.physical_keycode=KEY_R;key.keycode=KEY_R;key.pressed=true
	Input.parse_input_event(key)
	key=InputEventKey.new();key.physical_keycode=KEY_R;key.keycode=KEY_R;key.pressed=false
	Input.parse_input_event(key)
	await process_frame
	await process_frame
	await process_frame
	check("R does not pause the game",not paused)
	check("R does not open the pause menu",not main.pause_controller.menu.visible)
	check("R opens no restart confirmation",not main.pause_controller.menu.is_confirming() and main.pause_controller.menu.confirm_id=="")
	main.pause_controller.open_menu()
	await process_frame
	var checkpoint_row:=false
	for r in main.pause_controller.menu.rows:
		if r.id=="restart":checkpoint_row=true
	check("pause menu keeps the To checkpoint row",checkpoint_row)
	main.pause_controller.resume()
	print("RELOADKEY SUMMARY failures=",failures);quit(1 if failures else 0)
