extends SceneTree
# Weapon slots and shield swap: 1 hands free, 2 arm, 3 sidearm, 4 long gun; attack uses the
# drawn weapon; a fallen shield-bearer's riot shield replaces Rend's chest plate (dropped).
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("LOADOUT %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func tap(action: String) -> void:
	Input.action_press(action);await create_timer(.08).timeout;Input.action_release(action);await create_timer(.1).timeout
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	for d in r.wing_drones:if is_instance_valid(d):d.set_physics_process(false)
	for s in r.sentinels:s.set_physics_process(false)
	p.equip_weapon("robot_arm");p.global_position=Vector3(33.0,.05,0)
	check("the arm is drawn in slot 2",p.slot==2 and p._starter_model.visible)
	var pickups=load("res://modules/combat/gun_pickup.gd")
	pickups.drop(r,Vector3(33.2,0,0),"pistol",12)
	await create_timer(.2).timeout;await tap("interact")
	check("a pistol goes to slot 3 and is drawn",p.slot==3 and is_instance_valid(p.gun) and p.gun.kind=="pistol" and not p._starter_model.visible)
	pickups.drop(r,Vector3(33.2,0,0),"energy_rifle",8)
	await create_timer(.2).timeout;await tap("interact")
	check("a rifle goes to slot 4",p.slot==4 and p.gun.kind=="energy_rifle" and p.holstered.has(3))
	await tap("weapon_3")
	check("key 3 draws the pistol again",p.slot==3 and p.gun.kind=="pistol" and p.gun.ammo==12)
	var foe=r.enemies[0];foe.hp=99;foe.global_position=Vector3(36.0,.05,0);p.facing=1.0
	var hits0:int=foe.hits_taken
	await tap("attack");await create_timer(.3).timeout
	check("attack fires the drawn gun",p.holstered[3].ammo<12 or p.gun.ammo<12)
	await tap("weapon_2")
	check("key 2 draws the arm, gun put away",p.slot==2 and not is_instance_valid(p.gun) and p._starter_model.visible)
	await tap("weapon_1")
	check("key 1 frees the hands",p.slot==1 and not p._starter_model.visible and not is_instance_valid(p.gun))
	# Shield swap.
	r._equip_shield(false)
	var duelist
	for e in r.enemies:if e.encounter_id=="duelist":duelist=e
	duelist.global_position=Vector3(34.0,.05,0);duelist.take_melee_hit(99,Vector3(-4,1,0))
	await create_timer(.3).timeout
	var lying:Array=get_nodes_in_group("shield_pickups")
	check("the shield-bearer's shield lands on the floor",lying.size()==1)
	if lying.size()==1:
		p.global_position=Vector3(lying[0].global_position.x,.05,lying[0].global_position.z)
		await create_timer(.2).timeout;await tap("interact")
		check("Rend straps it on in place of his chest plate",p.shield_kind=="riot" and p.guard.block_cost<25.0)
		check("the chest plate is left on the floor",get_nodes_in_group("shield_pickups").any(func(s):return s.kind=="salvage"))
	print("LOADOUT SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
