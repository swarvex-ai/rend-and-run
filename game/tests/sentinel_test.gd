extends SceneTree
# Sentinels: asleep in their alcoves with the ring dark; sneaking past leaves them
# asleep, running past wakes them - the ring lights, they step out onto the floor strip
# and start the fight; the ring turns red while a strike winds up.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("SENTINEL %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	check("two sentinels wait in alcoves",r.sentinels.size()==2 and r.sentinels[0].global_position.z<-2.0)
	var sentinel=r.sentinels[0]
	await create_timer(.5).timeout
	check("asleep with the ring dark",sentinel.sentinel==sentinel.ASLEEP and sentinel._ring_level<0.05)
	# Sneak past (crouch-walk).
	p.global_position=Vector3(sentinel.global_position.x-3.5,.05,0.6);p.velocity=Vector3.ZERO
	Input.action_press("crouch");Input.action_press("move_right");await create_timer(2.6).timeout
	Input.action_release("move_right");Input.action_release("crouch")
	check("sneaking past leaves it asleep",sentinel.sentinel==sentinel.ASLEEP,"rend x=%.2f sentinel x=%.2f"%[p.global_position.x,sentinel.global_position.x])
	# Run past.
	p.global_position=Vector3(sentinel.global_position.x-4.0,.05,0.6);p.velocity=Vector3.ZERO
	await create_timer(.2).timeout
	Input.action_press("move_right");await create_timer(1.2).timeout;Input.action_release("move_right")
	check("running past wakes it",sentinel.sentinel!=sentinel.ASLEEP)
	await create_timer(.6).timeout
	check("its ring lights up",sentinel._ring_level>0.5)
	var joined:=false
	for i in 300:
		await physics_frame
		if sentinel.sentinel==sentinel.AWAKE:joined=true;break
	check("it steps out onto the floor strip",joined and sentinel.global_position.z>-1.1,"z=%.2f"%sentinel.global_position.z)
	var red:=false
	p.hp=99;p.max_hp=99
	for i in 600:
		await physics_frame
		if sentinel._state==sentinel.WINDUP and sentinel._ring_mat.emission.r>0.9 and sentinel._ring_mat.emission.g<0.3:red=true;break
	check("the ring turns red as it winds up a strike",red)
	print("SENTINEL SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
