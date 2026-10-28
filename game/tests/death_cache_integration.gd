extends SceneTree
## Farming policy: retain collected resources. Old caches remain reclaimable once.
var main:Node3D
var route:Node3D
var player:CharacterBody3D
var failures:=0
var checks:=0
func _initialize():Engine.max_fps=120;call_deferred("run")
func check(label:String,ok:bool):
	checks+=1
	if not ok:failures+=1
	print("FARM DEATH ","PASS " if ok else "FAIL ",label)
func load_scene():
	main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	route=main.route;player=main.player
	for e in route.enemies:e.set_physics_process(false)
	for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
	main.pause_controller.set_process_input(false);main.pause_controller.resume()
	await create_timer(.2).timeout
	player.set_physics_process(false)
func kill_player():
	player._iframes=0;player.take_damage(99,player.global_position+Vector3.LEFT)
func respawn():await create_timer(2.7,true,false,true).timeout  # ragdoll beat + respawn (main.gd 2.4 s)
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	await load_scene()
	route._equip_armor(false);route._equip_shield(false)
	route.checkpoint=true;main.spawn_point=route.checkpoint_pos
	route.cleared=["first"];route.shortcut_open=true;route.shards=12
	route.equipment.prefixes.credit_servo(2)
	route.servo_run.begin(107);route.servo_run.defeat(1,0)
	# Do not spawn the unfinished trial while this test drives actual death signals.
	route.servo_trial.set_process(false)
	kill_player()
	check("actual death retains collected resources",route.shards==12 and route.equipment.prefixes.servo==2 and not route.death_cache.is_active())
	check("pending reward survives",not route.servo_run.pending(1,0).is_empty())
	main._on_player_died()
	check("duplicate death hook never credits or subtracts",route.shards==12 and route.equipment.prefixes.servo==2)
	await respawn()
	check("respawn restores health at checkpoint",not player._dying and player.hp==player.max_hp and player.global_position.distance_to(main.spawn_point)<.1)
	check("equipment and progress retained",route.armor and route.shield and route.shortcut_open and "first" in route.cleared)
	# Compatibility with a cache earned under the old policy.
	route.death_cache.replace(5,Vector3(31,0,0));route._refresh_cache_marker();route._save_progress()
	kill_player()
	check("new death does not erase old cache",route.shards==12 and route.death_cache.amount()==5)
	check("dying player cannot claim old cache",not route.reclaim_shards())
	await respawn()
	check("remote cache claim refused",not route.reclaim_shards())
	player.global_position=Vector3(31,0,0)
	Input.action_press("interact");await process_frame;await process_frame;Input.action_release("interact")
	check("old cache recovered once through real interaction",route.shards==17 and not route.death_cache.is_active())
	check("duplicate claim cannot mint currency",not route.reclaim_shards() and route.shards==17)
	main.queue_free();await process_frame;await process_frame
	await load_scene();route.servo_trial.set_process(false)
	check("reload preserves wallet and servos",route.shards==17 and route.equipment.prefixes.servo==2)
	check("reload preserves pending trial group",route.servo_run.run_id==1 and not route.servo_run.pending(1,0).is_empty())
	check("reload retains consumed old cache",not route.death_cache.is_active())
	player.global_position=Vector3(40,-9,0);await process_frame;await process_frame
	check("fall death also retains resources",route.shards==17 and route.equipment.prefixes.servo==2 and not route.death_cache.is_active())
	await respawn()
	var prior=FileAccess.get_file_as_string(route.SAVE_PATH)
	DirAccess.make_dir_absolute(route.SAVE_PATH+".tmp")
	kill_player()
	check("failed save reported and original bytes preserved",route.save_error and FileAccess.get_file_as_string(route.SAVE_PATH)==prior)
	check("failed save does not subtract live resources",route.shards==17 and route.equipment.prefixes.servo==2)
	DirAccess.remove_absolute(route.SAVE_PATH+".tmp");await respawn();route._save_progress()
	var disk=JSON.parse_string(FileAccess.get_file_as_string(route.SAVE_PATH))
	check("retry persists entire state",not route.save_error and disk.shards==17 and disk.equipment.prefixes.materials.servo==2 and disk.death_cache.amount==0)
	main.queue_free();await create_timer(.3).timeout
	print("FARM DEATH SUMMARY checks=%d failures=%d"%[checks,failures]);quit(1 if failures else 0)
