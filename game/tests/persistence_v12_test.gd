extends SceneTree
func _initialize() -> void:call_deferred("run")
func run() -> void:
	if OS.get_environment("V12_PERSISTENCE_TEST")!="1":
		push_error("Use an isolated XDG_DATA_HOME with V12_PERSISTENCE_TEST=1")
		quit(2);return
	var f:=FileAccess.open("user://rendrun_route_v12.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":12,"armor":true,"checkpoint":true,"completed":false,"cleared":["first"]}));f.close()
	var scene: Node3D=load("res://main.tscn").instantiate()
	root.add_child(scene);current_scene=scene
	await create_timer(0.3).timeout
	var passed: bool=scene.route.armor and scene.route.checkpoint and scene.player.max_hp==7 and scene.player.hp==7 and absf(scene.player.position.x-26)<0.2 and scene.route.enemies.size()==3 and scene.player._hero_skel.has_node("LaborArmor")
	print("V12 PERSISTENCE ","PASS" if passed else "FAIL"," saved equipment/checkpoint/defeated guard restored on fresh scene")
	scene.queue_free();await create_timer(0.1).timeout
	quit(0 if passed else 1)
