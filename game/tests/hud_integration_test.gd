extends Node
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("V24 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func run()->void:
	var route:Node3D=get_parent()
	var p:CharacterBody3D=route.player
	for e in route.enemies:e.set_physics_process(false)
	await wait(0.3)
	var hud:Control=route.combat_hud
	check("legacy HUD hidden",not route.main.get_node("HUD").visible)
	check("health matches actual player",hud._hp_label.text=="HP %d/%d"%[p.hp,p.max_hp])
	check("shield bar hidden before pickup",not hud._stamina_bar.visible)
	route._equip_shield(false);p.guard.stamina=42
	await wait(0.05)
	check("unlocked shield displays live stamina",hud._stamina_bar.visible and absf(hud._stamina_bar.value-p.guard.stamina)<2)
	p.hp=2;route.shards=9
	await wait(0.05)
	check("damage and loot update live",hud._hp_bar.value==2 and hud._shards_label.text.contains("9"))
	var key:=InputEventKey.new();key.physical_keycode=KEY_F1;key.pressed=true
	Input.parse_input_event(key);await wait(0.05)
	check("F1 opens help",hud._help_panel.visible)
	key=InputEventKey.new();key.physical_keycode=KEY_F1;key.pressed=true;key.echo=true
	Input.parse_input_event(key);await wait(0.05)
	check("held F1 does not flicker",hud._help_panel.visible)
	key=InputEventKey.new();key.physical_keycode=KEY_F1;key.pressed=false
	Input.parse_input_event(key)
	key=InputEventKey.new();key.physical_keycode=KEY_F1;key.pressed=true
	Input.parse_input_event(key);await wait(0.05)
	check("second F1 closes help",not hud._help_panel.visible)
	p.global_position=Vector3(28.5,0.01,0);p.velocity=Vector3.ZERO
	route._message("Kontrollpunkt gesichert. Ausrüstung bleibt beim Tod erhalten.")
	route.save_error=true
	await wait(0.7)
	print("HUD rect ",hud.get_global_rect()," viewport ",get_viewport().get_visible_rect()," zone ",hud._zone_label.get_global_rect()," prompt ",hud._prompt_label.get_global_rect())
	check("actual workbench prompt displayed",hud._prompt_label.visible and hud._prompt_label.text.contains("Werkbank"))
	check("save warning survives concurrent feedback",hud._save_warn_label.visible and hud._feedback_label.visible)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V24_OUTPUT")+"/hud.png")
		get_window().size=Vector2i(960,540)
		get_window().content_scale_size=Vector2i(960,540)
		await wait(0.2)
		check("HUD root follows viewport",hud.size.is_equal_approx(get_viewport().get_visible_rect().size))
		check("prompt is inside viewport",get_viewport().get_visible_rect().encloses(hud._prompt_label.get_global_rect()))
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V24_OUTPUT")+"/hud-small.png")
	p.global_position=Vector3(0,0.01,0);route.feedback.clear();route.toast_time=0;route.save_error=false
	await wait(0.1)
	check("expired prompts and feedback disappear",not hud._prompt_label.visible and not hud._feedback_label.visible and not hud._save_warn_label.visible)
	print("V24 SUMMARY checks=%d failures=%d"%[checks,failures])
	get_tree().quit(1 if failures else 0)
