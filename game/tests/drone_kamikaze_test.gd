extends SceneTree
# Kamikaze drones: a woken drone locks on, dives at Rend and detonates; the blast hurts him
# and a robot standing next to him. Struck down first, a drone breaks without a blast.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("DRONE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	check("wing drones exist",r.wing_drones.size()==2)
	var drone=r.wing_drones[0]
	var foe=r.enemies[0];foe.hp=99;foe._stun=0
	p.global_position=Vector3(drone.home.x+1.5,.05,0);p.velocity=Vector3.ZERO;p.hp=p.max_hp;p._iframes=0
	foe.global_position=Vector3(p.global_position.x+0.9,.05,0.5)
	var hp0:int=p.hp;var foe_hits:int=foe.hits_taken
	var locked:=false
	for i in 300:
		await physics_frame
		if is_instance_valid(drone) and drone.phase==1:locked=true
		if not is_instance_valid(drone):break
	check("it locks on before diving",locked)
	check("it detonates",not is_instance_valid(drone))
	check("the blast hurts Rend",p.hp<hp0,"hp %d -> %d"%[hp0,p.hp])
	check("the blast hurts a robot beside him",foe.hits_taken>foe_hits)
	# Second drone: struck down while hovering, no blast.
	var other=r.wing_drones[1]
	p.global_position=Vector3(other.global_position.x-1.0,.05,0);p.hp=p.max_hp;p._iframes=1.0
	var hp1:int=p.hp
	other.take_melee_hit(1,Vector3(4,1,0));other.take_melee_hit(1,Vector3(4,1,0))
	await create_timer(.3).timeout
	check("a drone struck down breaks without a blast",not is_instance_valid(other) and p.hp==hp1)
	print("DRONE SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
