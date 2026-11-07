extends Node
## Arranged AI integration fixture. No claim of natural play or motion approval.
var failures:=0
var main:Node
var p:Node
var e:Node
func check(label:String,ok:bool)->void:
 print("V44 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func prepare(front:float=1.0)->void:
 e.set_physics_process(false);e.debug_reset_ai();e.hp=20;e._dead=false;e._stun=0;e._kb_timer=0
 e.global_position=Vector3(32,0.01,0);e.get_node("VisualPivot").rotation.y=0 if front>0 else PI
 p.global_position=Vector3(32+4*front,0.01,0);p.velocity=Vector3.ZERO;p._dying=false
 e._attack_front=front;e._ranged_attack=false;e._swing_hit=false;e._state=e.SWING
 e._enter(e.RECOVERY);e.set_physics_process(true)
func run()->void:
 main=get_parent();p=main.player;e=main.route.enemies[1]
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for foe in main.route.enemies:foe.set_physics_process(false)
 p.set_physics_process(false)
 await wait(0.3) # Let scene startup complete before measuring subsecond windows.
 for front in [1.0,-1.0]:
  await prepare(front)
  var start_x:float=e.global_position.x
  await wait(0.08)
  check("miss leaves an initial punish window %s"%front,absf(e.global_position.x-start_x)<0.03)
  # Player changes sides AFTER commitment: retreat must not reverse or home.
  p.global_position.x=32-4*front
  var sample_t:float=e._recovery_duration()-0.02
  await wait(maxf(0.0,sample_t-0.08));e.set_physics_process(false)
  var retreat:float=(start_x-e.global_position.x)*front
  check("fixed bounded retreat %s"%front,retreat>0.40 and retreat<0.60)
  check("still in vulnerable recovery",e._state==e.RECOVERY and not e._recovery_step.is_active())
 await prepare();await wait(0.16)
 e.take_melee_hit(1,Vector3(2,0,0))
 check("counterhit deals full damage and cancels step",e.hp==19 and not e._recovery_step.is_active() and e._hit_recovering)
 e.set_physics_process(false)
 e._state=e.SWING;e._swing_hit=true;e._stun=0;e._kb_timer=0;e._enter(e.RECOVERY)
 check("successful swing does not retreat",not e._recovery_step.is_active())
 e._state=e.SWING;e._swing_hit=false;e._enter(e.RECOVERY);e.receive_parry()
 check("parry cancels retreat",not e._recovery_step.is_active())
 # A solid wall behind the enemy blocks the CharacterBody and cancels the plan.
 var wall:=StaticBody3D.new();wall.collision_layer=1;wall.position=Vector3(31.35,1,0)
 var col:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(0.2,2,2);col.shape=box;wall.add_child(col);main.add_child(wall)
 await prepare();await wait(0.32);e.set_physics_process(false)
 check("backstep cannot pass through wall",e.global_position.x>31.8 and not e._recovery_step.is_active())
 wall.queue_free();await get_tree().physics_frame
 # Elevated isolated floor: existing ground-ahead ray must stop a backward step.
 var ledge:=StaticBody3D.new();ledge.collision_layer=1;ledge.position=Vector3(100,4.9,0)
 var lc:=CollisionShape3D.new();var lb:=BoxShape3D.new();lb.size=Vector3(1.4,0.2,2);lc.shape=lb;ledge.add_child(lc);main.add_child(ledge)
 await prepare();e.global_position=Vector3(99.65,5.01,0);p.global_position=Vector3(103,5,0)
 await wait(0.32);e.set_physics_process(false)
 check("backward ground check prevents ledge exit",e.global_position.x>99.5 and e.global_position.y>4.9 and not e._recovery_step.is_active())
 ledge.queue_free()
 # Same encounter seed, actual crouch input vs standing; pinned high strike, no second attacker.
 e.forced_strike="side"
 if is_instance_valid(main.route.awakened):
  main.route.awakened.set_physics_process(false);main.route.awakened.collision_layer=0;main.route.awakened._dead=true
 for crouch in [false,true]:
  await prepare()
  e.set_physics_process(false);e.debug_reset_ai();e._attack_count=0
  p.reset_state();p.hp=5;p.global_position=Vector3(34.3,0.01,0);p._iframes=0
  p.set_physics_process(true)
  if crouch:Input.action_press("crouch")
  e._enter(e.CHASE);e.set_physics_process(true)
  await wait(0.82)
  check("crouch avoids announced high attack" if crouch else "standing is punished by high attack",p.hp==5 if crouch else p.hp==4)
  print("V44 POLICY crouch=",crouch," hp=",p.hp," enemy_x=",e.global_position.x," state=",e._state)
  if crouch and DisplayServer.get_name()!="headless":
   RenderingServer.force_draw(false)
   get_viewport().get_texture().get_image().save_png(OS.get_environment("V44_OUTPUT")+"/crouch_counter_window.png")
  Input.action_release("crouch");p.set_physics_process(false);e.set_physics_process(false)
 print("V44 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
