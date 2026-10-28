extends SceneTree
# Firearms: gunners carry their Meshy gun and shoot Rend; a fallen gunner drops it; Rend
# takes it with interact, fires it with "fire", hits a robot, and drops it when magazine and reserve are spent.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("GUN %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	var kinds:={}
	for e in r.enemies:if e._gun:kinds[e.encounter_id]=e.gun_kind
	check("gunners carry their guns",kinds.get("guard")=="smg" and kinds.get("relay_guard")=="energy_rifle" and kinds.get("freight_raider")=="pistol",str(kinds))
	var guard
	for e in r.enemies:if e.encounter_id=="guard":guard=e
	# It shoots Rend.
	guard.territory_min_x=30.0  # the test stands Rend well inside its range, clear of the cover at x 40.8
	p.global_position=Vector3(guard.global_position.x-4.0,.05,0);p.velocity=Vector3.ZERO;p.hp=99;p.max_hp=99;p._iframes=0
	guard.set_physics_process(true)
	var hp0:int=p.hp
	for i in 600:
		await physics_frame
		p._iframes=0
		if p.hp<hp0:break
	check("a gunner's bullets hit Rend",p.hp<hp0,"hp %d -> %d shots=%d"%[hp0,p.hp,guard.shots_fired])
	# Down it: the gun drops.
	guard.take_melee_hit(99,Vector3(5,1,0))
	await create_timer(.3).timeout
	var pickups:=get_nodes_in_group("gun_pickups")
	check("the fallen gunner drops its gun",pickups.size()==1 and pickups[0].kind=="smg")
	if pickups.is_empty():print("GUN SUMMARY failures=",failures);quit(1);return
	var pickup=pickups[0]
	p.global_position=Vector3(pickup.global_position.x-0.4,.05,pickup.global_position.z);p.velocity=Vector3.ZERO
	await create_timer(.3).timeout
	Input.action_press("interact");await create_timer(.08).timeout;Input.action_release("interact");await create_timer(.1).timeout
	check("interact takes the gun",is_instance_valid(p.gun) and p.gun.kind=="smg" and p.gun.ammo==30)
	# Fire at a robot.
	var foe=r.enemies[0];foe.hp=99;foe.set_physics_process(false)
	p.global_position=Vector3(33.0,.05,0);p.velocity=Vector3.ZERO;p.facing=1.0  # open floor
	foe.global_position=Vector3(36.0,.05,0)
	await create_timer(.2).timeout
	var hits0:int=foe.hits_taken
	Input.action_press("fire");await create_timer(1.0).timeout;Input.action_release("fire")
	await create_timer(.3).timeout
	check("fire shoots and hits a robot",foe.hits_taken>hits0,"hits %d ammo %d"%[foe.hits_taken-hits0,p.gun.ammo if is_instance_valid(p.gun) else -1])
	check("a dropped gun carries a spare magazine",is_instance_valid(p.gun) and p.gun.reserve==30,"reserve %d"%(p.gun.reserve if is_instance_valid(p.gun) else -1))
	if is_instance_valid(p.gun):p.gun.reserve=0
	Input.action_press("fire");await create_timer(4.0).timeout;Input.action_release("fire")
	await create_timer(.6).timeout
	check("an empty gun is thrown away",not is_instance_valid(p.gun))
	print("GUN SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
