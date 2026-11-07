extends Node
var checks:=0
var failures:=0
var route: Node3D
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("V12 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func capture(label: String) -> void:
	if DisplayServer.get_name()=="headless":return
	RenderingServer.force_draw(false)
	get_viewport().get_texture().get_image().save_png(OS.get_environment("V12_OUTPUT")+"/"+label+".png")
func interact() -> void:
	Input.action_press("interact");await wait(0.05);Input.action_release("interact");await wait(0.05)
func run() -> void:
	seed(1337)
	route=get_parent()
	var mission=route.MISSION
	var p: CharacterBody3D=route.player
	await wait(0.4)
	check("authored encounters, no wave spawner",route.enemies.size()==mission.ENCOUNTERS.size() and route.find_child("WaveSpawner",true,false)==null)
	check("starts without armor",p.max_hp==5 and not route.armor)
	await capture("arrival")
	for e in route.enemies:e.set_physics_process(false)
	var foe: CharacterBody3D=route.enemies[0]
	check("enemy has retargeted full body combat",foe._anim.has_animation("combat/slash_light") and foe._anim.has_animation("combat/idle"))
	p.global_position=Vector3(6,0,0);foe.global_position=Vector3(8,0,0);foe.get_node("VisualPivot").rotation.y=PI
	var bone:int=foe._skeleton.find_bone("RightArm")
	if bone<0:print("POSE BONE MISSING RightArm index=",bone)
	foe._enter(3);foe._state_t=0.4;foe._update_weapon_pose(0.016)
	await wait(0.2)
	var wind:=Quaternion.IDENTITY
	if bone>=0:wind=foe._skeleton.get_bone_pose_rotation(bone)
	print("POSE WIND ",foe._anim.current_animation, " ",foe._anim.current_animation_position," ",wind);await capture("enemy_windup")
	foe._enter(4);foe._state_t=0.16;foe._update_weapon_pose(0.016)
	await wait(0.2)
	var strike:=Quaternion.IDENTITY
	if bone>=0:strike=foe._skeleton.get_bone_pose_rotation(bone)
	print("POSE STRIKE ",foe._anim.current_animation, " ",foe._anim.current_animation_position," ",strike);await capture("enemy_strike")
	check("attack actually changes arm pose",bone>=0 and wind.angle_to(strike)>0.2)
	foe.set_physics_process(true);foe.debug_reset_ai();p.hp=5;p._iframes=0
	p.global_position=Vector3(6.8,0,0)
	await wait(1.5)
	check("live enemy attacks after telegraph",p.hp<5)
	foe.set_physics_process(false);p.reset_state();p.hp=5
	p.global_position=Vector3(11,0.1,0);p.velocity=Vector3.ZERO;await wait(0.2)
	Input.action_press("move_right")
	for frame in 180:
		await get_tree().physics_frame
		if p.global_position.x>=18.0:break
	Input.action_release("move_right")
	print("TRAVERSE ",p.global_position)
	check("flat route traversable with actual movement",absf(p.global_position.x-18.0)<0.9 and p.global_position.y<1.0)
	p.global_position=route.cache_pos;await wait(0.25)
	await interact()
	check("armor pickup increases HP and hides pickup",route.armor and p.max_hp==7 and not route.armor_display.visible)
	await interact();check("armor cannot stack repeatedly",p.max_hp==7)
	await capture("armor_detour")
	p.global_position=route.checkpoint_pos;p.hp=2;await wait(0.15);await interact()
	check("security guards cannot attack safe checkpoint",not route.enemies[1]._can_attack())
	check("checkpoint heals and changes respawn",route.checkpoint and p.hp==7 and route.main.spawn_point==route.checkpoint_pos)
	var save=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12_test.json"))
	check("save contains armor and checkpoint",save is Dictionary and save.armor and save.checkpoint)
	p._iframes=0;p.take_damage(9,p.global_position+Vector3.RIGHT)
	for i in 600:
		await get_tree().physics_frame
		if not p._dying:break
	check("death preserves equipment and returns to checkpoint",not p._dying and p.max_hp==7 and p.hp==7 and absf(p.global_position.x-route.checkpoint_pos.x)<0.2)
	check("gate initially blocks progress",not route.gate_open and not route.gate.get_node("Collision").disabled)
	p._iframes=999
	for e in route.enemies:e.set_physics_process(true)
	p.global_position=Vector3(mission.BOSS_ENTRY_X+0.5,0.1,0);p.velocity=Vector3.ZERO
	for i in 120:
		await get_tree().physics_frame
		if route.overseer.active:break
	for e in route.enemies:
		if e.shield and is_instance_valid(e._shield):
			e.debug_reset_ai()
			for hit in e.shield_breaks_left:
				e._stun=0.0;e._shield_open=0.0;e._kb_timer=0.0
				e.take_melee_hit(2,Vector3(-e._front_sign()*5.0,3.2,0))
		e.hp=1
		e.take_melee_hit(1,Vector3(-e._front_sign()*5.0,0,0))
	await wait(0.2)
	check("all guards defeated opens actual gate collision",route.gate_open and route.gate.get_node("Collision").disabled)
	p.global_position=Vector3(mission.EXIT_X+1.0,0.1,0);await wait(0.3)
	check("reaching exit completes route",route.completed)
	await capture("exit")
	print("V12 SUMMARY checks=%d failures=%d"%[checks,failures])
	var code:=1 if failures else 0
	var scene:=get_tree().current_scene
	reparent(get_tree().root);scene.queue_free();route=null;p=null;foe=null;await wait(0.2)
	get_tree().quit(code)
