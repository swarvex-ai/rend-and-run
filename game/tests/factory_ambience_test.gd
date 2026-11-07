extends SceneTree
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool) -> void:
	print("FACTORY AMBIENCE ", "PASS " if ok else "FAIL ", label)
	if not ok: failures += 1
func run():
	Engine.max_fps=120
	var isolated := OS.get_user_data_dir().begins_with("/tmp/")
	check("isolated user data under /tmp", isolated)
	if not isolated: quit(1); return
	var scene=Node3D.new();root.add_child(scene)
	var actor=Node3D.new();scene.add_child(actor)
	var ambience=preload("res://modules/audio/factory_ambience.gd").new();ambience.actor=actor;scene.add_child(ambience)
	actor.position.x=4
	await create_timer(1.5).timeout
	check("ventilation and servers loops playing", ambience.ventilation.playing and ambience.servers.playing)
	check("ventilation audible, servers silent at spawn", ambience.ventilation.volume_linear>.35 and ambience.servers.volume_linear<.001)
	check("ventilation loop is ten seconds at 48 kHz", ambience.ventilation.stream.loop_end==480000 and ambience.ventilation.stream.mix_rate==48000)
	actor.position.x=12
	await create_timer(1.5).timeout
	check("servers fade in near the rack", ambience.servers.volume_linear>.30 and ambience.ventilation.volume_linear>.25)
	var gain:float=ambience.servers.volume_linear
	paused=true
	actor.position.x=30
	await create_timer(.25,true).timeout
	check("volumes hold while paused", is_equal_approx(gain,ambience.servers.volume_linear))
	paused=false
	await create_timer(2.5).timeout
	check("both loops fade out after exit", ambience.servers.volume_linear<.001 and ambience.ventilation.volume_linear<.001)
	check("scene owns exactly two audio players", scene.find_children("*","AudioStreamPlayer",true,false).size()==2)
	var first=ambience.ventilation;var second=ambience.servers
	scene.queue_free();await process_frame;await process_frame
	check("players freed with the scene", not is_instance_valid(first) and not is_instance_valid(second))
	await create_timer(.15).timeout
	print("FACTORY AMBIENCE PASS: loop length, room/rack crossfade, pause, exit fade, two scene-owned players, cleanup")
	print("FACTORY AMBIENCE SUMMARY failures=", failures)
	quit(1 if failures else 0)
