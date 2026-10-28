extends SceneTree
var fails := 0
func _initialize(): call_deferred("run")
func check(label: String, ok: bool):
 print("H18 VISUAL ","PASS " if ok else "FAIL ",label)
 if not ok: fails += 1
func run():
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 current_scene = scene
 await create_timer(0.8).timeout
 var player = get_first_node_in_group("player")
 if player == null:
  print("H18 FAIL missing player"); quit(1); return
 var fx = root.get_node("FX")
 var pos: Vector3 = player.global_position + Vector3(1.0,1.3,0.2)
 fx.blood(pos,26,4.5,Vector3(1,0.3,0))
 var spray = scene.get_node("CombatBloodSpray")
 check("scene-owned emitter", spray.get_parent()==scene)
 check("one live burst",spray.active_count()==1)
 await create_timer(0.13).timeout
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("H18_OUTPUT")+"/blood-right.png")
 # The burst retires on its own timer (1.5 s); an unfocused test window may pause the run
 # meanwhile, so allow up to 5 s of wall time.
 for i in 50:
  await create_timer(0.1).timeout
  if spray.active_count()==0 and spray.get_child_count()==0:break
 check("all particles and timers retired",spray.active_count()==0 and spray.get_child_count()==0)
 for i in 30: fx.blood(pos,26,4.5,Vector3(-1,0.3,0))
 check("burst limit under repeated hits",spray.active_count()==8)
 await process_frame
 check("bounded children",spray.get_child_count()<=16)
 await create_timer(0.13).timeout
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(OS.get_environment("H18_OUTPUT")+"/blood-left.png")
 var before: Array = spray.get_children()
 spray.clear()
 for i in 3: await process_frame  # queued frees leave at the end of a frame
 # (Judged on the bursts that existed: the running game may bleed anew meanwhile.)
 check("clear releases all children",before.all(func(c): return not is_instance_valid(c)))
 scene.queue_free()
 await process_frame
 check("scene reload releases emitter",not is_instance_valid(spray))
 print("H18 VISUAL failures=",fails)
 quit(1 if fails else 0)
