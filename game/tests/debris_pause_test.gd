extends SceneTree
var failures:=0
func check(label:String,ok:bool):
	if not ok:failures+=1
	print("DEBRIS PAUSE ","PASS " if ok else "FAIL ",label)
func _initialize():Engine.max_fps=120;call_deferred("run")
func run():
	var body=RigidBody3D.new();body.gravity_scale=0;body.linear_damp=0;body.angular_damp=0;body.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE
	var shape=CollisionShape3D.new();shape.shape=SphereShape3D.new();body.add_child(shape)
	body.add_child(preload("res://modules/combat/debris_pause.gd").new());root.add_child(body)
	body.linear_velocity=Vector3(1,0,0)
	await create_timer(.1).timeout
	for i in 5:
		paused=true;await process_frame;await process_frame
		var at:Vector3=body.global_position
		await create_timer(.1).timeout
		check("frozen while menu open %d"%i,body.freeze and body.global_position.distance_to(at)<.001)
		paused=false;await process_frame;await create_timer(.15).timeout
		check("motion restored %d"%i,not body.freeze and body.global_position.x>at.x+.05 and body.linear_velocity.is_equal_approx(Vector3.RIGHT))
	body.freeze=true;paused=true;await create_timer(.1).timeout;paused=false;await create_timer(.1).timeout
	check("originally frozen body remains frozen",body.freeze)
	body.queue_free();await process_frame
	print("DEBRIS PAUSE SUMMARY failures=",failures);quit(1 if failures else 0)
