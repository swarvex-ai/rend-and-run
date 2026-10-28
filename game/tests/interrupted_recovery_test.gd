extends SceneTree
var failures:=0
func _initialize()->void:call_deferred("run")
func check(label:String,ok:bool)->void:
 print("V36-REACT %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func run()->void:
 var main=load("res://main.tscn").instantiate();root.add_child(main);current_scene=main
 await create_timer(0.3).timeout
 var e=main.route.enemies[0];e.set_physics_process(false)
 e._enter(e.WINDUP);e._state_t=0.2;e._update_weapon_pose(0)
 e.take_melee_hit(1,Vector3(1,0,0))
 await create_timer(0.35).timeout
 e._stun=0;e._state_t=0.35;e._update_weapon_pose(0)
 check("interrupted swing cannot reappear after hit stun",e._anim.assigned_animation!="combat/slash_light" and e._hit_recovering)
 e._enter(e.CHASE);check("new decision clears reaction recovery",not e._hit_recovering)
 e._enter(e.SWING);e.receive_parry();await create_timer(0.7).timeout;e._stun=0;e._update_weapon_pose(0)
 check("parry recovery also avoids cancelled slash",e._anim.assigned_animation!="combat/slash_light" and e._hit_recovering)
 print("V36-REACT SUMMARY failures=",failures);quit(1 if failures else 0)
