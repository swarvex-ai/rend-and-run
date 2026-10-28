extends SceneTree
var failures := 0
func check(label:String, ok:bool) -> void:
	if not ok: failures += 1
	print("PREFIX SAVE ","PASS " if ok else "FAIL ",label)
func _initialize() -> void:
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var route_script=load("res://lab_route.gd")
	var a=route_script.new()
	a.equipment.grant("robot_arm");a.equipment.equip_weapon("robot_arm")
	a.equipment.credit(18);a.equipment.purchase("reinforced_arm")
	a.equipment.prefixes.credit_servo(2)
	check("craft in ledger",a.equipment.craft_module("servo_i").ok)
	a.equipment.install_module("reinforced_arm","servo_i")
	a.shards=a.equipment.shards
	a.equipment.grant("lab_armor");a.equipment.equip("armor","")
	a.servo_run.begin(784)
	a.servo_run.defeat(1,0)
	a._save_progress()
	check("atomic writer accepted save",not a.save_error)
	var b=route_script.new();b._load_progress()
	check("real route reload preserves paid module",b.equipment.prefixes.owns_module("servo_i") and b.equipment.prefixes.installed("reinforced_arm")=="servo_i" and b.equipment.prefixes.servo==0 and b.shards==0)
	check("route pending reward persists",b.servo_run.pending(1,0)=={"shards":2,"servo":0} and not b.servo_run.defeat(1,0))
	check("reload does not recharge recipe",not b.equipment.craft_module("servo_i").ok and b.equipment.shards==0)
	var state=JSON.parse_string(FileAccess.get_file_as_string(a.SAVE_PATH))
	state.armor=true;state.shield=true
	b._restore_progress(state)
	check("v3 empty slots override obsolete flags",not b.armor and not b.shield and b.equipment.owns("lab_armor"))
	b._record_found_shield()
	check("legacy shield helper preserves prefix payload",b.equipment.prefixes.installed("reinforced_arm")=="servo_i")
	b._save_progress()
	var c=route_script.new();c._load_progress()
	check("second save idempotent",c.equipment.export_state()==b.equipment.export_state())
	a.free();b.free();c.free()
	print("PREFIX SAVE SUMMARY failures=",failures)
	quit(1 if failures else 0)
