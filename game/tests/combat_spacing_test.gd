extends SceneTree
# Push-box spacing: Rend pressing into a robot while trading blows never hugs it.
# Bodies stay at weapon distance (>= ~1 m centre to centre) instead of overlapping.
func _initialize():call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player;var r=main.route;var foe=r.enemies[0]
	for e in r.enemies:if e!=foe:e.set_physics_process(false)
	foe.hp=99;p.max_hp=99;p.hp=99;p.equip_weapon("robot_arm")
	p.global_position=Vector3(foe.global_position.x-4.0,.05,foe.global_position.z)
	var close:=0;var frames:=0;var closest:=99.0
	for i in 480:
		await physics_frame
		var dx:float=foe.global_position.x-p.global_position.x
		if absf(dx)>1.25:Input.action_press("move_right" if dx>0 else "move_left")
		else:Input.action_release("move_right");Input.action_release("move_left")
		if absf(dx)<1.6 and i%20==0:Input.action_press("attack")
		if i%20==3:Input.action_release("attack")
		if i<60 or absf(foe.global_position.z-p.global_position.z)>=foe.PUSH_DEPTH:continue
		frames+=1;closest=minf(closest,absf(dx))
		if absf(dx)<0.9:close+=1
	Input.action_release("move_right");Input.action_release("move_left")
	var ok:bool=frames>200 and close<=frames*0.05 and foe.hits_taken>0
	print("SPACING %s frames=%d under_0.9m=%d closest=%.2f hits=%d"%["PASS" if ok else "FAIL",frames,close,closest,foe.hits_taken])
	main.queue_free();for i in 4:await process_frame
	quit(0 if ok else 1)
