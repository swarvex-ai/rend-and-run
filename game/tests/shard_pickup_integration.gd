extends SceneTree
var failures:=0
var checks:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("PICKUP ","PASS " if ok else "FAIL ",label)
func wait(t:float):await create_timer(t).timeout
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await wait(.3);main.pause_controller.resume();main.set_process(false)
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
	p.global_position=Vector3(1,0,0);p.velocity=Vector3.ZERO
	r.supply_crates[0].take_melee_hit(2,Vector3.ZERO);await wait(.55)
	check("break has visible reward before credit",r.shards==0 and r.pending_shards.get("entry_supply")==3 and is_instance_valid(r.shard_pickups.get("entry_supply")))
	if DisplayServer.get_name()!="headless":
		root.size=Vector2i(960,540);main.get_node("Camera3D").global_position=Vector3(3.3,1.2,5.2)
		await process_frame;RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(OS.get_environment("PICKUP_OUTPUT")+"/visible-drop.png")
	# Real scene reload reconstructs the pending visual from the saved state.
	main.free()
	main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await wait(.3);main.pause_controller.resume();main.set_process(false)
	r=main.route;p=main.player
	for e in r.enemies:e.set_physics_process(false);e.hide();e.collision_layer=0
	check("scene reload reconstructs uncollected drop",r.shards==0 and r.supply_crates[0].is_broken() and r.shard_pickups.has("entry_supply"))
	r.shards=2;r.on_player_death()
	check("death preserves uncollected reward separately",r.pending_shards.get("entry_supply")==3 and r.shards==0 and r.death_cache.amount()==2)
	p.global_position=Vector3(3.3,0,0);p.velocity=Vector3.ZERO;p.set_physics_process(false)
	var wall:=StaticBody3D.new();wall.collision_layer=1
	var col:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.15,2,2);col.shape=box;wall.add_child(col)
	main.add_child(wall);wall.global_position=Vector3(3.65,.9,0)
	await wait(.7);check("nearby drop does not pass through walls",r.shards==0)
	wall.queue_free();await physics_frame
	p.global_position=Vector3(4,2,0)
	await wait(.6)
	check("cannot collect from another elevation",r.shards==0)
	p.global_position=Vector3(4,0,0);p._dying=true
	await wait(.6);check("dead player cannot collect",r.shards==0)
	p._dying=false
	var sounds:int=root.get_node("FX").audio_events.get("footstep_metal_b",0)
	await wait(.8)
	check("nearby living player attracts reward",r.shards==3 and r.pending_shards.is_empty() and r.shard_pickups.is_empty())
	check("pickup emits metal sound",root.get_node("FX").audio_events.get("footstep_metal_b",0)>sounds)
	r._collect_shard_pickup("entry_supply");check("duplicate completion never credits twice",r.shards==3)
	var data=JSON.parse_string(FileAccess.get_file_as_string(r.SAVE_PATH))
	check("saved collection and pending removal are atomic",data.shards==3 and data.pending_shards.is_empty() and "entry_supply" in data.broken_crates)
	var legacy=load("res://lab_route.gd").new()
	legacy._restore_progress({"version":12,"economy_revision":1,"shards":3,"broken_crates":["entry_supply"]})
	check("legacy rewarded crate generates no second drop",legacy.shards==3 and legacy.pending_shards.is_empty())
	legacy._restore_progress({"version":12,"economy_revision":1,"broken_crates":["entry_supply"],"pending_shards":{"entry_supply":-2,"unknown":9,"exit_supply":3}})
	check("invalid or unbroken crate records rejected",legacy.pending_shards.is_empty());legacy.free()
	print("PICKUP SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
