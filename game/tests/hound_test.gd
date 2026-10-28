extends SceneTree
# Robot dog: spawns from the route, hunts Rend, bites low (ducking does not help,
# a jump clears it), and dies mechanically. HOUND_OUTPUT=<dir> stores captures (windowed).
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("HOUND %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func capture(label: String) -> void:
	var out := OS.get_environment("HOUND_OUTPUT")
	if out.is_empty() or DisplayServer.get_name() == "headless":return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out + "/" + label + ".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var p=main.player;var fx=root.get_node("FX")
	var dog=null
	for e in main.route.enemies:
		if e.encounter_id=="hound":dog=e
		else:e.set_physics_process(false)
	# Only the dog: the security wing's kamikaze drone and sentinels stay out of it.
	for d in main.route.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in main.route.sentinels:s.set_physics_process(false)
	check("hound spawns as robot dog",dog!=null and dog.get_script().resource_path.ends_with("enemy_dog.gd") and dog._mechanical)
	if dog==null:quit(1);return
	dog._attack_count=1;dog._committed_low=dog._next_attack_is_low()  # its first attack is the bite
	check("dog bites low",dog._committed_low and dog._attack_kind()=="low")
	dog._attack_count=0;dog._committed_low=false
	# Crouched Rend in front of the dog: the bite still lands.
	p.global_position=Vector3(dog.global_position.x-3.0,.05,dog.global_position.z);p.hp=p.max_hp;p._iframes=0
	dog._enter(dog.CHASE)
	await create_timer(.5).timeout;await capture("hound_run")
	Input.action_press("crouch")
	var hp0:int=p.hp;var lunged:=false
	for i in 150:
		await physics_frame
		if dog._state==dog.SWING and not lunged:lunged=true;await capture("hound_lunge")
		if p.hp<hp0:break
	Input.action_release("crouch")
	check("ducking does not avoid the bite",lunged and p.hp<hp0,"hp %d->%d"%[hp0,p.hp])
	# A jump over the bite clears it.
	await create_timer(1.2).timeout
	p.global_position=Vector3(dog.global_position.x-1.6,.05,dog.global_position.z);p.hp=p.max_hp;p._iframes=0;p.reset_state();p._iframes=0
	dog._stun=0;dog._enter(dog.WINDUP)
	await create_timer(dog._windup_duration()-0.12).timeout
	Input.action_press("jump");await create_timer(.25).timeout;Input.action_release("jump")
	await create_timer(.6).timeout
	check("jumping clears the bite",p.hp==p.max_hp,"hp=%d"%p.hp)
	# A hit visibly jolts the body: sparks and a nose-up flinch that springs back.
	var sparks0:int=fx.robot_impacts
	dog.hp=99;dog.take_melee_hit(1,Vector3(5.5,1.1,0))
	await create_timer(.08).timeout
	check("a hit throws sparks and jolts the dog",fx.robot_impacts>sparks0 and absf(dog._pitch[0])>0.05,"pitch=%.2f"%dog._pitch[0])
	await create_timer(1.0).timeout
	check("the flinch settles",absf(dog._pitch[0])<0.03,"pitch=%.2f"%dog._pitch[0])
	# Death: the body is thrown and the legs fold (ragdoll), no blood.
	fx.fx_stats["blood"]=0
	dog.hp=1;dog.take_melee_hit(2,Vector3(5.5,1.1,0))
	await create_timer(1.5).timeout;await capture("hound_death")
	check("dog dies without blood as a ragdoll",dog._dead and fx.fx_stats["blood"]==0 and is_instance_valid(dog._death_physics))
	if is_instance_valid(dog._death_physics):
		var torso:Node3D=dog._death_physics.physics_root.get_node("Body")
		check("the body comes to rest on the floor",torso.global_position.y<0.5,"y=%.2f"%torso.global_position.y)
	print("HOUND SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
