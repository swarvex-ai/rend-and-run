extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 if not ok:failures+=1
 print("RELAY ","PASS " if ok else "FAIL ",label)
func use():
 Input.action_press("interact");await create_timer(.08).timeout
 Input.action_release("interact");await create_timer(.08).timeout
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.2).timeout;main.pause_controller.resume()
 var r=main.route;var p=main.player
 for e in r.enemies:e.set_physics_process(false)
 p.global_position=Vector3(58,.05,0);p.velocity=Vector3.ZERO
 await create_timer(.2).timeout
 await use()
 check("relay cannot skip uncleared freight",not r.relay_checkpoint)
 r.cleared.append_array(["freight_raider","freight_duelist"]);p.hp=2
 await use()
 check("secured relay heals and sets new respawn",r.relay_checkpoint and main.spawn_point.x==58 and p.hp==p.max_hp)
 var data=JSON.parse_string(FileAccess.get_file_as_string(r.SAVE_PATH))
 var restored=load("res://lab_route.gd").new();restored._restore_progress(data)
 check("relay activation survives save restore",restored.relay_checkpoint and restored.checkpoint)
 restored.free()
 p.global_position=Vector3(26,.05,0);p.velocity=Vector3.ZERO;await create_timer(.2).timeout;await use()
 check("earlier checkpoint remains selectable",not r.relay_checkpoint and main.spawn_point.x==26)
 restored=load("res://lab_route.gd").new();restored._restore_progress({"version":12,"layout_revision":2,"checkpoint":true,"relay_checkpoint":true,"cleared":[]})
 check("forged flag cannot bypass freight prerequisite",not restored.relay_checkpoint)
 restored.free()
 print("RELAY SUMMARY failures=",failures);quit(1 if failures else 0)
