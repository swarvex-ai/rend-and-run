extends SceneTree
## Stable real-Godot art review: fixed gameplay-plane framing and settled temporal history.
func _initialize():call_deferred("run")
func run():
	assert(OS.get_user_data_dir().begins_with("/tmp/"))
	var output:=OS.get_environment("TOUR_OUTPUT")
	assert(not output.is_empty())
	root.content_scale_size=Vector2i(1280,720)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	if OS.get_environment("FACTORY_BASELINE_LENS")=="1":
		main.first_room_closeup=false
		main.follow_offset.z=5.8;main.get_node("Camera3D").fov=55.0
	for enemy in main.route.enemies:
		enemy.set_physics_process(false)
		if enemy._anim:
			enemy._anim.play("combat/idle",0);enemy._anim.advance(.3);enemy._anim.pause()
	var p=main.player;p.set_physics_process(false)
	# TOUR_XS="0,6,12" overrides the stops, e.g. for a full-route review.
	var stops:=[4.0,8.0,10.0,28.5,40.0,58.0]
	if not OS.get_environment("TOUR_XS").is_empty():
		stops=Array(OS.get_environment("TOUR_XS").split(",")).map(func(v):return float(v))
	for x in stops:
		p.global_position=Vector3(x,.05,0)
		p._hero_anim.play("idle",0);p._hero_anim.advance(.3);p._hero_anim.pause()
		await create_timer(1.5).timeout
		# An inactive window may skip normal draws. One force_draw leaves stale
		# TAA/SSR history and produces false speckles/ghosts in material reviews.
		for frame in 48:
			RenderingServer.force_draw(false,1.0/60.0)
			await process_frame
		assert(root.get_texture().get_image().save_png(output+"/room_%02d.png"%int(x))==OK)
	main.queue_free()
	for frame in 8:await process_frame
	quit()
