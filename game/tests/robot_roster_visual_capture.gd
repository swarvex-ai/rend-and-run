extends SceneTree
# Vision 2.0 roster check: every route opponent is a mechanical humanoid and never bleeds.
# ROSTER_OUTPUT=<dir> stores idle/slash/collapse captures per role; run windowed with isolated XDG_DATA_HOME.
func _initialize():call_deferred("run")
func capture(label):
	var out:=OS.get_environment("ROSTER_OUTPUT")
	if out.is_empty():return
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+label+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var fx=root.get_node("FX");var failures:=0;var seen:={}
	for enemy in main.route.enemies:enemy.set_physics_process(false)
	main.player.set_physics_process(false)
	for foe in main.route.enemies:
		if not foe._mechanical:
			failures+=1;print("FAIL not_mechanical ",foe.encounter_id)
		if foe.role in seen:continue
		seen[foe.role]=true
		main.player.global_position=Vector3(foe.global_position.x-2.0,.05,0)
		foe.get_node("VisualPivot").rotation.y=PI
		await create_timer(1.5).timeout  # let the follow camera settle on the new position
		for clip in ["combat/idle","combat/slash_light"]:
			foe._anim.play(clip);foe._anim.advance(0);foe._anim.pause()
			foe._anim.seek(.25,true);foe._anim.advance(0)
			await capture("role%d_%s"%[foe.role,clip.get_file()])
		fx.fx_stats["blood"]=0;fx.fx_stats["pool"]=0
		foe._die(Vector3(3,0,0));await create_timer(.8).timeout
		await capture("role%d_collapse"%foe.role)
		if fx.fx_stats["blood"]!=0 or fx.fx_stats["pool"]!=0:
			failures+=1;print("FAIL bled role=",foe.role," blood=",fx.fx_stats["blood"]," pools=",fx.fx_stats["pool"])
		else:print("PASS role=",foe.role," mechanical, no blood")
	if seen.size()<4:
		failures+=1;print("FAIL roles_seen=",seen.keys())
	print("ROSTER SUMMARY roles=",seen.size()," failures=",failures)
	main.queue_free();await process_frame;await process_frame;quit(0 if failures==0 else 1)
