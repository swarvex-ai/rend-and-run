extends Node
## Arranged visual/lifecycle fixture, not a natural-input playthrough.
var failures:=0
func check(label:String,ok:bool)->void:
 print("V41 %s %s"%["PASS" if ok else "FAIL",label])
 if not ok:failures+=1
func wait(t:float)->void:await get_tree().create_timer(t).timeout
func shot(name:String)->void:
 if DisplayServer.get_name()=="headless":return
 RenderingServer.force_draw(false);get_viewport().get_texture().get_image().save_png(OS.get_environment("V41_OUTPUT")+"/"+name+".png")
func run()->void:
 var main=get_parent();var p=main.player;var route=main.route
 for action in InputMap.get_actions():InputMap.action_erase_events(action);Input.action_release(action)
 main.pause_controller.set_process_input(false);main.pause_controller.resume()
 for e in route.enemies:e.set_physics_process(false)
 p.global_position=Vector3(32,0,0)
 await wait(0.4)
 var e=route.enemies[1];e.global_position=Vector3(34,0,0);e.get_node("VisualPivot").rotation.y=PI
 e.forced_strike="side"
 e._enter(e.WINDUP);e._state_t=0.15;e._update_weapon_pose(0)
 await wait(0.08)
 check("high cue visible in committed direction",e._attack_cue._pivot.visible and e._attack_cue._pivot.position.x<0 and is_equal_approx(e._attack_cue._pivot.position.y,1.25))
 e.forced_strike=""
 shot("high")
 e.take_melee_hit(1,Vector3(2,0,0))
 check("hit interruption cancels cue immediately",not e._attack_cue._pivot.visible)
 e._enter(e.WINDUP);e._state_t=0.15;e._update_weapon_pose(0)
 await wait(0.08);shot("low")
 check("low attack cue matches low commitment",e._committed_low and is_equal_approx(e._attack_cue._pivot.position.y,0.35))
 e.receive_parry();check("parry cancels cue",not e._attack_cue._pivot.visible)
 e._enter(e.WINDUP);e._enter(e.SWING);check("swing does not leave stale warning",not e._attack_cue._pivot.visible)
 var count:int=e._attack_cue.get_child_count(true)
 for i in 10:e._enter(e.WINDUP)
 check("repeat attacks reuse cue nodes",e._attack_cue.get_child_count(true)==count)
 await wait(0.5);check("cue expires if transition is delayed",not e._attack_cue._pivot.visible)
 e._enter(e.WINDUP);e.take_melee_hit(5,Vector3(2,0,0));check("death cancels cue",e._dead and not e._attack_cue._pivot.visible)
 var brute=main._make_enemy(34,2);brute.set_physics_process(false)
 brute.get_node("VisualPivot").rotation.y=PI
 brute._enter(brute.WINDUP);brute._state_t=0.4
 var hp_before:int=brute.hp
 brute.take_melee_hit(1,Vector3(2,0,0))
 check("heavy commitment takes the hit",brute.hp==hp_before-1)
 check("heavy commitment retains warning",brute._attack_cue._pivot.visible)
 brute._update_weapon_pose(0);await wait(0.08);shot("heavy")
 brute._enter(brute.IDLE);brute.queue_free()
 var guard=route.enemies[2];guard.global_position=Vector3(34,0,0);guard.get_node("VisualPivot").rotation.y=PI;guard._ranged_attack=true;guard._enter(guard.WINDUP)
 guard._state_t=0.3;guard._update_weapon_pose(0);await wait(0.08);shot("ranged")
 check("ranged warning has charge lifetime",guard._attack_cue._pivot.visible)
 print("V41 SUMMARY failures=",failures);get_tree().quit(1 if failures else 0)
