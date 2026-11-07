extends Node
## Integration test: a ranged guard (role 3) with a Meshy gun announces its shot,
## fires, hits Rend, and its bullets respect shields, cover and checkpoints.
## Started by lab_route via V17_TEST.
var checks:=0
var failures:=0
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H17 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
	# Watchdog: a broken fixture must still end the test run inside the 240 s timeout.
	get_tree().create_timer(60.0, false).timeout.connect(func() -> void:get_tree().quit(1))
	seed(1337)
	var route=get_parent();var p=route.player
	route.main.follow_offset.x=2.0
	for e in route.enemies:e.set_physics_process(false)
	var foe=route.enemies[2]
	check("one existing encounter replaced",foe.role==3 and foe.encounter_id=="guard" and route.enemies.size()==route.MISSION.ENCOUNTERS.size())
	check("ranged guard carries its gun",is_instance_valid(foe._gun) and foe.gun_kind=="smg")
	foe.territory_min_x=30.0  # keep Rend inside its firing range here; the checkpoint checks below stay west of it
	p.global_position=Vector3(32,0.03,0);p.velocity=Vector3.ZERO;p.hp=5;p._iframes=0
	foe.global_position=Vector3(37,0.03,0);foe.get_node("VisualPivot").rotation.y=PI
	foe.debug_reset_ai();foe.set_physics_process(true)
	var waited:=0.0
	while not (foe._state==foe.WINDUP and foe._ranged_attack) and waited<2.5:
		await wait(0.05);waited+=0.05
	waited=0.0
	while foe._state==foe.WINDUP and foe._state_t<0.58 and waited<1.0:
		await wait(0.02);waited+=0.02
	# A gun has no charge getter: gun.gd:155 makes set_charge a no-op. The guard's visible
	# charge-up is its ranged attack cue (begun in enemy.gd:489-491, locked in enemy.gd:396-397);
	# enemy.gd:438 only drives the pulse emitter, which a gunner does not carry.
	check("emitter charge is visible",foe._ranged_attack and foe._state==foe.WINDUP and foe._attack_cue._pivot.visible and foe._attack_cue._kind=="ranged")
	var muzzle:Node3D=foe._pulse_weapon.get_node("Muzzle")
	check("barrel aligned with committed aim",muzzle.global_basis.y.normalized().dot((foe._aim_point-muzzle.global_position).normalized())>0.99)
	check("visible charge before first shot",foe.shots_fired==0 and foe._state==foe.WINDUP and p.hp==5)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V17_OUTPUT")+"/charge.png")
	var burst:int=int(foe._gun.spec().burst)
	await wait(1.5)
	check("live ranged hit deals one damage",foe.shots_fired==burst and p.hp==4)
	foe.set_physics_process(false)
	# The route spawns a melee reinforcement for the guard encounter while the guard winds
	# up. It is not in route.enemies, so the initial loop above does not cover it; left
	# active it walks into Rend and randomly hits him during the later checks (seen at
	# x=34.31 during the crouch check). With the guard stopped no further mates spawn.
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(e):e.set_physics_process(false)
	await wait(1.0)
	check("no rapid second shot",foe.shots_fired==burst)
	foe._stun=0;foe._attack_front=-1
	foe.global_position=Vector3(37,0.03,0)
	p.global_position=Vector3(35.5,0.03,0);p.velocity=Vector3.ZERO;p.hp=5;p._iframes=0;p._hit_lock=0.0;p.guard.reset()
	route._equip_shield(false);p.facing=1;Input.action_press("guard");await wait(0.2)
	foe._aim_point=p.global_position+Vector3(0,1.2,0);foe._fire_energy(p)
	muzzle=foe._pulse_weapon.get_node("Muzzle")
	var emitted:=false
	for child in get_tree().current_scene.get_children():
		if child.get_script()==preload("res://modules/combat/energy_bolt.gd") and child.global_position.distance_to(muzzle.global_position)<0.01:emitted=true
	check("projectile starts at actual muzzle",emitted)
	await wait(0.5)
	check("front shield blocks gun burst",p.hp==5 and p.guard.stamina==0.0)
	Input.action_release("guard");await wait(0.1)
	p.guard.reset();p._iframes=0;p.hp=5;p.global_position=Vector3(35.5,0.03,0)
	foe._stun=0
	Input.action_press("guard");await wait(0.05)
	foe._aim_point=p.global_position+Vector3(0,1.2,0);foe._fire_energy(p)
	muzzle=foe._pulse_weapon.get_node("Muzzle")
	var arrival:float=muzzle.global_position.distance_to(foe._aim_point)/float(foe._gun.spec().speed)
	await wait(maxf(0.0,arrival-0.06)+0.2)
	check("timed guard parries projectile and staggers shooter",p.hp==5 and p.guard.stamina==90.0 and foe._stun>0)
	Input.action_release("guard");await wait(0.1);foe._stun=0
	# Root cause: the SMG muzzle sits near y=1.8 while the aim point was y=1.4, so at this
	# 1.5 m range the shot points ~16 degrees down. The +-4 degree spread (and the gun
	# sinking during the burst) let the lowest pellet cross y=1.22 at x~35.9 and reach
	# (35.46, 1.04), just under the crouched capsule top (1.05), so it hit. Stale pellets
	# from the shield/parry bursts could also still be in flight. Aim above the crouched
	# silhouette but below the standing head (1.65), clear leftover bolts and wait
	# (bounded) for the crouch.
	var bolt_script = load("res://modules/combat/energy_bolt.gd")
	for child in get_tree().current_scene.get_children():
		if child.get_script() == bolt_script and not child.is_resolved():
			child.set_physics_process(false)
			child.queue_free()
	await get_tree().physics_frame
	p._iframes=0;p.hp=5;p.global_position=Vector3(35.5,0.03,0)
	Input.action_press("crouch")
	var crouch_wait:=0.0
	while not p.crouching and crouch_wait<0.5:
		await wait(0.02);crouch_wait+=0.02
	await wait(0.05)
	foe._aim_point=p.global_position+Vector3(0,1.6,0);foe._fire_energy(p)
	await wait(0.5);Input.action_release("crouch")
	check("crouch evades committed high projectile",p.hp==5)
	var wall:=StaticBody3D.new();var col:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(0.08,2,2);col.shape=box;wall.add_child(col);route.add_child(wall);wall.global_position=Vector3(36.5,1,0)
	await wait(0.1)
	var count: int=foe.shots_fired
	foe._aim_point=p.global_position+Vector3(0,1.2,0)
	foe._fire_energy(p)
	check("wall prevents firing",foe.shots_fired==count)
	wall.queue_free();await wait(0.1)
	p.global_position=Vector3(26,0.03,0);foe.global_position=Vector3(31,0.03,0)
	foe._aim_point=p.global_position+Vector3.UP;foe._fire_energy(p)
	check("checkpoint prevents ranged fire",foe.shots_fired==count)
	var parent:=Node3D.new();parent.position=Vector3(80,3,0);route.add_child(parent)
	var bolt=load("res://modules/combat/energy_bolt.gd").new()
	bolt.lifetime=0;bolt.launch(Vector3(90,4,0),Vector3(1000,0,0),1)
	parent.add_child(bolt);await get_tree().physics_frame;await get_tree().physics_frame
	check("pre-ready launch retains world origin under parent",bolt.global_position.is_equal_approx(Vector3(90,4,0)))
	check("zero lifetime cannot travel",bolt.is_resolved() and bolt.global_position.x==90)
	Input.action_release("guard");Input.action_release("crouch")
	foe._drop_weapon(Vector3(3,0,0))
	await wait(0.05)
	var drops=get_tree().get_nodes_in_group("gun_pickups")
	check("fallen gunner drops its gun with muzzle",drops.size()==1 and drops[0].kind=="smg" and drops[0].find_child("Muzzle",true,false)!=null)
	print("H17 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
