extends SceneTree
var failures:=0
var observations:Dictionary={}
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
	print("CALIBRATION ","PASS " if ok else "FAIL ",label)
	if not ok:failures+=1
func observe(cycle:SkeletonModifier3D):
	var sk=cycle.get_skeleton()
	var id=cycle.get_instance_id()
	var wrist=sk.global_transform*sk.get_bone_global_pose(sk.find_bone("LeftHand")).origin
	if not observations.has(id):observations[id]={"first":wrist,"travel":0.0,"samples":0,"foot_error":0.0}
	var stats=observations[id];stats.travel=maxf(stats.travel,stats.first.distance_to(wrist));stats.samples+=1
	for side in ["Left","Right"]:
		var foot=sk.find_bone(side+"Foot")
		var actual=sk.global_transform*sk.get_bone_global_pose(foot).origin
		var rest=sk.global_transform*sk.get_bone_global_rest(foot).origin
		stats.foot_error=maxf(stats.foot_error,actual.distance_to(rest))
func run():
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	root.content_scale_size=Vector2i(1280,720);root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP
	var scene=load("res://main.tscn").instantiate();root.add_child(scene);current_scene=scene
	await create_timer(.4).timeout;scene.pause_controller.resume()
	for foe in scene.route.enemies:foe.set_physics_process(false)
	scene.player.set_physics_process(false);scene.player.global_position=Vector3(4,.05,0)
	var cycles=scene.find_children("CalibrationCycle","SkeletonModifier3D",true,false)
	# Two first-room bays plus the assembly bays the factory corridor adds along the route.
	check("at least two calibration bays on the route", cycles.size()>=2)
	for cycle in cycles:cycle.modification_processed.connect(observe.bind(cycle))
	await create_timer(17.0).timeout
	for cycle in cycles:
		var stats=observations.get(cycle.get_instance_id(),{})
		var valid=not stats.is_empty() and stats.samples>100 and stats.travel>.04 and stats.travel<.5 and stats.foot_error<.001
		print("CALIBRATION ","PASS " if valid else "FAIL ",stats)
		if not valid:failures+=1
	scene.queue_free();for i in 8:await process_frame
	print("CALIBRATION SUMMARY failures=",failures)
	quit(1 if failures else 0)
