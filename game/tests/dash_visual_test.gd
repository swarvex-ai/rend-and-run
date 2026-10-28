extends SceneTree
var failures := 0
var checks: Array = []
func _initialize(): call_deferred("run")
func check(label: String, ok: bool):
 checks.append({"label":label,"pass":ok})
 print("DASH ","PASS " if ok else "FAIL ",label)
 if not ok: failures += 1
func run():
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 current_scene = scene
 await create_timer(0.8).timeout
 var player = get_first_node_in_group("player")
 for action in InputMap.get_actions():
  InputMap.action_erase_events(action)
  Input.action_release(action)
 scene.pause_controller.set_process_input(false)
 scene.pause_controller.resume()
 for e in scene.route.enemies:
  e.set_physics_process(false)
  e.hide()
  e.collision_layer=0
 var fx = root.get_node("FX")
 for dir in [1.0,-1.0]:
  player.global_position=Vector3(31,0.05,0)
  player.velocity=Vector3.ZERO
  await create_timer(0.8).timeout
  var start: Vector3 = player.global_position
  var action: String = "move_right" if dir>0 else "move_left"
  Input.action_press(action)
  Input.action_press("dodge")
  await physics_frame
  await process_frame
  Input.action_release("dodge")
  Input.action_release(action)
  var spray=scene.get_node_or_null("DashStreaks")
  check("input starts dash " + str(dir),spray!=null and player._dash_left>0)
  if spray==null:
   quit(1);return
  var burst: CPUParticles3D=spray.get_child(spray.get_child_count()-1)
  check("visible mesh trails opposite movement " + str(dir),burst.mesh!=null and burst.direction.dot(Vector3(dir,0,0)) < -0.99)
  check("particles remain in world space " + str(dir),burst.top_level and not burst.local_coords and burst.global_basis.is_equal_approx(Basis.IDENTITY))
  await create_timer(0.05).timeout
  if DisplayServer.get_name()!="headless":
   RenderingServer.force_draw(false)
   root.get_texture().get_image().save_png(OS.get_environment("DASH_OUTPUT")+"/dash-"+("right" if dir>0 else "left")+".png")
  for tick in 20:
   if player._dash_left<=0.001: break
   await physics_frame
   await process_frame
  var distance: float=(player.global_position.x-start.x)*dir
  print("DASH measured distance=",distance," remaining=",player._dash_left)
  check("dash covers expected 2.3–2.9m " + str(dir),distance>2.3 and distance<2.9)
  check("dash window ends " + str(dir),player._dash_left<=0.001)
  await create_timer(0.3).timeout
  check("burst and timer retire " + str(dir),spray.active_count()==0 and spray.get_child_count()==0)
 for i in 20: fx.dash_flash(player.global_position,Vector3.RIGHT)
 var spray=scene.get_node("DashStreaks")
 check("burst cap",spray.active_count()==4)
 await process_frame
 check("retired bursts freed",spray.get_child_count()==4)
 spray.clear()
 await process_frame
 check("clear frees timers too",spray.get_child_count()==0)
 fx.dash_flash(player.global_position,Vector3.ZERO)
 check("zero direction safe fallback",spray.get_child(0).direction==Vector3.LEFT)
 scene.queue_free()
 await process_frame
 check("scene unload releases effect",not is_instance_valid(spray))
 var output=OS.get_environment("DASH_OUTPUT")
 if not output.is_empty():
  var f=FileAccess.open(output+"/dash-results.json",FileAccess.WRITE)
  f.store_string(JSON.stringify({"failures":failures,"checks":checks},"  "))
 quit(1 if failures else 0)
