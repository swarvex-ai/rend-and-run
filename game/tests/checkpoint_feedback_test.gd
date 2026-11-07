extends Node
var TEXT = load("res://data/route_texts.gd")
var failures:=0
func check(label:String,ok:bool)->void:
 print("V35 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func interact()->void:
 Input.action_press("interact");await wait(0.05);Input.action_release("interact");await wait(0.05)
func run()->void:
 var main=get_parent();var route=main.route;var c=route.checkpoint_console
 if DisplayServer.get_name()!="headless":DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
 # Isolate scripted actions from live desktop/controller events.
 for action in InputMap.get_actions():
  InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false)
 main.pause_controller.resume()
 for e in route.enemies:e.set_physics_process(false)
 await wait(0.3)
 check("new console starts unsaved",not c.saved and c.get_state_snapshot().label=="BEREIT")
 main.player.global_position=route.checkpoint_pos;main.player.hp=2;await wait(0.3)
 # Isolated test profile only: directory prevents opening the temporary save file.
 DirAccess.make_dir_absolute("user://rendrun_route_v12.json.tmp")
 await interact()
 check("failed write reports failure",route.save_error and route.toast==TEXT.t("msg_checkpoint_save_failed"))
 check("failure never claims persisted checkpoint",not c.saved and c.get_state_snapshot().label=="FEHLER")
 check("session checkpoint and healing retained",route.checkpoint and main.player.hp==main.player.max_hp and main.spawn_point==route.checkpoint_pos)
 DirAccess.remove_absolute("user://rendrun_route_v12.json.tmp")
 await interact()
 check("retry replaces stale error label immediately",not route.save_error and c.saved and c.get_state_snapshot().label=="GESICHERT")
 var data=JSON.parse_string(FileAccess.get_file_as_string("user://rendrun_route_v12.json"))
 check("real save contains checkpoint",data is Dictionary and data.checkpoint)
 await wait(0.7)
 check("pulse settles into persisted state",c.get_state_snapshot().pulse=="" and c.saved)
 c.flash_result(false);await wait(0.2);c.flash_result(true);await wait(0.45)
 check("replacement pulse still active",c.get_state_snapshot().pulse=="ok")
 await wait(0.2);check("replacement pulse expires",c.get_state_snapshot().pulse=="")
 Input.action_press("move_left");await wait(0.15);Input.action_release("move_left");await wait(0.2)
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(OS.get_environment("V35_OUTPUT")+"/checkpoint.png")
 var restored=load("res://lab_route.gd").new();restored._restore_progress(data)
 var fresh=load("res://modules/world/checkpoint_console.gd").new();fresh.set_saved(restored.checkpoint)
 check("restored checkpoint initializes saved visual",fresh.saved and fresh.get_state_snapshot().label=="GESICHERT")
 fresh.free();restored.free()
 print("V35 SUMMARY failures=",failures)
 get_tree().quit(1 if failures else 0)
