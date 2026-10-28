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
	route=get_parent()
	var p: CharacterBody3D=route.player
	await wait(0.4)
	check("four authored encounters, no wave spawner",route.enemies.size()==4)
	check("starts without armor",p.max_hp==5 and not route.armor)
	await capture("arrival")
	for e in route.enemies:e.set_physics_process(false)
	var foe: CharacterBody3D=route.enemies[0]
	check("enemy has retargeted full body combat",foe._anim.has_animation("combat/slash_light") and foe._anim.has_animation("combat/idle"))
	p.global_position=Vector3(6,0,0);foe.global_position=Vector3(8,0,0);foe.get_node("VisualPivot").rotation.y=PI
	foe._enter(3);foe._state_t=0.4;foe._update_weapon_pose(0.016)
	await wait(0.2);print("POSE WIND ",foe._anim.current_animation, " ",foe._anim.current_animation_position," ",foe._skeleton.get_bone_pose_rotation(foe._skeleton.find_bone("mixamorig_RightArm")));await capture("enemy_windup")
	var wind: Quaternion=foe._skeleton.get_bone_pose_rotation(foe._skeleton.find_bone("mixamorig_RightArm"))
	foe._enter(4);foe._state_t=0.16;foe._update_weapon_pose(0.016)
	await wait(0.2);print("POSE STRIKE ",foe._anim.current_animation, " ",foe._anim.current_animation_position," ",foe._skeleton.get_bone_pose_rotation(foe._skeleton.find_bone("mixamorig_RightArm")));await capture("enemy_strike")
	check("attack actually changes arm pose",wind.angle_to(foe._skeleton.get_bone_pose_rotation(foe._skeleton.find_bone("mixamorig_RightArm")))>0.2)
	foe.set_physics_process(true);foe.debug_reset_ai();p.hp=5;p._iframes=0
	p.global_position=Vector3(6.8,0,0)
	await wait(1.5)
	check("live enemy attacks after telegraph",p.hp<5)
	foe.set_physics_process(false);p.reset_state();p.hp=5
	p.global_position=Vector3(8.5,0.1,0);p.velocity=Vector3.ZERO;await wait(0.2)
	for target in [11.0,14.0,18.0]:
		Input.action_press("jump");Input.action_press("move_right")
		for frame in 90:
			await get_tree().physics_frame
			if p.global_position.x>=target-0.12:break
		Input.action_release("move_right")
		await wait(0.6)
		Input.action_release("jump");await wait(0.1)
		print("TRAVERSE ",target," ",p.global_position)
	check("upper detour reachable with actual jumps",absf(p.global_position.x-18)<0.9 and p.global_position.y>2.3)
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
	p._iframes=0;p.take_damage(9,p.global_position+Vector3.RIGHT);await wait(1.5)
	check("death preserves equipment and returns to checkpoint",not p._dying and p.max_hp==7 and p.hp==7 and absf(p.global_position.x-26)<0.2)
	check("gate initially blocks progress",not route.gate_open and not route.gate.get_node("Collision").disabled)
	for e in route.enemies:
		e.hp=1;e.take_melee_hit(1,Vector3(3,1,0))
	await wait(0.9)
	check("all guards defeated opens actual gate collision",route.gate_open and route.gate.get_node("Collision").disabled)
	p.global_position=Vector3(56,0.1,0);await wait(0.3)
	check("reaching exit completes route",route.completed)
	await capture("exit")
	print("V12 SUMMARY checks=%d failures=%d"%[checks,failures])
	var code:=1 if failures else 0
	var scene:=get_tree().current_scene
	reparent(get_tree().root);scene.queue_free();route=null;p=null;foe=null;await wait(0.2)
	get_tree().quit(code)
