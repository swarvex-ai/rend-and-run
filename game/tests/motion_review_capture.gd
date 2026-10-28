extends SceneTree
# Contact sheets for animation review: every clip of a library at four phases.
# MOTION_TARGET=res://... character, MOTION_LIBRARY=res://....tres, MOTION_OUTPUT=<dir>,
# MOTION_YAW=<radians> to face the camera. Windowed; writes <clip>.png per clip.
func _initialize():call_deferred("run")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var out:=OS.get_environment("MOTION_OUTPUT")
	root.size=Vector2i(1280,720)
	var world:=Node3D.new();root.add_child(world)
	var env:=WorldEnvironment.new();env.environment=Environment.new()
	env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color(.12,.13,.15)
	env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color(.5,.52,.55)
	world.add_child(env)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,30,0);world.add_child(sun)
	var floor:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(20,6);floor.mesh=plane;world.add_child(floor)
	var cam:=Camera3D.new();cam.position=Vector3(0,1.0,6.2);cam.fov=40;world.add_child(cam);cam.current=true
	var library:AnimationLibrary=load(OS.get_environment("MOTION_LIBRARY"))
	var actors:=[]
	for i in 4:
		var actor:Node3D=load(OS.get_environment("MOTION_TARGET")).instantiate()
		actor.position=Vector3(-2.7+i*1.8,0,0);actor.rotation.y=float(OS.get_environment("MOTION_YAW"))
		world.add_child(actor);actors.append(actor)
		var player:AnimationPlayer=actor.find_child("AnimationPlayer",true,false)
		player.add_animation_library("review",library)
	for clip in library.get_animation_list():
		var length:=library.get_animation(clip).length
		for i in 4:
			var player:AnimationPlayer=actors[i].find_child("AnimationPlayer",true,false)
			player.play("review/"+clip);player.seek(length*(i+.5)/4.0,true);player.pause()
		for f in 4:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out+"/"+clip+".png")
	quit()
