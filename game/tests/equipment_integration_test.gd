extends Node
var checks:=0
var failures:=0
func check(label: String,ok: bool) -> void:
	checks+=1
	if not ok:failures+=1
	print("H15 %s %s"%["PASS" if ok else "FAIL",label])
func wait(t: float) -> void:await get_tree().create_timer(t).timeout
func interact() -> void:
	Input.action_press("interact");await wait(0.08);Input.action_release("interact");await wait(0.08)
func run() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var route=get_parent();var p=route.player
	for e in route.enemies:e.set_physics_process(false)
	await wait(0.3)
	route.main.pause_controller.resume()
	route._equip_shield(true)
	check("found shield owned without charge",route.equipment.owns("salvage_shield") and route.shards==0)
	p.global_position=route.workbench_pos+Vector3(0,0.02,0);p.velocity=Vector3.ZERO
	await wait(0.2);await interact()
	route.apply_workbench_action("vibroblade")
	check("cannot buy without shards",not route.equipment.owns("vibroblade") and route.shards==0)
	route.main.pause_controller.resume();await wait(.08)
	for crate in [route.supply_crates[0]]:
		crate.take_melee_hit(2,Vector3.ZERO)
		p.global_position=Vector3(crate.position.x,crate.position.y+.02,0);p.velocity=Vector3.ZERO
		await wait(.85)
	p.global_position=route.workbench_pos+Vector3(0,.02,0);p.velocity=Vector3.ZERO
	await wait(.15)
	route._enemy_defeated(route.enemies[0])
	check("first crate and first guard afford upgrade before security wing",route.shards==6)
	route._enemy_defeated(route.enemies[0])
	check("defeated enemy never pays twice",route.shards==6)
	check("optional crates not required for upgrade",not route.supply_crates[1].is_broken() and not route.supply_crates[2].is_broken())
	await interact()
	route.apply_workbench_action("vibroblade");await wait(.05)
	check("real workbench purchase once without auto equip",route.equipment.owns("vibroblade") and route.shards==0 and p.weapon_id=="starter_sword")
	route.apply_workbench_action("vibroblade");await wait(.05)
	route.main.pause_controller.resume();await wait(.08)
	check("explicit selection equips owned heavy blade",p.weapon_id=="vibroblade" and p._sword_model==p._heavy_model and p._heavy_model.is_visible_in_tree() and not p._starter_model.visible and route.shards==0)
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12_test.json"))
	var fresh=load("res://lab_route.gd").new();fresh._restore_progress(data)
	check("save restores weapon shield and wallet",fresh.equipment.equipped_weapon()=="vibroblade" and fresh.shield and fresh.shards==0)
	fresh.free()
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V15_OUTPUT")+"/workbench.png")
	var crate=load("res://modules/loot/supply_crate.gd").new()
	route.add_child(crate)
	# Damage fixture in the authored high-cut path. The old floor/back-plane
	# placement misses the real blade (also in V59), so cannot test hit damage.
	crate.global_position=Vector3(32,0.65,0)
	p.global_position=Vector3(30.9,0.02,0);p.facing=1;p.velocity=Vector3.ZERO
	await wait(0.2)
	p._start_attack(1)
	check("heavy uses longer timing",p._attack_dur>0.73 and is_equal_approx(p._hero_anim.get_playing_speed(),0.8))
	route._use_workbench()
	check("cannot switch in mid attack",p.weapon_id=="vibroblade")
	await wait(0.28)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw(false)
		get_viewport().get_texture().get_image().save_png(OS.get_environment("V15_OUTPUT")+"/heavy-strike.png")
	await wait(0.85)
	check("heavy hit deals two damage",crate.is_broken())
	p.global_position=route.workbench_pos+Vector3(0,0.02,0);p.velocity=Vector3.ZERO
	await wait(0.2);await interact()
	route.apply_workbench_action("starter_sword");await wait(.05)
	route.main.pause_controller.resume();await wait(.08)
	check("free return to fast sword",p.weapon_id=="starter_sword" and p._starter_model.is_visible_in_tree() and not p._heavy_model.visible and route.shards==0)
	p._start_attack(1)
	check("starter timing preserved",is_equal_approx(p._attack_dur,0.59))
	var ledger=load("res://modules/equipment/equipment_ledger.gd").new()
	ledger.import_state({"shards":1e30})
	check("huge JSON number clamps before integer conversion",ledger.shards==999999)
	print("H15 SUMMARY checks=%d failures=%d"%[checks,failures])
	var result:=1 if failures else 0
	var scene:=get_tree().current_scene
	reparent(get_tree().root);scene.queue_free();route=null;p=null;crate=null;fresh=null;ledger=null
	await wait(0.2);get_tree().quit(result)
