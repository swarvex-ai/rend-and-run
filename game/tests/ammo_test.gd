extends SceneTree
# Magazines and mods: a gun empties its magazine, reloads from the reserve (R), a second
# gun of the same kind adds to the reserve; the weapon bench sells mods for shards, they
# show on the gun (laser) and change it (bigger magazine, armour piercer opens a shield).
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("AMMO %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
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
	p.global_position=Vector3(33.0,.05,0);p.velocity=Vector3.ZERO;p.facing=1.0
	p.equip_gun("pistol",24)
	check("a picked-up gun has a full magazine and the rest in reserve",p.gun.ammo==12 and p.gun.reserve==12,"%d/%d"%[p.gun.ammo,p.gun.reserve])
	check("the HUD shows the ammo",r.ammo_hud.player==p and p.slot_summary().contains("12/12"))
	Input.action_press("fire");await create_timer(1.2).timeout;Input.action_release("fire")
	check("firing spends the magazine",p.gun.ammo<12,"ammo %d"%p.gun.ammo)
	var before:int=p.gun.ammo
	await tap("reload")
	check("R starts a reload",p.gun.is_reloading())
	var mags:int=root.find_children("*","RigidBody3D",true,false).size()
	await create_timer(1.3).timeout
	check("the reload fills the magazine from the reserve",p.gun.ammo==12 and p.gun.reserve==12-(12-before),"%d/%d"%[p.gun.ammo,p.gun.reserve])
	check("the spent magazine drops",mags>0)
	var reserve0:int=p.gun.reserve
	p.equip_gun("pistol",24)
	check("the same gun again adds to the reserve",p.gun.reserve==reserve0+24 and p.holstered.size()==1)
	# The weapon bench.
	p.global_position=r.GUN_BENCH_POS+Vector3(0,.05,0);p.velocity=Vector3.ZERO
	r.shards=20;r.equipment.shards=20
	await create_timer(.3).timeout
	var line:String=r.combat_hud._prompt_label.text if r.combat_hud.get("_prompt_label") else ""
	check("the bench offers a mod",line.contains("Laservisier"),line)
	await tap("interact")
	check("buying fits the laser and costs shards",p.gun.has_mod("laser") and r.shards==16 and p.gun._laser!=null,"shards %d"%r.shards)
	await create_timer(.2).timeout
	check("the laser runs from the muzzle",p.gun._laser.visible and p.gun._laser.global_position.distance_to(p.gun.muzzle())>0.05)
	await tap("guard")
	await create_timer(.1).timeout
	check("the guard key cycles the offer",r.combat_hud._prompt_label.text.contains("Schnellladegriff"),r.combat_hud._prompt_label.text)
	p.fit_mod("pistol","extmag")
	check("the extended magazine holds more",p.gun.mag_size()==18)
	check("mods are saved",r.gun_mods.get("pistol",[]).has("laser"))
	# Armour piercer opens a shield-bearer's guard.
	var duelist
	for e in r.enemies:if e.encounter_id=="duelist":duelist=e
	p.fit_mod("pistol","piercer");p.gun.ammo=12;p.gun.reload_left=0.0
	p.global_position=Vector3(30.0,.05,0);p.velocity=Vector3.ZERO;p.facing=1.0
	duelist.global_position=Vector3(33.5,.05,0);duelist.hp=99;duelist.get_node("VisualPivot").rotation.y=PI  # faces Rend
	var breaks0:int=duelist.shield_breaks_left;var blocks0:int=duelist.blocks
	Input.action_press("fire");await create_timer(.8).timeout;Input.action_release("fire")
	check("the armour piercer knocks a shield aside",duelist.shield_breaks_left<breaks0,"breaks %d->%d blocks +%d"%[breaks0,duelist.shield_breaks_left,duelist.blocks-blocks0])
	print("AMMO SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
