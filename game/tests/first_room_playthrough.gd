extends SceneTree
var p:CharacterBody3D
func _initialize():call_deferred("run")
func walk(x:float):
	for i in 360:
		var dx:float=x-p.global_position.x
		Input.action_release("move_right");Input.action_release("move_left")
		if absf(dx)<.12:break
		Input.action_press("move_right" if dx>0 else "move_left")
		await physics_frame
	Input.action_release("move_right");Input.action_release("move_left")
	for i in 12:await physics_frame
func tap(action:String):
	Input.action_press(action);await process_frame;await process_frame;Input.action_release(action)
func snap(label):
	if DisplayServer.get_name()=="headless" or OS.get_environment("LOOP_OUTPUT").is_empty():return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OS.get_environment("LOOP_OUTPUT")+"/"+label+".png")
func run():
	assert(OS.get_user_data_dir().begins_with("/tmp/"))
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout
	for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
	main.pause_controller.set_process_input(false);main.pause_controller.resume()
	p=main.player;var r=main.route;var foe=r.enemies[0]
	await walk(1.3);await tap("interact")
	for i in 900:
		await physics_frame
		if foe._dead or p._dying:break
		var dx:float=foe.global_position.x-p.global_position.x
		Input.action_release("move_left");Input.action_release("move_right")
		if absf(dx)>.7:Input.action_press("move_right" if dx>0 else "move_left")
		if i%16==0:Input.action_press("attack")
		elif i%16==2:Input.action_release("attack")
	for action in ["attack","move_right","move_left"]:Input.action_release(action)
	assert(foe._dead and not p._dying)
	await walk(3.4)
	Input.action_press("move_right");await physics_frame;Input.action_release("move_right")
	Input.action_press("crouch")
	for i in 6:await physics_frame
	for i in 180:
		if r.supply_crates[0].is_broken():break
		if i%45==0:Input.action_press("attack")
		elif i%45==2:Input.action_release("attack")
		await physics_frame
	Input.action_release("attack");Input.action_release("crouch")
	print("CRATE CONTACT x=",p.global_position," hp=",r.supply_crates[0]._hp," crouch=",p.crouching)
	assert(r.supply_crates[0].is_broken())
	await walk(4);await create_timer(.8).timeout
	if r.pending_shards.has(r.FIRST_SALVAGE_ID):
		await walk(r.first_salvage_position.x);await create_timer(.8).timeout
	assert(r.shards==6)
	await walk(r.ENTRY_WORKBENCH_POS.x);await create_timer(.5).timeout
	await snap("04_workbench_ready")
	await tap("interact");await process_frame
	var shop=main.pause_controller.shop;assert(shop.visible and not shop._vibro_action.disabled)
	await snap("05_upgrade_menu_final")
	shop._vibro_action.pressed.emit();await process_frame
	shop._vibro_action.pressed.emit();await process_frame
	assert(p.weapon_id=="reinforced_arm" and r.shards==0)
	main.pause_controller.resume()
	await create_timer(.5).timeout;await snap("06_upgrade_equipped")
	print("FIRST ROOM PLAYTHROUGH PASS: input pickup, combat, crate, six salvage, workbench purchase/equip; hp=",p.hp)
	main.queue_free();for i in 8:await process_frame
	quit()
