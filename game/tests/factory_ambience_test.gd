extends SceneTree
func _initialize():call_deferred("run")
func run():
	Engine.max_fps=120
	assert(OS.get_user_data_dir().begins_with("/tmp/"))
	var scene=Node3D.new();root.add_child(scene)
	var actor=Node3D.new();scene.add_child(actor)
	var ambience=preload("res://modules/audio/factory_ambience.gd").new();ambience.actor=actor;scene.add_child(ambience)
	actor.position.x=4
	await create_timer(1.5).timeout
	assert(ambience.ventilation.playing and ambience.servers.playing)
	assert(ambience.ventilation.volume_linear>.35 and ambience.servers.volume_linear<.001)
	assert(ambience.ventilation.stream.loop_end==480000 and ambience.ventilation.stream.mix_rate==48000)
	actor.position.x=12
	await create_timer(1.5).timeout
	assert(ambience.servers.volume_linear>.30 and ambience.ventilation.volume_linear>.25)
	var gain:float=ambience.servers.volume_linear
	paused=true
	actor.position.x=30
	await create_timer(.25,true).timeout
	assert(is_equal_approx(gain,ambience.servers.volume_linear))
	paused=false
	await create_timer(2.5).timeout
	assert(ambience.servers.volume_linear<.001 and ambience.ventilation.volume_linear<.001)
	assert(scene.find_children("*","AudioStreamPlayer",true,false).size()==2)
	var first=ambience.ventilation;var second=ambience.servers
	scene.queue_free();await process_frame;await process_frame
	assert(not is_instance_valid(first) and not is_instance_valid(second))
	await create_timer(.15).timeout
	print("FACTORY AMBIENCE PASS: loop length, room/rack crossfade, pause, exit fade, two scene-owned players, cleanup")
	quit()
