extends Node
var checks:=0
var failures:=0
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H14 %s %s"%["PASS" if ok else "FAIL",label])
func sounding(cue:String)->bool:
	for voice in FX._players:
		if voice.playing and voice.stream==FX._sfx.get(cue):return true
	return false
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func run() -> void:
	var route=get_parent();var p=route.player
	for e in route.enemies:e.set_physics_process(false)
	await wait(0.3)
	check("shield locked initially",not p.shield_unlocked)
	p.global_position=route.shield_pos+Vector3(0,0.05,0)
	await wait(0.15)
	Input.action_press("interact");await wait(0.1);Input.action_release("interact")
	check("actual interaction unlocks shield",route.shield and p.shield_unlocked and not route.shield_display.visible)
	var saved=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12_test.json"))
	check("unlock persisted",saved is Dictionary and saved.get("shield")==true)
	var fresh=load("res://lab_route.gd").new()
	fresh._restore_progress(saved)
	check("fresh route restores shield from saved data",fresh.shield)
	fresh.free()
	p.global_position=Vector3(30,0.05,0);p.velocity=Vector3.ZERO;p.facing=1
	await wait(0.2)
	p._iframes=0;p.guard.reset();p.hp=p.max_hp
	var sparks_before:=FX.metal_contacts
	var parry_before:=FX.parry_contacts
	Input.action_press("guard");await wait(0.035)
	var enemy=route.enemies[0]
	enemy.global_position=p.global_position+Vector3(1.1,0,0)
	enemy._attack_front=-1;enemy._swing_hit=false;enemy._committed_low=false
	enemy._try_swing_hit(p,-1.1,0)
	check("front parry costs10 no HP and staggers attacker",p.hp==p.max_hp and p.guard.stamina==90 and enemy._stun>0.5)
	check("parry cue actually playing",sounding("parry"))
	check("confirmed parry emits cooler metal contact",FX.metal_contacts==sparks_before+1 and FX.parry_contacts==parry_before+1)
	await wait(0.16)
	p.take_damage(1,p.global_position+Vector3.RIGHT)
	check("held guard blocks for25",p.hp==p.max_hp and p.guard.stamina==65)
	check("block cue actually playing",sounding("block"))
	check("held block emits normal contact",FX.metal_contacts==sparks_before+2 and FX.parry_contacts==parry_before+1)
	await wait(0.025)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V14_OUTPUT")+"/guard.png")
	p.take_damage(1,p.global_position-Vector3.RIGHT)
	check("back hit bypasses shield",p.hp==p.max_hp-1)
	check("unblocked flesh hit emits no sparks",FX.metal_contacts==sparks_before+2)
	Input.action_release("guard");await wait(0.3)
	p._iframes=0;p.guard.reset();p.guard.stamina=20
	Input.action_press("guard");await wait(0.17)
	var hurt_before:=int(FX.audio_events.get("rend_hurt_heavy",0))
	var hp: int=p.hp;p.take_damage(1,p.global_position+Vector3.RIGHT)
	check("guard break and hurt cues playing",sounding("guard_break") and int(FX.audio_events.get("rend_hurt_heavy",0))==hurt_before+1)
	check("guard break deals damage and locks recovery",p.hp==hp-1 and p.guard.break_remaining()>0.5 and not p.guard.is_guarding())
	await wait(0.85)
	check("held guard does not auto raise after break",not p.guard.is_guarding())
	Input.action_release("guard");await wait(0.05);Input.action_press("guard");await wait(0.04)
	check("fresh press restores guard",p.guard.is_guarding())
	route.equipment.grant("robot_arm");route.equipment.equip_weapon("robot_arm");p.equip_weapon("robot_arm")
	p._start_attack(1)
	check("attack releases guard without stamina cost",not p.guard.is_guarding() and p._attack_phase==1)
	Input.action_release("guard");await wait(0.65)
	Input.action_press("guard");await wait(0.05);Input.action_press("jump");await wait(0.06);Input.action_release("jump")
	check("jump releases guard",not p.guard.is_guarding() and p.velocity.y>0)
	Input.action_release("guard")
	p.reset_state()
	check("respawn preserves unlock resets stamina",p.shield_unlocked and p.guard.stamina==100 and not p.guard.is_guarding())
	await wait(0.6)
	check("contact particles and timers fully retired",FX._metal_sparks.active_count()==0 and FX._metal_sparks.get_child_count()==0)
	print("H14 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
