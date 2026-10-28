extends SceneTree
var fails := 0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 print("CABLE ","PASS " if ok else "FAIL ",label)
 if not ok:fails+=1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 root.size = Vector2i(960,540)
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 main.pause_controller.resume();main.set_process(false)
 for e in main.route.enemies:e.set_physics_process(false)
 main.player.global_position=Vector3(3.3,0,0)
 var cam=main.get_node("Camera3D");cam.global_position=Vector3(4,1.6,7)
 var cable=main.route.get_node("DamagedCable")
 check("authored socket imported",cable.socket!=null)
 check("mount and cut stay behind combat plane",cable.socket.global_position.z < -1.0 and cable.socket.global_position.y>1.8)
 check("bounded reusable emitter",cable.sparks.amount==14 and cable.sparks.one_shot and not cable.flash.shadow_enabled)
 var nodes=cable.get_child_count()
 cable.countdown=.01
 await create_timer(.12).timeout
 check("burst starts at cable tip",cable.burst_count>0 and cable.sparks.global_position.is_equal_approx(cable.socket.global_position))
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  root.get_texture().get_image().save_png(OS.get_environment("CABLE_OUTPUT")+"/sparks.png")
 paused=true
 var before=cable.countdown
 await create_timer(.35,true).timeout
 check("pause freezes effect schedule",is_equal_approx(before,cable.countdown))
 paused=false
 await create_timer(.7).timeout
 check("flash fades to zero",is_zero_approx(cable.flash.light_energy))
 cam.global_position.x=30
 var bursts=cable.burst_count
 await create_timer(3.4).timeout
 check("distant cable stops emitting",cable.burst_count==bursts and not cable.sparks.emitting and is_zero_approx(cable.flash.light_energy))
 cam.global_position.x=4
 await create_timer(3.5).timeout
 check("return resumes without node growth",cable.burst_count>bursts and cable.get_child_count()==nodes)
 main.queue_free();await process_frame;await process_frame
 print("CABLE SUMMARY failures=",fails);quit(1 if fails else 0)
