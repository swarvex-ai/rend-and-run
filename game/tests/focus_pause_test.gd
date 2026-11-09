extends SceneTree
## E11.7a: losing window focus pauses gameplay and opens the pause menu.
var failures:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
	print("FOCUS %s %s"%["PASS" if ok else "FAIL",label])
	if not ok:failures+=1
func run()->void:
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(0.2).timeout
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	check("focus loss pauses the game",paused and main.pause_controller.menu.visible)
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	await process_frame
	check("focus gain does not resume",paused and main.pause_controller.menu.visible)
	main.pause_controller.resume()
	await create_timer(0.05).timeout
	main.pause_controller.open_equipment()
	await process_frame
	main.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await process_frame
	check("open panel is kept",main.pause_controller.equipment_menu.visible and not main.pause_controller.menu.visible)
	print("FOCUS SUMMARY failures=",failures);quit(1 if failures else 0)
