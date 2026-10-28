extends SceneTree
func _initialize():call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout
	for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
	main.pause_controller.set_process_input(false);main.pause_controller.resume()
	var p=main.player;var r=main.route;var foe=r.enemies[0]
	Input.action_press("move_right")
	for i in 180:
		await physics_frame
		if p.global_position.x>=1.3:break
	Input.action_release("move_right")
	Input.action_press("interact");await process_frame;await process_frame;Input.action_release("interact")
	for i in 900:
		await physics_frame
		if foe._dead or p._dying:break
		var dx:float=foe.global_position.x-p.global_position.x
		Input.action_release("move_left");Input.action_release("move_right")
		if absf(dx)>.7:Input.action_press("move_right" if dx>0 else "move_left")
		if i%16==0:Input.action_press("attack")
		elif i%16==2:Input.action_release("attack")
	for action in ["attack","move_right","move_left"]:Input.action_release(action)
	var ok:bool=p.weapon_id=="robot_arm" and foe._dead and not p._dying
	print("ARM FIRST FIGHT ","PASS" if ok else "FAIL"," weapon=",p.weapon_id," hp=",p.hp," enemy_hp=",foe.hp," x=",p.global_position.x)
	main.queue_free();await process_frame;await process_frame;quit(0 if ok else 1)
