extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
	print("REWARDS ","PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func interact():
	Input.action_press("interact");await create_timer(.1).timeout
	Input.action_release("interact");await create_timer(.1).timeout
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout;main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
	p.global_position=Vector3(18,0,0);p.velocity=Vector3.ZERO;await create_timer(.15).timeout
	await interact();check("armor can be taken from the floor behind the maintenance door",r.equipment.owns("lab_armor"))
	p.global_position=Vector3(24,0,0);p.velocity=Vector3.ZERO;await create_timer(.2).timeout
	check("shield is on main floor before workbench",p.is_on_floor() and r.shield_pos.y==0 and r.shield_pos.x<r.workbench_pos.x)
	if DisplayServer.get_name()!="headless":
		root.size=Vector2i(960,540);main.get_node("Camera3D").global_position=Vector3(24,1.6,6)
		await process_frame;RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(OS.get_environment("REWARD_OUTPUT")+"/main-route-shield.png")
	await interact();check("main route shield collected through actual input",r.shield and r.equipment.owns("salvage_shield") and p.shield_unlocked)
	check("free shield does not consume upgrade budget",r.shards==0)
	quit(1 if failures else 0)
