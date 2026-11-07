extends SceneTree
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool) -> void:
	print("MECHANICAL ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func capture(label):
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("ENEMY_OUTPUT")+"/"+label+".png")
func run():
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var foe=main.route.enemies[0]
	for enemy in main.route.enemies:enemy.set_physics_process(false)
	main.player.set_physics_process(false);main.player.global_position=Vector3(1,.05,0)
	foe.global_position=Vector3(3,.05,0);foe.get_node("VisualPivot").rotation.y=PI
	check("foe is mechanical", foe._mechanical);check("foe has a weapon pivot", foe._weapon_pivot!=null)
	for clip in ["combat/idle","combat/slash_light","run","combat/hit_react"]:
		foe._anim.play(clip);foe._anim.advance(0);foe._anim.pause()
		foe._anim.seek(.25,true);foe._anim.advance(0)
		await capture(clip.replace("/","_"))
	foe._die(Vector3(3,3,0) if OS.get_environment("FINISHER")=="1" else Vector3(3,0,0));await create_timer(.8).timeout
	await capture("collapse")
	print("MECHANICAL blood_events=",root.get_node("FX").fx_stats["blood"]," pools=",root.get_node("FX").fx_stats["pool"])
	check("mechanical death emits no blood or pools", root.get_node("FX").fx_stats["blood"]==0 and root.get_node("FX").fx_stats["pool"]==0)
	main.queue_free();await process_frame;await process_frame
	print("MECHANICAL SUMMARY failures=", failures)
	quit(1 if failures else 0)
