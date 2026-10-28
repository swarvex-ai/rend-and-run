extends Node
var checks:=0
var failures:=0
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H17 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
	var route=get_parent();var p=route.player
	route.main.follow_offset.x=2.0
	for e in route.enemies:e.set_physics_process(false)
	var foe=route.enemies[2]
	check("one existing encounter replaced",foe.role==3 and route.enemies.size()==4)
	p.global_position=Vector3(32,0.03,0);p.velocity=Vector3.ZERO;p.hp=5;p._iframes=0
	foe.global_position=Vector3(38,0.03,0);foe.get_node("VisualPivot").rotation.y=PI
	foe.debug_reset_ai();foe.set_physics_process(true)
	await wait(0.8)
	print("PULSE transform ",foe._pulse_weapon.global_transform," local scale ",foe._pulse_weapon.scale)
	check("emitter charge is visible",foe._pulse_weapon.get_charge()>0)
	var muzzle:Node3D=foe._pulse_weapon.get_node("Muzzle")
	check("barrel aligned with committed aim",muzzle.global_basis.y.normalized().dot((foe._aim_point-muzzle.global_position).normalized())>0.99)
	check("visible charge before first shot",foe.shots_fired==0 and foe._state==foe.WINDUP and p.hp==5)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V17_OUTPUT")+"/charge.png")
	await wait(1.5)
	check("live ranged hit deals one damage",foe.shots_fired==1 and p.hp==4)
	await wait(0.35)
	check("no rapid second shot",foe.shots_fired==1)
	foe.set_physics_process(false);foe._stun=0;foe._attack_front=-1
	p.global_position=Vector3(32,0.03,0);p.velocity=Vector3.ZERO;p.hp=5;p._iframes=0
	route._equip_shield(false);p.facing=1;Input.action_press("guard");await wait(0.2)
	foe._aim_point=p.global_position+Vector3(0,1.2,0);foe._fire_energy(p)
	var emitted:=false
	for child in get_tree().current_scene.get_children():
		if child.get_script()==preload("res://modules/combat/energy_bolt.gd") and child.global_position.distance_to(muzzle.global_position)<0.01:emitted=true
	check("projectile starts at actual muzzle",emitted)
	await wait(0.25)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V17_OUTPUT")+"/projectile.png")
	await wait(0.6)
	check("front shield blocks projectile",p.hp==5 and p.guard.stamina==75)
	Input.action_release("guard");await wait(0.1)
	p.guard.reset();p._iframes=0;p.hp=5;p.global_position=Vector3(32,0.03,0)
	foe._aim_point=p.global_position+Vector3(0,1.2,0);foe._fire_energy(p)
	var arrival:float=foe._pulse_weapon.get_node("Muzzle").global_position.distance_to(foe._aim_point)/8.0
	await wait(maxf(0.0,arrival-0.12));Input.action_press("guard");await wait(0.2)
	check("timed guard parries projectile and staggers shooter",p.hp==5 and p.guard.stamina==90 and foe._stun>0)
	Input.action_release("guard");await wait(0.1);foe._stun=0
	p._iframes=0;p.hp=5;p.global_position=Vector3(32,0.03,0)
	foe._aim_point=p.global_position+Vector3(0,1.2,0);foe._fire_energy(p)
	Input.action_press("crouch");await wait(0.85);Input.action_release("crouch")
	check("crouch evades committed high projectile",p.hp==5)
	var wall:=StaticBody3D.new();var col:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(0.08,2,2);col.shape=box;wall.add_child(col);route.add_child(wall);wall.global_position=Vector3(35,1,0)
	await wait(0.1)
	var count: int=foe.shots_fired
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
	var drops=get_tree().get_nodes_in_group("dropped_weapons")
	check("pulse emitter drops with muzzle",drops.size()==1 and drops[0].find_child("Muzzle",true,false)!=null)
	print("H17 SUMMARY checks=%d failures=%d"%[checks,failures])
	var result:=1 if failures else 0
	var scene:=get_tree().current_scene
	reparent(get_tree().root);scene.queue_free();route=null;p=null;foe=null;bolt=null;parent=null
	await wait(0.2);get_tree().quit(result)
