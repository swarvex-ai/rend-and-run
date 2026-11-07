extends Node
var failures:=0
func check(label:String,ok:bool)->void:
 print("V48 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func run()->void:
 var main=get_parent();var route=main.route;var p=main.player;var guard=route.enemies[2]
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for e in route.enemies:e.set_physics_process(false)
 p.set_physics_process(false)
 guard.debug_reset_ai();guard._state=guard.CHASE
 var edge:float=guard._west_edge()
 guard.debug_reset_ai();guard.get_node("VisualPivot").rotation.y=PI
 var guard_x:float=edge+0.9
 guard.global_position=Vector3(guard_x,0.01,0)
 p.global_position=Vector3(guard_x-2.2,0,0)
 guard.set_physics_process(true);await wait(0.2);guard._enter(guard.CHASE)
 var start:float=guard.global_position.x
 var step_start:float=start
 for i in 60:
  await get_tree().physics_frame
  if guard._guard_spacing.is_active():step_start=guard.global_position.x;break
 await wait(0.05)
 check("approach triggers visible retreat",guard._guard_spacing.is_active() and guard.global_position.x>start+0.1)
 check("retreat uses backward walk",guard._guard_spacing.is_active() and guard._anim.assigned_animation=="walk")
 if DisplayServer.get_name()!="headless":
  RenderingServer.force_draw(false)
  get_viewport().get_texture().get_image().save_png(OS.get_environment("V48_OUTPUT")+"/retreat.png")
 for i in 60:
  await get_tree().physics_frame
  if not guard._guard_spacing.is_active():break
 guard.set_physics_process(false)
 var distance:float=guard.global_position.x-step_start
 print("V48 retreat actual=",distance," desired=",guard._guard_spacing.distance_traveled())
 check("retreat is bounded near 0.7m",distance>0.5 and distance<=0.72)
 p.global_position.x=guard.global_position.x-2.2
 check("step does not repeat while close",not guard._guard_spacing.is_armed() and is_zero_approx(guard._guard_retreat_velocity(-2.2,0.1)))
 guard._guard_retreat_velocity(-4.1,0.01)
 check("separation rearms step",guard._guard_spacing.is_armed())
 guard._state=guard.CHASE;guard._stun=0;guard._kb_timer=0
 guard._guard_retreat_velocity(-2.2,0.01);var hp:int=guard.hp
 guard.take_melee_hit(1,Vector3(-2,0,0))
 check("ordinary hit damages and cancels retreat",guard.hp==hp-1 and not guard._guard_spacing.is_active())
 guard._stun=0;guard._kb_timer=0;guard.debug_reset_ai();guard._state=guard.CHASE
 guard._guard_retreat_velocity(-2.2,0.01);guard.receive_parry()
 check("parry cancels retreat",not guard._guard_spacing.is_active())
 guard._stun=0;guard._kb_timer=0;guard.debug_reset_ai();guard._state=guard.CHASE
 guard._guard_retreat_velocity(-2.2,0.01);guard.interrupt_with_pressure(guard.global_position-Vector3.RIGHT)
 check("coolant cancels retreat",not guard._guard_spacing.is_active())
 guard._stun=0;guard._kb_timer=0;guard.debug_reset_ai();guard._state=guard.CHASE
 guard._guard_retreat_velocity(-2.2,0.01);guard._guard_retreat_velocity(2.2,0.01)
 check("crossing behind cancels committed direction",not guard._guard_spacing.is_active())
 # Backed against the actual security cover: no clipping or futile step.
 guard.debug_reset_ai();guard._stun=0;guard._kb_timer=0;guard._state=guard.CHASE
 var cover_x:float=route.get_node("SecurityCover").global_position.x
 guard.global_position=Vector3(cover_x-1.3,0.01,0);guard.velocity=Vector3.ZERO
 await wait(0.1)
 check("solid cover prevents retreat start",is_zero_approx(guard._guard_retreat_velocity(-2.2,0.016)) and not guard._guard_spacing.is_active())
 # Remove the floor under the guard's retreat target; the rest of the setup stays valid.
 guard.global_position=Vector3(guard_x,0.01,0);guard.velocity=Vector3.ZERO
 await wait(0.1)
 var floor_shape:CollisionShape3D=route.get_node("Foundation/Collision")
 floor_shape.set_deferred("disabled",true);await wait(0.05)
 var no_ground:bool=guard.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(guard_x+0.7,0.31,0),Vector3(guard_x+0.7,-0.79,0),1)).is_empty()
 check("no ground behind prevents retreat",no_ground and is_zero_approx(guard._guard_retreat_velocity(-2.2,0.016)) and not guard._guard_spacing.is_active())
 floor_shape.set_deferred("disabled",false);await wait(0.05)
 guard.debug_reset_ai();check("reset is armed and inactive",guard._guard_spacing.is_armed() and not guard._guard_spacing.is_active())
 route._message("Speicherfehler",5,3);route._guard_feedback("block")
 check("save warning survives combat feedback",route.toast=="Speicherfehler")
 route.feedback.clear();route._message("hint",3,0);route._guard_feedback("parry")
 check("parry replaces routine hint",route.toast=="PARIERT — Gegenangriff!")
 print("V48 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
