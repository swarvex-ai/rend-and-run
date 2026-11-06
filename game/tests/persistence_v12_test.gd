extends SceneTree
## V12 persistence: equipment, checkpoint and defeated encounters survive a restart,
## from the legacy save (migration path) and from the route's current save format.
const SAVE_PATH := "user://rendrun_route_v12.json"
const MISSION := preload("res://modules/world/notstrom_layout.gd")
var failures := 0
func _initialize() -> void:call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("V12 PERSISTENCE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run() -> void:
	if OS.get_environment("V12_PERSISTENCE_TEST")!="1":
		push_error("Use an isolated XDG_DATA_HOME with V12_PERSISTENCE_TEST=1")
		quit(2);return
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	_remove_save()
	var f:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":12,"armor":true,"checkpoint":true,"completed":false,"cleared":["first"]}));f.close()
	await _verify_loaded("legacy")
	_remove_save()
	var source=await _open_scene()
	source.route._equip_armor(false)
	source.route.checkpoint=true
	source.route.cleared.append("first")
	source.route._save_progress()
	source.queue_free();await create_timer(0.1).timeout
	await _verify_loaded("current")
	print("V12 PERSISTENCE SUMMARY failures=",failures)
	quit(0 if failures == 0 else 1)
func _remove_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
func _open_scene():
	var scene:Node3D=load("res://main.tscn").instantiate()
	root.add_child(scene);current_scene=scene
	await create_timer(0.3).timeout
	return scene
func _verify_loaded(prefix: String) -> void:
	var scene=await _open_scene()
	var route=scene.route
	var player=scene.player
	check("%s equipment restored"%prefix,
		route.armor and player.max_hp==7 and player.hp==7 and player._hero_skel.has_node("LaborArmor"))
	check("%s checkpoint restored"%prefix,
		route.checkpoint and absf(player.position.x-26)<0.2)
	var first_spawned:=false
	for foe in route.enemies:
		if foe.encounter_id=="first":first_spawned=true
	check("%s defeated guard stays defeated"%prefix,
		route.enemies.size()==MISSION.ENCOUNTERS.size()-1 and not first_spawned,
		"enemies=%d expected=%d first_spawned=%s"%[route.enemies.size(),MISSION.ENCOUNTERS.size()-1,first_spawned])
	scene.queue_free();await create_timer(0.1).timeout
