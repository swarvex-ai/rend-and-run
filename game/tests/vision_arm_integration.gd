extends SceneTree
var failures := 0
func _initialize(): call_deferred("run")
func check(label: String, ok: bool):
	print("ARM ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):
		push_error("Use isolated XDG_DATA_HOME under /tmp"); quit(2); return
	var ledger = load("res://modules/equipment/equipment_ledger.gd").new()
	check("new game owns no weapon", ledger.equipped_weapon().is_empty() and not ledger.owns("robot_arm"))
	ledger.credit(20)
	check("upgrade cannot bypass arm discovery", not ledger.purchase("reinforced_arm").ok and ledger.shards == 20)
	ledger.import_state({"loadout_version":1,"owned":["starter_sword","vibroblade"],"equipped_weapon":"vibroblade","shards":9})
	check("legacy blades migrate without losing progress", ledger.owns("robot_arm") and ledger.owns("reinforced_arm") and ledger.equipped_weapon()=="reinforced_arm" and ledger.shards==9)
	var exported: Dictionary = ledger.export_state()
	ledger.import_state(exported)
	check("migration roundtrip is idempotent", ledger.export_state()==exported)
	var slot_restore=load("res://lab_route.gd").new()
	slot_restore._restore_progress({"version":12,"armor":true,"shield":true,"equipment":{"loadout_version":2,"owned":["robot_arm","lab_armor","salvage_shield"],"equipped_weapon":"robot_arm","slots":{"armor":"","shield":""}}})
	check("v2 empty gear slots override legacy flags", not slot_restore.armor and not slot_restore.shield)
	slot_restore.free()
	var main = load("res://main.tscn").instantiate()
	root.add_child(main); current_scene=main
	await create_timer(0.3).timeout
	main.pause_controller.resume(); main.set_process(false)
	var r=main.route; var p=main.player
	for enemy in r.enemies:
		enemy.set_physics_process(false); enemy.collision_layer=0
	p.set_physics_process(false)
	check("real player starts unarmed with hidden weapon", p.weapon_id.is_empty() and not p._starter_model.visible and not p._heavy_model.visible)
	p._start_attack(1)
	check("unarmed player cannot produce weapon attack", p._attack_phase==0)
	p.global_position=Vector3(12,0.05,0)
	check("cannot collect remotely", not r.collect_start_arm())
	p.global_position=Vector3(1.8,0.05,0); p._dash_left=0
	p._dash_left = 0.1
	check("dash suppresses pickup eligibility", not r.can_collect_start_arm())
	p._dash_left = 0.0
	check("nearby idle player can collect", r.can_collect_start_arm())
	r.arm_pickup.set_focused(true)
	check("reachable pickup shows focused feedback", r.arm_pickup.focused)
	check("collect and auto equip arm", r.collect_start_arm() and p.weapon_id=="robot_arm" and p._starter_model.visible)
	check("pickup consumed exactly once", not r.collect_start_arm() and r.arm_pickup.collected and not r.arm_pickup.get_node("SalvageArm").visible)
	check("collected pickup clears focus", not r.arm_pickup.focused)
	check("found arm is saved", not r.save_error)
	var saved=JSON.parse_string(FileAccess.get_file_as_string(r.SAVE_PATH))
	var restored=load("res://lab_route.gd").new(); restored._restore_progress(saved)
	check("save restores mechanical weapon ownership", restored.equipment.owns("robot_arm") and restored.equipment.equipped_weapon()=="robot_arm")
	restored.free()
	p.crouching=true; p._start_attack(1)
	check("crouched arm attack starts", p._attack_phase==1 and p._crouch_attack)
	p._cancel_attack(); p.crouching=false
	check("obsolete sword selection rejected", not r.apply_equipment_selection("weapon","starter_sword"))
	r.equipment.credit(6)
	check("earned upgrade still works", r.equipment.purchase("reinforced_arm").ok)
	check("upgrade uses mechanical model", r.apply_equipment_selection("weapon","reinforced_arm") and p._heavy_model.visible and not p._starter_model.visible)
	paused=false
	main.queue_free(); await process_frame; await process_frame
	print("ARM RESULT failures=",failures)
	quit(1 if failures else 0)
