extends SceneTree
# The robot dog's back arm: bite and arm swipe alternate; the swipe hits a standing Rend at
# chest height and misses a ducking one; the arm reaches forward in the swing and is torn
# off when the dog dies. DOG_OUTPUT=<dir> (windowed) stores frames of the swipe.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("DOGARM %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func swipe(main, dog, p, crouch: bool, shots := "") -> bool:
	p.global_position=Vector3(42.0,.05,0);p.velocity=Vector3.ZERO;p.facing=1.0;p.hp=p.max_hp;p.reset_state();p._iframes=0
	dog.global_position=Vector3(43.3,.05,0);dog.velocity=Vector3.ZERO;dog._stun=0;dog.territory_min_x=-10.0
	dog.get_node("VisualPivot").rotation.y=PI
	if crouch:Input.action_press("crouch")
	await create_timer(.4).timeout
	dog._attack_count=1  # the next attack is the swipe
	dog.set_physics_process(true);dog._enter(dog.WINDUP)
	var hp0:int=p.hp;var frame:=0;var reach:=0.0
	var out:=OS.get_environment("DOG_OUTPUT")
	for i in 70:
		await physics_frame
		dog.global_position.z=0.0
		if dog._state==dog.SWING or dog._state==dog.RECOVERY:
			var claw:Node3D=dog._arm_joints.DogArmClaw
			reach=maxf(reach,(dog.global_position.x-claw.global_position.x))
		if dog._state==dog.CHASE:dog.set_physics_process(false)
		if not shots.is_empty() and not out.is_empty() and i%5==0 and DisplayServer.get_name()!="headless":
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("%s/%s_%02d.png"%[out,shots,frame]);frame+=1
	dog.set_physics_process(false)
	Input.action_release("crouch")
	dog.set_meta("reach",reach)
	return p.hp<hp0
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var dog
	for e in r.enemies:if e.encounter_id=="hound":dog=e
	check("the dog carries its arm",is_instance_valid(dog._arm) and dog._arm_joints.DogArmClaw!=null)
	dog._attack_count=1;var first_low:bool=dog._next_attack_is_low();dog._attack_count=2
	check("attacks alternate",first_low and not dog._next_attack_is_low())
	main.set_process(false)
	var cam:Camera3D=main.get_node("Camera3D");cam.global_position=Vector3(42.7,1.0,3.6);cam.rotation=Vector3.ZERO;cam.fov=40
	check("the swipe hits a standing Rend",await swipe(main,dog,p,false,"stand"))
	check("the arm whips forward",dog.get_meta("reach")>0.35,"reach %.2f"%dog.get_meta("reach"))
	check("ducking under the swipe",not await swipe(main,dog,p,true,"duck"))
	dog.take_melee_hit(99,Vector3(4,1,0))
	await create_timer(.5).timeout
	check("the arm is torn off when it dies",dog._arm==null)
	print("DOGARM SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
