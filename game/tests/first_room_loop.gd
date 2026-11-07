extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
	print("FIRST ROOM ","PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func snap(label):
	if DisplayServer.get_name()=="headless" or OS.get_environment("LOOP_OUTPUT").is_empty():return
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OS.get_environment("LOOP_OUTPUT")+"/"+label+".png")
func scene():
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.3).timeout;main.pause_controller.resume()
	for enemy in main.route.enemies:enemy.set_physics_process(false)
	main.player.set_physics_process(false)
	return main
func run():
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=await scene();var r=main.route;var p=main.player
	p.global_position=r.ENTRY_WORKBENCH_POS;r._use_workbench()
	check("first bench locked while guard alive",not main.pause_controller.shop.visible)
	p.global_position=Vector3(1.3,.05,0);check("arm pickup",r.collect_start_arm() and p.weapon_id=="robot_arm")
	var foe=r.enemies[0];foe.global_position=Vector3(7.0,.05,0)
	p.global_position=Vector3(4.8,.05,0)
	foe.take_melee_hit(99,Vector3(3,0,0))
	await create_timer(.65).timeout
	check("guard death reveals uncredited salvage",r.shards==0 and r.pending_shards.get(r.FIRST_SALVAGE_ID)==3 and r.shard_pickups.has(r.FIRST_SALVAGE_ID))
	await snap("01_salvage")
	main.queue_free()
	for i in 6:await process_frame
	main=await scene();r=main.route;p=main.player
	check("reload preserves guard drop without respawn",r.pending_shards.get(r.FIRST_SALVAGE_ID)==3 and "first" in r.cleared and r.shards==0)
	p.global_position=r.first_salvage_position-Vector3(0,.28,0)
	await create_timer(.9).timeout
	check("guard salvage collected once",r.shards==3 and not r.pending_shards.has(r.FIRST_SALVAGE_ID))
	r._collect_shard_pickup(r.FIRST_SALVAGE_ID);check("duplicate reward rejected",r.shards==3)
	p.global_position=Vector3(4,.05,0)
	r.supply_crates[0].take_melee_hit(2,Vector3(1,0,0));await create_timer(.9).timeout
	check("guard plus crate affords existing six-splitter upgrade",r.shards==6)
	p.global_position=r.ENTRY_WORKBENCH_POS;p._attack_phase=0;p._dash_left=0
	await create_timer(.8).timeout;r._use_workbench();await process_frame
	check("first room workbench opens after fight",main.pause_controller.shop.visible and paused)
	for i in 3:await process_frame
	var shop=main.pause_controller.shop
	check("upgrade details do not overlap purchase button",shop._vibro_info.get_global_rect().end.x<shop._vibro_action.get_global_rect().position.x)
	await snap("02_upgrade_menu")
	r.apply_workbench_action("reinforced_arm");await process_frame
	check("upgrade purchases exactly six",r.shards==0 and r.equipment.owns("reinforced_arm"))
	r.apply_workbench_action("reinforced_arm");await process_frame
	check("upgrade equips visible reinforcement",p.weapon_id=="reinforced_arm" and p._heavy_model.visible and not p._starter_model.visible)
	main.pause_controller.resume();await create_timer(.6).timeout;await snap("03_upgraded")
	main.queue_free()
	for i in 6:await process_frame
	main=await scene();r=main.route;p=main.player
	check("reload retains upgrade without duplicate drops",p.weapon_id=="reinforced_arm" and r.shards==0 and r.pending_shards.is_empty() and r.supply_crates[0].is_broken())
	p.global_position=r.workbench_pos;r._use_workbench();check("later workbench still available",main.pause_controller.shop.visible);main.pause_controller.resume()
	var legacy=load("res://lab_route.gd").new()
	legacy._restore_progress({"version":12,"layout_revision":2,"economy_revision":1,"cleared":["first"],"shards":3})
	check("legacy credited kill does not create second reward",legacy.shards==3 and legacy.pending_shards.is_empty());legacy.free()
	var bad=load("res://lab_route.gd").new()
	bad._restore_progress({"version":12,"layout_revision":2,"economy_revision":1,"cleared":["first"],"pending_shards":{"enemy_first":3},"first_salvage_position":[999,.28,0]})
	check("invalid saved drop position rejected",bad.pending_shards.is_empty());bad.free()
	main.queue_free();for i in 8:await process_frame
	print("FIRST ROOM SUMMARY failures=",failures);quit(1 if failures else 0)
