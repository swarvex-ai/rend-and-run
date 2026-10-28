extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 print("V40 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await create_timer(t).timeout
func run()->void:
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await wait(0.2)
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 var p=main.player;var route=main.route
 for e in route.enemies:e.set_physics_process(false)
 for role in [1,2]:
  var foe:Node
  for e in route.enemies:
   if e.role==role:foe=e
  p.reset_state();p.hp=5;p.global_position=Vector3(32,0.01,0);p.velocity=Vector3.ZERO
  await wait(0.65) # Let actual respawn invulnerability expire before measuring a hit.
  foe.global_position=Vector3(34.2 if role==2 else 34.3,0.01,0);foe.velocity=Vector3.ZERO
  foe.get_node("VisualPivot").rotation.y=PI;foe._kb_timer=0;foe._stun=0;foe._ranged_attack=false
  var start_x:float=foe.global_position.x
  foe._enter(foe.WINDUP);foe.set_physics_process(true)
  await wait(0.58 if role==1 else 0.82)
  foe.set_physics_process(false)
  check("role %d physically closes distance"%role,start_x-foe.global_position.x>0.5 and start_x-foe.global_position.x<1.5)
  check("role %d punishes standing in announced path"%role,p.hp==4)
 # Hint delivery stays once per kind and respects global spacing.
 var duelist=route.enemies[1]
 duelist.global_position=Vector3(33,0,0);p.global_position=Vector3(32,0,0)
 duelist._enter(duelist.WINDUP);duelist._committed_low=true
 route._combat_hint_cooldown=0;route.feedback.clear();route.toast_time=0
 route._offer_combat_hint()
 check("low attack teaches jump",route.toast.contains("springen"))
 route.toast="sentinel";route._offer_combat_hint()
 check("cooldown prevents hint spam",route.toast=="sentinel")
 route._combat_hint_cooldown=0;route._offer_combat_hint()
 check("same cue does not repeat",route.toast=="sentinel")
 print("V40 SUMMARY failures=",failures);quit(1 if failures else 0)
