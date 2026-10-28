extends Node
var failures := 0
func check(label: String, ok: bool):
 print("H19 ","PASS " if ok else "FAIL ",label)
 if not ok: failures += 1
func wait(seconds:float): await get_tree().create_timer(seconds).timeout
func run():
 var scene = get_tree().current_scene
 var player = get_tree().get_first_node_in_group("player")
 for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
 await wait(0.4)
 var before = FX.landing_events
 await wait(0.4)
 check("standing emits no dust",FX.landing_events==before)
 player.global_position=Vector3(0,2.0,0)
 player.velocity=Vector3(0,-5,0)
 for i in 100:
  await get_tree().physics_frame
  if FX.landing_events>before: break
 check("real falling contact emits exactly once",FX.landing_events==before+1)
 var dust=scene.get_node_or_null("LandingDust")
 check("landing owns two fans",dust!=null and dust.active_count()==1)
 await wait(0.045)
 RenderingServer.force_draw(false)
 if OS.get_environment("H19_OUTPUT")!="":get_viewport().get_texture().get_image().save_png(OS.get_environment("H19_OUTPUT")+"/landing.png")
 await wait(0.65)
 check("standing after landing does not retrigger",FX.landing_events==before+1)
 check("dust and timers fully cleaned",dust!=null and dust.get_child_count()==0)
 Input.action_press("jump")
 await wait(0.1)
 Input.action_release("jump")
 await wait(1.0)
 check("actual jump emits one more landing",FX.landing_events==before+2)
 print("H19 INTEGRATION failures=",failures)
 get_tree().quit(1 if failures else 0)
