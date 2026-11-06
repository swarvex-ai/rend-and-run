extends SceneTree
var failures:=0
func _initialize():call_deferred("run")
func check(label:String,ok:bool):
 print("RETURN ","PASS " if ok else "FAIL ",label)
 if not ok:failures+=1
func run():
 if not OS.get_user_data_dir().begins_with("/tmp/"):quit(2);return
 root.size=Vector2i(960,540)
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(.3).timeout
 main.pause_controller.resume()
 for e in main.route.enemies:e.set_physics_process(false);e.collision_layer=0
 var r=main.route;var p=main.player;var service=r.service_return
 var lift_x:float=service.lift_x
 var catwalk_x:float=lift_x-1.2
 var return_start:float=service.return_start_x
 if DisplayServer.get_name()!="headless":
  p.global_position=Vector3(lift_x,.08,0);await create_timer(.35).timeout
  RenderingServer.force_draw(false);root.get_texture().get_image().save_png(OS.get_environment("RETURN_OUTPUT")+"/lift-bottom.png")
 check("locked before boss",not service.interact(Vector3(lift_x,0,0)))
 for e in r.enemies:
  e._dead=true
  r._enemy_defeated(e)
 p.global_position=Vector3(r.MISSION.EXIT_X+1,.08,0);p.velocity=Vector3.ZERO
 var waited:=0.0
 while not r.completed and waited<2.0:
  await create_timer(.1).timeout
  waited+=.1
 check("completion remains available before return",r.completed and paused)
 main.pause_controller.resume();await create_timer(.15).timeout
 Input.action_press("interact");await create_timer(.05).timeout;Input.action_release("interact")
 await create_timer(1).timeout
 check("E input starts lift with rider",service.target_y==5 and p.global_position.y>1.2)
 paused=true;var y=service.lift.position.y
 await create_timer(.25,true).timeout
 check("normal tree pause freezes lift",is_equal_approx(y,service.lift.position.y))
 paused=false;await create_timer(2.6).timeout
 check("actual player reaches upper level",p.is_on_floor() and absf(p.global_position.y-5)<.08)
 Input.action_press("jump");await create_timer(.18).timeout;Input.action_release("jump")
 check("upper jump respects ceiling",p.global_position.y<5.3)
 await create_timer(.4).timeout
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false);root.get_texture().get_image().save_png(OS.get_environment("RETURN_OUTPUT")+"/lift-top.png")
 var walk_time:float=(catwalk_x-return_start)/p.move_speed*1.5
 Input.action_press("move_left")
 var walked:=0.0
 while p.global_position.x>=1.5 and walked<walk_time:
  await create_timer(.1).timeout
  walked+=.1
 Input.action_release("move_left")
 await create_timer(1.4).timeout
 check("full physical return reaches first room alive",p.global_position.x<1.5 and p.global_position.y<.1 and p.is_on_floor() and not p._dying)
 print("RETURN POSITION ",p.global_position)
 # Recall from ground uses actual interaction even after player left lift upstairs.
 p.global_position=Vector3(lift_x,.08,0);p.velocity=Vector3.ZERO;await create_timer(.2).timeout
 Input.action_press("interact");await create_timer(.05).timeout;Input.action_release("interact")
 check("ground recall does not require riding upstairs",service.target_y==0)
 await create_timer(3.4).timeout
 check("lift returns for reboarding",is_zero_approx(service.lift.position.y))
 check("beside lower deck cannot accidentally dispatch empty lift",not service.interact(Vector3(lift_x-1.5,0,0)))
 check("midshaft position has no station interaction",service.prompt(Vector3(lift_x,2.5,0)).is_empty() and not service.interact(Vector3(lift_x,2.5,0)))
 p.global_position=Vector3(catwalk_x,5.08,0);p.velocity=Vector3.ZERO;await create_timer(.2).timeout
 Input.action_press("interact");await create_timer(.05).timeout;Input.action_release("interact")
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false);root.get_texture().get_image().save_png(OS.get_environment("RETURN_OUTPUT")+"/lift-entry.png")
 check("upper landing can call lift from safe catwalk",service.target_y==5)
 await create_timer(3.4).timeout
 check("upper recall arrives without moving waiting player",absf(service.lift.position.y-5)<.01 and p.is_on_floor() and absf(p.global_position.y-5)<.08)
 r._save_progress();var shards=r.shards
 main.queue_free();await process_frame;await process_frame
 main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main;await create_timer(.2,true).timeout
 check("completed state restores access after reload",main.route.completed and main.route.service_return.unlocked and main.route.shards==shards)
 main.queue_free();paused=false;await process_frame;await process_frame
 print("RETURN SUMMARY failures=",failures);quit(1 if failures else 0)
