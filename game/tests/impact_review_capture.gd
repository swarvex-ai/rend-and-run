extends SceneTree
# Impact review in the real route: Rend striking a robot (light, heavy, shock) and
# robots striking Rend (light, high, heavy). IMPACT_OUTPUT=<dir> receives a frame
# series per scenario; asserts no blood on robots, blood on Rend, travel < 1 m.
const TIMES := [0.0, 0.05, 0.15, 0.3, 0.6, 1.0]
func _initialize():call_deferred("run")
func capture(label: String) -> void:
	var out:=OS.get_environment("IMPACT_OUTPUT")
	await RenderingServer.frame_post_draw
	if not out.is_empty():root.get_texture().get_image().save_png(out+"/"+label+".png")
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var fx=root.get_node("FX");var p=main.player;var failures:=0
	var foe=main.route.enemies[1]
	for e in main.route.enemies:if not e.shield and e.gun_kind=="" and e.role<2 and e.encounter_id!="hound":foe=e;break  # bare robot: a shield would block the light hit
	for e in main.route.enemies:if e!=foe:e.set_physics_process(false)
	p.set_physics_process(false);p.equip_weapon("robot_arm")
	for spec in [["robot_light",1,Vector3(5.5,1.1,0)],["robot_heavy",1,Vector3(7.5,3.2,0)],["robot_shock",2,Vector3(6.6,1.3,0)]]:
		p.global_position=Vector3(foe.global_position.x-1.6,.05,0);foe.hp=99;foe._stun=0;foe._enter(foe.IDLE)
		await create_timer(1.2).timeout
		fx.fx_stats["blood"]=0;var start: float=foe.global_position.x;var sparks0:int=fx.robot_impacts
		foe.take_melee_hit(spec[1],spec[2])
		if spec[0]!="robot_shock" and fx.robot_impacts==sparks0:failures+=1;print("IMPACT FAIL no spark burst on ",spec[0])
		if spec[0]!="robot_shock" and not foe._hit_physics.is_reacting():failures+=1;print("IMPACT FAIL no physical reaction on ",spec[0])
		var last:=0.0
		for t in TIMES:
			await create_timer(maxf(t-last,0.001),true,false,true).timeout;last=t
			await capture("%s_%02d"%[spec[0],int(t*100)])
		if foe._hit_physics.is_reacting():failures+=1;print("IMPACT FAIL physical reaction not cleared on ",spec[0])
		var travel:=absf(foe.global_position.x-start)
		print("IMPACT %s travel=%.2f blood=%d" % [spec[0],travel,fx.fx_stats["blood"]])
		if travel>1.0 or fx.fx_stats["blood"]!=0:failures+=1;print("IMPACT FAIL ",spec[0])
	foe.set_physics_process(false);p.set_physics_process(true)
	for spec in [["rend_light","low",1],["rend_high","high",1],["rend_heavy","heavy",2]]:
		p.global_position=Vector3(foe.global_position.x-1.6,.05,0);p.hp=p.max_hp;p._iframes=0;p.reset_state();p._iframes=0;p.facing=1.0
		await create_timer(1.2).timeout
		foe.set("_committed_low",spec[1]=="low");foe.role=2 if spec[1]=="heavy" else 1
		fx.fx_stats["blood"]=0;var start: float=p.global_position.x
		p.take_damage(spec[2],foe.global_position,foe)
		var last:=0.0
		for t in TIMES:
			await create_timer(maxf(t-last,0.001),true,false,true).timeout;last=t
			await capture("%s_%02d"%[spec[0],int(t*100)])
		var travel:=absf(p.global_position.x-start)
		print("IMPACT %s clip=%s travel=%.2f blood=%d" % [spec[0],p._anim_state,travel,fx.fx_stats["blood"]])
		if travel>1.0 or fx.fx_stats["blood"]<1:failures+=1;print("IMPACT FAIL ",spec[0])
	var cries:int=fx.audio_events.get("rend_hurt_light",0)+fx.audio_events.get("rend_hurt_heavy",0)
	print("IMPACT voice cries=",cries)
	if cries<3:failures+=1;print("IMPACT FAIL rend voice")
	print("IMPACT SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
