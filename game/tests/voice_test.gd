extends SceneTree
# Voices: a robot that engages says a line (with a subtitle over its head), the squad does not
# talk over itself, and the PA announces the escape and the next sectors.
var failures := 0
func _initialize():call_deferred("run")
func check(label: String, ok: bool, detail := "") -> void:
	print("VOICE %s %s %s" % ["PASS" if ok else "FAIL", label, detail])
	if not ok:failures += 1
func run():
	if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
	var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(.4).timeout;main.pause_controller.resume()
	var r=main.route;var p=main.player
	for e in r.enemies:e.set_physics_process(false)
	await create_timer(1.5).timeout
	check("the PA announces the escape",r.voice.pa_spoken>=1)
	var foe=r.enemies[0];foe.set_physics_process(true);foe._taunted=false;r.voice._quiet=0.0
	foe._enter(foe.IDLE);foe.provoke()
	await process_frame
	var subtitle:Array=foe.get_children().filter(func(c):return c is Label3D and c.text!="" and c.name!="RoleLabel")
	check("an engaging robot speaks with a subtitle",foe._taunted and subtitle.size()>=1,"lines=%d"%r.voice.lines_spoken)
	var other=r.enemies[1]
	check("the squad does not talk over itself",not r.voice.say(other,"taunt"))
	p.global_position=Vector3(31.0,.05,0)
	await create_timer(.5).timeout
	check("the PA announces the sectors he reaches",r._pa_done.has("lockdown") or r._pa_done.has("assembly"))
	print("VOICE SUMMARY failures=",failures)
	main.queue_free();for i in 4:await process_frame
	quit(1 if failures else 0)
