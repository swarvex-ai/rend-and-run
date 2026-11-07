extends Node
var failures:=0
func check(label:String,ok:bool)->void:
 print("V45 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func run()->void:
 var main=get_parent();var p=main.player;var route=main.route
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for e in route.enemies:e.set_physics_process(false)
 await wait(0.3)
 var guard:Node=null;var hound:Node=null
 for e in route.enemies:
  if e.encounter_id=="guard":guard=e
  elif e.encounter_id=="hound":hound=e
 var guard_x:=0.0;var hound_x:=0.0
 for spec in route.MISSION.ENCOUNTERS:
  if spec.id=="guard":guard_x=spec.x
  elif spec.id=="hound":hound_x=spec.x
 check("pair shares a nearby engagement area",is_equal_approx(guard.global_position.x-hound.global_position.x,guard_x-hound_x))
 p.set_physics_process(false);p.global_position=Vector3(33,0.01,0)
 guard.get_node("VisualPivot").rotation.y=PI;guard._ranged_attack=true;guard._aim_point=Vector3(32,1.2,0);guard._enter(guard.WINDUP)
 guard._state_t=0.3;guard._physics_process(0.016)
 check("early charge acquires visible target",guard._aim_point.distance_to(guard._chest(p))<0.001)
 var front_target:Vector3=guard._aim_point
 p.global_position.x=guard.global_position.x+2;guard._physics_process(0.016)
 check("acquisition never swivels behind body",guard._aim_point==front_target)
 var locked:Vector3=guard._aim_point
 guard._state_t=0.6;p.global_position.x=34;guard._physics_process(0.016)
 check("final charge commits aim",guard._aim_point==locked)
 check("aim lock is visibly marked",guard._attack_cue._mat.albedo_color.r>0.9)
 guard._enter(guard.CHASE)
 check("lock marker clears with phase",not guard._attack_cue._pivot.visible)
 var cover=route.get_node("SecurityCover")
 var impacts:Array=[]
 var bolt=preload("res://modules/combat/energy_bolt.gd").new();main.add_child(bolt)
 bolt.impacted.connect(func(body,_point,_normal):impacts.append(body))
 bolt.launch(Vector3(39.3,1.2,0),Vector3(40,0,0),1)
 await wait(0.15)
 check("real swept bolt stops at cover",impacts.size()==1 and impacts[0]==cover and bolt.is_resolved())
 bolt.queue_free()
 var ray:=PhysicsRayQueryParameters3D.create(Vector3(39,1.5,0),Vector3(43,1.5,0),1)
 check("space above cover stays clear",p.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
 guard.global_position.x=30.0
 p.global_position=Vector3(39.4,0.01,0);p.velocity=Vector3.ZERO;p.set_physics_process(true)
 await wait(0.1);Input.action_press("move_right");Input.action_press("jump")
 var top:=0.0
 for i in 100:
  await get_tree().physics_frame
  top=maxf(top,p.global_position.y)
  if p.global_position.x>42.0:break
 Input.action_release("jump");Input.action_release("move_right")
 check("actual jump clears barrier",p.global_position.x>42.0 and top>1.25)
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  get_viewport().get_texture().get_image().save_png(OS.get_environment("V45_OUTPUT")+"/security_cover.png")
 print("V45 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
